function issues = codeAnalyzer(files, configuration, check, hint)
%CODEANALYZER Run codeIssues one file at a time and convert to contract issues.
%   CONFIGURATION is "factory" or a configuration file path. HINT is a
%   function (checkId, description) -> fix advice appended to the message.
%   Info-level findings are dropped.
arguments
    files (:,1) string
    configuration (1,1) string
    check (1,1) string
    hint (1,1) function_handle = @(~, ~) ""
end
arguments (Output)
    issues (:,1) struct
end
issues = verify.emptyIssues();
for f = files'
    result = codeIssues(verify.absPath(f), CodeAnalyzerConfiguration=configuration);
    found = result.Issues;
    for k = 1:height(found)
        severity = string(found.Severity(k));
        if severity == "info"
            continue
        end
        id = string(found.CheckID(k));
        message = strip(string(found.Description(k)) + " " + hint(id, string(found.Description(k))));
        issues(end + 1, 1) = verify.issue(f, [found.LineStart(k) found.ColumnStart(k)], ...
            severity, check, id, message); %#ok<AGROW>
    end
end
end
