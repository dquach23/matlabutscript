function s = summarizeResults(results)
%SUMMARIZERESULTS Build a struct of pass/fail counts and aggregate timing.

    arguments
        results
    end

    s = struct( ...
        "Total",      0, ...
        "Passed",     0, ...
        "Failed",     0, ...
        "Incomplete", 0, ...
        "Filtered",   0, ...
        "Duration",   0, ...
        "PassRate",   NaN, ...
        "Verdict",    "NOT EXECUTED");

    if isempty(results)
        return
    end

    s.Total      = numel(results);
    s.Passed     = sum([results.Passed]);
    s.Failed     = sum([results.Failed]);
    s.Incomplete = sum([results.Incomplete]);
    if isprop(results, 'FilteredByAssumption')
        try
            s.Filtered = sum([results.FilteredByAssumption]);
        catch
            s.Filtered = 0;
        end
    end
    s.Duration = sum([results.Duration]);
    s.PassRate = 100 * s.Passed / max(s.Total, 1);
    if s.Failed == 0 && s.Incomplete == 0
        s.Verdict = "PASS";
    elseif s.Failed > 0
        s.Verdict = "FAIL";
    else
        s.Verdict = "INCONCLUSIVE";
    end
end
