function [t, state] = rangeType(node, state, ctx)
%RANGETYPE Abstract value of lo:hi or lo:step:hi (double row; length when constant).
arguments (Input)
    node (1,1) mtree
    state (1,1) struct
    ctx (1,1) struct
end
arguments (Output)
    t (1,1) struct
    state (1,1) struct
end
t = verify.types.make();
if isnull(node.Left)
    return
end
lo = node.Left;
if iskind(lo, "COLON")
    parts = {lo.Left, lo.Right, node.Right};
else
    parts = {node.Left, [], node.Right};
end
vals = [NaN 1 NaN];
for k = 1:3
    if ~isempty(parts{k})
        [p, state] = verify.types.exprType(parts{k}, state, ctx);
        vals(k) = scalarValue(p);
    end
end
n = "?";
if all(~isnan(vals)) && vals(2) ~= 0
    n = string(max(0, floor((vals(3) - vals(1)) / vals(2)) + 1));
end
t = verify.types.make("double", ["1" n]);
end

function v = scalarValue(t)
arguments (Input)
    t (1,1) struct
end
arguments (Output)
    v (1,1) double
end
v = NaN;
if isscalar(t.value)
    v = str2double(t.value);
end
end
