function printIssues(check, remaining, stale, root)
%PRINTISSUES Print remaining issues and stale baseline entries, one per line.
arguments
    check (1,1) string
    remaining (:,1) struct
    stale (:,1) string
    root (1,1) string
end
for k = 1:numel(remaining)
    fprintf("%s\n", verify.formatIssue(remaining(k)));
end
baseline = verify.relPath(verify.baselineFile(check, root));
for k = 1:numel(stale)
    fprintf("%s:0:0: error: [%s/baseline] Stale entry, the issue is fixed: ""%s"". " + ...
            "Run 'just update-baselines' to remove it.\n", baseline, check, stale(k));
end
end
