function [t, state] = concatType(node, state, ctx)
%CONCATTYPE Abstract value of [ ... ] (LB) or { ... } (LC).
%   Rows are concatenated horizontally then vertically; empty [] elements are
%   dropped. Unknown or N-D element shapes make the result shape unknown.
arguments (Input)
    node (1,1) mtree
    state (1,1) struct
    ctx (1,1) struct
end
arguments (Output)
    t (1,1) struct
    state (1,1) struct
end
isCell = iskind(node, "LC");
cls = "double";
if isCell
    cls = "cell";
end
rows = verify.mtree.items(node.Arg);
if isempty(rows)
    t = verify.types.make(cls, ["0" "0"]);
    return
end
rowTypes = cell(1, numel(rows));
for k = 1:numel(rows)
    [rowTypes{k}, state] = verify.types.exprList(rows{k}.Arg, state, ctx);
end
if isCell
    counts = cellfun(@numel, rowTypes);
    dims = ["?" "?"];
    if all(counts == counts(1))
        dims = string([numel(rows) counts(1)]);
    end
    t = verify.types.make("cell", dims);
    return
end
elems = [rowTypes{:}];
classes = string(cellfun(@(x) x.cls, elems, "UniformOutput", false));
t = verify.types.make(verify.types.concatClass(classes), stackRows(rowTypes));
end

function dims = stackRows(rowTypes)
arguments (Input)
    rowTypes (1,:) cell
end
arguments (Output)
    dims (1,:) string
end
rowDims = cell(1, numel(rowTypes));
for k = 1:numel(rowTypes)
    rowDims{k} = joinParts(cellfun(@(x) x.dims, rowTypes{k}, "UniformOutput", false), 2);
end
dims = joinParts(rowDims, 1);
end

function dims = joinParts(parts, along)
arguments (Input)
    parts (1,:) cell
    along (1,1) double
end
arguments (Output)
    dims (1,:) string
end
parts = parts(~cellfun(@(d) isequal(d, ["0" "0"]), parts));
dims = strings(1, 0);
if isempty(parts)
    dims = ["0" "0"];
    return
end
if any(cellfun(@(d) numel(d) ~= 2, parts))
    return
end
d = vertcat(parts{:});
other = 3 - along;
dims = ["?" "?"];
if all(d(:, other) == d(1, other))
    dims(other) = d(1, other);
end
n = str2double(d(:, along));
if all(~isnan(n))
    dims(along) = string(sum(n));
end
end
