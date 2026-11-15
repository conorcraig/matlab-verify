function s = describe(t)
%DESCRIBE Human-readable "class RxC" text for an abstract value.
arguments (Input)
    t (1,1) struct
end
arguments (Output)
    s (1,1) string
end
cls = t.cls;
if cls == ""
    cls = "unknown-class";
end
if isempty(t.dims)
    s = cls + " (unknown size)";
else
    s = cls + " " + strjoin(t.dims, "x");
end
if t.origin ~= ""
    s = s + " (" + t.origin + ")";
end
end
