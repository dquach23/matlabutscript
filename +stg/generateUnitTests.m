function testFile = generateUnitTests(info, outDir, requirements)
%GENERATEUNITTESTS Emit a matlab.unittest.TestCase class for INFO.
%
%   TESTFILE = STG.GENERATEUNITTESTS(INFO, OUTDIR, REQUIREMENTS) writes a
%   test class file inside OUTDIR and returns the absolute path. The
%   generated class follows the naming convention test<SourceName>.m and
%   contains:
%
%       * a TestClassSetup that adds the source-under-test folder to MATLAB
%         path so qualified calls resolve correctly
%       * a per-method header comment block holding a unique Test Case ID,
%         description, traced requirement (if available), category,
%         expected pass criteria and an "Auto-Generated" classification
%       * smoke / instantiation / type-shape verification calls using the
%         standard verifyWarningFree, verifyClass, verifyEqual, etc.
%
%   For .mlapp files the test class also installs an onCleanup that deletes
%   any UI figures created during a test, ensuring no graphics handles leak
%   between runs.
%
%   The TESTFILE is intentionally written so it can be edited by hand after
%   generation; the comment block records its provenance.

    arguments
        info        (1,1) struct
        outDir      (1,1) string
        requirements (:,1) struct = repmat(struct("Id","","Description","","Verification","Test"),0,1)
    end

    if ~isfolder(outDir)
        mkdir(outDir);
    end

    baseName  = sanitizeName(info.Name);
    className = "test" + baseName;
    testFile  = fullfile(outDir, className + ".m");

    cases = buildTestCases(info, requirements);

    text = renderClass(className, info, cases);

    fid = fopen(char(testFile), 'w');
    if fid < 0
        error("stg:generateUnitTests:WriteFailed", ...
            "Could not write test file '%s'.", testFile);
    end
    cleanup = onCleanup(@() fclose(fid));
    fwrite(fid, text);

    testFile = char(stg.absPath(testFile));
end

% =========================================================================
function name = sanitizeName(name)
    name = string(name);
    if name == ""
        name = "Unnamed";
    end
    name = regexprep(name, "[^A-Za-z0-9_]", "_");
    if ~isempty(regexp(extractBefore(name,2), "[0-9]", 'once'))
        name = "x" + name;
    end
end

% =========================================================================
function cases = buildTestCases(info, requirements)
%BUILDTESTCASES Plan all test methods up front so the report can be aligned.
    cases = struct("Id", {}, "MethodName", {}, "Body", {}, ...
        "Description", {}, "Category", {}, "Requirement", {}, ...
        "ExpectedResult", {}, "Target", {});
    counter = 0;
    nextId = @() sprintf("TC-%03d", counter+1);

    function append(c)
        cases(end+1) = c; %#ok<AGROW>
    end

    switch info.Kind
        case "script"
            counter = counter + 1;
            append(scriptCase(nextId(), info));
        case "function"
            for k = 1:numel(info.Functions)
                f = info.Functions(k);
                if f.IsLocal
                    continue   % cannot be invoked from outside the file
                end
                counter = counter + 1;
                c = functionCase(nextId(), f, info);
                append(c);
            end
        case "class"
            % Constructor smoke
            counter = counter + 1;
            append(constructorCase(nextId(), info));

            % Public, non-abstract methods
            for k = 1:numel(info.Functions)
                m = info.Functions(k);
                if isMethodTestable(m, info)
                    counter = counter + 1;
                    append(methodCase(nextId(), m, info));
                end
            end
        case "app"
            counter = counter + 1;
            append(appLaunchCase(nextId(), info));
            % Public callbacks / methods (best-effort)
            for k = 1:numel(info.Functions)
                m = info.Functions(k);
                if isMethodTestable(m, info) && ~strcmp(m.Name, info.Class.Name)
                    counter = counter + 1;
                    append(methodCase(nextId(), m, info));
                end
            end
    end

    % Attach traceable requirements round-robin if provided.
    for k = 1:numel(cases)
        if ~isempty(requirements)
            r = requirements(mod(k-1, numel(requirements))+1);
            cases(k).Requirement = string(r.Id);
        end
    end
end

function tf = isMethodTestable(m, info)
    tf = ~m.IsAbstract && ...
        any(strcmpi(m.Access, ["public" ""])) && ...
        ~strcmp(m.Name, info.Class.Name);
end

% =========================================================================
function c = scriptCase(id, info)
    body = sprintf([ ...
        "            %% %s : Run script and verify it completes without error.\n" ...
        "            scriptName = ""%s"";\n" ...
        "            testCase.verifyWarningFree(@() evalin('base', scriptName), ...\n" ...
        "                ""Script must execute to completion without errors."");\n"], ...
        id, info.Name);
    c = struct( ...
        "Id",             id, ...
        "MethodName",     "tc_" + lower(replace(id,"-","_")) + "_run_script", ...
        "Body",           body, ...
        "Description",    "Execute the script and verify normal termination.", ...
        "Category",       "Smoke", ...
        "Requirement",    "", ...
        "ExpectedResult", "Script runs without errors or warnings.", ...
        "Target",         info.Name);
end

% =========================================================================
function c = functionCase(id, f, ~)
    [argList, prelude] = buildArgList(f.Inputs);
    nout = max(1, numel(f.Outputs));
    if numel(f.Outputs) == 0
        callExpr = sprintf("%s(%s)", f.Name, argList);
        verify = sprintf([ ...
            "            testCase.verifyWarningFree(@() %s, ...\n" ...
            "                ""Function must run without errors or warnings."");\n"], ...
            callExpr);
    else
        outNames = arrayfun(@(i) sprintf("out%d", i), 1:nout, 'UniformOutput', false);
        outAssign = strjoin(outNames, ", ");
        if nout > 1
            outAssign = "[" + outAssign + "]";
        end
        callExpr = sprintf("%s(%s)", f.Name, argList);
        verify = sprintf([ ...
            "            actualFcn = @() captureOutputs(@() %s, %d);\n" ...
            "            outs = testCase.verifyWarningFree(actualFcn, ...\n" ...
            "                ""Function must run without errors."");\n" ...
            "            testCase.verifyNumElements(outs, %d, ...\n" ...
            "                ""Function must return %d output(s)."");\n" ...
            "            for kOut = 1:numel(outs)\n" ...
            "                testCase.verifyNotEmpty(outs{kOut}, sprintf('Output %%d should not be empty', kOut));\n" ...
            "            end\n"], ...
            callExpr, nout, nout, nout);
    end

    body = prelude + verify;
    descr = ifelse(f.Description == "", ...
        sprintf("Smoke test of '%s'.", f.Name), ...
        sprintf("%s", f.Description));

    c = struct( ...
        "Id",             id, ...
        "MethodName",     "tc_" + lower(replace(id,"-","_")) + "_" + sanitizeMethodName(f.Name), ...
        "Body",           body, ...
        "Description",    descr, ...
        "Category",       "Functional / Smoke", ...
        "Requirement",    "", ...
        "ExpectedResult", "Function returns without raising errors or warnings; outputs are non-empty.", ...
        "Target",         f.Name);
end

% =========================================================================
function c = constructorCase(id, info)
    cls = info.Class;
    [argList, prelude] = buildArgList(cls.ConstructorInputs);
    body = sprintf([ ...
        "%s" ...
        "            ctor = @() %s(%s);\n" ...
        "            obj = testCase.verifyWarningFree(ctor, ...\n" ...
        "                ""Constructor must run without errors or warnings."");\n" ...
        "            testCase.verifyClass(obj, ""%s"", ...\n" ...
        "                ""Constructor must return an instance of the class."");\n" ...
        "            testCase.addTeardown(@() safeDelete(obj));\n"], ...
        prelude, cls.Name, argList, cls.Name);

    c = struct( ...
        "Id",             id, ...
        "MethodName",     "tc_" + lower(replace(id,"-","_")) + "_construct_" + sanitizeMethodName(cls.Name), ...
        "Body",           body, ...
        "Description",    sprintf("Construct an instance of '%s' using inferred default arguments.", cls.Name), ...
        "Category",       "Constructor / Smoke", ...
        "Requirement",    "", ...
        "ExpectedResult", "Object is created and is of the expected class.", ...
        "Target",         cls.Name);
end

% =========================================================================
function c = methodCase(id, m, info)
    cls = info.Class;
    if m.IsStatic
        [argList, prelude] = buildArgList(m.Inputs);
        callPrefix = sprintf("%s.%s", cls.Name, m.Name);
        instanceLines = "";
    else
        % Drop the first input (obj/self) and build from the rest.
        if isempty(m.Inputs)
            extraArgs = strings(0,1);
        else
            extraArgs = m.Inputs(2:end);
        end
        [argList, prelude] = buildArgList(extraArgs);
        [ctorArgs, ctorPre] = buildArgList(cls.ConstructorInputs);
        instanceLines = sprintf([ ...
            "%s" ...
            "            obj = %s(%s);\n" ...
            "            testCase.addTeardown(@() safeDelete(obj));\n"], ...
            ctorPre, cls.Name, ctorArgs);
        callPrefix = sprintf("obj.%s", m.Name);
    end

    nout = numel(m.Outputs);
    if nout == 0
        callExpr = sprintf("%s(%s)", callPrefix, argList);
        verify = sprintf([ ...
            "            testCase.verifyWarningFree(@() %s, ...\n" ...
            "                ""Method must run without errors or warnings."");\n"], ...
            callExpr);
    else
        callExpr = sprintf("%s(%s)", callPrefix, argList);
        verify = sprintf([ ...
            "            outs = testCase.verifyWarningFree(@() captureOutputs(@() %s, %d), ...\n" ...
            "                ""Method must run without errors."");\n" ...
            "            testCase.verifyNumElements(outs, %d);\n"], ...
            callExpr, max(nout,1), max(nout,1));
    end

    body = instanceLines + prelude + verify;
    descr = ifelse(m.Description == "", ...
        sprintf("Smoke test of method '%s.%s'.", cls.Name, m.Name), ...
        m.Description);

    c = struct( ...
        "Id",             id, ...
        "MethodName",     "tc_" + lower(replace(id,"-","_")) + "_" + sanitizeMethodName(m.Name), ...
        "Body",           body, ...
        "Description",    descr, ...
        "Category",       ifelse(m.IsStatic, "Static Method / Smoke", "Method / Smoke"), ...
        "Requirement",    "", ...
        "ExpectedResult", "Method returns without errors or warnings.", ...
        "Target",         sprintf("%s.%s", cls.Name, m.Name));
end

% =========================================================================
function c = appLaunchCase(id, info)
    body = sprintf([ ...
        "            ctor = @() %s();\n" ...
        "            app = testCase.verifyWarningFree(ctor, ...\n" ...
        "                ""App must launch without errors or warnings."");\n" ...
        "            testCase.addTeardown(@() safeDelete(app));\n" ...
        "            testCase.verifyClass(app, ""%s"");\n" ...
        "            %% Verify a UIFigure was created and is valid.\n" ...
        "            figProp = findUIFigureProperty(app);\n" ...
        "            if figProp ~= """"\n" ...
        "                testCase.verifyTrue(isgraphics(app.(figProp)), ...\n" ...
        "                    ""App should construct a valid UIFigure."");\n" ...
        "            end\n"], ...
        info.Class.Name, info.Class.Name);

    c = struct( ...
        "Id",             id, ...
        "MethodName",     "tc_" + lower(replace(id,"-","_")) + "_launch_" + sanitizeMethodName(info.Class.Name), ...
        "Body",           body, ...
        "Description",    sprintf("Instantiate the App Designer app '%s' and verify the UIFigure is created.", info.Class.Name), ...
        "Category",       "App Launch / Smoke", ...
        "Requirement",    "", ...
        "ExpectedResult", "App launches and a valid UIFigure handle is created.", ...
        "Target",         info.Class.Name);
end

% =========================================================================
function [argList, prelude] = buildArgList(inputs)
    inputs = string(inputs);
    if isempty(inputs)
        argList = "";
        prelude = "";
        return
    end

    pre  = strings(0,1);
    args = strings(0,1);
    for k = 1:numel(inputs)
        nm = strtrim(inputs(k));
        if nm == "varargin" || nm == "~"
            continue
        end
        expr = stg.inferTestInput(nm);
        if expr == ""
            continue
        end
        varName = sprintf("arg_%s", regexprep(nm, "[^A-Za-z0-9_]", "_"));
        pre(end+1,1) = sprintf("            %s = %s;\n", varName, expr); %#ok<AGROW>
        args(end+1,1) = string(varName); %#ok<AGROW>
    end
    argList = strjoin(args, ", ");
    prelude = strjoin(pre, "");
end

function n = sanitizeMethodName(n)
    n = string(n);
    n = regexprep(n, "[^A-Za-z0-9_]", "_");
end

function out = ifelse(cond, a, b)
    if cond, out = a; else, out = b; end
end

% =========================================================================
function txt = renderClass(className, info, cases)
    nl = newline;
    parts = strings(0,1);
    parts(end+1) = "classdef " + className + " < matlab.unittest.TestCase";
    parts(end+1) = "    %" + upper(className) + " Auto-generated test class for " + info.Name;
    parts(end+1) = "    %";
    parts(end+1) = "    % Source under test : " + string(info.FilePath);
    parts(end+1) = "    % Source kind       : " + string(info.Kind);
    parts(end+1) = "    % Source SHA-256    : " + string(info.Hash);
    parts(end+1) = "    % Generated         : " + string(datetime("now","Format","yyyy-MM-dd HH:mm:ss"));
    parts(end+1) = "    % Generator         : matlabutscript / stg.generateUnitTests";
    parts(end+1) = "    % Standards         : MIL-STD-498, IEEE 829, AFI 63-101/20-101";
    parts(end+1) = "    %";
    parts(end+1) = "    % All test cases below were synthesized from a static analysis of";
    parts(end+1) = "    % the source under test. They are smoke / structural tests intended";
    parts(end+1) = "    % to detect regressions in callability and basic output shape.";
    parts(end+1) = "    % Requirements-based test cases must be added by the responsible";
    parts(end+1) = "    % test engineer in accordance with the project Software Test Plan.";
    parts(end+1) = "";
    parts(end+1) = "    properties (Constant)";
    parts(end+1) = "        SourceUnderTest = """ + string(info.FilePath) + """;";
    parts(end+1) = "        SourceHash      = """ + string(info.Hash) + """;";
    parts(end+1) = "    end";
    parts(end+1) = "";
    parts(end+1) = "    methods (TestClassSetup)";
    parts(end+1) = "        function addSourcePath(testCase)";
    parts(end+1) = "            srcDir = fileparts(testCase.SourceUnderTest);";
    parts(end+1) = "            if ~isempty(srcDir) && exist(srcDir, 'dir')";
    parts(end+1) = "                addpath(srcDir);";
    parts(end+1) = "                testCase.addTeardown(@() rmpath(srcDir));";
    parts(end+1) = "            end";
    parts(end+1) = "        end";
    parts(end+1) = "    end";
    parts(end+1) = "";
    parts(end+1) = "    methods (TestMethodTeardown)";
    parts(end+1) = "        function closeAnyFigures(~)";
    parts(end+1) = "            try";
    parts(end+1) = "                figs = findall(groot, 'Type', 'figure');";
    parts(end+1) = "                if ~isempty(figs)";
    parts(end+1) = "                    delete(figs);";
    parts(end+1) = "                end";
    parts(end+1) = "            catch";
    parts(end+1) = "            end";
    parts(end+1) = "        end";
    parts(end+1) = "    end";
    parts(end+1) = "";
    parts(end+1) = "    methods (Test)";

    for k = 1:numel(cases)
        c = cases(k);
        parts(end+1) = ""; %#ok<AGROW>
        parts(end+1) = "        function " + c.MethodName + "(testCase)"; %#ok<AGROW>
        parts(end+1) = "            % " + c.Id + " | Category: " + c.Category; %#ok<AGROW>
        parts(end+1) = "            % Target       : " + c.Target; %#ok<AGROW>
        parts(end+1) = "            % Description  : " + c.Description; %#ok<AGROW>
        parts(end+1) = "            % Expected     : " + c.ExpectedResult; %#ok<AGROW>
        if strlength(c.Requirement) > 0
            parts(end+1) = "            % Requirement  : " + c.Requirement; %#ok<AGROW>
        end
        parts(end+1) = "            % Pass criteria: All verifyXxx assertions succeed."; %#ok<AGROW>
        parts(end+1) = ""; %#ok<AGROW>
        parts(end+1) = string(c.Body); %#ok<AGROW>
        parts(end+1) = "        end"; %#ok<AGROW>
    end

    parts(end+1) = "    end";
    parts(end+1) = "";
    parts(end+1) = "    methods (Static, Access = private)";
    parts(end+1) = "        % (Helper functions live as local functions below the classdef.)";
    parts(end+1) = "    end";
    parts(end+1) = "end";
    parts(end+1) = "";
    parts(end+1) = "% ===== Local helper functions =============================================";
    parts(end+1) = "function outs = captureOutputs(callable, nout)";
    parts(end+1) = "    if nargin < 2 || nout < 1, nout = 1; end";
    parts(end+1) = "    outs = cell(1, nout);";
    parts(end+1) = "    [outs{:}] = callable();";
    parts(end+1) = "end";
    parts(end+1) = "";
    parts(end+1) = "function safeDelete(obj)";
    parts(end+1) = "    try";
    parts(end+1) = "        if isvalid(obj)";
    parts(end+1) = "            delete(obj);";
    parts(end+1) = "        end";
    parts(end+1) = "    catch";
    parts(end+1) = "    end";
    parts(end+1) = "end";
    parts(end+1) = "";
    parts(end+1) = "function name = findUIFigureProperty(app)";
    parts(end+1) = "    name = """";";
    parts(end+1) = "    try";
    parts(end+1) = "        m = metaclass(app);";
    parts(end+1) = "        for p = m.PropertyList'";
    parts(end+1) = "            try";
    parts(end+1) = "                v = app.(p.Name);";
    parts(end+1) = "                if isgraphics(v) && strcmp(get(v,'Type'),'figure')";
    parts(end+1) = "                    name = p.Name;";
    parts(end+1) = "                    return";
    parts(end+1) = "                end";
    parts(end+1) = "            catch";
    parts(end+1) = "            end";
    parts(end+1) = "        end";
    parts(end+1) = "    catch";
    parts(end+1) = "    end";
    parts(end+1) = "end";

    txt = strjoin(parts, nl);
    if ~endsWith(txt, nl)
        txt = txt + nl;
    end
end
