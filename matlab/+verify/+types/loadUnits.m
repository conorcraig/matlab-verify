function units = loadUnits(files)
%LOADUNITS Parse each file once: tree, function records and signatures.
%   Files that do not parse get ok = false and are skipped by the checks
%   (the parse check reports syntax errors).
arguments (Input)
    files (:,1) string
end
arguments (Output)
    units (:,1) struct
end
units = repmat(struct("file", "", "ok", false, "tree", mtree(""), "info", [], "sigs", []), 0, 1);
for k = 1:numel(files)
    u = struct("file", files(k), "ok", false, "tree", mtree(""), "info", [], "sigs", []);
    [tree, errMsg] = verify.mtree.parseFile(verify.absPath(files(k)));
    if errMsg == ""
        u.tree = tree;
        u.ok = true;
        u.info = verify.mtree.functionList(tree, readlines(verify.absPath(files(k))));
        u.sigs = cell(numel(u.info), 1);
        for jj = 1:numel(u.info)
            u.sigs{jj} = verify.types.parseSignature(u.info(jj).node);
        end
    end
    units(end + 1, 1) = u; %#ok<AGROW>
end
end
