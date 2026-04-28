function expr = inferTestInput(name)
%INFERTESTINPUT Heuristic to choose a representative MATLAB literal for an
%input argument given its parameter name. The returned EXPR is a string of
%MATLAB code suitable for direct insertion in a generated test.

    arguments
        name (1,1) string
    end

    n = lower(strtrim(string(name)));

    if n == "" || n == "~" || n == "varargin"
        expr = "";
        return
    end
    if n == "obj" || n == "self" || n == "this" || n == "app"
        expr = "";   % handled separately by the test generator
        return
    end

    % Order matters: more specific patterns first.
    rules = {
        "^(file|filename|filepath|fname|fullpath)$",      "tempname + "".txt"""
        "^(path|folder|dir|directory)$",                   "tempdir"
        "^(name|label|str|text|tag|id|key|description)$",  """test_value"""
        "^(opts|options|params|kwargs|args|cfg|config)$",  "struct()"
        "^(tol|tolerance|epsilon|eps)$",                   "1e-6"
        "^(flag|enable|enabled|disabled)$",                "true"
        "^(is[a-z].*|has[a-z].*|should[a-z].*|use[a-z].*|do[a-z].*)$", "true"
        "^(n|num|count|len|length|size|nx|ny|nz|nrows|ncols|niter|maxiter)$", "3"
        "^(idx|index|i|j|k)$",                             "1"
        "^(x|y|z|t|signal|series)$",                       "(1:10)'"
        "^(vec|vector|values|data)$",                      "[1 2 3 4 5]"
        "^(mat|matrix|a|b|c|m)$",                          "magic(3)"
        "^(img|image|frame|pic)$",                         "uint8(255*ones(8,8,3))"
        "^(date|datetime|when)$",                          "datetime(""now"")"
        "^(time|duration|dt)$",                            "seconds(1)"
        "^(rate|freq|frequency|hz)$",                      "100"
        "^(amp|amplitude|gain)$",                          "1.0"
        "^(fig|figure|ui|uifig|uifigure|hfig)$",           "uifigure(""Visible"",""off"")"
        "^(ax|axes|haxes)$",                               "axes(figure(""Visible"",""off""))"
    };

    for r = 1:size(rules,1)
        if ~isempty(regexp(n, rules{r,1}, 'once'))
            expr = string(rules{r,2});
            return
        end
    end

    % Looser keyword matches:
    if contains(n, ["filename" "filepath" "file"])
        expr = "tempname + "".txt"""; return
    end
    if contains(n, ["path" "folder" "dir"])
        expr = "tempdir"; return
    end
    if contains(n, ["name" "label" "id" "key" "tag" "title"])
        expr = """test_value"""; return
    end
    if contains(n, ["bool" "flag" "enabled" "is_" "has_"])
        expr = "true"; return
    end
    if contains(n, ["count" "num" "size" "length" "iter"])
        expr = "3"; return
    end
    if contains(n, ["matrix" "mat"])
        expr = "magic(3)"; return
    end
    if contains(n, ["vector" "vec" "array" "list"])
        expr = "[1 2 3 4 5]"; return
    end
    if contains(n, ["image" "img" "frame"])
        expr = "uint8(255*ones(8,8,3))"; return
    end
    if contains(n, ["fig" "axes"])
        expr = "uifigure(""Visible"",""off"")"; return
    end
    if contains(n, ["opts" "options" "params" "config"])
        expr = "struct()"; return
    end

    % Fallback: a numeric scalar.
    expr = "1.0";
end
