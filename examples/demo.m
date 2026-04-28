function demo()
%DEMO Run the matlabutscript pipeline end-to-end against the example targets.
%
%   This script demonstrates the workflow against three targets:
%       1. examples/exampleMath.m          (function file)
%       2. examples/ExampleCounter.m        (class file)
%       3. (optional) any .mlapp passed as the first argument
%
%   The demo writes test artifacts and the Software Test Report into
%   test_output/<target_name>/ and prints a one-line summary for each.

    rootDir = fileparts(mfilename('fullpath'));
    rootDir = fileparts(rootDir);
    addpath(rootDir);

    targets = ["examples/exampleMath.m", "examples/ExampleCounter.m"];

    for k = 1:numel(targets)
        sourceFile = fullfile(rootDir, targets(k));
        [~, name] = fileparts(sourceFile);
        fprintf("\n=== %s ===\n", name);

        outDir = fullfile(rootDir, "test_output", name);

        out = generateTestSuite(sourceFile, ...
            OutputDir       = outDir, ...
            ReportFormat    = "html", ...
            ProjectName     = "MATLABUTSCRIPT DEMO", ...
            DocumentId      = "STR-DEMO-" + upper(string(name)), ...
            Author          = "Capt. T. Tester", ...
            Organization    = "United States Air Force - 412 TW", ...
            Classification  = "UNCLASSIFIED", ...
            RequirementsFile = fullfile(rootDir, "examples", "sampleRequirements.csv"), ...
            Verbosity       = 2);

        s = stg.summarizeResults(out.Results);
        fprintf("Verdict: %s   (%d/%d passed in %.2fs)\n", ...
            s.Verdict, s.Passed, s.Total, s.Duration);
        if isfield(out.ReportPaths, "HTML")
            fprintf("Report: %s\n", out.ReportPaths.HTML);
        end
    end

    fprintf("\nDemo complete. Open the HTML reports above in a browser to inspect.\n");
end
