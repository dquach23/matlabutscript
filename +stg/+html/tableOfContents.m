function html = tableOfContents()
%TABLEOFCONTENTS Static TOC matching the section anchors used elsewhere.

    parts = strings(0,1);
    parts(end+1) = "        <section class=""toc"">";
    parts(end+1) = "            <h2>Table of Contents</h2>";
    parts(end+1) = "            <ol>";
    parts(end+1) = "                <li><a href=""#sec-scope"">Scope</a></li>";
    parts(end+1) = "                <li><a href=""#sec-refs"">Referenced Documents</a></li>";
    parts(end+1) = "                <li><a href=""#sec-overview"">Overview of Test Results</a></li>";
    parts(end+1) = "                <li><a href=""#sec-detail"">Detailed Test Results</a></li>";
    parts(end+1) = "                <li><a href=""#sec-log"">Test Log</a></li>";
    parts(end+1) = "                <li><a href=""#sec-cov"">Code Coverage Analysis</a></li>";
    parts(end+1) = "                <li><a href=""#sec-ci"">Configuration Items</a></li>";
    parts(end+1) = "                <li><a href=""#sec-trace"">Requirements Traceability Matrix</a></li>";
    parts(end+1) = "                <li><a href=""#sec-notes"">Notes (Acronyms / Glossary)</a></li>";
    parts(end+1) = "                <li><a href=""#sec-approve"">Approvals</a></li>";
    parts(end+1) = "            </ol>";
    parts(end+1) = "        </section>";
    html = strjoin(parts, newline);
end
