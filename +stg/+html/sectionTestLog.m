function html = sectionTestLog(metadata)
%SECTIONTESTLOG Render Section 5 (Test Log).
%   Embeds the captured runner stdout from runTests so the report contains
%   a full chronological record of execution per IEEE 829 Section 7.

    parts = strings(0,1);
    parts(end+1) = "        <section id=""sec-log"">";
    parts(end+1) = "            <h2>5. Test Log</h2>";
    logFile = fullfile(metadata.OutputDir, "test_log.txt");
    if isfile(logFile)
        try
            txt = fileread(char(logFile));
        catch
            txt = "(test log could not be read)";
        end
        if isempty(strtrim(txt))
            txt = "(test log was empty)";
        end
        parts(end+1) = "            <p>The following is a verbatim capture of the matlab.unittest runner output, " + ...
            "preserved for chain-of-custody purposes.</p>";
        parts(end+1) = "            <pre class=""log"">" + stg.escapeHtml(txt) + "</pre>";
    else
        parts(end+1) = "            <p><em>No runtime log was captured (RunTests was disabled or the runner did not produce output).</em></p>";
    end
    parts(end+1) = "        </section>";
    html = strjoin(parts, newline);
end
