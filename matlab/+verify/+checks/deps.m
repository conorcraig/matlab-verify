function issues = deps(files, cfg)
%DEPS Dependency rules: no cycles, no unresolved calls, allowed products only.
%   Edges come from matlab.codetools.requiredFilesAndProducts(file, 'toponly').
%   Unresolved calls are plain calls (mtree CALL nodes) that are neither
%   defined in any checked file nor found on the path. Files with syntax
%   errors are skipped; the parse check reports them.
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
    filePath = char(verify.absPath(files(k)));
    try
        [required, products] = matlab.codetools.requiredFilesAndProducts(filePath, "toponly");
    catch err
        if err.identifier == "MATLAB:depfun:req:BadSyntax"
            continue
        end
        rethrow(err);
    end
    [isLocal, target] = ismember(lower(string(required)), absFiles);
    target = target(isLocal & target ~= k);
    edges = [edges; repmat(k, numel(target), 1), target(:)]; %#ok<AGROW>
    for name = reshape(setdiff(string({products.Name}), allowed), 1, [])
        msg = "Requires '" + name + "', which is not in deps.allowedProducts (" + strjoin(allowed, ", ") + ...
            "). Use base MATLAB functions instead, or add the product to config/verify.json.";
        issues(end + 1, 1) = verify.issue(files(k), [1 1], "error", "deps", "product", msg); %#ok<AGROW>
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
depGraph = digraph(edges(:, 1), edges(:, 2), [], numel(files));
bins = conncomp(depGraph);
for b = unique(bins)
    members = find(bins == b);
    if numel(members) < 2
        continue
    end
    loop = strjoin(files(members), " -> ") + " -> " + files(members(1));
    msg = "File is in a dependency cycle (" + loop + "). Break it by moving the shared code " + ...
        "into a separate function that both files call.";
    for m = members
        issues(end + 1, 1) = verify.issue(files(m), [1 1], "error", "deps", "cycle", msg); %#ok<AGROW>
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
    lineNos = lineno(calls);
    cols = charno(calls);
    for c = 1:numel(names)
        if ~ismember(names(c), defined) && isempty(which(names(c), "-all"))
            msg = "Call to '" + names(c) + "' does not resolve to any function on the path or in the " + ...
                "checked files. Fix the name, add the defining file, or add its folder to the path.";
            issues(end + 1, 1) = verify.issue(files(k), [lineNos(c) cols(c)], "error", "deps", "unresolved", ...
                                              msg); %#ok<AGROW>
        end
    end
end
end
