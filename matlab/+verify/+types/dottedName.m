function name = dottedName(node)
%DOTTEDNAME "a.b.c" for an ID or a DOT chain of ID/FIELD nodes, else "".
arguments (Input)
    node (1,1) mtree
end
arguments (Output)
    name (1,1) string
end
name = "";
if iskind(node, "ID")
    name = verify.mtree.nodeText(node);
elseif iskind(node, "DOT") && iskind(node.Right, "FIELD")
    left = verify.types.dottedName(node.Left);
    if left ~= ""
        name = left + "." + verify.mtree.nodeText(node.Right);
    end
end
end
