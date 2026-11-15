function issues = parse(files, cfg)
%PARSE Syntax errors, using codeIssues with the factory configuration.
arguments
    files (:,1) string
    cfg (1,1) struct %#ok<INUSA>
end
arguments (Output)
    issues (:,1) struct
end
advice = "Fix the syntax at this location; nothing else in the file can be checked until it parses.";
issues = verify.codeAnalyzer(files, "factory", "parse", @(~, ~) advice);
if ~isempty(issues)
    issues = issues([issues.severity] == "error");
end
end
