function out = constants(tree)
%CONSTANTS Properties declared in properties (Constant) blocks: struct array name, line, column.
arguments (Input)
    tree (1,1) mtree
end
arguments (Output)
    out (:,1) struct
end
out = repmat(struct("name", "", "line", 0, "column", 0), 0, 1);
blocks = verify.mtree.members(mtfind(tree, "Kind", "PROPERTIES"));
for k = 1:numel(blocks)
    if ~any(verify.mtree.attributes(blocks{k}) == "Constant")
        continue
    end
    props = verify.mtree.items(blocks{k}.Body);
    for jj = 1:numel(props)
        n = nameNode(props{jj});
        if ~isnull(n)
            out(end + 1, 1) = struct("name", verify.mtree.nodeText(n), ...
                                     "line", lineno(n), "column", charno(n)); %#ok<AGROW>
        end
    end
end
end

function n = nameNode(prop)
arguments (Input)
    prop (1,1) mtree
end
arguments (Output)
    n (1,1) mtree
end
n = prop;
if iskind(n, "EQUALS")
    n = n.Left;
end
if iskind(n, "PROPTYPEDECL")
    n = n.VarName;
end
if ~iskind(n, "ID")
    n = n.Left;
end
end
