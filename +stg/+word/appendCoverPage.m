function appendCoverPage(doc, metadata, summary)
%APPENDCOVERPAGE Cover page for the Word STR.

    import mlreportgen.dom.*

    spacer = Paragraph(' '); spacer.FontSize = '36pt';
    append(doc, spacer);

    seal = Paragraph(char(9733));   % ★
    seal.HAlign = 'center';
    seal.FontSize = '60pt';
    seal.Color = '#ffc20e';
    append(doc, seal);

    org = Paragraph('DEPARTMENT OF THE AIR FORCE');
    org.HAlign = 'center'; org.Bold = true; org.FontSize = '14pt';
    org.Color = '#003a70';
    append(doc, org);

    org2 = Paragraph(metadata.Organization);
    org2.HAlign = 'center'; org2.FontSize = '12pt';
    append(doc, org2);

    append(doc, Paragraph(' '));

    title = Paragraph('SOFTWARE TEST REPORT');
    title.HAlign = 'center'; title.Bold = true; title.FontSize = '24pt';
    title.Color = '#003a70';
    append(doc, title);

    project = Paragraph(metadata.ProjectName);
    project.HAlign = 'center'; project.FontSize = '14pt';
    append(doc, project);

    append(doc, Paragraph(' '));

    docid = Paragraph(sprintf('Document ID: %s', metadata.DocumentId));
    docid.HAlign = 'center'; docid.FontFamilyName = 'Courier New'; docid.FontSize = '12pt';
    append(doc, docid);

    issued = Paragraph(sprintf('Date Issued: %s', metadata.GeneratedDate));
    issued.HAlign = 'center'; issued.FontFamilyName = 'Courier New'; issued.FontSize = '12pt';
    append(doc, issued);

    verdict = Paragraph(sprintf('Overall Verdict: %s', summary.Verdict));
    verdict.HAlign = 'center'; verdict.Bold = true; verdict.FontSize = '14pt';
    switch lower(string(summary.Verdict))
        case "pass", verdict.Color = '#1e7e34';
        case "fail", verdict.Color = '#b21f2d';
        otherwise,    verdict.Color = '#b8860b';
    end
    append(doc, verdict);

    append(doc, Paragraph(' '));

    classBanner = Paragraph(upper(string(metadata.Classification)));
    classBanner.HAlign = 'center'; classBanner.Bold = true; classBanner.FontSize = '12pt';
    classBanner.Color = '#FFFFFF';
    classBanner.BackgroundColor = '#003a70';
    append(doc, classBanner);

    append(doc, PageBreak);
end
