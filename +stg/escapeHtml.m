function s = escapeHtml(s)
%ESCAPEHTML Escape HTML metacharacters in arbitrary text.
    s = string(s);
    s = replace(s, "&",  "&amp;");
    s = replace(s, "<",  "&lt;");
    s = replace(s, ">",  "&gt;");
    s = replace(s, """", "&quot;");
    s = replace(s, "'",  "&#39;");
end
