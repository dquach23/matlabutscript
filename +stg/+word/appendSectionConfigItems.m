function appendSectionConfigItems(doc, info, metadata)
%APPENDSECTIONCONFIGITEMS Section 7 (Configuration Items).

    import mlreportgen.dom.*

    append(doc, stg.word.heading("7. Configuration Items", 2));

    append(doc, Paragraph(sprintf( ...
        "The following configuration items are placed under control of the project software " + ...
        "configuration management system. SHA-256 digests are recorded so downstream consumers " + ...
        "can verify integrity without recomputing the test suite.")));

    items = {};
    items(end+1,:) = {"Source Under Test", info.Name, info.FilePath, info.Hash};
    if isfield(metadata,"TestFile") && isfile(metadata.TestFile)
        items(end+1,:) = {"Generated Test Class", "test"+string(info.Name), ...
            metadata.TestFile, char(stg.fileHash(metadata.TestFile))};
    end
    logFile = fullfile(metadata.OutputDir, "test_log.txt");
    if isfile(logFile)
        items(end+1,:) = {"Test Log", "test_log.txt", logFile, char(stg.fileHash(logFile))};
    end
    matFile = fullfile(metadata.OutputDir, "test_results.mat");
    if isfile(matFile)
        items(end+1,:) = {"Test Result Archive", "test_results.mat", matFile, char(stg.fileHash(matFile))};
    end

    headers = {'Type','Identifier','Path','SHA-256'};
    tbl = Table(numel(headers));
    tbl.Border = 'solid'; tbl.RowSep = 'solid'; tbl.ColSep = 'solid';
    tbl.BorderColor = '#ccd2d8'; tbl.Width = '100%';

    headerRow = TableRow();
    for h = string(headers)
        e = TableEntry(Paragraph(char(h)));
        e.Style = {BackgroundColor('#003a70'), Color('#ffffff'), Bold(true)};
        append(headerRow, e);
    end
    append(tbl, headerRow);

    for k = 1:size(items,1)
        tr = TableRow();
        for c = 1:size(items,2)
            entry = TableEntry(char(items{k,c}));
            if c == 4
                entry.Style = {FontFamily('Courier New'), FontSize('8pt')};
            end
            append(tr, entry);
        end
        append(tbl, tr);
    end

    append(doc, tbl);
end
