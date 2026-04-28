function rows = joinResults(results, methodMeta)
%JOINRESULTS Merge matlab.unittest.TestResult records with the planning
%metadata extracted from the generated test class so the report has a single
%row per test case carrying both the planned values (Id, target, expected
%result, requirement) and the actual outcome.

    rows = struct("Id",{}, "MethodName",{}, "Target",{}, "Description",{}, ...
        "Category",{}, "Requirement",{}, "ExpectedResult",{}, ...
        "Verdict",{}, "Duration",{}, "Diagnostics",{}, "TestName",{});

    if isempty(results)
        for k = 1:numel(methodMeta)
            m = methodMeta(k);
            rows(end+1) = makeRow(m, "NOT EXECUTED", 0, "", string(m.MethodName)); %#ok<AGROW>
        end
        return
    end

    for k = 1:numel(results)
        r = results(k);
        nameParts = split(string(r.Name), "/");
        if numel(nameParts) >= 2
            method = nameParts(end);
        else
            method = string(r.Name);
        end
        method = regexprep(method, "\(.*\)$", "");
        m = findMethod(methodMeta, method);

        if r.Passed
            v = "PASS";
        elseif r.Failed
            v = "FAIL";
        elseif r.Incomplete
            v = "INCOMPLETE";
        else
            v = "OTHER";
        end

        diagnostics = collectDiagnostics(r);

        rows(end+1) = makeRow(m, v, r.Duration, diagnostics, string(r.Name)); %#ok<AGROW>
    end
end

function row = makeRow(meta, verdict, duration, diag, fullName)
    row = struct( ...
        "Id",             string(getfieldOr(meta, "Id", "")), ...
        "MethodName",     string(getfieldOr(meta, "MethodName", "")), ...
        "Target",         string(getfieldOr(meta, "Target", "")), ...
        "Description",    string(getfieldOr(meta, "Description", "")), ...
        "Category",       string(getfieldOr(meta, "Category", "Functional")), ...
        "Requirement",    string(getfieldOr(meta, "Requirement", "")), ...
        "ExpectedResult", string(getfieldOr(meta, "ExpectedResult", "")), ...
        "Verdict",        string(verdict), ...
        "Duration",       double(duration), ...
        "Diagnostics",    string(diag), ...
        "TestName",       string(fullName));
end

function v = getfieldOr(s, f, d)
    if isstruct(s) && isfield(s, f)
        v = s.(f);
    else
        v = d;
    end
end

function m = findMethod(methodMeta, name)
    m = struct();
    if isempty(methodMeta), return; end
    names = string({methodMeta.MethodName});
    idx = find(names == name, 1);
    if ~isempty(idx)
        m = methodMeta(idx);
    end
end

function s = collectDiagnostics(r)
    s = "";
    try
        if ~isempty(r.Details) && isfield(r.Details, 'DiagnosticRecord')
            recs = r.Details.DiagnosticRecord;
            buf = strings(0,1);
            for i = 1:numel(recs)
                rec = recs(i);
                if isprop(rec,'Report') && ~isempty(rec.Report)
                    buf(end+1,1) = string(rec.Report); %#ok<AGROW>
                end
            end
            s = strjoin(buf, newline + newline);
        end
    catch
    end
end
