function html = sectionNotes()
%SECTIONNOTES Render Section 9 (Notes / Acronyms / Glossary).

    acronyms = {
        "AFI",     "Air Force Instruction"
        "CDRL",    "Contract Data Requirements List"
        "CI",      "Configuration Item"
        "CSU",     "Computer Software Unit"
        "DID",     "Data Item Description"
        "DT&E",    "Developmental Test and Evaluation"
        "IEEE",    "Institute of Electrical and Electronics Engineers"
        "MIL-STD", "Military Standard"
        "OT&E",    "Operational Test and Evaluation"
        "RTM",     "Requirements Traceability Matrix"
        "SCM",     "Software Configuration Management"
        "STD",     "Software Test Description"
        "STP",     "Software Test Plan"
        "STR",     "Software Test Report"
        "SUT",     "Software Under Test"
        "T&E",     "Test and Evaluation"
        "USAF",    "United States Air Force"
        "V&V",     "Verification and Validation"
    };

    parts = strings(0,1);
    parts(end+1) = "        <section id=""sec-notes"">";
    parts(end+1) = "            <h2>9. Notes</h2>";
    parts(end+1) = "            <h3>9.1 Acronyms</h3>";
    parts(end+1) = "            <table class=""results"">";
    parts(end+1) = "                <thead><tr><th>Acronym</th><th>Expansion</th></tr></thead><tbody>";
    for k = 1:size(acronyms,1)
        parts(end+1) = "                    <tr><td>" + stg.escapeHtml(acronyms{k,1}) + ...
            "</td><td>" + stg.escapeHtml(acronyms{k,2}) + "</td></tr>"; %#ok<AGROW>
    end
    parts(end+1) = "                </tbody></table>";

    parts(end+1) = "            <h3>9.2 Generation Methodology</h3>";
    parts(end+1) = "            <p>This STR was produced by an automated tool that (1) statically " + ...
        "analyzed the MATLAB source under test, (2) synthesized matlab.unittest test cases " + ...
        "exercising the public API surface (constructors, functions, methods, app launch), " + ...
        "(3) executed those cases under the matlab.unittest runner and (4) rendered this " + ...
        "report. The tool is unqualified per DO-330; the test engineer of record retains " + ...
        "responsibility for the technical content of this report.</p>";
    parts(end+1) = "        </section>";
    html = strjoin(parts, newline);
end
