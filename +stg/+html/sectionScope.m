function html = sectionScope(info, metadata)
%SECTIONSCOPE Render Section 1 (Scope) per MIL-STD-498 STR DID.

    parts = strings(0,1);
    parts(end+1) = "        <section id=""sec-scope"">";
    parts(end+1) = "            <h2>1. Scope</h2>";

    parts(end+1) = "            <h3>1.1 Identification</h3>";
    parts(end+1) = "            <p>This Software Test Report (STR), document <strong>" + ...
        stg.escapeHtml(metadata.DocumentId) + "</strong>, documents the verification activities " + ...
        "performed against the MATLAB software item <strong>" + stg.escapeHtml(metadata.SourceName) + ...
        "</strong> belonging to project <strong>" + stg.escapeHtml(metadata.ProjectName) + ...
        "</strong>. The report is issued by " + stg.escapeHtml(metadata.Organization) + ...
        " and is structured in accordance with the data preparation instructions of " + ...
        "DI-IPSC-81440A and the test reporting practices of IEEE Std 829.</p>";

    parts(end+1) = "            <h3>1.2 System Overview</h3>";
    desc = string(info.Description);
    if desc == ""
        desc = "No documentation header was found in the source under test.";
    end
    parts(end+1) = "            <p>" + stg.escapeHtml(desc) + "</p>";
    parts(end+1) = "            <table class=""meta-table"">";
    parts(end+1) = row("Software Item Name",   info.Name);
    parts(end+1) = row("Software Item Kind",   info.Kind);
    parts(end+1) = row("Source File Type",     info.FileType);
    parts(end+1) = row("Absolute Path",        info.FilePath);
    parts(end+1) = row("Source SHA-256",       info.Hash);
    parts(end+1) = "            </table>";

    parts(end+1) = "            <h3>1.3 Document Overview</h3>";
    parts(end+1) = "            <p>The remainder of this document records the test environment, " + ...
        "the test cases executed, their detailed pass/fail outcomes, the resulting code-coverage " + ...
        "metrics (when supported by the host MATLAB release), the configuration items under " + ...
        "test, the traceability of test cases to requirements, and the formal approval block.</p>";
    parts(end+1) = "            <p><em>Limitation:</em> The test cases described herein were " + ...
        "synthesized automatically from a static analysis of the software item. They constitute " + ...
        "structural / smoke verification of basic callability and output shape and do <strong>not</strong> " + ...
        "supersede requirements-based test cases that the responsible test engineer must " + ...
        "develop in accordance with the project's Software Test Plan (STP).</p>";

    parts(end+1) = "        </section>";
    html = strjoin(parts, newline);
end

function r = row(label, value)
    r = "                <tr><th>" + stg.escapeHtml(label) + "</th><td>" + stg.escapeHtml(value) + "</td></tr>";
end
