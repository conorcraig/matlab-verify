function cls = arithClass(a, b, op)
%ARITHCLASS Result class of arithmetic between classes A and B.
%   Integer dominates (mixed integer classes are an error -> unknown), then
%   single, then double; char and logical promote to double; string PLUS
%   anything is string. Adapted from Tamer's class-propagation rules for
%   builtin arithmetic (github.com/Sable/mclab-core, Apache-2.0).
arguments (Input)
    a (1,1) string
    b (1,1) string
    op (1,1) string = "PLUS"
end
arguments (Output)
    cls (1,1) string
end
cls = "";
if a == "" || b == ""
    return
end
if op == "PLUS" && any([a b] == "string")
    cls = "string";
    return
end
ints = ["int8" "int16" "int32" "int64" "uint8" "uint16" "uint32" "uint64"];
if ~all(ismember([a b], [ints "double" "single" "char" "logical"]))
    return
end
isInt = ismember([a b], ints);
if all(isInt)
    if a == b
        cls = a;
    end
elseif any(isInt)
    cls = a;
    if ~isInt(1)
        cls = b;
    end
elseif any([a b] == "single")
    cls = "single";
else
    cls = "double";
end
end
