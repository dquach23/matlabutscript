function appendTableOfContents(doc)
%APPENDTABLEOFCONTENTS Insert a Word TOC field that auto-populates on open.

    import mlreportgen.dom.*

    append(doc, stg.word.heading("Table of Contents", 2));

    tocPara = Paragraph();
    tocCmd = TOC(2);   % include levels 1 and 2
    append(tocPara, tocCmd);
    append(doc, tocPara);

    note = Paragraph('(Press F9 in Word to refresh the table of contents.)');
    note.FontSize = '9pt'; note.Color = '#666666';
    append(doc, note);

    append(doc, PageBreak);
end
