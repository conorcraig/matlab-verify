function [t, state] = indexType(base, args, state, ctx)
%INDEXTYPE Abstract value of BASE(args): same class, scalar if every index is scalar.
%   Calling a function_handle variable is a known gap and counts as unchecked.
arguments (Input)
    base (1,1) struct
    args (1,:) cell
    state (1,1) struct
    ctx (1,1) struct
end
arguments (Output)
    t (1,1) struct
    state (1,1) struct
end
types = cell(1, numel(args));
for k = 1:numel(args)
    [types{k}, state] = verify.types.exprType(args{k}, state, ctx);
end
t = verify.types.make(base.cls);
if base.cls == "function_handle"
    state.unchecked = state.unchecked + 1;
    t = verify.types.make();
elseif isscalar(args) && isBareColon(args{1})
    t = verify.types.make(base.cls, ["?" "1"]);
elseif ~isempty(args) && all(cellfun(@(x) isequal(x.dims, ["1" "1"]), types))
    t = verify.types.make(base.cls, ["1" "1"]);
end
end

function tf = isBareColon(node)
arguments (Input)
    node (1,1) mtree
end
arguments (Output)
    tf (1,1) logical
end
tf = iskind(node, "COLON") && isnull(node.Left);
end
