function html = sectionApprovals(metadata)
%SECTIONAPPROVALS Render Section 10 (Approvals).
%   Three-line signature block consistent with USAF technical reports:
%   Prepared By, Reviewed By (Test Lead), Approved By (Program Manager).

    parts = strings(0,1);
    parts(end+1) = "        <section id=""sec-approve"">";
    parts(end+1) = "            <h2>10. Approvals</h2>";
    parts(end+1) = "            <p>By signature below, the undersigned attest that this Software Test " + ...
        "Report accurately reflects the verification activities performed against software " + ...
        "item " + stg.escapeHtml(metadata.SourceName) + " on " + stg.escapeHtml(metadata.GeneratedDate) + ".</p>";
    parts(end+1) = "            <table class=""approval"">";
    parts(end+1) = "                <thead><tr><th>Role</th><th>Name</th><th>Signature</th><th>Date</th></tr></thead>";
    parts(end+1) = "                <tbody>";
    parts(end+1) = approvalRow("Prepared By (Test Engineer)", metadata.Author);
    parts(end+1) = approvalRow("Reviewed By (Test Lead)", "");
    parts(end+1) = approvalRow("Approved By (Program Manager)", "");
    parts(end+1) = approvalRow("Quality Assurance", "");
    parts(end+1) = "                </tbody>";
    parts(end+1) = "            </table>";
    parts(end+1) = "        </section>";
    html = strjoin(parts, newline);
end

function r = approvalRow(role, name)
    r = "                    <tr><td>" + stg.escapeHtml(role) + ...
        "</td><td>" + stg.escapeHtml(name) + ...
        "</td><td class=""signblock""></td><td class=""signblock""></td></tr>";
end
