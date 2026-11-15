function [remaining, stale, nAccepted] = applyBaseline(check, issues, root, mode)
%APPLYBASELINE Split issues into accepted-by-baseline and remaining.
%   Baseline lines are "file: severity: [check/id] message" (no line or
%   column), sorted. Matching is a multiset: each line accepts one issue.
%   Baseline lines with no matching issue are returned as STALE.
%   In "update" mode stale lines are removed from the file; new issues are
%   never added (they stay in REMAINING).
arguments
    check (1,1) string
    issues (:,1) struct
    root (1,1) string
    mode (1,1) string = "check"
end
arguments (Output)
    remaining (:,1) struct
    stale (:,1) string
    nAccepted (1,1) double
end
file = verify.baselineFile(check, root);
base = strings(0, 1);
if isfile(file)
    base = strip(splitlines(string(fileread(file))));
    base = base(base ~= "");
end
keep = true(size(issues));
used = false(size(base));
for k = 1:numel(issues)
    hit = find(base == verify.baselineKey(issues(k)) & ~used, 1);
    if ~isempty(hit)
        used(hit) = true;
        keep(k) = false;
    end
end
remaining = issues(keep);
stale = base(~used);
nAccepted = nnz(used);
if mode == "update" && ~isempty(stale)
    kept = sort(base(used));
    writelines(kept, file);
    fprintf("baseline %s: removed %d fixed entries, %d remain\n", verify.relPath(file), numel(stale), numel(kept));
    stale = strings(0, 1);
end
if mode == "update" && ~isempty(remaining)
    fprintf("baseline %s: refusing to add %d new issue(s); fix them instead\n", ...
        verify.relPath(file), numel(remaining));
end
end
