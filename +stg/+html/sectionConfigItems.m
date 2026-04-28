function html = sectionConfigItems(info, metadata)
%SECTIONCONFIGITEMS Render Section 7 (Configuration Items) per AFI 63-101.
%   Captures the precise versions and integrity hashes of every artifact
%   produced or consumed by this verification activity.

    items = struct("Type",{}, "Identifier",{}, "Path",{}, "Hash",{});
    items(end+1) = item("Source Under Test", info.Name, info.FilePath, info.Hash);
    if isfield(metadata, "TestFile") && isfile(metadata.TestFile)
        items(end+1) = item("Generated Test Class", "test" + string(info.Name), ...
            metadata.TestFile, char(stg.fileHash(metadata.TestFile)));
    end
    logFile = fullfile(metadata.OutputDir, "test_log.txt");
    if isfile(logFile)
        items(end+1) = item("Test Log", "test_log.txt", logFile, char(stg.fileHash(logFile)));
    end
    matFile = fullfile(metadata.OutputDir, "test_results.mat");
    if isfile(matFile)
        items(end+1) = item("Test Result Archive", "test_results.mat", matFile, char(stg.fileHash(matFile)));
    end

    parts = strings(0,1);
    parts(end+1) = "        <section id=""sec-ci"">";
    parts(end+1) = "            <h2>7. Configuration Items</h2>";
    parts(end+1) = "            <p>The following configuration items are placed under control of " + ...
        "the project software configuration management system. SHA-256 digests are recorded so " + ...
        "downstream consumers can verify integrity without recomputing the test suite.</p>";
    parts(end+1) = "            <table class=""results"">";
    parts(end+1) = "                <thead><tr><th>Type</th><th>Identifier</th><th>Path</th><th>SHA-256</th></tr></thead>";
    parts(end+1) = "                <tbody>";
    for k = 1:numel(items)
        it = items(k);
        parts(end+1) = "                    <tr><td>" + stg.escapeHtml(it.Type) + ...
            "</td><td>" + stg.escapeHtml(it.Identifier) + ...
            "</td><td>" + stg.escapeHtml(it.Path) + ...
            "</td><td><code>" + stg.escapeHtml(it.Hash) + "</code></td></tr>"; %#ok<AGROW>
    end
    parts(end+1) = "                </tbody>";
    parts(end+1) = "            </table>";
    parts(end+1) = "        </section>";
    html = strjoin(parts, newline);
end

function it = item(typ, id, p, h)
    it = struct("Type",string(typ), "Identifier",string(id), "Path",string(p), "Hash",string(h));
end
