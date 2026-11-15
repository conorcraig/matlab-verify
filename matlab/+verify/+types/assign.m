function state = assign(assignment, state, ctx)
%ASSIGN Abstractly execute one assignment (EQUALS node).
%   x = e binds x; [a, b] = f(...) asks f for two outputs; indexed or field
%   assignment keeps the variable's class and forgets its shape.
arguments (Input)
    assignment (1,1) mtree
    state (1,1) struct
    ctx (1,1) struct
end
arguments (Output)
    state (1,1) struct
end
lhs = assignment.Left;
targets = {lhs};
if iskind(lhs, "LB")
    targets = verify.mtree.items(lhs.Arg);
end
[outs, state] = rhsTypes(assignment.Right, numel(targets), state, ctx);
for k = 1:numel(targets)
    state = bind(targets{k}, outs{min(k, numel(outs))}, state, ctx);
end
end

function [outs, state] = rhsTypes(rhs, n, state, ctx)
arguments (Input)
    rhs (1,1) mtree
    n (1,1) double
    state (1,1) struct
    ctx (1,1) struct
end
arguments (Output)
    outs (1,:) cell
    state (1,1) struct
end
callee = "";
args = cell(1, 0);
if n > 1 && any(strcmp(kind(rhs), ["CALL" "LP" "SUBSCR"]))
    callee = verify.types.dottedName(rhs.Left);
    args = verify.mtree.items(rhs.Right);
elseif n > 1
    callee = verify.types.dottedName(rhs);
end
if callee ~= "" && ~isfield(state.env, extractBefore(callee + ".", "."))
    call = struct("name", callee, "args", {args}, "nout", n);
    [outs, state] = verify.types.evaluate("call", rhs, state, ctx, call);
    return
end
[t, state] = verify.types.evaluate("expr", rhs, state, ctx);
outs = [t repmat({verify.types.make()}, 1, n - 1)];
end

function state = bind(target, t, state, ctx)
arguments (Input)
    target (1,1) mtree
    t (1,1) struct
    state (1,1) struct
    ctx (1,1) struct
end
arguments (Output)
    state (1,1) struct
end
if iskind(target, "ID")
    state.env.(verify.mtree.nodeText(target)) = t;
    return
end
base = target;
while ~isnull(base) && ~iskind(base, "ID")
    if ~iskind(base, "DOT")
        [~, state] = verify.types.evaluate("list", base.Right, state, ctx);
    end
    base = base.Left;
end
if isnull(base)
    return
end
name = verify.mtree.nodeText(base);
if isfield(state.env, name)
    state.env.(name) = verify.types.make(state.env.(name).cls);
elseif iskind(target, "CELL")
    state.env.(name) = verify.types.make("cell");
elseif iskind(target, "DOT")
    state.env.(name) = verify.types.make("struct");
else
    state.env.(name) = verify.types.make(t.cls);
end
end
