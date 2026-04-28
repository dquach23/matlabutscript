function h = fileHash(filePath)
%FILEHASH Compute SHA-256 hash of a file for configuration management.
    arguments
        filePath (1,1) string
    end
    try
        digest = java.security.MessageDigest.getInstance('SHA-256');
        fid = fopen(char(filePath), 'r');
        if fid < 0
            h = "unavailable";
            return
        end
        cleanup = onCleanup(@() fclose(fid));
        buf = fread(fid, Inf, '*uint8');
        hashBytes = typecast(digest.digest(buf), 'uint8');
        h = string(lower(reshape(dec2hex(hashBytes,2).', 1, [])));
    catch
        h = "unavailable";
    end
end
