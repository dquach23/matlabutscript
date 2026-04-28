function appendSectionTestLog(doc, metadata)
%APPENDSECTIONTESTLOG Section 5 (Test Log).

    import mlreportgen.dom.*

    append(doc, stg.word.heading("5. Test Log", 2));

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
        append(doc, Paragraph(sprintf( ...
            "The following is a verbatim capture of the matlab.unittest runner output, " + ...
            "preserved for chain-of-custody purposes.")));
        logPara = Paragraph(char(txt));
        logPara.FontFamilyName = 'Courier New';
        logPara.FontSize = '9pt';
        logPara.BackgroundColor = '#0e1116';
        logPara.Color = '#e6edf3';
        append(doc, logPara);
    else
        p = Paragraph("No runtime log was captured (RunTests was disabled or the runner did not produce output).");
        p.Italic = true;
        append(doc, p);
    end
end
