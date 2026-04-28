function reqs = loadRequirements(reqFile)
%LOADREQUIREMENTS Load a requirements list for traceability.
%
%   The file may be CSV (Id,Description[,Verification]) or a plain text file
%   with one requirement per line of the form "ID: text". Returns a struct
%   array with fields Id, Description, Verification.

    arguments
        reqFile (1,1) string = ""
    end

    reqs = repmat(struct("Id","", "Description","", "Verification","Test"), 0, 1);
    if reqFile == "" || ~isfile(reqFile)
        return
    end

    [~, ~, ext] = fileparts(reqFile);
    ext = lower(string(ext));

    if ext == ".csv"
        try
            T = readtable(reqFile, 'TextType', 'string');
        catch
            T = readtable(reqFile, 'TextType', 'string', 'Delimiter', ',');
        end
        cols = lower(string(T.Properties.VariableNames));
        idCol   = pickColumn(cols, ["id" "reqid" "requirementid"]);
        descCol = pickColumn(cols, ["description" "desc" "text" "requirement"]);
        verCol  = pickColumn(cols, ["verification" "method" "vmethod"]);
        for k = 1:height(T)
            r = struct( ...
                "Id",           cellstrSafe(T, idCol,   k), ...
                "Description",  cellstrSafe(T, descCol, k), ...
                "Verification", cellstrSafe(T, verCol,  k));
            if r.Verification == ""
                r.Verification = "Test";
            end
            reqs(end+1,1) = r; %#ok<AGROW>
        end
    else
        lines = splitlines(string(fileread(reqFile)));
        for k = 1:numel(lines)
            L = strtrim(lines(k));
            if strlength(L) == 0 || startsWith(L, "#")
                continue
            end
            tok = regexp(L, "^([A-Za-z0-9._-]+)\s*[:\-]\s*(.+)$", 'tokens', 'once');
            if isempty(tok)
                reqs(end+1,1) = struct("Id", sprintf("REQ-%03d",k), ...
                    "Description", char(L), "Verification","Test"); %#ok<AGROW>
            else
                reqs(end+1,1) = struct("Id", char(tok{1}), ...
                    "Description", char(tok{2}), "Verification","Test"); %#ok<AGROW>
            end
        end
    end
end

function name = pickColumn(cols, candidates)
    name = "";
    for c = candidates
        idx = find(cols == c, 1);
        if ~isempty(idx)
            name = string(idx);
            return
        end
    end
end

function v = cellstrSafe(T, colIdx, row)
    if colIdx == ""
        v = "";
        return
    end
    val = T{row, double(colIdx)};
    if iscell(val)
        v = string(val{1});
    else
        v = string(val);
    end
end
