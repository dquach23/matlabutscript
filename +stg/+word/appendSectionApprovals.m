function appendSectionApprovals(doc, metadata)
%APPENDSECTIONAPPROVALS Section 10 (Approvals / signature block).

    import mlreportgen.dom.*

    append(doc, stg.word.heading("10. Approvals", 2));

    append(doc, Paragraph(sprintf( ...
        "By signature below, the undersigned attest that this Software Test Report " + ...
        "accurately reflects the verification activities performed against software item " + ...
        "%s on %s.", metadata.SourceName, metadata.GeneratedDate)));

    headers = {'Role','Name','Signature','Date'};
    tbl = Table(numel(headers));
    tbl.Border = 'solid'; tbl.RowSep = 'solid'; tbl.ColSep = 'solid';
    tbl.BorderColor = '#000000'; tbl.Width = '100%';

    headerRow = TableRow();
    for h = string(headers)
        e = TableEntry(Paragraph(char(h)));
        e.Style = {BackgroundColor('#f5f7fa'), Bold(true)};
        append(headerRow, e);
    end
    append(tbl, headerRow);

    appendRow(tbl, "Prepared By (Test Engineer)",  char(metadata.Author));
    appendRow(tbl, "Reviewed By (Test Lead)",      "");
    appendRow(tbl, "Approved By (Program Manager)", "");
    appendRow(tbl, "Quality Assurance",             "");

    append(doc, tbl);
end

function appendRow(tbl, role, name)
    import mlreportgen.dom.*
    tr = TableRow(); tr.Height = '0.55in';
    append(tr, TableEntry(Paragraph(char(role))));
    append(tr, TableEntry(Paragraph(char(name))));
    append(tr, TableEntry(Paragraph(' ')));
    append(tr, TableEntry(Paragraph(' ')));
    append(tbl, tr);
end
