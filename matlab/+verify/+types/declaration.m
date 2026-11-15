function d = declaration(name, cls, dims)
%DECLARATION One arguments-block entry of a signature table.
%   Fields: name, field (name-value field, "" if positional), cls ("" if
%   none), dims (":" or concrete per dimension; empty if no size), hasSize,
%   validators, hasDefault, repeating, line, column.
arguments (Input)
    name (1,1) string
    cls (1,1) string = ""
    dims (1,:) string = strings(1, 0)
end
arguments (Output)
    d (1,1) struct
end
d = struct("name", name, "field", "", "cls", cls, "dims", dims, "hasSize", ~isempty(dims), ...
    "validators", strings(1, 0), "hasDefault", false, "repeating", false, "line", 0, "column", 0);
end
