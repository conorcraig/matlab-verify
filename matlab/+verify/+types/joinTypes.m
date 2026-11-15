function t = joinTypes(a, b)
%JOINTYPES Least upper bound of two abstract values (control-flow merge).
%   Equal classes are kept, different classes go to top. Shapes of equal rank
%   are joined per dimension (equal kept, different -> "?"); different ranks
%   go to top. Lattice from Mc2For (github.com/Sable/Mc2For, Apache-2.0).
arguments (Input)
    a (1,1) struct
    b (1,1) struct
end
arguments (Output)
    t (1,1) struct
end
cls = "";
if a.cls == b.cls
    cls = a.cls;
end
dims = strings(1, 0);
if numel(a.dims) == numel(b.dims) && ~isempty(a.dims)
    dims = a.dims;
    dims(a.dims ~= b.dims) = "?";
end
value = strings(1, 0);
if isequal(a.value, b.value)
    value = a.value;
end
origin = "";
if a.origin == b.origin
    origin = a.origin;
end
t = verify.types.make(cls, dims, value, origin);
end
