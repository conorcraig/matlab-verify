function [t, state] = unaryType(node, state, ctx)
%UNARYTYPE Abstract value of ~x, -x, +x, x' and x.'.
arguments (Input)
    node (1,1) mtree
    state (1,1) struct
    ctx (1,1) struct
end
arguments (Output)
    t (1,1) struct
    state (1,1) struct
end
[a, state] = verify.types.exprType(node.Arg, state, ctx);
switch kind(node)
    case "NOT"
        t = verify.types.make("logical", a.dims);
    case {"TRANS", "DOTTRANS"}
        dims = a.dims;
        if numel(dims) == 2
            dims = dims([2 1]);
        elseif ~isempty(dims)
            dims = strings(1, 0);
        end
        t = verify.types.make(a.cls, dims, strings(1, 0), a.origin);
    otherwise
        t = verify.types.make(verify.types.arithClass(a.cls, "double", "MINUS"), a.dims);
end
end
