function appendSectionNotes(doc)
%APPENDSECTIONNOTES Section 9 (Notes / Acronyms).

    import mlreportgen.dom.*

    append(doc, stg.word.heading("9. Notes", 2));
    append(doc, stg.word.heading("9.1 Acronyms", 3));

    acronyms = {
        "AFI",     "Air Force Instruction"
        "CDRL",    "Contract Data Requirements List"
        "CI",      "Configuration Item"
        "CSU",     "Computer Software Unit"
        "DID",     "Data Item Description"
        "DT&E",    "Developmental Test and Evaluation"
        "IEEE",    "Institute of Electrical and Electronics Engineers"
        "MIL-STD", "Military Standard"
        "OT&E",    "Operational Test and Evaluation"
        "RTM",     "Requirements Traceability Matrix"
        "SCM",     "Software Configuration Management"
        "STD",     "Software Test Description"
        "STP",     "Software Test Plan"
        "STR",     "Software Test Report"
        "SUT",     "Software Under Test"
        "T&E",     "Test and Evaluation"
        "USAF",    "United States Air Force"
        "V&V",     "Verification and Validation"
    };

    headers = {'Acronym','Expansion'};
    tbl = Table(numel(headers));
    tbl.Border = 'solid'; tbl.RowSep = 'solid'; tbl.ColSep = 'solid';
    tbl.BorderColor = '#ccd2d8'; tbl.Width = '60%';

    headerRow = TableRow();
    for h = string(headers)
        e = TableEntry(Paragraph(char(h)));
        e.Style = {BackgroundColor('#003a70'), Color('#ffffff'), Bold(true)};
        append(headerRow, e);
    end
    append(tbl, headerRow);

    for k = 1:size(acronyms,1)
        tr = TableRow();
        e1 = TableEntry(Paragraph(char(acronyms{k,1})));
        e1.Style = {Bold(true), FontFamily('Courier New')};
        append(tr, e1);
        append(tr, TableEntry(char(acronyms{k,2})));
        append(tbl, tr);
    end
    append(doc, tbl);

    append(doc, stg.word.heading("9.2 Generation Methodology", 3));
    append(doc, Paragraph(sprintf( ...
        "This STR was produced by an automated tool that (1) statically analyzed the MATLAB " + ...
        "source under test, (2) synthesized matlab.unittest test cases exercising the public " + ...
        "API surface (constructors, functions, methods, app launch), (3) executed those cases " + ...
        "under the matlab.unittest runner and (4) rendered this report. The tool is " + ...
        "unqualified per DO-330; the test engineer of record retains responsibility for the " + ...
        "technical content of this report.")));
end
