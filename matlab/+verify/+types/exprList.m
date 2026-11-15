function [types, state] = exprList(first, state, ctx)
%EXPRLIST Evaluate every expression in a Next-chain; returns a cell row of abstract values.
arguments (Input)
    first (1,1) mtree
    state (1,1) struct
    ctx (1,1) struct
end
arguments (Output)
    types (1,:) cell
    state (1,1) struct
end
nodes = verify.mtree.items(first);
types = cell(1, numel(nodes));
for k = 1:numel(nodes)
    [types{k}, state] = verify.types.exprType(nodes{k}, state, ctx);
end
end
