function appendSectionDetailedResults(doc, rows)
%APPENDSECTIONDETAILEDRESULTS Section 4 (Detailed Test Results).

    import mlreportgen.dom.*

    append(doc, stg.word.heading("4. Detailed Test Results", 2));

    if isempty(rows)
        p = Paragraph("No test cases were planned for this software item.");
        p.Italic = true;
        append(doc, p);
        return
    end

    append(doc, stg.word.heading("4.1 Summary Table", 3));

    headers = {'Case ID','Target','Category','Requirement','Verdict','Duration (s)'};
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

    for k = 1:numel(rows)
        r = rows(k);
        tr = TableRow();
        append(tr, TableEntry(char(r.Id)));
        append(tr, TableEntry(char(r.Target)));
        append(tr, TableEntry(char(r.Category)));
        if r.Requirement == "", req = "(not traced)"; else, req = r.Requirement; end
        append(tr, TableEntry(char(req)));
        verdictEntry = TableEntry(Paragraph(char(r.Verdict)));
        verdictEntry.Style = {Color(verdictColor(r.Verdict)), Bold(true)};
        append(tr, verdictEntry);
        append(tr, TableEntry(sprintf("%.4f", r.Duration)));
        append(tbl, tr);
    end
    append(doc, tbl);

    append(doc, stg.word.heading("4.2 Test Case Records", 3));
    for k = 1:numel(rows)
        r = rows(k);
        appendCaseBlock(doc, r);
    end
end

function appendCaseBlock(doc, r)
    import mlreportgen.dom.*

    h = stg.word.heading(sprintf("%s — %s [%s]", r.Id, r.Target, r.Verdict), 4);
    h.Color = verdictColor(r.Verdict);
    append(doc, h);

    descr = [
        "Test Method",   r.MethodName
        "Description",   r.Description
        "Category",      r.Category
        "Requirement",   ifEmpty(r.Requirement, "(not traced)")
        "Expected",      r.ExpectedResult
        "Actual",        actualText(r)
        "Duration",      sprintf("%.4f s", r.Duration)
    ];
    append(doc, stg.word.keyValueTable(descr));

    if r.Diagnostics ~= "" && lower(string(r.Verdict)) ~= "pass"
        diagHead = Paragraph("Diagnostics:");
        diagHead.Bold = true; diagHead.FontSize = '10pt';
        append(doc, diagHead);
        diag = Paragraph(char(r.Diagnostics));
        diag.FontFamilyName = 'Courier New'; diag.FontSize = '9pt';
        diag.BackgroundColor = '#f5f7fa';
        append(doc, diag);
    end
    append(doc, Paragraph(' '));
end

function c = verdictColor(verdict)
    switch lower(string(verdict))
        case "pass",       c = '#1e7e34';
        case "fail",       c = '#b21f2d';
        case "incomplete", c = '#b8860b';
        otherwise,         c = '#666666';
    end
end

function v = ifEmpty(v, d)
    if strlength(string(v)) == 0, v = d; end
end

function s = actualText(r)
    switch lower(string(r.Verdict))
        case "pass",       s = "All assertions satisfied; no errors or warnings raised.";
        case "fail",       s = "Assertion failed or error raised. See diagnostics below.";
        case "incomplete", s = "Test did not run to completion. See diagnostics below.";
        otherwise,         s = "See diagnostics.";
    end
end
