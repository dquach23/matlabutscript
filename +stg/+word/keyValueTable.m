function tbl = keyValueTable(rows)
%KEYVALUETABLE Build a 2-column metadata-style table for the Word report.
%   ROWS is an Nx2 string array (label, value).

    import mlreportgen.dom.*

    arguments
        rows (:,2) string
    end

    tbl = Table(2);
    tbl.Border = 'solid';
    tbl.BorderColor = '#ccd2d8';
    tbl.RowSep = 'solid';
    tbl.ColSep = 'solid';
    tbl.Width = '100%';
    tbl.TableEntriesInnerMargin = '4pt';

    for k = 1:size(rows,1)
        tr = TableRow();
        keyEntry = TableEntry(makeKey(rows(k,1)));
        keyEntry.Style = {Width('30%'), BackgroundColor('#f5f7fa')};
        valEntry = TableEntry(Paragraph(char(rows(k,2))));
        append(tr, keyEntry);
        append(tr, valEntry);
        append(tbl, tr);
    end
end

function p = makeKey(label)
    import mlreportgen.dom.*
    p = Paragraph(char(label));
    p.Bold = true;
end
