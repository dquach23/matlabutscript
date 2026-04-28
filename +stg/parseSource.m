function info = parseSource(sourceFile)
%PARSESOURCE Static analysis of a .m or .mlapp file.
%
%   INFO = STG.PARSESOURCE(SOURCEFILE) returns a struct describing the
%   testable units in the supplied MATLAB source file. Both classic
%   function/script .m files and App Designer .mlapp packages are
%   supported. .mlapp files are treated as ZIP containers and their
%   embedded MATLAB source is extracted from the document XML.
%
%   The returned struct has the following fields:
%       FilePath        - absolute path to the source
%       FileType        - "m" or "mlapp"
%       Kind            - "script", "function", "class", or "app"
%       Name            - primary identifier (function/class/app name)
%       Description     - first H1 line / first comment block
%       Functions       - struct array describing each function in the file
%                         (Name, Inputs, Outputs, IsLocal, IsMethod, Parent,
%                          Access, IsStatic, LineNumber, Description)
%       Class           - struct describing the class definition (if any)
%       SourceLines     - cell array containing the raw source lines
%       AppMetadata     - additional info for .mlapp files
%       Hash            - SHA-256 of source for configuration management

    arguments
        sourceFile (1,1) string
    end

    sourceFile = string(stg.absPath(sourceFile));
    [~, ~, ext] = fileparts(sourceFile);
    ext = lower(string(ext));

    switch ext
        case ".m"
            info = parseMFile(sourceFile);
            info.FileType = "m";
        case ".mlapp"
            info = parseMlappFile(sourceFile);
            info.FileType = "mlapp";
        otherwise
            error("stg:parseSource:UnsupportedFile", ...
                "Unsupported file extension '%s'. Provide a .m or .mlapp file.", ext);
    end

    info.FilePath = char(sourceFile);
    info.Hash = stg.fileHash(sourceFile);
end

% =========================================================================
function info = parseMFile(sourceFile)
    code = fileread(char(sourceFile));
    lines = splitlines(string(code));

    info = newInfoStruct();
    info.SourceLines = cellstr(lines);

    [~, baseName] = fileparts(sourceFile);
    info.Name = char(baseName);

    classdefIdx = findCodeMatch(lines, "^\s*classdef\b");
    funcIdx     = findCodeMatch(lines, "^\s*function\b");

    if ~isempty(classdefIdx)
        info.Kind = "class";
        info.Class = parseClassDef(lines, classdefIdx(1));
        if ~isempty(info.Class.Name)
            info.Name = info.Class.Name;
        end
        info.Functions = info.Class.Methods;
    elseif ~isempty(funcIdx)
        info.Kind = "function";
        info.Functions = parseFunctions(lines, funcIdx);
        if ~isempty(info.Functions)
            info.Functions(1).IsLocal = false;
            info.Name = info.Functions(1).Name;
            for k = 2:numel(info.Functions)
                info.Functions(k).IsLocal = true;
            end
        end
    else
        info.Kind = "script";
    end

    info.Description = extractH1(lines, info.Kind, info.Name);
end

% =========================================================================
function info = parseMlappFile(sourceFile)
    info = newInfoStruct();
    info.Kind = "app";
    [~, baseName] = fileparts(sourceFile);
    info.Name = char(baseName);

    [code, appMeta] = stg.extractMlappCode(sourceFile);
    info.AppMetadata = appMeta;
    info.SourceLines = cellstr(splitlines(string(code)));

    if isempty(code) || strlength(strtrim(string(code))) == 0
        % Could not extract source; fall back to launch-only smoke test
        info.Description = sprintf("App Designer file '%s'. Source code could not be statically extracted; an instantiation smoke test will be generated.", info.Name);
        info.Functions = repmat(newFunctionStruct(), 0, 1);
        info.Class = struct("Name", info.Name, "Parent", "matlab.apps.AppBase", ...
            "Methods", info.Functions, "Properties", strings(0,1), ...
            "ConstructorInputs", strings(0,1), "Description", info.Description);
        return
    end

    lines = string(splitlines(code));
    classdefIdx = findCodeMatch(lines, "^\s*classdef\b");

    if ~isempty(classdefIdx)
        info.Class = parseClassDef(lines, classdefIdx(1));
        if ~isempty(info.Class.Name)
            info.Name = info.Class.Name;
        end
        info.Functions = info.Class.Methods;
    else
        info.Functions = parseFunctions(lines, findCodeMatch(lines, "^\s*function\b"));
        info.Class = struct("Name", info.Name, "Parent", "matlab.apps.AppBase", ...
            "Methods", info.Functions, "Properties", strings(0,1), ...
            "ConstructorInputs", strings(0,1), "Description", "");
    end
    info.Description = extractH1(lines, "app", info.Name);
end

% =========================================================================
function info = newInfoStruct()
    info = struct( ...
        "FilePath",    "", ...
        "FileType",    "", ...
        "Kind",        "", ...
        "Name",        "", ...
        "Description", "", ...
        "Functions",   repmat(newFunctionStruct(), 0, 1), ...
        "Class",       struct("Name", "", "Parent", "", "Methods", [], ...
                              "Properties", strings(0,1), ...
                              "ConstructorInputs", strings(0,1), ...
                              "Description", ""), ...
        "SourceLines", {{}}, ...
        "AppMetadata", struct(), ...
        "Hash",        "");
end

function fs = newFunctionStruct()
    fs = struct( ...
        "Name",        "", ...
        "Inputs",      strings(0,1), ...
        "Outputs",     strings(0,1), ...
        "IsLocal",     false, ...
        "IsMethod",    false, ...
        "Parent",      "", ...
        "Access",      "public", ...
        "IsStatic",    false, ...
        "IsAbstract",  false, ...
        "LineNumber",  0, ...
        "Description", "");
end

% =========================================================================
function idx = findCodeMatch(lines, pattern)
    idx = [];
    for i = 1:numel(lines)
        % Strip trailing comment but preserve string literals reasonably
        L = stripComment(lines(i));
        if ~isempty(regexp(L, pattern, 'once'))
            idx(end+1,1) = i; %#ok<AGROW>
        end
    end
end

function out = stripComment(line)
    s = char(line);
    inSingle = false; inDouble = false;
    out = s;
    for i = 1:numel(s)
        c = s(i);
        if c == '''' && ~inDouble
            inSingle = ~inSingle;
        elseif c == '"' && ~inSingle
            inDouble = ~inDouble;
        elseif c == '%' && ~inSingle && ~inDouble
            out = s(1:i-1);
            return
        end
    end
end

% =========================================================================
function fns = parseFunctions(lines, indices)
    fns = repmat(newFunctionStruct(), 0, 1);
    for k = 1:numel(indices)
        i = indices(k);
        sig = stripComment(lines(i));
        % Handle line continuation (...) for multi-line signatures
        while endsWith(strtrim(sig), "...") && i < numel(lines)
            i2 = i + 1;
            sig = strtrim(extractBefore(strtrim(sig), strlength(strtrim(sig))-2)) + " " + strtrim(stripComment(lines(i2)));
            i = i2;
        end
        f = parseFunctionSignature(sig, indices(k));
        if ~isempty(f.Name)
            f.Description = extractFunctionH1(lines, indices(k));
            fns(end+1,1) = f; %#ok<AGROW>
        end
    end
end

function f = parseFunctionSignature(sig, lineNumber)
    f = newFunctionStruct();
    f.LineNumber = lineNumber;
    sig = strtrim(string(sig));
    sig = regexprep(sig, "^\s*function\s+", "");

    % Possible forms:
    %   [a,b] = name(x,y)
    %   a = name(x,y)
    %   name(x,y)
    %   name
    eqIdx = strfind(sig, "=");
    if ~isempty(eqIdx)
        outsPart = strtrim(extractBefore(sig, eqIdx(1)));
        rest     = strtrim(extractAfter(sig,  eqIdx(1)));
        outsPart = regexprep(outsPart, "[\[\]]", "");
        outs = strtrim(split(outsPart, ","));
        outs = outs(strlength(outs) > 0);
        f.Outputs = outs;
    else
        rest = sig;
        f.Outputs = strings(0,1);
    end

    parenIdx = strfind(rest, "(");
    if isempty(parenIdx)
        f.Name = char(strtrim(rest));
        f.Inputs = strings(0,1);
    else
        f.Name = char(strtrim(extractBefore(rest, parenIdx(1))));
        argPart = extractBetween(rest, "(", ")");
        if isempty(argPart)
            f.Inputs = strings(0,1);
        else
            args = strtrim(split(argPart{1}, ","));
            args = args(strlength(args) > 0);
            f.Inputs = args;
        end
    end
end

function desc = extractFunctionH1(lines, fnLine)
    desc = "";
    for i = (fnLine+1):min(fnLine+5, numel(lines))
        L = strtrim(lines(i));
        if startsWith(L, "%")
            desc = strtrim(regexprep(L, "^%+", ""));
            return
        end
        if strlength(L) == 0
            continue
        end
        return
    end
end

% =========================================================================
function classInfo = parseClassDef(lines, classLine)
    classInfo = struct("Name","", "Parent","", "Methods",[], ...
        "Properties", strings(0,1), "ConstructorInputs", strings(0,1), ...
        "Description","");

    sig = strtrim(stripComment(lines(classLine)));
    sig = regexprep(sig, "^\s*classdef\s*(\([^)]*\))?\s*", "");
    parts = regexp(sig, "^([A-Za-z]\w*)\s*(<\s*([\w\.&\s]+))?", 'tokens', 'once');
    if isempty(parts)
        return
    end
    classInfo.Name = char(strtrim(string(parts{1})));
    if numel(parts) >= 3 && ~isempty(parts{3})
        classInfo.Parent = char(strtrim(string(parts{3})));
    end

    classInfo.Description = extractFunctionH1(lines, classLine);
    [methods, props] = walkClassBody(lines, classLine, classInfo.Name);
    classInfo.Methods = methods;
    classInfo.Properties = props;

    ctor = methods(strcmp({methods.Name}, classInfo.Name));
    if ~isempty(ctor)
        classInfo.ConstructorInputs = ctor(1).Inputs;
    end
end

function [methods, props] = walkClassBody(lines, classLine, className)
    methods = repmat(newFunctionStruct(), 0, 1);
    props   = strings(0,1);

    i = classLine + 1;
    nLines = numel(lines);

    while i <= nLines
        L = strtrim(stripComment(lines(i)));
        if startsWith(L, "methods")
            attrs = parseBlockAttributes(L);
            blockStart = i + 1;
            blockEnd   = matchEnd(lines, i);
            % Find function lines within this block (only top-level funcs)
            funcIdx = findCodeMatchInRange(lines, "^\s*function\b", blockStart, blockEnd-1);
            funcIdx = filterTopLevelFunctions(lines, funcIdx, blockStart, blockEnd-1);
            blockMethods = parseFunctions(lines, funcIdx);
            for k = 1:numel(blockMethods)
                blockMethods(k).IsMethod   = true;
                blockMethods(k).Parent     = className;
                blockMethods(k).Access     = attrs.Access;
                blockMethods(k).IsStatic   = attrs.IsStatic;
                blockMethods(k).IsAbstract = attrs.IsAbstract;
            end
            methods = [methods; blockMethods]; %#ok<AGROW>
            i = blockEnd + 1;
        elseif startsWith(L, "properties")
            blockStart = i + 1;
            blockEnd   = matchEnd(lines, i);
            for j = blockStart:(blockEnd-1)
                P = strtrim(stripComment(lines(j)));
                tok = regexp(P, "^([A-Za-z]\w*)", 'tokens', 'once');
                if ~isempty(tok)
                    props(end+1,1) = string(tok{1}); %#ok<AGROW>
                end
            end
            i = blockEnd + 1;
        elseif startsWith(L, "events") || startsWith(L, "enumeration")
            i = matchEnd(lines, i) + 1;
        elseif L == "end"
            break
        else
            i = i + 1;
        end
    end
end

function endLine = matchEnd(lines, startLine)
    depth = 1;
    keywords = ["if","for","while","switch","try","function","parfor","methods","properties","events","enumeration","classdef","arguments","spmd"];
    endLine = numel(lines);
    for i = (startLine+1):numel(lines)
        L = strtrim(stripComment(lines(i)));
        if isempty(L), continue; end
        firstWord = regexp(L, "^[A-Za-z]\w*", 'match', 'once');
        if any(strcmp(firstWord, keywords))
            depth = depth + 1;
        elseif strcmp(firstWord, "end") || L == "end"
            depth = depth - 1;
            if depth == 0
                endLine = i;
                return
            end
        end
    end
end

function idx = findCodeMatchInRange(lines, pattern, lo, hi)
    idx = [];
    for i = lo:hi
        L = stripComment(lines(i));
        if ~isempty(regexp(L, pattern, 'once'))
            idx(end+1,1) = i; %#ok<AGROW>
        end
    end
end

function topIdx = filterTopLevelFunctions(lines, funcIdx, blockStart, blockEnd)
    % Keep only function lines whose match-end falls inside the block, and
    % which are at the outer-most depth of the methods block.
    topIdx = [];
    pos = blockStart;
    while pos <= blockEnd
        L = stripComment(lines(pos));
        if ~isempty(regexp(L, "^\s*function\b", 'once')) && any(funcIdx == pos)
            topIdx(end+1,1) = pos; %#ok<AGROW>
            pos = matchEnd(lines, pos) + 1;
        else
            pos = pos + 1;
        end
    end
end

function attrs = parseBlockAttributes(line)
    attrs = struct("Access","public", "IsStatic", false, "IsAbstract", false);
    tok = regexp(line, "methods\s*\(([^)]*)\)", 'tokens', 'once');
    if isempty(tok), return; end
    body = string(tok{1});
    pairs = split(body, ",");
    for k = 1:numel(pairs)
        p = strtrim(pairs(k));
        if startsWith(lower(p), "static")
            v = extractValue(p);
            attrs.IsStatic = isTruthy(v);
        elseif startsWith(lower(p), "abstract")
            v = extractValue(p);
            attrs.IsAbstract = isTruthy(v);
        elseif startsWith(lower(p), "access")
            v = extractValue(p);
            if strlength(v) > 0
                attrs.Access = char(lower(v));
            end
        end
    end
end

function v = extractValue(p)
    eqIdx = strfind(p, "=");
    if isempty(eqIdx)
        v = "true";
    else
        v = strtrim(extractAfter(p, eqIdx(1)));
    end
end

function tf = isTruthy(v)
    tf = any(strcmpi(v, ["true" "1"]));
end

% =========================================================================
function desc = extractH1(lines, kind, name)
    desc = "";
    startSearch = 1;
    if any(kind == ["function" "class" "app"])
        for i = 1:numel(lines)
            L = strtrim(lines(i));
            if startsWith(L, "function") || startsWith(L, "classdef")
                startSearch = i + 1;
                break
            end
        end
    end
    for i = startSearch:min(startSearch+10, numel(lines))
        L = strtrim(lines(i));
        if startsWith(L, "%")
            desc = strtrim(regexprep(L, "^%+", ""));
            return
        end
        if strlength(L) == 0
            continue
        end
        return
    end
    if desc == "" && ~isempty(name)
        desc = "MATLAB " + string(kind) + " '" + string(name) + "'.";
    end
end
