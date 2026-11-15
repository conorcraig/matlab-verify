function out = names(first)
%NAMES Text of each node in a Next-chain (e.g. the Ins or Outs of a FUNCTION).
arguments (Input)
    first (1,1) mtree
end
arguments (Output)
    out (1,:) string
end
nodes = verify.mtree.items(first);
out = strings(1, numel(nodes));
for k = 1:numel(nodes)
    out(k) = verify.mtree.nodeText(nodes{k});
end
end
