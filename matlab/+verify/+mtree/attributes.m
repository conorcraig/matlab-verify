function out = attributes(block)
%ATTRIBUTES Attribute names of a METHODS/PROPERTIES/ARGUMENTS block, e.g. ["Static" "Access"].
%   Attributes set to false (Constant = false) are omitted.
arguments (Input)
    block (1,1) mtree
end
arguments (Output)
    out (1,:) string
end
out = strings(1, 0);
attrs = block.Attr;
if isnull(attrs)
    return
end
nodes = verify.mtree.items(attrs.Arg);
for k = 1:numel(nodes)
    a = nodes{k};
    v = a.Right;
    if ~isnull(v) && any(verify.mtree.nodeText(v) == ["false" "0"])
        continue
    end
    out(end + 1) = verify.mtree.nodeText(a.Left); %#ok<AGROW>
end
end
