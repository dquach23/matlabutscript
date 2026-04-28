function output = generateTestSuite(sourceFile, options)
%GENERATETESTSUITE Build a MATLAB unit test suite and Software Test Report.
%
%   GENERATETESTSUITE(SOURCEFILE) parses any MATLAB source file (.m or
%   .mlapp), automatically generates a matlab.unittest test class, executes
%   it, and produces an official Software Test Report (STR) following the
%   tailored MIL-STD-498 / IEEE 829 conventions used by the United States
%   Air Force for software verification artifacts.
%
%   OUTPUT = GENERATETESTSUITE(SOURCEFILE, NAME=VALUE) accepts:
%
%     OutputDir       - Directory for generated artifacts (default
%                       "test_output").
%     ReportFormat    - "html", "word", or "both" (default "html"). Word
%                       output requires MATLAB Report Generator.
%     RunTests        - Execute the generated suite (default true).
%     ProjectName     - Program / project name printed on the cover page.
%     DocumentId      - Document identifier (e.g. "STR-001").
%     Classification  - Marking banner, default "UNCLASSIFIED".
%     Author          - Test engineer name placed on the cover page.
%     Organization    - Issuing organization (default "USAF").
%     RequirementsFile- Optional path to a CSV/TXT of requirement IDs and
%                       descriptions for traceability.
%     Verbosity       - 0..3, controls runner verbosity.
%
%   OUTPUT is a struct with fields:
%       SourceInfo   - parsed metadata about the input file
%       TestFile     - absolute path to the generated test class
%       Results      - matlab.unittest TestResult array (when RunTests=true)
%       ReportPaths  - struct of paths to generated report artifacts
%
%   Example:
%       generateTestSuite("examples/exampleMath.m", ...
%           ProjectName="DEMO", DocumentId="STR-DEMO-001", ...
%           Author="Capt. T. Tester", ReportFormat="both");
%
%   See also: matlab.unittest.TestCase, matlab.unittest.TestRunner

    arguments
        sourceFile (1,1) string {mustBeNonzeroLengthText}
        options.OutputDir       (1,1) string = "test_output"
        options.ReportFormat    (1,1) string {mustBeMember(options.ReportFormat, ["html","word","both"])} = "html"
        options.RunTests        (1,1) logical = true
        options.ProjectName     (1,1) string  = ""
        options.DocumentId      (1,1) string  = ""
        options.Classification  (1,1) string  = "UNCLASSIFIED"
        options.Author          (1,1) string  = ""
        options.Organization    (1,1) string  = "United States Air Force"
        options.RequirementsFile(1,1) string  = ""
        options.Verbosity       (1,1) double {mustBeMember(options.Verbosity,[0 1 2 3])} = 2
    end

    if ~isfile(sourceFile)
        error("generateTestSuite:FileNotFound", ...
            "Source file '%s' was not found.", sourceFile);
    end

    outDir = char(options.OutputDir);
    if ~isfolder(outDir)
        mkdir(outDir);
    end

    log = @(msg) fprintf("[%s] %s\n", datestr(now,'HH:MM:SS'), msg); %#ok<TNOW1,DATST>

    % ---- 1. Parse the source -------------------------------------------------
    log(sprintf("Parsing source file: %s", sourceFile));
    sourceInfo = stg.parseSource(sourceFile);

    % ---- 2. Optional: load requirements for traceability --------------------
    requirements = stg.loadRequirements(options.RequirementsFile);

    % ---- 3. Generate the unit test class -----------------------------------
    log("Generating MATLAB unit test class...");
    testFile = stg.generateUnitTests(sourceInfo, outDir, requirements);
    log(sprintf("  -> %s", testFile));

    % ---- 4. Run the tests ---------------------------------------------------
    results = matlab.unittest.TestResult.empty;
    coverage = struct('Available', false);
    if options.RunTests
        log("Executing test suite...");
        [results, coverage] = stg.runTests(testFile, outDir, options.Verbosity);
    else
        log("RunTests=false; skipping execution.");
    end

    % ---- 5. Build report metadata ------------------------------------------
    [~, srcName, srcExt] = fileparts(sourceFile);
    if options.ProjectName == ""
        options.ProjectName = string(srcName);
    end
    if options.DocumentId == ""
        options.DocumentId = "STR-" + upper(string(srcName));
    end
    if options.Author == ""
        options.Author = string(getenv("USERNAME"));
        if options.Author == ""
            options.Author = string(getenv("USER"));
        end
        if options.Author == ""
            options.Author = "Anonymous Test Engineer";
        end
    end

    metadata = struct( ...
        "ProjectName",     char(options.ProjectName), ...
        "DocumentId",      char(options.DocumentId), ...
        "Classification",  char(options.Classification), ...
        "Author",          char(options.Author), ...
        "Organization",    char(options.Organization), ...
        "GeneratedDate",   char(datetime("now","Format","yyyy-MM-dd HH:mm:ss")), ...
        "SourceFile",      char(sourceFile), ...
        "SourceName",      char(string(srcName) + string(srcExt)), ...
        "TestFile",        char(testFile), ...
        "OutputDir",       char(outDir), ...
        "Standards",       {{ ...
            "MIL-STD-498 Software Test Report (DI-IPSC-81440A)", ...
            "IEEE Std 829 - Standard for Software Test Documentation", ...
            "AFI 63-101/20-101 Integrated Life Cycle Management", ...
            "DO-178C Software Considerations in Airborne Systems", ...
            "RTCA/DO-330 Software Tool Qualification Considerations"}});

    % ---- 6. Generate reports ------------------------------------------------
    reportPaths = struct();
    if any(options.ReportFormat == ["html" "both"])
        log("Generating HTML Software Test Report...");
        reportPaths.HTML = stg.generateHTMLReport(sourceInfo, results, ...
            coverage, requirements, metadata, outDir);
        log(sprintf("  -> %s", reportPaths.HTML));
    end
    if any(options.ReportFormat == ["word" "both"])
        log("Generating Word Software Test Report...");
        try
            reportPaths.Word = stg.generateWordReport(sourceInfo, results, ...
                coverage, requirements, metadata, outDir);
            log(sprintf("  -> %s", reportPaths.Word));
        catch ME
            warning("generateTestSuite:WordReportFailed", ...
                "Word report generation failed: %s\n" + ...
                "MATLAB Report Generator may not be installed. " + ...
                "Falling back to HTML.", ME.message);
            if ~isfield(reportPaths, "HTML")
                reportPaths.HTML = stg.generateHTMLReport(sourceInfo, ...
                    results, coverage, requirements, metadata, outDir);
            end
        end
    end

    % ---- 7. Build output struct --------------------------------------------
    output = struct( ...
        "SourceInfo",  sourceInfo, ...
        "TestFile",    testFile, ...
        "Results",     results, ...
        "Coverage",    coverage, ...
        "Metadata",    metadata, ...
        "ReportPaths", reportPaths);

    log("Done.");
end
