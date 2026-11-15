function files = gitGrep(names)
%GITGREP Tracked .m files that contain any NAME as a whole word.
%   One git grep over the repository. No match is an empty list, not an error.
arguments
    names (:,1) string
end
arguments (Output)
    files (:,1) string
end
files = strings(0, 1);
names = unique(names(strlength(names) > 0));
if isempty(names)
    return
end
listFile = string(tempname) + ".txt";
writelines(names, listFile);
cmd = "git grep -l -I -F -w -f """ + listFile + """";
[gitCode, gitOut] = system(cmd);
if isfile(listFile)
    delete(listFile);
end
if gitCode == 1 && strlength(strtrim(string(gitOut))) == 0
    return
end
if gitCode ~= 0
    error("verify:gitGrep", "git grep failed (" + string(gitCode) + "): " + strtrim(string(gitOut)));
end
hits = splitlines(string(gitOut));
hits = replace(hits, "\", "/");
for k = 1:numel(hits)
    rel = strip(hits(k));
    if startsWith(rel, "./")
        rel = extractAfter(rel, 2);
    end
    if rel == "" || ~endsWith(lower(rel), ".m")
        continue
    end
    files(end + 1, 1) = verify.relPath(rel); %#ok<AGROW>
end
end
