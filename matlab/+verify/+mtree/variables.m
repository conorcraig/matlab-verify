function vars = variables(fnNode)
%VARIABLES Variables introduced by one function (not its nested functions).
%   Inputs, outputs, assignment targets (x = ..., [a, b] = ..., x(i) = ...),
%   for-loop indices, catch identifiers and global/persistent names. One
%   entry per name at its first occurrence: struct array name, line, column.
arguments (Input)
    fnNode (1,1) mtree
end
arguments (Output)
    vars (:,1) struct
end
nodes = [verify.mtree.items(fnNode.Ins) verify.mtree.items(fnNode.Outs)];
sub = Tree(fnNode);
eqs = verify.mtree.members(mtfind(sub, "Kind", "EQUALS"));
for k = 1:numel(eqs)
    if owner(eqs{k}) == indices(fnNode)
        nodes = [nodes targetsOf(eqs{k}.Left)]; %#ok<AGROW>
    end
end
others = cell(1, 0);
for kindName = ["FOR" "PARFOR" "TRY" "GLOBAL" "PERSISTENT"]
    others = [others verify.mtree.members(mtfind(sub, "Kind", kindName))]; %#ok<AGROW>
end
for k = 1:numel(others)
    if owner(others{k}) == indices(fnNode)
        nodes = [nodes declared(others{k})]; %#ok<AGROW>
    end
end
vars = firstOccurrences(nodes);
end

function ix = owner(node)
%OWNER Index of the nearest enclosing FUNCTION node.
arguments (Input)
    node (1,1) mtree
end
arguments (Output)
    ix (1,1) double
end
ix = 0;
p = trueparent(node);
while ~isnull(p)
    if iskind(p, "FUNCTION")
        ix = indices(p);
        return
    end
    p = trueparent(p);
end
end

function out = targetsOf(lhs)
arguments (Input)
    lhs (1,1) mtree
end
arguments (Output)
    out (1,:) cell
end
parts = {lhs};
if iskind(lhs, "LB")
    parts = verify.mtree.items(lhs.Arg);
end
out = cell(1, 0);
for k = 1:numel(parts)
    base = parts{k};
    while ~isnull(base) && any(strcmp(kind(base), ["SUBSCR" "CELL" "DOT" "DOTLP" "CALL" "LP"]))
        base = base.Left;
    end
    if ~isnull(base) && iskind(base, "ID")
        out{end + 1} = base; %#ok<AGROW>
    end
end
end

function out = declared(stmt)
arguments (Input)
    stmt (1,1) mtree
end
arguments (Output)
    out (1,:) cell
end
switch kind(stmt)
    case {"FOR", "PARFOR"}
        out = {stmt.Index};
    case "TRY"
        out = {stmt.CatchID};
    otherwise
        out = verify.mtree.items(stmt.Arg);
end
out = out(cellfun(@(n) ~isnull(n) && iskind(n, "ID"), out));
end

function vars = firstOccurrences(nodes)
arguments (Input)
    nodes (1,:) cell
end
arguments (Output)
    vars (:,1) struct
end
vars = repmat(struct("name", "", "line", 0, "column", 0), 0, 1);
for k = 1:numel(nodes)
    name = verify.mtree.nodeText(nodes{k});
    if name == "~" || any(string([vars.name]) == name)
        continue
    end
    vars(end + 1, 1) = struct("name", name, "line", lineno(nodes{k}), "column", charno(nodes{k})); %#ok<AGROW>
end
end
