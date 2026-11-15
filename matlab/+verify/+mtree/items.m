function out = items(first)
%ITEMS Nodes of the Next-chain starting at FIRST, as a cell row of mtree nodes.
arguments (Input)
    first (1,1) mtree
end
arguments (Output)
    out (1,:) cell
end
out = cell(1, 0);
if isnull(first)
    return
end
chain = List(first);
ix = indices(chain);
out = cell(1, numel(ix));
for k = 1:numel(ix)
    out{k} = select(chain, ix(k));
end
end
