function html = documentControl(metadata)
%DOCUMENTCONTROL Render the document-control / revision-history block
%required by AFI 33-360 and DI-IPSC-81440A for configuration management.

    rows = strings(0,1);
    rows(end+1) = "        <section class=""doc-control"">";
    rows(end+1) = "            <h2>Document Control</h2>";
    rows(end+1) = "            <table class=""meta-table"">";
    rows(end+1) = row("Document Identifier",     metadata.DocumentId);
    rows(end+1) = row("Document Title",          "Software Test Report (STR)");
    rows(end+1) = row("Project / Program",       metadata.ProjectName);
    rows(end+1) = row("Issuing Organization",    metadata.Organization);
    rows(end+1) = row("Prepared By",             metadata.Author);
    rows(end+1) = row("Date Issued",             metadata.GeneratedDate);
    rows(end+1) = row("Classification",          metadata.Classification);
    rows(end+1) = row("Source Under Test",       metadata.SourceFile);
    rows(end+1) = row("Generated Test Class",    metadata.TestFile);
    rows(end+1) = row("Distribution Statement",  "Distribution authorized to U.S. Government agencies and their contractors. Other requests shall be referred to the issuing organization.");
    rows(end+1) = "            </table>";

    rows(end+1) = "            <h3>Revision History</h3>";
    rows(end+1) = "            <table class=""results"">";
    rows(end+1) = "                <thead><tr><th>Version</th><th>Date</th><th>Author</th><th>Description of Change</th></tr></thead>";
    rows(end+1) = "                <tbody>";
    rows(end+1) = "                    <tr><td>1.0</td><td>" + stg.escapeHtml(metadata.GeneratedDate) + "</td><td>" + stg.escapeHtml(metadata.Author) + "</td><td>Initial automated issue produced by matlabutscript test generator.</td></tr>";
    rows(end+1) = "                </tbody>";
    rows(end+1) = "            </table>";
    rows(end+1) = "        </section>";

    html = strjoin(rows, newline);
end

function r = row(label, value)
    r = "                <tr><th>" + stg.escapeHtml(label) + "</th><td>" + stg.escapeHtml(value) + "</td></tr>";
end
