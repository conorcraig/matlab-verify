function out = expandFiles(paths)
%EXPANDFILES Expand folders to the .m files below them; keep files as given.
%   Returns a sorted, unique column of paths relative to pwd where possible,
%   using forward slashes.
arguments
    paths (:,1) string
end
arguments (Output)
    out (:,1) string
end
out = strings(0, 1);
for p = paths'
    if isfolder(p)
        listing = dir(fullfile(p, "**", "*.m"));
        out = [out; string(fullfile({listing.folder}, {listing.name}))']; %#ok<AGROW>
    elseif isfile(p)
        out(end + 1, 1) = p; %#ok<AGROW>
    else
        error("verify:noSuchPath", "Path '%s' does not exist.", p);
    end
end
out = unique(arrayfun(@verify.relPath, out));
end
