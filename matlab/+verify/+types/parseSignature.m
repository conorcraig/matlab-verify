function sig = parseSignature(fnNode)
%PARSESIGNATURE Signature table entry for one FUNCTION node from its arguments blocks.
%   sig fields: name, line, column, inNames, outNames, hasInBlock,
%   hasOutBlock, inputs, outputs, unparseable. inputs/outputs are struct
%   arrays of declarations (see declaration). Anything the parser does not
%   understand is counted in unparseable and left unchecked.
arguments (Input)
    fnNode (1,1) mtree
end
arguments (Output)
    sig (1,1) struct
end
none = repmat(verify.types.declaration(""), 0, 1);
sig = struct("name", verify.mtree.nodeText(fnNode.Fname), "line", lineno(fnNode), ...
             "column", charno(fnNode), "inNames", verify.mtree.names(fnNode.Ins), ...
             "outNames", verify.mtree.names(fnNode.Outs), "hasInBlock", false, "hasOutBlock", false, ...
             "inputs", none, "outputs", none, "unparseable", 0);
blocks = verify.mtree.items(fnNode.Arguments);
for k = 1:numel(blocks)
    attrs = verify.mtree.attributes(blocks{k});
    isOut = any(attrs == "Output");
    [decls, nBad] = parseBlock(blocks{k}, any(attrs == "Repeating"));
    sig.unparseable = sig.unparseable + nBad;
    if isOut
        sig.hasOutBlock = true;
        sig.outputs = [sig.outputs; decls];
    else
        sig.hasInBlock = true;
        sig.inputs = [sig.inputs; decls];
    end
end
end

function [decls, nBad] = parseBlock(block, repeating)
arguments (Input)
    block (1,1) mtree
    repeating (1,1) logical
end
arguments (Output)
    decls (:,1) struct
    nBad (1,1) double
end
decls = repmat(verify.types.declaration(""), 0, 1);
nBad = 0;
args = verify.mtree.items(block.Body);
for k = 1:numel(args)
    [d, ok] = parseArgument(args{k}, repeating);
    nBad = nBad + ~ok;
    if d.name ~= ""
        decls(end + 1, 1) = d; %#ok<AGROW>
    end
end
end

function [d, ok] = parseArgument(arg, repeating)
arguments (Input)
    arg (1,1) mtree
    repeating (1,1) logical
end
arguments (Output)
    d (1,1) struct
    ok (1,1) logical
end
d = verify.types.declaration("");
d.line = lineno(arg);
d.column = charno(arg);
d.repeating = repeating;
d.hasDefault = ~isnull(arg.ArgumentInitialization);
v = arg.ArgumentValidation;
ok = ~isnull(v) && iskind(v, "PROPTYPEDECL");
if ~ok
    return
end
d.name = verify.mtree.nodeText(v.VarName);
d.field = verify.mtree.nodeText(v.VarNamedField);
[d.cls, okCls] = parseClass(v.VarType);
[d.dims, okDims] = parseDims(v.VarDimensions);
d.hasSize = ~isempty(d.dims);
d.validators = validatorNames(v.VarValidators);
ok = okCls && okDims;
end

function [cls, ok] = parseClass(node)
arguments (Input)
    node (1,1) mtree
end
arguments (Output)
    cls (1,1) string
    ok (1,1) logical
end
cls = "";
ok = isnull(node) || iskind(node, "ID");
if ~isnull(node) && ok
    cls = verify.mtree.nodeText(node);
end
end

function [dims, ok] = parseDims(first)
arguments (Input)
    first (1,1) mtree
end
arguments (Output)
    dims (1,:) string
    ok (1,1) logical
end
nodes = verify.mtree.items(first);
dims = strings(1, numel(nodes));
ok = true;
for k = 1:numel(nodes)
    if iskind(nodes{k}, "INT")
        dims(k) = verify.mtree.nodeText(nodes{k});
    elseif iskind(nodes{k}, "COLON")
        dims(k) = ":";
    else
        dims(k) = ":";
        ok = false;
    end
end
end

function out = validatorNames(first)
arguments (Input)
    first (1,1) mtree
end
arguments (Output)
    out (1,:) string
end
nodes = verify.mtree.items(first);
out = strings(1, numel(nodes));
for k = 1:numel(nodes)
    n = nodes{k};
    if ~iskind(n, "ID")
        n = n.Left;
    end
    out(k) = verify.mtree.nodeText(n);
end
end
