function out = members(nodeSet)
%MEMBERS Each node of an mtree node set (e.g. an mtfind result) as a cell row.
%   Unlike verify.mtree.items this does not follow Next links.
arguments (Input)
    nodeSet (1,1) mtree
end
arguments (Output)
    out (1,:) cell
end
ix = indices(nodeSet);
out = cell(1, numel(ix));
for k = 1:numel(ix)
    out{k} = select(nodeSet, ix(k));
end
end
