function m = builtinRules()
%BUILTINRULES Starter table of builtin class/shape rules: name -> struct(fn, maxIn).
%   fn(argTypes, argNodes, nargout) returns a cell row of output abstract
%   values. Shape rules (fill from size arguments, size/numel values,
%   reductions, elementwise) are adapted from Mc2For's builtin shape
%   equations (github.com/Sable/Mc2For, Apache-2.0); result classes follow
%   Tamer's builtin class-propagation spec (github.com/Sable/mclab-core,
%   Apache-2.0).
arguments (Output)
    m (:,1) containers.Map
end
persistent cache
if isempty(cache)
    cache = build();
end
m = cache;
end

function m = build()
arguments (Output)
    m (:,1) containers.Map
end
m = containers.Map("KeyType", "char", "ValueType", "any");
r = @verify.types.builtinShapes;
reg = @(names, fn, maxIn) addRules(m, names, fn, maxIn);
scalarOf = @(c) @(~, ~, ~) {verify.types.make(c, ["1" "1"])};
reg(["zeros" "ones" "rand" "randn" "nan" "NaN" "inf" "Inf" "eye" "pi" "eps"], ...
    @(a, n, ~) r("fill", "double", a, n), Inf);
reg(["true" "false"], @(a, n, ~) r("fill", "logical", a, n), Inf);
reg("cell", @(a, n, ~) r("fill", "cell", a, n), Inf);
reg("strings", @(a, n, ~) r("fill", "string", a, n), Inf);
reg("size", @(a, n, k) r("size", "", a, n, k), Inf);
for c = ["numel" "length" "ndims" "nnz"]
    reg(c, @(a, n, ~) r("count", c, a, n), Inf);
end
reg(["isempty" "isscalar" "isvector" "isrow" "iscolumn" "isnumeric" "ischar" "isstring" ...
     "islogical" "iscell" "isstruct" "isfloat" "isinteger" "isreal"], scalarOf("logical"), 1);
reg(["isa" "isequal" "isfile" "isfolder" "strcmp" "strcmpi" "isfield"], scalarOf("logical"), Inf);
reg("exist", scalarOf("double"), 2);
reg("string", @(a, n, ~) r("toString", "", a, n), 1);
reg("char", @(a, n, ~) r("toChar", "", a, n), Inf);
for c = ["double" "single" "logical" "int8" "int16" "int32" "int64" "uint8" "uint16" "uint32" "uint64"]
    reg(c, @(a, n, ~) r("cast", c, a, n), 1);
end
for c = ["sum" "prod" "mean" "any" "all" "max" "min" "cumsum"]
    reg(c, @(a, n, ~) r("reduce", c, a, n), Inf);
end
for c = ["upper" "lower" "strtrim" "abs" "round" "floor" "ceil" "fix" "sqrt" "exp" "log" "sign"]
    reg(c, @(a, n, ~) r("same", c, a, n), Inf);
end
reg(["num2str" "mat2str" "int2str" "class" "func2str" "fileread"], ...
    @(~, ~, ~) {verify.types.make("char", ["1" "?"])}, Inf);
reg(["sprintf" "strjoin" "strcat" "fullfile" "strrep" "regexprep" "replace" "erase"], ...
    @(a, n, ~) r("text", "", a, n), Inf);
reg(["contains" "startsWith" "endsWith" "ismember"], @(a, n, ~) r("match", "", a, n), Inf);
reg("reshape", @(a, n, ~) r("reshape", "", a, n), Inf);
reg(["repmat" "find" "unique" "sort" "cat" "horzcat" "vertcat" "fliplr" "flipud"], ...
    @(a, n, ~) r("loose", "", a, n), Inf);
reg("fieldnames", @(~, ~, ~) {verify.types.make("cell", ["?" "1"])}, 2);
reg("struct", @(~, ~, ~) {verify.types.make("struct")}, Inf);
reg("strsplit", @(a, n, ~) r("split", "", a, n), Inf);
reg(["error" "warning" "fprintf" "disp" "assert"], @(~, ~, ~) cell(1, 0), Inf);
end

function addRules(m, names, fn, maxIn)
arguments (Input)
    m (:,1) containers.Map
    names (1,:) string
    fn (1,1) function_handle
    maxIn (1,1) double
end
for name = names
    m(char(name)) = struct("fn", fn, "maxIn", maxIn);
end
end
