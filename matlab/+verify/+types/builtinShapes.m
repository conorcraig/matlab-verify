function outs = builtinShapes(rule, cls, args, nodes, nout)
%BUILTINSHAPES Output abstract values for one builtin rule family.
%   Rule equations adapted from Mc2For's builtin shape propagation
%   (github.com/Sable/Mc2For, Apache-2.0) and Tamer's builtin class
%   propagation (github.com/Sable/mclab-core, Apache-2.0).
arguments (Input)
    rule (1,1) string
    cls (1,1) string
    args (1,:) cell
    nodes (1,:) cell
    nout (1,1) double = 1
end
arguments (Output)
    outs (1,:) cell
end
persistent rules
if isempty(rules)
    rules = struct("fill", @fillShape, "size", @sizeOf, "count", @countOf, "toString", @toString, ...
                   "toChar", @toChar, "cast", @castTo, "reduce", @reduce, "same", @same, "text", @textOf, ...
                   "match", @match, "reshape", @reshapeOf, "loose", @loose, "split", @splitOf);
end
mk = @verify.types.make;
if isempty(args)
    args = {mk()};
    if rule == "fill"
        args = cell(1, 0);
    end
end
outs = rules.(rule)(cls, args, nodes, nout);
end

function outs = fillShape(cls, args, nodes, ~)
% zeros(n), zeros(m,n,...), zeros(size(x)), zeros(..., "int32"), zeros(..., "like", x)
arguments (Input)
    cls (1,1) string
    args (1,:) cell
    nodes (1,:) cell
    ~
end
arguments (Output)
    outs (1,:) cell
end
isText = cellfun(@(n) iskind(n, "STRING") || iskind(n, "CHARVECTOR"), nodes);
last = find(isText, 1);
if ~isempty(last)
    word = regexprep(verify.mtree.nodeText(nodes{last}), "^[""']|[""']$", "");
    cls = word;
    if word == "like" && last < numel(args)
        cls = args{last + 1}.cls;
    end
    args = args(1:last - 1);
end
dims = ["1" "1"];
if isscalar(args) && numel(args{1}.value) > 1
    dims = args{1}.value;
elseif isscalar(args)
    dims = [dimOf(args{1}) dimOf(args{1})];
elseif ~isempty(args)
    dims = dimsOf(args);
end
outs = {verify.types.make(cls, dims)};
end

function d = dimOf(t)
arguments (Input)
    t (1,1) struct
end
arguments (Output)
    d (1,1) string
end
d = "?";
if isscalar(t.value)
    d = t.value;
end
end

function dims = dimsOf(args)
arguments (Input)
    args (1,:) cell
end
arguments (Output)
    dims (1,:) string
end
dims = strings(1, numel(args));
for k = 1:numel(args)
    dims(k) = dimOf(args{k});
end
end

function outs = sizeOf(~, args, ~, nout)
arguments (Input)
    ~
    args (1,:) cell
    ~
    nout (1,1) double
end
arguments (Output)
    outs (1,:) cell
end
x = args{1};
scalarDim = @(v) verify.types.make("double", ["1" "1"], v);
if nout > 1
    outs = cell(1, nout);
    for k = 1:nout
        outs{k} = scalarDim(dimAt(x.dims, k));
    end
elseif numel(args) == 2 && isscalar(args{2}.value)
    outs = {scalarDim(dimAt(x.dims, str2double(args{2}.value)))};
elseif numel(args) >= 2
    outs = {verify.types.make("double", ["1" string(numel(args) - 1)])};
elseif isempty(x.dims)
    outs = {verify.types.make("double", ["1" "?"])};
else
    outs = {verify.types.make("double", ["1" string(numel(x.dims))], x.dims)};
end
end

function v = dimAt(dims, k)
arguments (Input)
    dims (1,:) string
    k (1,1) double
end
arguments (Output)
    v (1,:) string
end
v = strings(1, 0);
if isempty(dims) || isnan(k) || any(dims == "?")
    return
end
if k <= numel(dims)
    v = dims(k);
else
    v = "1";
end
end

function outs = countOf(name, args, ~, ~)
% numel -> prod(dims), length -> max(dims) (0 if empty), ndims -> rank; nnz unknown
arguments (Input)
    name (1,1) string
    args (1,:) cell
    ~
    ~
end
arguments (Output)
    outs (1,:) cell
end
dims = args{1}.dims;
n = str2double(dims);
v = strings(1, 0);
if name == "ndims" && ~isempty(dims)
    v = string(numel(dims));
elseif name == "numel" && ~isempty(n) && all(~isnan(n))
    v = string(prod(n));
elseif name == "length" && ~isempty(n) && all(~isnan(n))
    v = string(max(n) * all(n > 0));
end
outs = {verify.types.make("double", ["1" "1"], v)};
end

function outs = toString(~, args, ~, ~)
arguments (Input)
    ~
    args (1,:) cell
    ~
    ~
end
arguments (Output)
    outs (1,:) cell
end
x = args{1};
dims = x.dims;
if x.cls == "char"
    dims = ["1" "1"];
end
outs = {verify.types.make("string", dims)};
end

function outs = toChar(~, args, ~, ~)
arguments (Input)
    ~
    args (1,:) cell
    ~
    ~
end
arguments (Output)
    outs (1,:) cell
end
x = args{1};
dims = strings(1, 0);
if x.cls == "string" && isequal(x.dims, ["1" "1"]) || x.cls == "char"
    dims = ["1" "?"];
elseif ismember(x.cls, ["double" "single" "logical"])
    dims = x.dims;
end
outs = {verify.types.make("char", dims)};
end

function outs = castTo(cls, args, ~, ~)
arguments (Input)
    cls (1,1) string
    args (1,:) cell
    ~
    ~
end
arguments (Output)
    outs (1,:) cell
end
outs = {verify.types.make(cls, args{1}.dims, args{1}.value)};
end

function outs = reduce(name, args, ~, ~)
% sum/prod/mean/any/all/max/min/cumsum along the first non-singleton dimension
arguments (Input)
    name (1,1) string
    args (1,:) cell
    ~
    ~
end
arguments (Output)
    outs (1,:) cell
end
x = args{1};
if any(name == ["max" "min"]) && numel(args) == 2
    outs = {verify.types.make(verify.types.arithClass(x.cls, args{2}.cls, "MINUS"), ...
                              verify.types.broadcast(x.dims, args{2}.dims))};
    return
end
dims = reduceDims(name, x.dims, numel(args));
outs = {verify.types.make(reduceClass(name, x.cls), dims), verify.types.make("double", dims)};
end

function cls = reduceClass(name, inCls)
arguments (Input)
    name (1,1) string
    inCls (1,1) string
end
arguments (Output)
    cls (1,1) string
end
cls = verify.types.arithClass(inCls, "double", "MINUS");
if any(name == ["any" "all"])
    cls = "logical";
elseif any(name == ["max" "min"]) && ~any(inCls == ["char" "logical"])
    cls = inCls;
end
end

function dims = reduceDims(name, inDims, nArgs)
arguments (Input)
    name (1,1) string
    inDims (1,:) string
    nArgs (1,1) double
end
arguments (Output)
    dims (1,:) string
end
dims = strings(1, 0);
if name == "cumsum"
    dims = inDims;
elseif nArgs > 1
    return
elseif numel(inDims) == 2 && any(inDims == "1")
    dims = ["1" "1"];
elseif ~isempty(inDims) && ~isnan(str2double(inDims(1)))
    dims = ["1" inDims(2:end)];
end
end

function outs = same(name, args, ~, ~)
% upper/lower/strtrim keep the class; elementwise math promotes char/logical to double
arguments (Input)
    name (1,1) string
    args (1,:) cell
    ~
    ~
end
arguments (Output)
    outs (1,:) cell
end
x = args{1};
cls = x.cls;
if ~any(name == ["upper" "lower" "strtrim"]) && any(cls == ["char" "logical"])
    cls = "double";
end
outs = {verify.types.make(cls, x.dims)};
end

function outs = textOf(~, args, ~, ~)
% sprintf/strjoin/strcat/fullfile/strrep...: string in -> string, cell -> cell, else char row
arguments (Input)
    ~
    args (1,:) cell
    ~
    ~
end
arguments (Output)
    outs (1,:) cell
end
classes = string(cellfun(@(t) t.cls, args, "UniformOutput", false));
outs = {verify.types.make("char", ["1" "?"])};
if any(classes == "")
    outs = {verify.types.make()};
elseif classes(1) == "cell"
    outs = {verify.types.make("cell", args{1}.dims)};
elseif any(classes == "string")
    outs = {verify.types.make("string", verify.types.broadcast(args{1}.dims, ["1" "1"]))};
end
end

function outs = match(~, args, ~, ~)
arguments (Input)
    ~
    args (1,:) cell
    ~
    ~
end
arguments (Output)
    outs (1,:) cell
end
x = args{1};
dims = x.dims;
if x.cls == "char"
    dims = ["1" "1"];
end
outs = {verify.types.make("logical", dims)};
end

function outs = reshapeOf(~, args, ~, ~)
% reshape(x, m, n, ...) / reshape(x, [m n]) / reshape(x, [], n)
arguments (Input)
    ~
    args (1,:) cell
    ~
    ~
end
arguments (Output)
    outs (1,:) cell
end
dims = strings(1, 0);
rest = args(2:end);
if isscalar(rest) && numel(rest{1}.value) > 1
    dims = rest{1}.value;
elseif numel(rest) > 1
    dims = dimsOf(rest);
end
outs = {verify.types.make(args{1}.cls, dims)};
end

function outs = loose(~, args, ~, ~)
arguments (Input)
    ~
    args (1,:) cell
    ~
    ~
end
arguments (Output)
    outs (1,:) cell
end
outs = {verify.types.make(args{1}.cls)};
end

function outs = splitOf(~, args, ~, ~)
arguments (Input)
    ~
    args (1,:) cell
    ~
    ~
end
arguments (Output)
    outs (1,:) cell
end
cls = "cell";
if args{1}.cls == "string"
    cls = "string";
end
outs = {verify.types.make(cls, ["1" "?"])};
end
