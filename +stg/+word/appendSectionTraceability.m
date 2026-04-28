function appendSectionTraceability(doc, rows, requirements)
%APPENDSECTIONTRACEABILITY Section 8 (Requirements Traceability Matrix).

    import mlreportgen.dom.*

    append(doc, stg.word.heading("8. Requirements Traceability Matrix", 2));

    if isempty(rows)
        p = Paragraph("No test cases to trace.");
        p.Italic = true; append(doc, p);
        return
    end

    append(doc, Paragraph(sprintf( ...
        "Bidirectional traceability is mandatory for software undergoing DT&E or OT&E " + ...
        "activities. The matrix below presents the test-to-requirement mapping (forward) " + ...
        "and the corresponding verdict.")));

    append(doc, stg.word.heading("8.1 Test → Requirement", 3));
    headers = {'Test Case','Target','Requirement','Verdict'};
    tbl = makeStyledTable(headers);
    for k = 1:numel(rows)
        r = rows(k);
        req = r.Requirement; if req == "", req = "(not traced)"; end
        tr = TableRow();
        append(tr, TableEntry(char(r.Id)));
        append(tr, TableEntry(char(r.Target)));
        append(tr, TableEntry(char(req)));
        append(tr, TableEntry(char(r.Verdict)));
        append(tbl, tr);
    end
    append(doc, tbl);

    if ~isempty(requirements)
        append(doc, stg.word.heading("8.2 Requirement → Test (Reverse Trace)", 3));
        headers = {'Requirement','Description','Verification Method','Covering Test Cases'};
        tbl = makeStyledTable(headers);
        for r = 1:numel(requirements)
            req = requirements(r);
            covering = string({});
            for k = 1:numel(rows)
                if string(rows(k).Requirement) == string(req.Id)
                    covering(end+1) = string(rows(k).Id); %#ok<AGROW>
                end
            end
            if isempty(covering)
                covText = "(NONE — GAP)";
            else
                covText = strjoin(covering, ", ");
            end
            tr = TableRow();
            append(tr, TableEntry(char(req.Id)));
            append(tr, TableEntry(char(req.Description)));
            append(tr, TableEntry(char(req.Verification)));
            append(tr, TableEntry(char(covText)));
            append(tbl, tr);
        end
        append(doc, tbl);
    else
        p = Paragraph("No requirements file was supplied; reverse trace is not available.");
        p.Italic = true;
        append(doc, p);
    end
end

function tbl = makeStyledTable(headers)
    import mlreportgen.dom.*
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
end
