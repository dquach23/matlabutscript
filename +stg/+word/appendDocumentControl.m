function appendDocumentControl(doc, metadata)
%APPENDDOCUMENTCONTROL Document-control / revision-history block.

    import mlreportgen.dom.*

    append(doc, stg.word.heading("Document Control", 2));

    rows = [
        "Document Identifier",  metadata.DocumentId
        "Document Title",       "Software Test Report (STR)"
        "Project / Program",    metadata.ProjectName
        "Issuing Organization", metadata.Organization
        "Prepared By",          metadata.Author
        "Date Issued",          metadata.GeneratedDate
        "Classification",       metadata.Classification
        "Source Under Test",    metadata.SourceFile
        "Generated Test Class", metadata.TestFile
        "Distribution",         "Distribution authorized to U.S. Government agencies and their contractors."
    ];
    append(doc, stg.word.keyValueTable(rows));

    append(doc, Paragraph(' '));
    append(doc, stg.word.heading("Revision History", 3));

    tbl = Table({'Version', 'Date', 'Author', 'Description of Change'});
    tbl.Border = 'solid'; tbl.RowSep = 'solid'; tbl.ColSep = 'solid';
    tbl.BorderColor = '#ccd2d8'; tbl.Width = '100%';

    headerRow = TableRow();
    for h = ["Version" "Date" "Author" "Description of Change"]
        e = TableEntry(Paragraph(char(h)));
        e.Style = {BackgroundColor('#003a70'), Color('#ffffff'), Bold(true)};
        append(headerRow, e);
    end
    append(tbl, headerRow);

    dataRow = TableRow();
    append(dataRow, TableEntry("1.0"));
    append(dataRow, TableEntry(char(metadata.GeneratedDate)));
    append(dataRow, TableEntry(char(metadata.Author)));
    append(dataRow, TableEntry("Initial automated issue produced by matlabutscript test generator."));
    append(tbl, dataRow);

    append(doc, tbl);
    append(doc, PageBreak);
end
