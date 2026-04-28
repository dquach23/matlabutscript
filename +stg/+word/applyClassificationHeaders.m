function applyClassificationHeaders(doc, metadata)
%APPLYCLASSIFICATIONHEADERS Configure the page-level classification banner
%on every page of the Word document, matching DoD marking conventions.

    import mlreportgen.dom.*

    classification = upper(string(metadata.Classification));

    open(doc);

    pageLayout = doc.CurrentPageLayout;

    % Header (top of every page)
    pageLayout.PageHeaders = PageHeader('default');
    headerText = Paragraph(char(classification));
    headerText.Bold = true;
    headerText.HAlign = 'center';
    headerText.FontFamilyName = 'Arial';
    headerText.FontSize = '11pt';
    headerText.Color = '#FFFFFF';
    headerText.BackgroundColor = '#003a70';
    append(pageLayout.PageHeaders, headerText);

    % Footer (bottom of every page)
    pageLayout.PageFooters = PageFooter('default');
    footerText = Paragraph(char(classification));
    footerText.Bold = true;
    footerText.HAlign = 'center';
    footerText.FontFamilyName = 'Arial';
    footerText.FontSize = '11pt';
    footerText.Color = '#FFFFFF';
    footerText.BackgroundColor = '#003a70';
    append(pageLayout.PageFooters, footerText);

    docId = Paragraph(sprintf("Document ID: %s   |   %s", ...
        metadata.DocumentId, metadata.GeneratedDate));
    docId.HAlign = 'center';
    docId.FontSize = '8pt';
    docId.Color = '#444444';
    append(pageLayout.PageFooters, docId);
end
