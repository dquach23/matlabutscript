function appendSectionOverview(doc, summary, coverage, metadata)
%APPENDSECTIONOVERVIEW Section 3 (Overview of Test Results).

    import mlreportgen.dom.*

    append(doc, stg.word.heading("3. Overview of Test Results", 2));

    if isfield(coverage,'Available') && coverage.Available && ~isnan(coverage.Percent)
        covText = sprintf("%.1f%%", coverage.Percent);
    else
        covText = "n/a";
    end

    rows = [
        "Total Test Cases", string(summary.Total)
        "Passed",           string(summary.Passed)
        "Failed",           string(summary.Failed)
        "Incomplete",       string(summary.Incomplete)
        "Filtered",         string(summary.Filtered)
        "Pass Rate",        sprintf("%.1f%%", summary.PassRate)
        "Total Duration",   sprintf("%.2f s", summary.Duration)
        "Line Coverage",    covText
        "Overall Verdict",  summary.Verdict
    ];
    append(doc, stg.word.keyValueTable(rows));

    verdictClass = lower(string(summary.Verdict));
    if verdictClass == "pass"
        assessText = "All planned test cases passed. The software item is recommended for advancement to the next verification phase, contingent on the limitations noted in 1.3.";
        impactText = "No mission impact identified from the executed verification scope.";
        recText    = "Augment the auto-generated structural cases with requirements-based and operational scenario tests prior to fielding.";
    elseif verdictClass == "fail"
        assessText = sprintf("Of %d planned test cases, %d failed and %d completed normally. The software item is NOT recommended for advancement until the failures listed in Section 4 are dispositioned.", ...
            summary.Total, summary.Failed, summary.Passed);
        impactText = "Failures in basic callability or output shape are likely to manifest as runtime defects when the item is integrated. Risk to mission is assessed as MEDIUM until anomalies are closed.";
        recText    = "Triage failures, capture defect reports, regression-fix, and re-baseline this STR.";
    else
        assessText = "Test execution was incomplete; results are inconclusive. See Section 4 for the affected cases.";
        impactText = "Verification status cannot be determined from this run. Mission risk is UNKNOWN.";
        recText    = "Resolve test environment / fixture issues and re-run prior to formal review.";
    end

    append(doc, stg.word.heading("3.1 Overall Assessment", 3));
    append(doc, Paragraph(char(assessText)));

    append(doc, stg.word.heading("3.2 Impact", 3));
    append(doc, Paragraph(char(impactText)));

    append(doc, stg.word.heading("3.3 Recommended Improvements", 3));
    append(doc, Paragraph(char(recText)));

    append(doc, stg.word.heading("3.4 Test Environment", 3));
    envRows = [
        "Operating System",  string(computer('arch'))
        "MATLAB Version",    string(version)
        "Test Framework",    "matlab.unittest"
        "Report Generator",  "matlabutscript / stg.generateWordReport"
        "Output Directory",  metadata.OutputDir
    ];
    append(doc, stg.word.keyValueTable(envRows));
end
