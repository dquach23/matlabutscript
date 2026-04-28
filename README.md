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

## Quick start

From the repository root in MATLAB:

```matlab
addpath(pwd)
run examples/demo.m
```

The demo runs the pipeline against `exampleMath.m` and `ExampleCounter.m`
and prints the absolute path to each rendered STR.

## API reference — `generateTestSuite`

```text
out = generateTestSuite(sourceFile, NAME=VALUE, ...)
```

| Name              | Type      | Default          | Description                                                                 |
| ----------------- | --------- | ---------------- | --------------------------------------------------------------------------- |
| `OutputDir`       | string    | `"test_output"`  | Folder for all generated artifacts.                                         |
| `ReportFormat`    | string    | `"html"`         | `"html"`, `"word"`, or `"both"`. Word requires MATLAB Report Generator.     |
| `RunTests`        | logical   | `true`           | Execute the generated suite. Set false to only render scaffolding.          |
| `ProjectName`     | string    | source basename  | Printed on the STR cover page.                                              |
| `DocumentId`      | string    | `STR-<NAME>`     | Document identifier used throughout the report.                             |
| `Classification`  | string    | `"UNCLASSIFIED"` | Banner shown at the top and bottom of every page.                           |
| `Author`          | string    | `$USER`          | Test engineer credited on the cover page and signature block.               |
| `Organization`    | string    | `"USAF"`         | Issuing organization on the cover page.                                     |
| `RequirementsFile`| string    | `""`             | Optional CSV/TXT file listing requirement IDs for the traceability matrix.  |
| `Verbosity`       | 0..3      | `2`              | Passed to `matlab.unittest.Verbosity`.                                      |

`out` is a struct containing the parsed source info, the path to the
generated test class, the `TestResult` array, the coverage struct, the
metadata struct, and a `ReportPaths` struct of generated artifacts.

## What gets tested

The generator emits **structural / smoke tests** — they verify that the
public surface of the software item is callable, returns the expected
number of outputs, and does not raise unexpected errors or warnings under
heuristically inferred default inputs. Specifically:

| Source kind       | Generated cases                                                                      |
| ----------------- | ------------------------------------------------------------------------------------ |
| Function file     | One smoke test per externally callable function, output count + non-empty checks.    |
| Script file       | One test that runs the script via `evalin('base', ...)` under `verifyWarningFree`.   |
| Class file        | Constructor smoke + one test per public, non-abstract instance / static method.      |
| App Designer file | Launch test (constructs the app, verifies the `UIFigure` handle), plus method tests. |

Argument literals are inferred from parameter names (e.g. `numIterations`
→ `3`, `filename` → `tempname + ".txt"`, `matrix` → `magic(3)`,
`isEnabled` → `true`, otherwise `1.0`). The full rule set lives in
`+stg/inferTestInput.m` and is the first place to extend if your project
needs richer fixtures.

> **The auto-generated suite is a starting point, not a substitute for
> requirements-based testing.** Section 1.3 of every report explicitly
> records this limitation.

## Software Test Report structure

The HTML and Word reports share the same MIL-STD-498 STR section
structure (DI-IPSC-81440A), with USAF cover-page conventions:

1. **Scope** — identification, system overview, document overview
2. **Referenced Documents**
3. **Overview of Test Results** — KPI grid, overall assessment, mission impact, recommended improvements, environment
4. **Detailed Test Results** — summary table + per-case IEEE 829 record (id, target, description, expected, actual, verdict, diagnostics on failure)
5. **Test Log** — verbatim runner stdout
6. **Code Coverage Analysis** — line-rate, file list, acceptance call against the 80% threshold
7. **Configuration Items** — SHA-256 hashes of all artifacts for SCM
8. **Requirements Traceability Matrix** — bidirectional when a requirements file is supplied
9. **Notes** — acronyms / glossary, generation methodology disclosure
10. **Approvals** — signature block (Test Engineer / Test Lead / Program Manager / QA)

A `UNCLASSIFIED` (or your override) banner appears at the top and bottom
of every page in both formats.

## Requirements file format

Either CSV with `Id,Description[,Verification]` headers or plain text with
`ID: description` per line. Verification methods may be `Test`, `Analysis`,
`Inspection`, or `Demonstration`. See `examples/sampleRequirements.csv`.

## USAF / standards alignment

The tool is structured to support — but does not by itself constitute —
verification artifacts compliant with:

- **MIL-STD-498** Software Test Report (DI-IPSC-81440A) section structure
- **IEEE Std 829** test-documentation field set
- **AFI 33-360** publication / forms management (revision history, doc id, classification banner)
- **AFI 63-101 / 20-101** integrated lifecycle management (configuration items, traceability)
- **DO-178C** structural-coverage objectives (Tables A-7) — note that for
  formal credit the test tool must be qualified per **DO-330**, which
  matlabutscript explicitly is **not**

These mappings are restated inside every generated report so reviewers can
audit the claim trail without leaving the document.

## Requirements

- MATLAB R2019a or newer (uses the `arguments` block, string scalars, `uifigure`).
- **Optional:** MATLAB Report Generator for `.docx` output. Without it,
  `ReportFormat="word"` falls back to HTML and prints a warning.
- **Optional:** code coverage requires `matlab.unittest.plugins.CodeCoveragePlugin`
  (R2017a+).

## Limitations

- The .mlapp parser depends on the App Designer XML schema, which has
  changed across MATLAB releases. If extraction fails, only an
  app-launch smoke test is generated.
- Heuristic input inference cannot guarantee meaningful coverage of the
  problem domain. Treat generated cases as a regression net underneath
  hand-authored requirements-based tests.
- Code coverage instrumentation is currently single-folder; nested
  package directories may need the `IncludingSubfolders` plugin option
  enabled by hand.

## License

Provided as-is for U.S. Government use. No warranty.

