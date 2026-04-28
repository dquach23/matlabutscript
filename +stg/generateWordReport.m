function reportPath = generateWordReport(info, results, coverage, requirements, metadata, outDir)
%GENERATEWORDREPORT Produce a MIL-STD-498 / IEEE 829 Software Test Report
%as a Microsoft Word .docx using MATLAB Report Generator (mlreportgen.dom).
%
%   This is the editable counterpart of generateHTMLReport. The same
%   section structure is used so the two outputs are 1:1 substitutable
%   for inclusion in a CDRL submission. The Word artifact is preferred
%   when reviewer markup is required during a Test Readiness Review (TRR);
%   the HTML artifact is preferred for archival and CI publication.
%
%   Errors with a clear message if MATLAB Report Generator is not licensed.

    arguments
        info        (1,1) struct
        results
        coverage    (1,1) struct
        requirements
        metadata    (1,1) struct
        outDir      (1,1) string
    end

    if ~license('test', 'MATLAB_Report_Gen')
        error("stg:generateWordReport:Unlicensed", ...
            "MATLAB Report Generator is required to produce Word output.");
    end

    if ~isfolder(outDir)
        mkdir(outDir);
    end

    summary    = stg.summarizeResults(results);
    methodMeta = stg.parseTestMethods(metadata.TestFile);
    enriched   = stg.html.joinResults(results, methodMeta);

    [~, srcName] = fileparts(metadata.SourceName);
    reportPath = char(fullfile(outDir, "STR_" + string(srcName) + ".docx"));

    import mlreportgen.dom.*

    doc = Document(reportPath, 'docx');
    doc.StreamOutput = false;
    cleanup = onCleanup(@() safeClose(doc));

    stg.word.applyClassificationHeaders(doc, metadata);
    stg.word.appendCoverPage(doc, metadata, summary);
    stg.word.appendDocumentControl(doc, metadata);
    stg.word.appendTableOfContents(doc);
    stg.word.appendSectionScope(doc, info, metadata);
    stg.word.appendSectionReferences(doc);
    stg.word.appendSectionOverview(doc, summary, coverage, metadata);
    stg.word.appendSectionDetailedResults(doc, enriched);
    stg.word.appendSectionTestLog(doc, metadata);
    stg.word.appendSectionCoverage(doc, coverage);
    stg.word.appendSectionConfigItems(doc, info, metadata);
    stg.word.appendSectionTraceability(doc, enriched, requirements);
    stg.word.appendSectionNotes(doc);
    stg.word.appendSectionApprovals(doc, metadata);

    close(doc);
    cleanup = []; %#ok<NASGU>  % already closed cleanly

    reportPath = char(stg.absPath(string(reportPath)));
end

function safeClose(doc)
    try
        if isvalid(doc)
            close(doc);
        end
    catch
    end
end
