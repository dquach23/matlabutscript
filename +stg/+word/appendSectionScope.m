function appendSectionScope(doc, info, metadata)
%APPENDSECTIONSCOPE Section 1 (Scope) of the Word STR.

    import mlreportgen.dom.*

    append(doc, stg.word.heading("1. Scope", 2));

    append(doc, stg.word.heading("1.1 Identification", 3));
    p = Paragraph(sprintf( ...
        "This Software Test Report (STR), document %s, documents the verification activities " + ...
        "performed against the MATLAB software item %s belonging to project %s. " + ...
        "The report is issued by %s and is structured in accordance with the data preparation " + ...
        "instructions of DI-IPSC-81440A and the test reporting practices of IEEE Std 829.", ...
        metadata.DocumentId, metadata.SourceName, metadata.ProjectName, metadata.Organization));
    append(doc, p);

    append(doc, stg.word.heading("1.2 System Overview", 3));
    desc = string(info.Description);
    if desc == ""
        desc = "No documentation header was found in the source under test.";
    end
    append(doc, Paragraph(char(desc)));

    rows = [
        "Software Item Name", info.Name
        "Software Item Kind", info.Kind
        "Source File Type",   info.FileType
        "Absolute Path",      info.FilePath
        "Source SHA-256",     info.Hash
    ];
    append(doc, stg.word.keyValueTable(rows));

    append(doc, stg.word.heading("1.3 Document Overview", 3));
    append(doc, Paragraph(sprintf( ...
        "The remainder of this document records the test environment, the test cases " + ...
        "executed, their detailed pass/fail outcomes, the resulting code-coverage metrics " + ...
        "(when supported by the host MATLAB release), the configuration items under test, " + ...
        "the traceability of test cases to requirements, and the formal approval block.")));

    note = Paragraph(sprintf( ...
        "Limitation: The test cases described herein were synthesized automatically from " + ...
        "a static analysis of the software item. They constitute structural / smoke " + ...
        "verification of basic callability and output shape and do NOT supersede " + ...
        "requirements-based test cases that the responsible test engineer must develop in " + ...
        "accordance with the project's Software Test Plan."));
    note.Italic = true;
    append(doc, note);
end
