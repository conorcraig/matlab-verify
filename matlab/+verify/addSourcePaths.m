function roots = addSourcePaths(files)
%ADDSOURCEPATHS Put the folders containing FILES on the path.
%   Package (+), class (@) and private folders resolve to the folder above
%   them, which is what MATLAB needs on the path.
arguments
    files (:,1) string
end
arguments (Output)
    roots (:,1) string
end
roots = strings(0, 1);
for f = files'
    parts = split(string(fileparts(verify.absPath(f))), ["/", "\"]);
    special = find(startsWith(parts, ["+", "@"]) | parts == "private", 1);
    if ~isempty(special)
        parts = parts(1:special - 1);
    end
    roots(end + 1, 1) = strjoin(parts, filesep); %#ok<AGROW>
end
roots = unique(roots);
for r = roots'
    addpath(r);
end
end
