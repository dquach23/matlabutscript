function html = sectionDetailedResults(rows)
%SECTIONDETAILEDRESULTS Render Section 4 (Detailed Test Results).
%   For every executed test case the report emits an IEEE 829-style record
%   with: Test Case ID, Test Item / Target, Description, Inputs, Expected
%   Result, Actual Result, Verdict, Duration and Diagnostics on failure.

    parts = strings(0,1);
    parts(end+1) = "        <section id=""sec-detail"">";
    parts(end+1) = "            <h2>4. Detailed Test Results</h2>";

    if isempty(rows)
        parts(end+1) = "            <p><em>No test cases were planned for this software item.</em></p>";
        parts(end+1) = "        </section>";
        html = strjoin(parts, newline);
        return
    end

    % Summary table for quick scanning
    parts(end+1) = "            <h3>4.1 Summary Table</h3>";
    parts(end+1) = "            <table class=""results"">";
    parts(end+1) = "                <thead><tr>";
    parts(end+1) = "                    <th>Case ID</th><th>Target</th><th>Category</th>";
    parts(end+1) = "                    <th>Requirement</th><th>Verdict</th><th>Duration (s)</th>";
    parts(end+1) = "                </tr></thead><tbody>";
    for k = 1:numel(rows)
        r = rows(k);
        parts(end+1) = "                    <tr>"; %#ok<AGROW>
        parts(end+1) = "                        <td>" + stg.escapeHtml(r.Id) + "</td>"; %#ok<AGROW>
        parts(end+1) = "                        <td>" + stg.escapeHtml(r.Target) + "</td>"; %#ok<AGROW>
        parts(end+1) = "                        <td>" + stg.escapeHtml(r.Category) + "</td>"; %#ok<AGROW>
        parts(end+1) = "                        <td>" + stg.escapeHtml(r.Requirement) + "</td>"; %#ok<AGROW>
        parts(end+1) = "                        <td>" + verdictBadge(r.Verdict) + "</td>"; %#ok<AGROW>
        parts(end+1) = "                        <td>" + sprintf("%.4f", r.Duration) + "</td>"; %#ok<AGROW>
        parts(end+1) = "                    </tr>"; %#ok<AGROW>
    end
    parts(end+1) = "                </tbody></table>";

    % Per-case detail blocks
    parts(end+1) = "            <h3>4.2 Test Case Records</h3>";
    for k = 1:numel(rows)
        r = rows(k);
        cls = lower(string(r.Verdict));
        if cls ~= "pass" && cls ~= "fail" && cls ~= "incomplete"
            cls = "incomplete";
        end
        parts(end+1) = "            <div class=""testcase " + cls + """>"; %#ok<AGROW>
        parts(end+1) = "                <h4>" + stg.escapeHtml(r.Id) + " &mdash; " + stg.escapeHtml(r.Target) + " " + verdictBadge(r.Verdict) + "</h4>"; %#ok<AGROW>
        parts(end+1) = "                <dl>"; %#ok<AGROW>
        parts(end+1) = dl("Test Method",   r.MethodName); %#ok<AGROW>
        parts(end+1) = dl("Description",   r.Description); %#ok<AGROW>
        parts(end+1) = dl("Category",      r.Category); %#ok<AGROW>
        parts(end+1) = dl("Requirement",   ifempty(r.Requirement, "(not traced)")); %#ok<AGROW>
        parts(end+1) = dl("Expected",      r.ExpectedResult); %#ok<AGROW>
        parts(end+1) = dl("Actual",        actualText(r)); %#ok<AGROW>
        parts(end+1) = dl("Duration",      sprintf("%.4f s", r.Duration)); %#ok<AGROW>
        parts(end+1) = "                </dl>"; %#ok<AGROW>
        if r.Diagnostics ~= "" && lower(string(r.Verdict)) ~= "pass"
            parts(end+1) = "                <pre class=""log"">" + stg.escapeHtml(r.Diagnostics) + "</pre>"; %#ok<AGROW>
        end
        parts(end+1) = "            </div>"; %#ok<AGROW>
    end

    parts(end+1) = "        </section>";
    html = strjoin(parts, newline);
end

function s = verdictBadge(verdict)
    v = lower(string(verdict));
    switch v
        case "pass"
            s = "<span class=""verdict pass"">PASS</span>";
        case "fail"
            s = "<span class=""verdict fail"">FAIL</span>";
        otherwise
            s = "<span class=""verdict warn"">" + stg.escapeHtml(upper(verdict)) + "</span>";
    end
end

function s = dl(label, value)
    s = "                    <dt>" + stg.escapeHtml(label) + "</dt>" + ...
        "<dd>" + stg.escapeHtml(value) + "</dd>";
end

function v = ifempty(v, d)
    if v == "", v = d; end
end

function s = actualText(r)
    v = lower(string(r.Verdict));
    switch v
        case "pass"
            s = "All assertions satisfied; no errors or warnings raised.";
        case "fail"
            s = "Assertion failed or error raised. See diagnostics below.";
        case "incomplete"
            s = "Test did not run to completion. See diagnostics below.";
        otherwise
            s = "See diagnostics.";
    end
end
