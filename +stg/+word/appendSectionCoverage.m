function appendSectionCoverage(doc, coverage)
%APPENDSECTIONCOVERAGE Section 6 (Code Coverage Analysis).

    import mlreportgen.dom.*

    append(doc, stg.word.heading("6. Code Coverage Analysis", 2));

    if ~coverage.Available
        append(doc, Paragraph("Code coverage instrumentation was not available for this run."));
        if isfield(coverage,'Reason') && ~isempty(coverage.Reason)
            p = Paragraph(char(coverage.Reason)); p.Italic = true;
            append(doc, p);
        end
        append(doc, Paragraph(sprintf( ...
            "Per DO-178C objective tables A-7, structural coverage analysis is required for " + ...
            "software at level C and above. Where this STR supports DO-178C credit, coverage " + ...
            "shall be recomputed using a qualified tool.")));
        return
    end

    rows = [
        "Line Coverage",   sprintf("%.2f%%", coverage.Percent)
        "Cobertura XML",   string(coverage.XmlPath)
    ];
    if isfield(coverage,'SourceDir')
        rows(end+1,:) = ["Source Directory", string(coverage.SourceDir)];
    end
    append(doc, stg.word.keyValueTable(rows));

    if isfield(coverage,'FilesCovered') && ~isempty(coverage.FilesCovered)
        append(doc, stg.word.heading("6.1 Covered Files", 3));
        list = UnorderedList();
        for k = 1:numel(coverage.FilesCovered)
            append(list, ListItem(char(coverage.FilesCovered(k))));
        end
        append(doc, list);
    end

    append(doc, stg.word.heading("6.2 Coverage Acceptance", 3));
    if coverage.Percent >= 80
        verdict = "MEETS the 80% line-coverage threshold typically required for USAF software at IEEE 829 Risk Level Moderate.";
    else
        verdict = "DOES NOT meet the 80% line-coverage threshold typically required for USAF software at IEEE 829 Risk Level Moderate. Additional test cases shall be authored.";
    end
    append(doc, Paragraph(char(verdict)));
end
