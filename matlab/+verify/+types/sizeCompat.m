function status = sizeCompat(declared, actual)
%SIZECOMPAT Whether an arguments-block size DECLARED accepts shape ACTUAL.
%   declared: entries "3" or ":" (from the arguments block).
%   actual:   entries "3", "?" or a symbol; strings(1,0) = unknown rank.
%   Returns "ok", "unknown", "wrongSize" or "wrongRank". Rules measured on
%   MATLAB: scalars expand to any declared size, a vector converts to a
%   declared vector of either orientation, trailing singleton dims are free.
arguments (Input)
    declared (1,:) string
    actual (1,:) string
end
arguments (Output)
    status (1,1) string
end
status = "unknown";
if isempty(declared) || isempty(actual)
    return
end
conc = @(d) ~isnan(str2double(d)) & d ~= ":";
if all(conc(actual)) && all(actual == "1")
    status = "ok";
    return
end
if isVector(declared) && isVector(actual)
    dl = declared(declared ~= "1");
    al = actual(actual ~= "1");
    if conc(dl) && conc(al) && dl ~= al
        status = "wrongSize";
    else
        status = "ok";
    end
    return
end
if nnz(conc(actual) & actual ~= "1") > numel(declared)
    status = "wrongRank";
    return
end
n = max(numel(declared), numel(actual));
d = [declared repmat("1", 1, n - numel(declared))];
a = [actual repmat("1", 1, n - numel(actual))];
both = conc(d) & conc(a);
if any(both & d ~= a)
    status = "wrongSize";
elseif all(both)
    status = "ok";
end
end

function tf = isVector(dims)
arguments (Input)
    dims (1,:) string
end
arguments (Output)
    tf (1,1) logical
end
tf = numel(dims) == 2 && nnz(dims == "1") == 1;
end
