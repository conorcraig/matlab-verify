function name = className(tree)
%CLASSNAME Name declared by a classdef file ("" when the root is not CLASSDEF).
arguments (Input)
    tree (1,1) mtree
end
arguments (Output)
    name (1,1) string
end
name = "";
r = root(tree);
if ~iskind(r, "CLASSDEF")
    return
end
c = r.Cexpr;
while ~isnull(c) && ~iskind(c, "ID")
    c = c.Left;
end
name = verify.mtree.nodeText(c);
end
