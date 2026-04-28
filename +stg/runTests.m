function [results, coverage] = runTests(testFile, outDir, verbosity)
%RUNTESTS Execute the generated test class and return enriched results.
%
%   [RESULTS, COVERAGE] = STG.RUNTESTS(TESTFILE, OUTDIR, VERBOSITY) builds
%   a matlab.unittest TestSuite from TESTFILE, runs it, captures the test
%   log, and (when supported) produces Cobertura-XML coverage for the
%   source under test.

    arguments
        testFile  (1,1) string {mustBeFile}
        outDir    (1,1) string
        verbosity (1,1) double = 2
    end

    import matlab.unittest.TestSuite
    import matlab.unittest.TestRunner
    import matlab.unittest.plugins.ToFile
    import matlab.unittest.plugins.TestRunProgressPlugin
    import matlab.unittest.plugins.DiagnosticsOutputPlugin
    import matlab.unittest.Verbosity

    [testDir, testName] = fileparts(char(testFile));
    addedPath = false;
    if ~contains(path, testDir)
        addpath(testDir);
        addedPath = true;
    end
    cleanupPath = onCleanup(@() conditionalRmpath(addedPath, testDir));

    suite = TestSuite.fromClass(meta.class.fromName(testName));

    runner = TestRunner.withNoPlugins();

    logFile = fullfile(outDir, "test_log.txt");
    runner.addPlugin(TestRunProgressPlugin.withVerbosity(Verbosity(verbosity), ToFile(char(logFile))));
    runner.addPlugin(TestRunProgressPlugin.withVerbosity(Verbosity(verbosity)));
    runner.addPlugin(DiagnosticsOutputPlugin('OutputDetail', Verbosity(verbosity)));

    coverage = struct( ...
        "Available", false, ...
        "Reason",    "MATLAB code-coverage plugin not available in this release.", ...
        "XmlPath",   "", ...
        "HtmlPath",  "", ...
        "Percent",   NaN, ...
        "FilesCovered", strings(0,1));

    sourceDir = inferSourceDir(testFile);
    coverage = tryAttachCoverage(runner, sourceDir, outDir, coverage);

    startTime = datetime('now');
    results = runner.run(suite);
    finishTime = datetime('now');

    % Persist a results MAT file for downstream tooling.
    save(fullfile(outDir, "test_results.mat"), "results", "startTime", "finishTime");

    coverage = finalizeCoverage(coverage);
end

% =========================================================================
function dir = inferSourceDir(testFile)
    % By convention the source under test sits next to (or above) the test
    % output directory. We open the test file and read SourceUnderTest.
    dir = "";
    try
        txt = string(fileread(char(testFile)));
        tok = regexp(txt, "SourceUnderTest\s*=\s*""([^""]+)""", 'tokens', 'once');
        if ~isempty(tok)
            dir = string(fileparts(string(tok{1})));
        end
    catch
    end
end

% =========================================================================
function coverage = tryAttachCoverage(runner, sourceDir, outDir, coverage)
    if sourceDir == "" || ~isfolder(sourceDir)
        coverage.Reason = "Source directory could not be located for coverage.";
        return
    end
    try
        import matlab.unittest.plugins.CodeCoveragePlugin
        import matlab.unittest.plugins.codecoverage.CoberturaFormat
        xmlPath = char(fullfile(outDir, "coverage.xml"));
        plugin = CodeCoveragePlugin.forFolder(char(sourceDir), ...
            'Producing', CoberturaFormat(xmlPath), ...
            'IncludingSubfolders', false);
        runner.addPlugin(plugin);
        coverage.Available = true;
        coverage.XmlPath   = xmlPath;
        coverage.SourceDir = char(sourceDir);
    catch ME
        coverage.Reason = char("Code coverage unavailable: " + string(ME.message));
    end
end

% =========================================================================
function coverage = finalizeCoverage(coverage)
    if ~coverage.Available || ~isfile(coverage.XmlPath)
        return
    end
    try
        txt = fileread(coverage.XmlPath);
        % <coverage line-rate="0.85" ...>
        tok = regexp(txt, "line-rate\s*=\s*""([0-9.]+)""", 'tokens', 'once');
        if ~isempty(tok)
            coverage.Percent = 100 * str2double(tok{1});
        end
        files = regexp(txt, "<class[^>]*filename=""([^""]+)""", 'tokens');
        if ~isempty(files)
            coverage.FilesCovered = string(cellfun(@(c) c{1}, files, 'UniformOutput', false));
        end
    catch
    end
end

% =========================================================================
function conditionalRmpath(added, dir)
    if added
        try
            rmpath(dir);
        catch
        end
    end
end
