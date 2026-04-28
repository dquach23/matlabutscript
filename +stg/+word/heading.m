function p = heading(text, level)
%HEADING Convenience wrapper for a styled heading paragraph.

    import mlreportgen.dom.*

    arguments
        text  (1,1) string
        level (1,1) double {mustBeMember(level,[1 2 3 4])} = 2
    end

    p = Paragraph(char(text));
    p.Bold = true;
    p.Color = '#003a70';
    switch level
        case 1, p.FontSize = '20pt';
        case 2, p.FontSize = '16pt';
        case 3, p.FontSize = '13pt';
        case 4, p.FontSize = '11.5pt';
    end
    p.OutlineLevel = level;
end
