function p = relPath(p)
%RELPATH Path relative to pwd with forward slashes (unchanged if outside pwd).
arguments
    p (1,1) string
end
arguments (Output)
    p (1,1) string
end
p = replace(p, "\", "/");
here = replace(string(pwd), "\", "/") + "/";
if startsWith(lower(p), lower(here))
    p = extractAfter(p, strlength(here));
end
end
