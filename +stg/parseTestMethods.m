function methods = parseTestMethods(testFile)
%PARSETESTMETHODS Read the generated test class file and extract per-test
%metadata (id, target, description, expected result, requirement) from the
%standardized comment blocks emitted by stg.generateUnitTests.

    arguments
        testFile (1,1) string {mustBeFile}
    end

    methods = repmat(newRecord(), 0, 1);

    lines = splitlines(string(fileread(char(testFile))));
    inMethod = false;
    cur = newRecord();

    for i = 1:numel(lines)
        L = strtrim(lines(i));
        tok = regexp(L, "^function\s+(\w+)\s*\(.*\)$", 'tokens', 'once');
        if ~isempty(tok)
            if inMethod
                methods(end+1,1) = cur; %#ok<AGROW>
            end
            cur = newRecord();
            cur.MethodName = char(tok{1});
            inMethod = true;
            continue
        end
        if inMethod && startsWith(L, "%")
            body = strtrim(regexprep(L, "^%+", ""));
            if startsWith(body, "TC-")
                cur.Id = char(extractBefore(body + " ", " "));
                catTok = regexp(body, "Category:\s*(.*)$", 'tokens', 'once');
                if ~isempty(catTok)
                    cur.Category = strtrim(string(catTok{1}));
                end
            elseif startsWith(body, "Target")
                cur.Target = stripField(body, "Target");
            elseif startsWith(body, "Description")
                cur.Description = stripField(body, "Description");
            elseif startsWith(body, "Expected")
                cur.ExpectedResult = stripField(body, "Expected");
            elseif startsWith(body, "Requirement")
                cur.Requirement = stripField(body, "Requirement");
            end
        end
        if inMethod && L == "end" && i + 1 <= numel(lines) ...
                && (strtrim(lines(i+1)) == "" || startsWith(strtrim(lines(i+1)), "function"))
            % Likely end of method
            methods(end+1,1) = cur; %#ok<AGROW>
            cur = newRecord();
            inMethod = false;
        end
    end

    if inMethod && cur.MethodName ~= ""
        methods(end+1,1) = cur;
    end
end

function r = newRecord()
    r = struct( ...
        "MethodName",     "", ...
        "Id",             "", ...
        "Category",       "Functional", ...
        "Target",         "", ...
        "Description",    "", ...
        "ExpectedResult", "", ...
        "Requirement",    "");
end

function out = stripField(line, name)
    pat = "^" + name + "\s*[:\-]\s*(.*)$";
    tok = regexp(line, pat, 'tokens', 'once');
    if isempty(tok)
        out = "";
    else
        out = strtrim(string(tok{1}));
    end
end
