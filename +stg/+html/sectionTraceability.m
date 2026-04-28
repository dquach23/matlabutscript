function html = sectionTraceability(rows, requirements)
%SECTIONTRACEABILITY Render Section 8 (Requirements Traceability Matrix).
%   The RTM cross-references every test case to a source requirement.
%   Where requirements were not supplied (-RequirementsFile not given),
%   each row displays "(not traced)" so the gap is explicit on inspection.

    parts = strings(0,1);
    parts(end+1) = "        <section id=""sec-trace"">";
    parts(end+1) = "            <h2>8. Requirements Traceability Matrix</h2>";

    if isempty(rows)
        parts(end+1) = "            <p><em>No test cases to trace.</em></p>";
        parts(end+1) = "        </section>";
        html = strjoin(parts, newline);
        return
    end

    parts(end+1) = "            <p>Bidirectional traceability is mandatory for software undergoing " + ...
        "DT&amp;E or OT&amp;E activities. The matrix below presents the test-to-requirement mapping " + ...
        "(forward) and the corresponding verdict.</p>";

    parts(end+1) = "            <h3>8.1 Test &rarr; Requirement</h3>";
    parts(end+1) = "            <table class=""results"">";
    parts(end+1) = "                <thead><tr><th>Test Case</th><th>Target</th><th>Requirement</th><th>Verdict</th></tr></thead><tbody>";
    for k = 1:numel(rows)
        r = rows(k);
        req = r.Requirement; if req == "", req = "(not traced)"; end
        parts(end+1) = "                    <tr><td>" + stg.escapeHtml(r.Id) + ...
            "</td><td>" + stg.escapeHtml(r.Target) + ...
            "</td><td>" + stg.escapeHtml(req) + ...
            "</td><td>" + stg.escapeHtml(r.Verdict) + "</td></tr>"; %#ok<AGROW>
    end
    parts(end+1) = "                </tbody></table>";

    if ~isempty(requirements)
        parts(end+1) = "            <h3>8.2 Requirement &rarr; Test (Reverse Trace)</h3>";
        parts(end+1) = "            <table class=""results"">";
        parts(end+1) = "                <thead><tr><th>Requirement</th><th>Description</th><th>Verification Method</th><th>Covering Test Cases</th></tr></thead><tbody>";
        for r = 1:numel(requirements)
            req = requirements(r);
            covering = string({});
            for k = 1:numel(rows)
                if string(rows(k).Requirement) == string(req.Id)
                    covering(end+1) = string(rows(k).Id); %#ok<AGROW>
                end
            end
            if isempty(covering)
                covText = "(NONE - GAP)";
            else
                covText = strjoin(covering, ", ");
            end
            parts(end+1) = "                    <tr><td>" + stg.escapeHtml(req.Id) + ...
                "</td><td>" + stg.escapeHtml(req.Description) + ...
                "</td><td>" + stg.escapeHtml(req.Verification) + ...
                "</td><td>" + stg.escapeHtml(covText) + "</td></tr>"; %#ok<AGROW>
        end
        parts(end+1) = "                </tbody></table>";
    else
        parts(end+1) = "            <p><em>No requirements file was supplied; reverse trace is not available.</em></p>";
    end

    parts(end+1) = "        </section>";
    html = strjoin(parts, newline);
end
