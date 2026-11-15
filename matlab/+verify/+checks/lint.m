function issues = lint(files, cfg)
%LINT Code Analyzer warnings plus size limits (R2024a configurable subset).
%   Limits come from cfg.lint: FCNLL function lines, MNCSN nesting depth,
%   LLMNC line length, FCNIL inputs, FCNOL outputs. Other error-severity
%   findings are syntax errors and are left to the parse check.
arguments
    files (:,1) string
    cfg (1,1) struct
end
arguments (Output)
    issues (:,1) struct
end
lintSettings = cfg.lint;
limits = struct();
limits.FCNLL = struct("limit", lintSettings.maxFunctionLines, "hint", "Split the function into smaller helpers.");
limits.MNCSN = struct("limit", lintSettings.maxNesting, "hint", "Reduce nesting with early returns or a helper.");
limits.LLMNC = struct("limit", lintSettings.maxLineLength, "hint", "Wrap the line with ... continuation.");
limits.FCNIL = struct("limit", lintSettings.maxInputs, "hint", "Group related inputs into a struct or options.");
limits.FCNOL = struct("limit", lintSettings.maxOutputs, "hint", "Return a struct instead of many outputs.");
limitIds = string(fieldnames(limits));
checks = struct();
for id = limitIds'
    checks.(id) = struct("severity", "error", "limit", limits.(id).limit, "enabled", true);
end
config = struct("name", "matlab-verify lint", "baseConfiguration", "factory", "checks", checks);
configFile = string(fullfile(cfg.reportDir, "lint.codeAnalyzerConfiguration.json"));
writelines(jsonencode(config, PrettyPrint = true), configFile);

issues = verify.codeAnalyzer(files, configFile, "lint", @(id, ~) lintHint(id, limits));
if ~isempty(issues)
    issues = issues([issues.severity] == "warning" | ismember([issues.id], limitIds'));
end
end

function hint = lintHint(id, limits)
arguments
    id (1,1) string
    limits (1,1) struct
end
arguments (Output)
    hint (1,1) string
end
if isfield(limits, id)
    hint = sprintf("(limit %d) %s", limits.(id).limit, limits.(id).hint);
else
    hint = "Fix the code, or if intended suppress it on that line with %#ok<" + id + "> and a comment why.";
end
end
