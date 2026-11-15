function issues = complexity(files, cfg)
%COMPLEXITY McCabe cyclomatic complexity per function via checkcode -cyc.
arguments
    files (:,1) string
    cfg (1,1) struct
end
arguments (Output)
    issues (:,1) struct
end
limit = cfg.complexity.max;
issues = verify.emptyIssues();
for f = files'
    info = checkcode(char(verify.absPath(f)), "-cyc", "-id");
    for k = 1:numel(info)
        if info(k).id ~= "CABE"
            continue
        end
        tok = regexp(info(k).message, "'([^']+)' is (\d+)", "tokens", "once");
        if isempty(tok) || str2double(tok{2}) <= limit
            continue
        end
        message = sprintf("Function '%s' has cyclomatic complexity %s (limit %d). " + ...
            "Split branches into helper functions or replace if/elseif chains with a lookup.", ...
            tok{1}, tok{2}, limit);
        issues(end + 1, 1) = verify.issue(f, [info(k).line info(k).column(1)], "error", ...
            "complexity", "CABE", message); %#ok<AGROW>
    end
end
end
