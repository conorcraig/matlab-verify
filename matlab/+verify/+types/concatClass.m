function cls = concatClass(classes)
%CONCATCLASS Result class of [a, b, ...] concatenation.
%   cell > struct > string > char > integer > single > double; all-logical
%   stays logical. Adapted from Tamer's class-propagation rules for
%   concatenation (github.com/Sable/mclab-core, Apache-2.0).
arguments (Input)
    classes (1,:) string
end
arguments (Output)
    cls (1,1) string
end
cls = "";
if isempty(classes) || any(classes == "")
    return
end
ints = ["int8" "int16" "int32" "int64" "uint8" "uint16" "uint32" "uint64"];
order = ["cell" "struct" "string" "char"];
for c = order
    if any(classes == c)
        cls = c;
        return
    end
end
if ~all(ismember(classes, [ints "double" "single" "logical"]))
    return
end
firstInt = classes(ismember(classes, ints));
if ~isempty(firstInt)
    cls = firstInt(1);
elseif any(classes == "single")
    cls = "single";
elseif all(classes == "logical")
    cls = "logical";
else
    cls = "double";
end
end
