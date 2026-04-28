function html = coverPage(metadata, summary)
%COVERPAGE Render the cover page for the Software Test Report.
%   Layout follows USAF technical-document conventions: classification
%   banner, agency seal placeholder, document title, document identifier,
%   project, organization, author, date.

    verdictClass = lower(string(summary.Verdict));
    if verdictClass == "pass"
        verdictTag = "<span class=""verdict pass"">PASS</span>";
    elseif verdictClass == "fail"
        verdictTag = "<span class=""verdict fail"">FAIL</span>";
    else
        verdictTag = "<span class=""verdict warn"">" + stg.escapeHtml(upper(summary.Verdict)) + "</span>";
    end

    parts = strings(0,1);
    parts(end+1) = "        <section class=""cover"">";
    parts(end+1) = "            <div class=""seal"" aria-hidden=""true"">&#9733;</div>";
    parts(end+1) = "            <div class=""subtitle"">DEPARTMENT OF THE AIR FORCE</div>";
    parts(end+1) = "            <div class=""subtitle"">" + stg.escapeHtml(metadata.Organization) + "</div>";
    parts(end+1) = "            <h1 class=""title"">SOFTWARE TEST REPORT</h1>";
    parts(end+1) = "            <div class=""subtitle"">" + stg.escapeHtml(metadata.ProjectName) + "</div>";
    parts(end+1) = "            <div class=""docid"">Document ID: " + stg.escapeHtml(metadata.DocumentId) + "</div>";
    parts(end+1) = "            <div class=""docid"">Date: " + stg.escapeHtml(metadata.GeneratedDate) + "</div>";
    parts(end+1) = "            <div class=""docid"">Overall Verdict: " + verdictTag + "</div>";
    parts(end+1) = "        </section>";
    html = strjoin(parts, newline);
end
