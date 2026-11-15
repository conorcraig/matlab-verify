function s = nodeText(node)
%NODETEXT Source text of an ID/FIELD/literal node ("" for a null node, "~" for an ignored input).
arguments (Input)
    node (1,1) mtree
end
arguments (Output)
    s (1,1) string
end
if isnull(node)
    s = "";
elseif iskind(node, "NOT")
    s = "~";
else
    s = string(string(node));
end
end
