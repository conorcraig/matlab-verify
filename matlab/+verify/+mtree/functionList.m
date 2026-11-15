function records = functionList(tree, srcLines)
%FUNCTIONLIST One record per FUNCTION node (primary, local, nested, method).
%   Fields: node, name, line, column, role ("primary" | "local" | "nested" |
%   "method"), className, blockAttrs (attributes of the enclosing methods
%   block), isConstructor, isAccessor (set.X/get.X), isTest (method in a
%   matlab.unittest Test/setup/teardown block), optOut (function line carries
%   %#verify:no-arguments). Abstract method signatures are PROTO nodes and
%   are not returned.
arguments (Input)
    tree (1,1) mtree
    srcLines (:,1) string
end
arguments (Output)
    records (:,1) struct
end
r = root(tree);
className = "";
if iskind(r, "CLASSDEF")
    className = verify.mtree.className(tree);
end
fns = verify.mtree.members(mtfind(tree, "Kind", "FUNCTION"));
records = repmat(record(r, "", "", strings(1, 0)), 0, 1);
for k = 1:numel(fns)
    [role, attrs] = roleOf(fns{k}, r);
    rec = record(fns{k}, role, className, attrs);
    if rec.line >= 1 && rec.line <= numel(srcLines)
        rec.optOut = contains(srcLines(rec.line), "%#verify:no-arguments");
    end
    records(end + 1, 1) = rec; %#ok<AGROW>
end
end

function rec = record(f, role, className, attrs)
arguments (Input)
    f (1,1) mtree
    role (1,1) string
    className (1,1) string
    attrs (1,:) string
end
arguments (Output)
    rec (1,1) struct
end
name = "";
if iskind(f, "FUNCTION")
    name = verify.mtree.nodeText(f.Fname);
end
testAttrs = ["Test" "TestMethodSetup" "TestMethodTeardown" "TestClassSetup" "TestClassTeardown"];
rec = struct("node", f, "name", name, "line", lineno(f), "column", charno(f), ...
    "role", role, "className", className, "blockAttrs", attrs, ...
    "isConstructor", role == "method" && name == className, ...
    "isAccessor", contains(name, "."), "isTest", any(ismember(attrs, testAttrs)), "optOut", false);
end

function [role, attrs] = roleOf(f, r)
arguments (Input)
    f (1,1) mtree
    r (1,1) mtree
end
arguments (Output)
    role (1,1) string
    attrs (1,:) string
end
attrs = strings(1, 0);
role = "local";
if indices(f) == indices(r)
    role = "primary";
    return
end
p = trueparent(f);
while ~isnull(p) && role == "local"
    if iskind(p, "FUNCTION")
        role = "nested";
    elseif iskind(p, "METHODS")
        role = "method";
        attrs = verify.mtree.attributes(p);
    end
    p = trueparent(p);
end
end
