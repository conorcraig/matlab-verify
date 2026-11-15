function [issues, stats] = types(files, cfg)
%TYPES Static class/size checker driven by arguments blocks (check name "types").
%   1. Policy: every function declares class and size for each input in an
%      arguments block, and for each output in an arguments (Output) block
%      (opt out with %#verify:no-arguments on the function line).
%   2. Call sites: a class-and-size dataflow inside each function, seeded
%      from its arguments block, checks calls to functions in the checked
%      files and a starter table of builtins: wrong class, size or rank,
%      too many inputs, missing required inputs, unknown name-value names,
%      and declared outputs the body cannot produce.
%   Calls that cannot be resolved (unknown functions, methods, function
%   handles, feval/eval/cellfun/arrayfun) are counted as unchecked and
%   printed in a summary line; they never fail the check.
%   cfg.types.summary (default true) controls the summary line. The second
%   output has the counts: checked, unchecked, unparseable.
arguments (Input)
    files (:,1) string
    cfg (1,1) struct
end
arguments (Output)
    issues (:,1) struct
    stats (1,1) struct
end
units = verify.types.loadUnits(files);
[shared, locals] = verify.types.signatureTable(units);
issues = repmat(verify.issue(""), 0, 1);
stats = struct("checked", 0, "unchecked", 0, "unparseable", 0);
for k = 1:numel(units)
    if ~units(k).ok
        continue
    end
    ctx = struct("file", units(k).file, "local", locals{k}, "global", shared, ...
        "builtins", verify.types.builtinRules());
    [found, stats] = checkUnit(units(k), ctx, stats);
    issues = [issues; found]; %#ok<AGROW>
end
if showSummary(cfg)
    fprintf("types: %d call site(s) checked, %d unchecked (unresolved callee or known gap), " + ...
        "%d unparseable declaration(s)\n", stats.checked, stats.unchecked, stats.unparseable);
end
end

function [issues, stats] = checkUnit(u, ctx, stats)
arguments (Input)
    u (1,1) struct
    ctx (1,1) struct
    stats (1,1) struct
end
arguments (Output)
    issues (:,1) struct
    stats (1,1) struct
end
issues = repmat(verify.issue(""), 0, 1);
for jj = 1:numel(u.info)
    sig = u.sigs{jj};
    issues = [issues; verify.types.policy(u.info(jj), sig, u.file)]; %#ok<AGROW>
    state = verify.types.analyzeFunction(u.info(jj), sig, ctx);
    issues = [issues; state.issues]; %#ok<AGROW>
    stats.checked = stats.checked + state.checked;
    stats.unchecked = stats.unchecked + state.unchecked;
    stats.unparseable = stats.unparseable + sig.unparseable;
end
end

function tf = showSummary(cfg)
arguments (Input)
    cfg (1,1) struct
end
arguments (Output)
    tf (1,1) logical
end
tf = true;
if isfield(cfg, "types") && isfield(cfg.types, "summary")
    tf = logical(cfg.types.summary);
end
end
