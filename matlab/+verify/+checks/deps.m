function issues = deps(files, cfg)
%DEPS Dependency rules: no cycles, no unresolved calls, allowed products only.
%   Edges come from matlab.codetools.requiredFilesAndProducts(file, 'toponly').
%   Unresolved calls are plain calls (mtree CALL nodes) that are neither
%   defined in any checked file nor found on the path.
arguments
    files (:,1) string
    cfg (1,1) struct
end
arguments (Output)
    issues (:,1) struct
end
allowed = string(cfg.deps.allowedProducts);
absFiles = lower(arrayfun(@verify.absPath, files));
edges = zeros(0, 2);
issues = verify.emptyIssues();
for k = 1:numel(files)
    [required, products] = matlab.codetools.requiredFilesAndProducts(char(verify.absPath(files(k))), "toponly");
    [isLocal, target] = ismember(lower(string(required)), absFiles);
    target = target(isLocal & target ~= k);
    edges = [edges; repmat(k, numel(target), 1), target(:)]; %#ok<AGROW>
    for name = reshape(setdiff(string({products.Name}), allowed), 1, [])
        issues(end + 1, 1) = verify.issue(files(k), 1, 1, "error", "deps", "product", ...
            sprintf("Requires '%s', which is not in deps.allowedProducts (%s). " + ...
            "Use base MATLAB functions instead, or add the product to config/verify.json.", ...
            name, strjoin(allowed, ", "))); %#ok<AGROW>
    end
end
issues = [issues; cycleIssues(files, edges); unresolvedIssues(files)];
end

function issues = cycleIssues(files, edges)
arguments
    files (:,1) string
    edges (:,2) double
end
arguments (Output)
    issues (:,1) struct
end
issues = verify.emptyIssues();
graph = digraph(edges(:, 1), edges(:, 2), [], numel(files));
bins = conncomp(graph);
for b = unique(bins)
    members = find(bins == b);
    if numel(members) < 2
        continue
    end
    loop = strjoin(files(members), " -> ") + " -> " + files(members(1));
    for m = members
        issues(end + 1, 1) = verify.issue(files(m), 1, 1, "error", "deps", "cycle", ...
            "File is in a dependency cycle (" + loop + "). Break it by moving the shared code " + ...
            "into a separate function that both files call."); %#ok<AGROW>
    end
end
end

function issues = unresolvedIssues(files)
arguments
    files (:,1) string
end
arguments (Output)
    issues (:,1) struct
end
issues = verify.emptyIssues();
trees = cell(numel(files), 1);
defined = strings(0, 1);
for k = 1:numel(files)
    trees{k} = mtree(char(verify.absPath(files(k))), "-file");
    defined = [defined; string(strings(Fname(mtfind(trees{k}, "Kind", "FUNCTION"))))']; %#ok<AGROW>
end
for k = 1:numel(files)
    calls = Left(mtfind(trees{k}, "Kind", "CALL"));
    calls = mtfind(calls, "Kind", "ID");
    names = string(strings(calls));
    lines = lineno(calls);
    cols = charno(calls);
    for c = 1:numel(names)
        if ~ismember(names(c), defined) && ~ismember(exist(names(c)), [2 3 5 6 8]) %#ok<EXIST>
            issues(end + 1, 1) = verify.issue(files(k), lines(c), cols(c), "error", "deps", "unresolved", ...
                sprintf("Call to '%s' does not resolve to any function on the path or in the checked files. " + ...
                "Fix the name, add the defining file, or add its folder to the path.", names(c))); %#ok<AGROW>
        end
    end
end
end
