function p = absPath(p)
%ABSPATH Absolute form of a path given relative to pwd.
arguments
    p (1,1) string
end
arguments (Output)
    p (1,1) string
end
if ~(startsWith(p, ["/", "\"]) || ~isempty(regexp(p, "^[A-Za-z]:", "once")))
    p = string(fullfile(pwd, p));
end
end
