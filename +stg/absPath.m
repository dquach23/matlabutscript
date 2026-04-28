function p = absPath(p)
%ABSPATH Return an absolute, normalized path string.
    p = string(p);
    if startsWith(p, "~")
        home = string(getenv("HOME"));
        if home == ""
            home = string(getenv("USERPROFILE"));
        end
        p = home + extractAfter(p, 1);
    end
    f = java.io.File(char(p));
    if ~f.isAbsolute()
        f = java.io.File(fullfile(pwd, char(p)));
    end
    p = string(char(f.getCanonicalPath()));
end
