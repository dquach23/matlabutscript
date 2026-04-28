function html = sectionOverview(summary, coverage, metadata)
%SECTIONOVERVIEW Render Section 3 (Overview of Test Results).
%   Provides the executive-summary KPI grid, overall assessment, mission
%   impact statement and recommended improvements per MIL-STD-498 STR DID.

    verdictClass = lower(string(summary.Verdict));
    if verdictClass == "pass"
        assessText = "All planned test cases passed. The software item is recommended for advancement to the next verification phase, contingent on the limitations noted in &sect;1.3.";
        impactText = "No mission impact identified from the executed verification scope.";
        recText    = "Augment the auto-generated structural cases with requirements-based and operational scenario tests prior to fielding.";
    elseif verdictClass == "fail"
        assessText = sprintf("Of %d planned test cases, %d failed and %d completed normally. The software item is <strong>not</strong> recommended for advancement until the failures listed in &sect;4 are dispositioned.", ...
            summary.Total, summary.Failed, summary.Passed);
        impactText = "Failures in basic callability or output shape are likely to manifest as runtime defects when the item is integrated. Risk to mission is assessed as MEDIUM until anomalies are closed.";
        recText    = "Triage failures, capture defect reports, regression-fix, and re-baseline this STR.";
    else
        assessText = "Test execution was incomplete; results are inconclusive. See &sect;4 for the affected cases.";
        impactText = "Verification status cannot be determined from this run. Mission risk is UNKNOWN.";
        recText    = "Resolve test environment / fixture issues and re-run prior to formal review.";
    end

    if isfield(coverage,'Available') && coverage.Available && ~isnan(coverage.Percent)
        covText = sprintf("%.1f%%", coverage.Percent);
    else
        covText = "n/a";
    end

    parts = strings(0,1);
    parts(end+1) = "        <section id=""sec-overview"">";
    parts(end+1) = "            <h2>3. Overview of Test Results</h2>";

    parts(end+1) = "            <div class=""kpi-grid"">";
    parts(end+1) = kpi("Test Cases", string(summary.Total));
    parts(end+1) = kpi("Passed",     string(summary.Passed));
    parts(end+1) = kpi("Failed",     string(summary.Failed));
    parts(end+1) = kpi("Pass Rate",  sprintf("%.1f%%", summary.PassRate));
    parts(end+1) = kpi("Incomplete", string(summary.Incomplete));
    parts(end+1) = kpi("Filtered",   string(summary.Filtered));
    parts(end+1) = kpi("Duration",   sprintf("%.2f s", summary.Duration));
    parts(end+1) = kpi("Coverage",   covText);
    parts(end+1) = "            </div>";

    parts(end+1) = "            <h3>3.1 Overall Assessment</h3>";
    parts(end+1) = "            <p>" + assessText + "</p>";

    parts(end+1) = "            <h3>3.2 Impact</h3>";
    parts(end+1) = "            <p>" + impactText + "</p>";

    parts(end+1) = "            <h3>3.3 Recommended Improvements</h3>";
    parts(end+1) = "            <p>" + recText + "</p>";

    parts(end+1) = "            <h3>3.4 Test Environment</h3>";
    parts(end+1) = "            <table class=""meta-table"">";
    parts(end+1) = row("Operating System",  computer('arch'));
    parts(end+1) = row("MATLAB Version",    string(version));
    parts(end+1) = row("Test Framework",    "matlab.unittest");
    parts(end+1) = row("Report Generator",  "matlabutscript / stg.generateHTMLReport");
    parts(end+1) = row("Output Directory",  metadata.OutputDir);
    parts(end+1) = "            </table>";

    parts(end+1) = "        </section>";
    html = strjoin(parts, newline);
end

function s = kpi(label, value)
    s = "                <div class=""kpi""><div class=""label"">" + ...
        stg.escapeHtml(label) + "</div><div class=""value"">" + ...
        stg.escapeHtml(value) + "</div></div>";
end

function r = row(label, value)
    r = "                <tr><th>" + stg.escapeHtml(label) + "</th><td>" + ...
        stg.escapeHtml(value) + "</td></tr>";
end
