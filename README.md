# matlabutscript

Auto-generate a `matlab.unittest` test suite for any `.m` or `.mlapp` file
and produce an official **Software Test Report (STR)** in HTML or Microsoft
Word — formatted to follow United States Air Force documentation
conventions (MIL-STD-498 *Software Test Report* DID DI-IPSC-81440A,
IEEE Std 829, AFI 63-101/20-101 lifecycle management, with awareness of
DO-178C / DO-330 for safety-critical projects).

```matlab
% One line: parse the source, build a test class, run it, render the STR.
generateTestSuite("examples/exampleMath.m", ...
    ProjectName="DEMO", ...
    DocumentId="STR-DEMO-001", ...
    Author="Capt. T. Tester", ...
    ReportFormat="both");          % "html" | "word" | "both"
```

The pipeline writes everything into `test_output/`:

```
test_output/
├── testExampleMath.m       % auto-generated matlab.unittest class
├── test_log.txt            % verbatim runner output
├── test_results.mat        % saved TestResult array
├── coverage.xml            % Cobertura coverage (if available)
└── STR_exampleMath.html    % Software Test Report (and/or .docx)
```

## Repository layout

| Path                              | Purpose                                          |
| --------------------------------- | ------------------------------------------------ |
| `generateTestSuite.m`             | Top-level user-facing entry point                |
| `+stg/parseSource.m`              | Static analysis of `.m` and `.mlapp` files       |
| `+stg/extractMlappCode.m`         | Pulls source from App Designer ZIP archives      |
| `+stg/generateUnitTests.m`        | Emits the `matlab.unittest` test class           |
| `+stg/runTests.m`                 | Executes the suite, captures log + coverage      |
| `+stg/generateHTMLReport.m`       | Renders the self-contained HTML STR              |
| `+stg/generateWordReport.m`       | Renders the editable Word STR                    |
| `+stg/+html/`                     | HTML section builders (one file per section)     |
| `+stg/+word/`                     | Word section builders (one file per section)     |
| `examples/exampleMath.m`          | Demo function used by the test                   |
| `examples/ExampleCounter.m`       | Demo class used by the test                      |
| `examples/sampleRequirements.csv` | Demo requirement set for traceability            |
| `examples/demo.m`                 | End-to-end demo script                           |
