function [outs, state] = callType(name, argNodes, callNode, nout, state, ctx)
%CALLTYPE Check a call to NAME and return the abstract values of its outputs.
%   Resolution order: known gaps (unchecked), local functions of the file,
%   functions/classes in the checked file set, the builtin starter table;
%   anything else is counted as unchecked.
arguments (Input)
    name (1,1) string
    argNodes (1,:) cell
    callNode (1,1) mtree
    nout (1,1) double
    state (1,1) struct
    ctx (1,1) struct
end
arguments (Output)
    outs (1,:) cell
    state (1,1) struct
end
n = numel(argNodes);
types = cell(1, n);
nvNames = strings(1, n);
for k = 1:n
    a = argNodes{k};
    if iskind(a, "NAMEVALUE")
        nvNames(k) = verify.mtree.nodeText(a.Left);
        a = a.Right;
    end
    [types{k}, state] = verify.types.exprType(a, state, ctx);
end
outs = repmat({verify.types.make()}, 1, max(nout, 1));
call = struct("name", name, "nodes", {argNodes}, "types", {types}, "nvNames", nvNames, ...
    "line", lineno(callNode), "column", charno(callNode), "nout", nout);
gaps = ["feval" "eval" "evalin" "evalc" "cellfun" "arrayfun" "structfun"];
sig = lookupSig(name, ctx);
if any(name == gaps)
    state.unchecked = state.unchecked + 1;
elseif ~isempty(sig)
    state.issues = [state.issues; verify.types.checkCall(sig, call, ctx.file)];
    state.checked = state.checked + 1;
    outs = sigOutputs(sig, max(nout, 1));
elseif isKey(ctx.builtins, char(name))
    [outs, state] = builtinCall(ctx.builtins(char(name)), call, outs, state, ctx);
else
    state.unchecked = state.unchecked + 1;
end
for k = 1:numel(outs)
    if outs{k}.cls ~= "" && outs{k}.origin == ""
        outs{k}.origin = sprintf("returned by %s at line %d", name, call.line);
    end
end
end

function sig = lookupSig(name, ctx)
arguments (Input)
    name (1,1) string
    ctx (1,1) struct
end
arguments (Output)
    sig (:,1) struct
end
sig = repmat(struct(), 0, 1);
if isKey(ctx.local, char(name))
    sig = ctx.local(char(name));
elseif isKey(ctx.global, char(name))
    sig = ctx.global(char(name));
end
end

function outs = sigOutputs(sig, nout)
arguments (Input)
    sig (1,1) struct
    nout (1,1) double
end
arguments (Output)
    outs (1,:) cell
end
outs = repmat({verify.types.make()}, 1, nout);
for k = 1:min(nout, numel(sig.outNames))
    d = sig.outputs(string([sig.outputs.name]) == sig.outNames(k) & ~[sig.outputs.repeating]);
    if isscalar(d)
        outs{k} = verify.types.fromDecl(d);
    end
end
end

function [outs, state] = builtinCall(rule, call, outs, state, ctx)
arguments (Input)
    rule (1,1) struct
    call (1,1) struct
    outs (1,:) cell
    state (1,1) struct
    ctx (1,1) struct
end
arguments (Output)
    outs (1,:) cell
    state (1,1) struct
end
state.checked = state.checked + 1;
got = rule.fn(call.types, call.nodes, call.nout);
outs(1:numel(got)) = got;
nIn = numel(call.types);
if nIn > rule.maxIn
    state.issues(end + 1, 1) = verify.issue(ctx.file, [call.line call.column], "error", "types", ...
        "tooManyInputs", sprintf("'%s' accepts at most %d input(s) but this call passes %d. " + ...
        "Remove the extra argument(s).", call.name, rule.maxIn, nIn));
end
end
