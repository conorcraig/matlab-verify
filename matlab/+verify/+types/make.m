function t = make(cls, dims, value, origin)
%MAKE Abstract value: class, shape and (optionally) known constant value.
%   cls     class name, "" = unknown (lattice top).
%   dims    string row, one entry per dimension: a concrete size ("3"),
%           "?" (unknown extent) or a symbol ("n"); strings(1,0) = unknown rank.
%   value   known constant contents as a string row (e.g. "3" for a literal,
%           x.dims for size(x)), strings(1,0) = unknown.
%   origin  where the value came from, used in messages.
%   The shape lattice follows Mc2For's ShapePropagation (concrete dims, symbolic
%   dims, top) -- github.com/Sable/Mc2For, Apache-2.0.
arguments (Input)
    cls (1,1) string = ""
    dims (1,:) string = strings(1, 0)
    value (1,:) string = strings(1, 0)
    origin (1,1) string = ""
end
arguments (Output)
    t (1,1) struct
end
while numel(dims) > 2 && dims(end) == "1"
    dims(end) = [];
end
if isscalar(dims)
    dims = [dims "1"];
end
t = struct("cls", cls, "dims", dims, "value", value, "origin", origin);
end
