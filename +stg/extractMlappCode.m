function [code, meta] = extractMlappCode(mlappFile)
%EXTRACTMLAPPCODE Pull the MATLAB source out of an App Designer .mlapp file.
%
%   .mlapp files are ZIP archives. The author's MATLAB source code is stored
%   as a CDATA section inside one of the embedded XML payloads (typically
%   matlab/document.xml or appdesigner/appModel.xml depending on the MATLAB
%   release that authored the file). This helper extracts that source so it
%   can be parsed like an ordinary classdef.
%
%   Returns an empty string if the source could not be located.

    arguments
        mlappFile (1,1) string {mustBeFile}
    end

    code = "";
    meta = struct("Extracted", false, "SourcePath", "", "Files", strings(0,1));

    tempDir = tempname;
    mkdir(tempDir);
    cleanup = onCleanup(@() safeRmdir(tempDir));

    try
        files = unzip(char(mlappFile), tempDir);
    catch ME
        warning("stg:extractMlappCode:UnzipFailed", ...
            "Could not unzip %s: %s", mlappFile, ME.message);
        return
    end
    meta.Files = string(files);

    candidates = ["matlab/document.xml", "appdesigner/document.xml", ...
        "matlab/code.xml", "appdesigner/appModel.xml"];

    for c = candidates
        candidate = fullfile(tempDir, char(c));
        if isfile(candidate)
            code = readCodeFromXml(candidate);
            if strlength(strtrim(code)) > 0
                meta.Extracted = true;
                meta.SourcePath = char(c);
                return
            end
        end
    end

    % Fallback: walk every file inside the archive looking for a classdef
    for k = 1:numel(files)
        f = files{k};
        [~, ~, e] = fileparts(f);
        if any(lower(string(e)) == [".xml" ".m" ".txt"])
            try
                txt = fileread(f);
            catch
                continue
            end
            if contains(txt, "classdef ")
                if endsWith(lower(string(f)), ".xml")
                    code = readCodeFromXml(f);
                else
                    code = string(txt);
                end
                if strlength(strtrim(code)) > 0
                    meta.Extracted = true;
                    meta.SourcePath = f;
                    return
                end
            end
        end
    end
end

function code = readCodeFromXml(xmlPath)
    code = "";
    txt = fileread(xmlPath);
    txt = string(txt);

    % CDATA blocks contain the raw source.
    cdataMatches = regexp(txt, "<!\[CDATA\[(.*?)\]\]>", 'tokens');
    if ~isempty(cdataMatches)
        for k = 1:numel(cdataMatches)
            piece = string(cdataMatches{k}{1});
            if contains(piece, "classdef ") || contains(piece, "function ")
                code = piece;
                return
            end
        end
        code = string(cdataMatches{1}{1});
        return
    end

    % Some releases store code inside a <Code> element with HTML escapes.
    codeNode = regexp(txt, "<r:Code[^>]*>(.*?)</r:Code>", 'tokens', 'once');
    if isempty(codeNode)
        codeNode = regexp(txt, "<Code[^>]*>(.*?)</Code>", 'tokens', 'once');
    end
    if ~isempty(codeNode)
        code = unescapeXml(string(codeNode{1}));
    end
end

function s = unescapeXml(s)
    s = replace(s, "&lt;",  "<");
    s = replace(s, "&gt;",  ">");
    s = replace(s, "&quot;", """");
    s = replace(s, "&apos;", "'");
    s = replace(s, "&amp;",  "&");
end

function safeRmdir(d)
    try
        if isfolder(d)
            rmdir(d, 's');
        end
    catch
    end
end
