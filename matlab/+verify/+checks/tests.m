function issues = tests(files, cfg)
%TESTS Run fast tests that cover FILES; JUnit XML goes to the report dir.
%   Runs a selected file that is itself a test, plus tests whose direct
%   requirements intersect FILES (see verify.dependentTests). The tag filter
%   is cfg.tests.tag. testsuite + TestRunner (equivalent to
%   runtests(..., Tag=tag)) keeps the JUnit plugin and a clean console.
arguments
    files (:,1) string
    cfg (1,1) struct
end
arguments (Output)
    issues (:,1) struct
end
issues = verify.emptyIssues();
testFiles = verify.dependentTests(files);
if isempty(testFiles)
    fprintf("tests: ran (none)\n");
    return
end
verify.addSourcePaths(testFiles);
suite = testsuite(cellstr(arrayfun(@verify.absPath, testFiles)), "Tag", cfg.tests.tag);
if isempty(suite)
    fprintf("tests: ran (none)\n");
    return
end
junit = string(fullfile(cfg.reportDir, "junit.xml"));
runner = matlab.unittest.TestRunner.withNoPlugins;
runner.addPlugin(matlab.unittest.plugins.XMLPlugin.producingJUnitFormat(junit));
runner.addPlugin(matlab.unittest.plugins.DiagnosticsRecordingPlugin);
results = runner.run(suite);
fprintf("tests: ran %s\n", strjoin(string({results.Name}), " "));
for k = find([results.Failed])
    [file, lineNo, detail] = failureDetail(results(k), testFiles);
    msg = "Test '" + results(k).Name + "' failed: " + detail + ...
        " Fix the code under test or the test; details in " + verify.relPath(junit) + ".";
    issues(end + 1, 1) = verify.issue(file, [lineNo 1], "error", "tests", "failed", msg); %#ok<AGROW>
end
end

function [file, lineNo, detail] = failureDetail(result, testFiles)
arguments
    result (1,1) matlab.unittest.TestResult
    testFiles (:,1) string
end
arguments (Output)
    file (1,1) string
    lineNo (1,1) double
    detail (1,1) string
end
className = extractBefore(string(result.Name), "/");
match = testFiles(endsWith(testFiles, "/" + className + ".m") | testFiles == className + ".m");
file = className + ".m";
if ~isempty(match)
    file = match(1);
end
lineNo = 0;
detail = "";
records = result.Details.DiagnosticRecord;
if isempty(records)
    return
end
record = records(1);
stack = record.Stack;
for s = 1:numel(stack)
    if endsWith(string(stack(s).file), className + ".m")
        lineNo = stack(s).line;
        break
    end
end
texts = string([{record.FrameworkDiagnosticResults.DiagnosticText}, ...
                {record.TestDiagnosticResults.DiagnosticText}, {record.Report}]);
texts = texts(strip(texts) ~= "");
if ~isempty(texts)
    detail = strip(regexprep(regexprep(texts(1), "_{3,}", ""), "\s+", " "));
    detail = extractBefore(detail + " ", min(strlength(detail), 240) + 1);
end
end
