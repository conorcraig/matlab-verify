function issues = runCheck(name, files, cfg)
%RUNCHECK Call verify.checks.<name>(files, cfg) and normalise its output.
%   A check that throws becomes one error issue so the run still reports
%   every other check.
arguments
    name (1,1) string
    files (:,1) string
    cfg (1,1) struct
end
arguments (Output)
    issues (:,1) struct
end
try
    raw = feval("verify.checks." + name, files, cfg);
catch err
    raw = verify.issue("matlab/+verify/+checks/" + name + ".m", [0 0], "error", name, "crashed", ...
                       "Check threw " + string(err.identifier) + ": " + string(err.message) + ...
                       " Fix the check or the input that triggers it.");
end
issues = verify.emptyIssues();
for k = 1:numel(raw)
    one = raw(k);
    position = [double(one.line) double(one.column)];
    severity = lower(string(one.severity));
    message = strjoin(strip(splitlines(string(one.message))), " ");
    issues(end + 1, 1) = verify.issue(verify.relPath(string(one.file)), position, severity, name, ...
                                      string(one.id), message); %#ok<AGROW>
end
end
