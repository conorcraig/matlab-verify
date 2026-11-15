function [tree, errMsg] = parseFile(file)
%PARSEFILE Parse a .m file with mtree; errMsg is "" on success.
%   mtree is undocumented and has no compatibility promise; the node kinds
%   this package relies on are listed in verify.mtree.pinnedKinds and pinned
%   by tests/types/MtreeKindsTest.m.
arguments (Input)
    file (1,1) string
end
arguments (Output)
    tree (1,1) mtree
    errMsg (1,1) string
end
tree = mtree(char(file), "-file");
errMsg = "";
if count(tree) == 1 && iskind(tree, "ERR")
    errMsg = string(string(tree));
end
end
