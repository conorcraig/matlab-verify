function [t, state] = binaryType(node, state, ctx)
%BINARYTYPE Abstract value of a binary operator expression.
%   Class rules from verify.types.arithClass (Tamer); shape rules adapted
%   from Mc2For's shape propagation (github.com/Sable/Mc2For, Apache-2.0):
%   elementwise ops broadcast, A*B is [rows(A) cols(B)], comparisons and
%   & | give logical, && || give a logical scalar.
arguments (Input)
    node (1,1) mtree
    state (1,1) struct
    ctx (1,1) struct
end
arguments (Output)
    t (1,1) struct
    state (1,1) struct
end
[a, state] = verify.types.exprType(node.Left, state, ctx);
[b, state] = verify.types.exprType(node.Right, state, ctx);
op = string(kind(node));
if any(op == ["ANDAND" "OROR"])
    t = verify.types.make("logical", ["1" "1"]);
elseif any(op == ["LT" "GT" "LE" "GE" "EQ" "NE" "AND" "OR"])
    t = verify.types.make("logical", verify.types.broadcast(a.dims, b.dims));
else
    t = verify.types.make(verify.types.arithClass(a.cls, b.cls, op), opShape(op, a.dims, b.dims), ...
        constantFold(op, a.value, b.value));
end
end

function dims = opShape(op, a, b)
arguments (Input)
    op (1,1) string
    a (1,:) string
    b (1,:) string
end
arguments (Output)
    dims (1,:) string
end
isScalar = @(d) ~isempty(d) && all(d == "1");
dims = strings(1, 0);
if ~any(op == ["MUL" "DIV" "LDIV" "EXP"]) || isScalar(a) && isScalar(b)
    dims = verify.types.broadcast(a, b);
elseif op == "MUL" && (isScalar(a) || isScalar(b))
    dims = verify.types.broadcast(a, b);
elseif op == "MUL" && numel(a) == 2 && numel(b) == 2
    dims = [a(1) b(2)];
elseif op == "DIV" && isScalar(b)
    dims = a;
elseif op == "LDIV" && isScalar(a)
    dims = b;
end
end

function v = constantFold(op, a, b)
arguments (Input)
    op (1,1) string
    a (1,:) string
    b (1,:) string
end
arguments (Output)
    v (1,:) string
end
v = strings(1, 0);
x = str2double(a);
y = str2double(b);
if ~isscalar(x) || ~isscalar(y) || isnan(x) || isnan(y)
    return
end
folds = struct("PLUS", x + y, "MINUS", x - y, "MUL", x * y, "DOTMUL", x * y);
if isfield(folds, op)
    v = string(folds.(op));
end
end
