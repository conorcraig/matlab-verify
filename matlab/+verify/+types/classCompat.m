function status = classCompat(declared, actual)
%CLASSCOMPAT Whether an arguments block declared as DECLARED accepts ACTUAL.
%   Returns "ok", "conflict" or "unknown". The table was measured on MATLAB by
%   passing one value of each class to a function whose arguments block
%   declares the other class (arguments blocks convert where they can, e.g.
%   double accepts char and string, but single and logical reject string).
%   User-defined or unlisted classes are "unknown" (never reported).
arguments (Input)
    declared (1,1) string
    actual (1,1) string
end
arguments (Output)
    status (1,1) string
end
status = "unknown";
if declared == "" || actual == ""
    return
end
if declared == actual
    status = "ok";
    return
end
cats = ["double" "single" "logical" "char" "string" "cell" "struct" "int" "function_handle"];
d = find(cats == category(declared));
a = find(cats == category(actual));
if isempty(d) || isempty(a)
    return
end
%       actual: dbl sgl lgc chr str cel str int fh
accepts = [ ...
    1 1 1 1 1 0 0 1 0   % double
    1 1 1 1 0 0 0 1 0   % single
    1 1 1 1 0 0 0 1 0   % logical
    1 1 0 1 1 2 0 1 1   % char   (cell: only cellstr converts)
    1 1 1 1 1 2 0 1 0   % string (cell: only cellstr converts)
    0 0 0 0 0 1 0 0 0   % cell
    0 0 0 0 0 0 1 0 0   % struct
    1 1 1 1 0 0 0 1 0   % intN/uintN
    0 0 0 0 0 0 0 0 1]; % function_handle
switch accepts(d, a)
    case 1
        status = "ok";
    case 0
        status = "conflict";
end
end

function c = category(cls)
arguments (Input)
    cls (1,1) string
end
arguments (Output)
    c (1,1) string
end
c = cls;
if any(cls == ["int8" "int16" "int32" "int64" "uint8" "uint16" "uint32" "uint64"])
    c = "int";
end
end
