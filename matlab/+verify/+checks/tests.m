function issues = tests(files, cfg)
%TESTS Run class-based tests tagged cfg.tests.tag; JUnit XML to the report dir.
%   Test files are the checked files whose classdef derives from
%   matlab.unittest.TestCase. Uses testsuite + TestRunner (equivalent to
%   runtests(..., Tag=tag)) so the JUnit plugin can be attached and the
%   console output stays clean.
arguments
    files (:,1) string
    cfg (1,1) struct
end
arguments (Output)
    issues (:,1) struct
end
issues = verify.emptyIssues();
isTest = arrayfun(@(f) ~isempty(regexp(fileread(verify.absPath(f)), ...
    "^\s*classdef[^\n]*<\s*matlab\.unittest\.TestCase", "once", "lineanchors")), files);
testFiles = files(isTest);
if isempty(testFiles)
    return
end
suite = testsuite(cellstr(arrayfun(@verify.absPath, testFiles)), "Tag", cfg.tests.tag);
if isempty(suite)
    return
end
junit = string(fullfile(cfg.reportDir, "junit.xml"));
runner = matlab.unittest.TestRunner.withNoPlugins;
runner.addPlugin(matlab.unittest.plugins.XMLPlugin.producingJUnitFormat(junit));
runner.addPlugin(matlab.unittest.plugins.DiagnosticsRecordingPlugin);
results = runner.run(suite);
for k = find([results.Failed])
    [file, line, detail] = failureDetail(results(k), testFiles);
    issues(end + 1, 1) = verify.issue(file, [line 1], "error", "tests", "failed", ...
        sprintf("Test '%s' failed: %s Fix the code under test or the test; details in %s.", ...
        results(k).Name, detail, verify.relPath(junit))); %#ok<AGROW>
end
end

function [file, line, detail] = failureDetail(result, testFiles)
arguments
    result (1,1) matlab.unittest.TestResult
    testFiles (:,1) string
end
arguments (Output)
    file (1,1) string
    line (1,1) double
    detail (1,1) string
end
className = extractBefore(string(result.Name), "/");
match = testFiles(endsWith(testFiles, "/" + className + ".m") | testFiles == className + ".m");
file = className + ".m";
if ~isempty(match)
    file = match(1);
end
line = 0;
detail = "";
records = result.Details.DiagnosticRecord;
if isempty(records)
    return
end
record = records(1);
stack = record.Stack;
for s = 1:numel(stack)
    if endsWith(string(stack(s).file), className + ".m")
        line = stack(s).line;
        break
    end
end
texts = string([{record.FrameworkDiagnosticResults.DiagnosticText}, ...
    {record.TestDiagnosticResults.DiagnosticText}, {record.Report}]);
texts = texts(strip(texts) ~= "");
if ~isempty(texts)
    detail = strjoin(strip(splitlines(texts(1))), " ");
    detail = extractBefore(detail + " ", min(strlength(detail), 200) + 1);
end
end
