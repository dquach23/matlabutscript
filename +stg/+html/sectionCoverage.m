function html = sectionCoverage(coverage)
%SECTIONCOVERAGE Render Section 6 (Code Coverage Analysis).

    parts = strings(0,1);
    parts(end+1) = "        <section id=""sec-cov"">";
    parts(end+1) = "            <h2>6. Code Coverage Analysis</h2>";

    if ~coverage.Available
        parts(end+1) = "            <p>Code coverage instrumentation was not available for this run.</p>";
        if isfield(coverage,'Reason') && ~isempty(coverage.Reason)
            parts(end+1) = "            <p><em>" + stg.escapeHtml(string(coverage.Reason)) + "</em></p>";
        end
        parts(end+1) = "            <p>Per DO-178C objective tables A-7, structural coverage analysis " + ...
            "is required for software at level C and above. Where this STR supports " + ...
            "DO-178C credit, coverage shall be recomputed using a qualified tool.</p>";
        parts(end+1) = "        </section>";
        html = strjoin(parts, newline);
        return
    end

    parts(end+1) = "            <p>The following metrics were produced by " + ...
        "matlab.unittest.plugins.CodeCoveragePlugin in Cobertura XML format.</p>";
    parts(end+1) = "            <table class=""meta-table"">";
    parts(end+1) = "                <tr><th>Line Coverage</th><td>" + sprintf("%.2f%%", coverage.Percent) + "</td></tr>";
    parts(end+1) = "                <tr><th>Cobertura XML</th><td>" + stg.escapeHtml(string(coverage.XmlPath)) + "</td></tr>";
    if isfield(coverage,'SourceDir')
        parts(end+1) = "                <tr><th>Source Directory</th><td>" + stg.escapeHtml(string(coverage.SourceDir)) + "</td></tr>";
    end
    parts(end+1) = "            </table>";

    if isfield(coverage,'FilesCovered') && ~isempty(coverage.FilesCovered)
        parts(end+1) = "            <h3>6.1 Covered Files</h3>";
        parts(end+1) = "            <ul>";
        for k = 1:numel(coverage.FilesCovered)
            parts(end+1) = "                <li>" + stg.escapeHtml(coverage.FilesCovered(k)) + "</li>"; %#ok<AGROW>
        end
        parts(end+1) = "            </ul>";
    end

    parts(end+1) = "            <h3>6.2 Coverage Acceptance</h3>";
    if coverage.Percent >= 80
        verdict = "MEETS the 80% line-coverage threshold typically required for USAF software at IEEE 829 Risk Level Moderate.";
    else
        verdict = "DOES NOT meet the 80% line-coverage threshold typically required for USAF software at IEEE 829 Risk Level Moderate. Additional test cases shall be authored.";
    end
    parts(end+1) = "            <p>" + verdict + "</p>";

    parts(end+1) = "        </section>";
    html = strjoin(parts, newline);
end
