function [shared, locals] = signatureTable(units)
%SIGNATURETABLE Callable signatures across the checked files.
%   shared: containers.Map of primary functions and class constructors,
%   keyed by file name and by package-qualified name (pkg.fn).
%   locals: one containers.Map per unit with that file's own functions
%   (local, nested and methods), which shadow global names.
arguments (Input)
    units (:,1) struct
end
arguments (Output)
    shared (:,1) containers.Map
    locals (:,1) cell
end
shared = containers.Map("KeyType", "char", "ValueType", "any");
locals = cell(numel(units), 1);
for k = 1:numel(units)
    locals{k} = containers.Map("KeyType", "char", "ValueType", "any");
    u = units(k);
    if ~u.ok
        continue
    end
    for jj = 1:numel(u.info)
        if u.info(jj).role ~= "primary" && ~u.info(jj).isAccessor
            locals{k}(char(u.info(jj).name)) = u.sigs{jj};
        end
    end
    [name, sig] = publicEntry(u);
    if name ~= ""
        shared(char(name)) = sig;
        shared(char(qualified(u.file, name))) = sig;
    end
end
end

function [name, sig] = publicEntry(u)
arguments (Input)
    u (1,1) struct
end
arguments (Output)
    name (1,1) string
    sig (1,1) struct
end
[~, name] = fileparts(u.file);
name = string(name);
cls = verify.mtree.className(u.tree);
isPrimary = string([u.info.role]) == "primary";
if cls == "" && any(isPrimary)
    sig = u.sigs{find(isPrimary, 1)};
    return
end
ctor = find([u.info.isConstructor], 1);
if isempty(ctor)
    sig = struct("name", cls, "line", 1, "column", 1, "inNames", strings(1, 0), ...
        "outNames", "obj", "hasInBlock", true, "hasOutBlock", true, ...
        "inputs", repmat(verify.types.declaration(""), 0, 1), ...
        "outputs", verify.types.declaration("obj"), "unparseable", 0);
else
    sig = u.sigs{ctor};
end
if cls == ""
    name = "";
    return
end
outName = [sig.outNames "obj"];
sig.outNames = outName(1);
sig.outputs = verify.types.declaration(outName(1), cls, ["1" "1"]);
end

function q = qualified(file, name)
arguments (Input)
    file (1,1) string
    name (1,1) string
end
arguments (Output)
    q (1,1) string
end
parts = split(replace(fileparts(file), "\", "/"), "/");
pkgs = extractAfter(parts(startsWith(parts, "+")), 1);
q = strjoin([reshape(pkgs, 1, []) name], ".");
end
