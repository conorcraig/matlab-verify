function info = functions(tree, lines)
%FUNCTIONS One record per FUNCTION node (primary, local, nested, method).
%   Fields: node, name, line, column, role ("primary" | "local" | "nested" |
%   "method"), className, isStatic, isConstructor, isAccessor, optOut.
%   optOut is true when the function line carries %#verify:no-arguments.
%   Abstract method signatures are PROTO nodes and are not returned.
arguments (Input)
    tree (1,1) mtree
    lines (:,1) string
end
arguments (Output)
    info (:,1) struct
end
info = repmat(record(tree, "", "", false), 0, 1);
className = "";
r = root(tree);
if iskind(r, "CLASSDEF")
    className = classNameOf(r);
end
fns = verify.mtree.items(mtfind(tree, "Kind", "FUNCTION"));
for k = 1:numel(fns)
    f = fns{k};
    [role, isStatic] = roleOf(f, r);
    rec = record(f, role, className, isStatic);
    if rec.line >= 1 && rec.line <= numel(lines)
        rec.optOut = contains(lines(rec.line), "%#verify:no-arguments");
    end
    info(end + 1, 1) = rec; %#ok<AGROW>
end
end

function rec = record(f, role, className, isStatic)
arguments (Input)
    f (1,1) mtree
    role (1,1) string
    className (1,1) string
    isStatic (1,1) logical
end
arguments (Output)
    rec (1,1) struct
end
name = "";
if iskind(f, "FUNCTION")
    name = verify.mtree.nodeText(f.Fname);
end
rec = struct("node", f, "name", name, "line", lineno(f), "column", charno(f), ...
    "role", role, "className", className, "isStatic", isStatic, ...
    "isConstructor", role == "method" && name == className, ...
    "isAccessor", contains(name, "."), "optOut", false);
end

function [role, isStatic] = roleOf(f, r)
arguments (Input)
    f (1,1) mtree
    r (1,1) mtree
end
arguments (Output)
    role (1,1) string
    isStatic (1,1) logical
end
isStatic = false;
role = "local";
if indices(f) == indices(r)
    role = "primary";
    return
end
p = trueparent(f);
while ~isnull(p)
    if iskind(p, "FUNCTION")
        role = "nested";
        return
    elseif iskind(p, "METHODS")
        role = "method";
        isStatic = any(verify.mtree.attributes(p) == "Static");
        return
    end
    p = trueparent(p);
end
end

function name = classNameOf(r)
arguments (Input)
    r (1,1) mtree
end
arguments (Output)
    name (1,1) string
end
c = r.Cexpr;
while ~isnull(c) && ~iskind(c, "ID")
    c = c.Left;
end
name = verify.mtree.nodeText(c);
end
