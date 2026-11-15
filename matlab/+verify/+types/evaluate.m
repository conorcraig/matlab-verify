function [out, state] = evaluate(op, node, state, ctx, call)
%EVALUATE Abstract evaluation of expressions and calls.
%   The evaluators are mutually recursive, so they live in this one file.
%   op "expr": out = {abstract value of NODE}
%   op "list": out = abstract values of the Next-chain starting at NODE
%   op "call": out = output values of call.name(call.args{:}) for
%              call.nout outputs; NODE is the call node (for positions)
%   Calls inside are checked as a side effect: issues and checked/unchecked
%   counts accumulate in STATE.
arguments (Input)
    op (1,1) string {mustBeMember(op, ["expr" "list" "call"])}
    node (1,1) mtree
    state (1,1) struct
    ctx (1,1) struct
    call (1,1) struct = struct("name", "", "args", {cell(1, 0)}, "nout", 1)
end
arguments (Output)
    out (1,:) cell
    state (1,1) struct
end
switch op
    case "expr"
        [t, state] = exprType(node, state, ctx);
        out = {t};
    case "list"
        [out, state] = exprList(node, state, ctx);
    otherwise
        [out, state] = callType(call.name, call.args, node, call.nout, state, ctx);
end
end

function [t, state] = exprType(node, state, ctx)
%EXPRTYPE Abstract value (class, shape) of an expression node.
%   Calls inside the expression are checked as a side effect (issues and
%   checked/unchecked counts accumulate in STATE). Unknown node kinds
%   evaluate to top after visiting their children.
arguments (Input)
    node (1,1) mtree
    state (1,1) struct
    ctx (1,1) struct
end
arguments (Output)
    t (1,1) struct
    state (1,1) struct
end
persistent handlers
if isempty(handlers)
    handlers = buildHandlers();
end
t = verify.types.make();
if isnull(node)
    return
end
k = kind(node);
if isKey(handlers, k)
    handler = handlers(k);
    [t, state] = handler(node, state, ctx);
else
    state = visitChildren(node, state, ctx);
end
end

function m = buildHandlers()
arguments (Output)
    m (:,1) containers.Map
end
m = containers.Map("KeyType", "char", "ValueType", "any");
add = @(keys, h) verify.types.addHandlers(m, keys, h);
add({'INT', 'DOUBLE'}, @numberLiteral);
add({'CHARVECTOR'}, @charLiteral);
add({'STRING'}, @(~, s, ~) deal(verify.types.make("string", ["1" "1"]), s));
add({'ID'}, @idType);
add({'CALL', 'LP', 'SUBSCR'}, @parenType);
add({'DOT'}, @dotType);
add({'PARENS'}, @(n, s, c) exprType(n.Arg, s, c));
add({'LB', 'LC'}, @concatType);
add({'COLON'}, @rangeType);
add({'ANON', 'AT'}, @(~, s, ~) deal(verify.types.make("function_handle", ["1" "1"]), s));
add({'NOT', 'UMINUS', 'UPLUS', 'TRANS', 'DOTTRANS'}, @unaryType);
add({'PLUS', 'MINUS', 'MUL', 'DIV', 'LDIV', 'EXP', 'DOTMUL', 'DOTDIV', 'DOTLDIV', 'DOTEXP', ...
     'LT', 'GT', 'LE', 'GE', 'EQ', 'NE', 'AND', 'OR', 'ANDAND', 'OROR'}, @binaryType);
end

function state = visitChildren(node, state, ctx)
arguments (Input)
    node (1,1) mtree
    state (1,1) struct
    ctx (1,1) struct
end
arguments (Output)
    state (1,1) struct
end
subs = {node.Left, node.Right, node.Arg};
for k = 1:numel(subs)
    [~, state] = exprList(subs{k}, state, ctx);
end
end

function [t, state] = numberLiteral(node, state, ~)
arguments (Input)
    node (1,1) mtree
    state (1,1) struct
    ~
end
arguments (Output)
    t (1,1) struct
    state (1,1) struct
end
t = verify.types.make("double", ["1" "1"], verify.mtree.nodeText(node));
end

function [t, state] = charLiteral(node, state, ~)
arguments (Input)
    node (1,1) mtree
    state (1,1) struct
    ~
end
arguments (Output)
    t (1,1) struct
    state (1,1) struct
end
raw = verify.mtree.nodeText(node);
inner = replace(extractBetween(raw, 2, max(strlength(raw) - 1, 1)), "''", "'");
t = verify.types.make("char", ["1" string(strlength(inner))], inner);
end

function [t, state] = idType(node, state, ctx)
arguments (Input)
    node (1,1) mtree
    state (1,1) struct
    ctx (1,1) struct
end
arguments (Output)
    t (1,1) struct
    state (1,1) struct
end
name = verify.mtree.nodeText(node);
if isfield(state.env, name)
    t = state.env.(name);
    numeric = ismember(t.cls, ["double" "single" "int8" "int16" "int32" "int64" "uint8" "uint16" "uint32" "uint64"]);
    if numeric && isempty(t.value) && isequal(t.dims, ["1" "1"])
        t.value = name;
    end
elseif name == "end"
    t = verify.types.make("double", ["1" "1"]);
else
    [outs, state] = callType(name, cell(1, 0), node, 1, state, ctx);
    t = outs{1};
end
end

function [t, state] = parenType(node, state, ctx)
arguments (Input)
    node (1,1) mtree
    state (1,1) struct
    ctx (1,1) struct
end
arguments (Output)
    t (1,1) struct
    state (1,1) struct
end
left = node.Left;
args = verify.mtree.items(node.Right);
name = verify.types.dottedName(left);
base = extractBefore(name + ".", ".");
if name ~= "" && isfield(state.env, base)
    if iskind(left, "ID")
        [t, state] = indexType(state.env.(base), args, state, ctx);
        return
    end
    name = "";
end
if name == ""
    [~, state] = exprList(node.Right, state, ctx);
    state.unchecked = state.unchecked + 1;
    t = verify.types.make();
    return
end
[outs, state] = callType(name, args, node, 1, state, ctx);
t = outs{1};
end

function [t, state] = dotType(node, state, ctx)
arguments (Input)
    node (1,1) mtree
    state (1,1) struct
    ctx (1,1) struct
end
arguments (Output)
    t (1,1) struct
    state (1,1) struct
end
t = verify.types.make();
name = verify.types.dottedName(node);
if name == "" || isfield(state.env, extractBefore(name + ".", "."))
    state = visitChildren(node, state, ctx);
    return
end
[outs, state] = callType(name, cell(1, 0), node, 1, state, ctx);
t = outs{1};
end

function [types, state] = exprList(first, state, ctx)
%EXPRLIST Evaluate every expression in a Next-chain; returns a cell row of abstract values.
arguments (Input)
    first (1,1) mtree
    state (1,1) struct
    ctx (1,1) struct
end
arguments (Output)
    types (1,:) cell
    state (1,1) struct
end
nodes = verify.mtree.items(first);
types = cell(1, numel(nodes));
for k = 1:numel(nodes)
    [types{k}, state] = exprType(nodes{k}, state, ctx);
end
end

function [t, state] = indexType(base, args, state, ctx)
%INDEXTYPE Abstract value of BASE(args): same class, scalar if every index is scalar.
%   Calling a function_handle variable is a known gap and counts as unchecked.
arguments (Input)
    base (1,1) struct
    args (1,:) cell
    state (1,1) struct
    ctx (1,1) struct
end
arguments (Output)
    t (1,1) struct
    state (1,1) struct
end
types = cell(1, numel(args));
for k = 1:numel(args)
    [types{k}, state] = exprType(args{k}, state, ctx);
end
t = verify.types.make(base.cls);
if base.cls == "function_handle"
    state.unchecked = state.unchecked + 1;
    t = verify.types.make();
elseif isscalar(args) && isBareColon(args{1})
    t = verify.types.make(base.cls, ["?" "1"]);
elseif ~isempty(args) && all(cellfun(@(x) isequal(x.dims, ["1" "1"]), types))
    t = verify.types.make(base.cls, ["1" "1"]);
end
end

function tf = isBareColon(node)
arguments (Input)
    node (1,1) mtree
end
arguments (Output)
    tf (1,1) logical
end
tf = iskind(node, "COLON") && isnull(node.Left);
end

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
    [rowTypes{k}, state] = exprList(rows{k}.Arg, state, ctx);
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

function [t, state] = rangeType(node, state, ctx)
%RANGETYPE Abstract value of lo:hi or lo:step:hi (double row; length when constant).
arguments (Input)
    node (1,1) mtree
    state (1,1) struct
    ctx (1,1) struct
end
arguments (Output)
    t (1,1) struct
    state (1,1) struct
end
t = verify.types.make();
if isnull(node.Left)
    return
end
lo = node.Left;
if iskind(lo, "COLON")
    parts = {lo.Left, lo.Right, node.Right};
else
    parts = {node.Left, [], node.Right};
end
vals = [NaN 1 NaN];
for k = 1:3
    if ~isempty(parts{k})
        [p, state] = exprType(parts{k}, state, ctx);
        vals(k) = scalarValue(p);
    end
end
n = "?";
if all(~isnan(vals)) && vals(2) ~= 0
    n = string(max(0, floor((vals(3) - vals(1)) / vals(2)) + 1));
end
t = verify.types.make("double", ["1" n]);
end

function v = scalarValue(t)
arguments (Input)
    t (1,1) struct
end
arguments (Output)
    v (1,1) double
end
v = NaN;
if isscalar(t.value)
    v = str2double(t.value);
end
end

function [t, state] = unaryType(node, state, ctx)
%UNARYTYPE Abstract value of ~x, -x, +x, x' and x.'.
arguments (Input)
    node (1,1) mtree
    state (1,1) struct
    ctx (1,1) struct
end
arguments (Output)
    t (1,1) struct
    state (1,1) struct
end
[a, state] = exprType(node.Arg, state, ctx);
switch kind(node)
    case "NOT"
        t = verify.types.make("logical", a.dims);
    case {"TRANS", "DOTTRANS"}
        dims = a.dims;
        if numel(dims) == 2
            dims = dims([2 1]);
        elseif ~isempty(dims)
            dims = strings(1, 0);
        end
        t = verify.types.make(a.cls, dims, strings(1, 0), a.origin);
    otherwise
        t = verify.types.make(verify.types.arithClass(a.cls, "double", "MINUS"), a.dims);
end
end

function [t, state] = binaryType(node, state, ctx)
%BINARYTYPE Abstract value of a binary operator expression.
%   Class rules from verify.types.arithClass (Tamer); shape rules adapted
%   from Mc2For's shape propagation (github.com/Sable/Mc2For, Apache-2.0):
%   elementwise ops broadcast, A*B is [rows(A) cols(B)], comparisons and
%   & | give logical, && || give a logical scalar.
arguments (Input)
    node (1,1) mtree
    state (1,1) struct
    ctx (1,1) struct
end
arguments (Output)
    t (1,1) struct
    state (1,1) struct
end
[a, state] = exprType(node.Left, state, ctx);
[b, state] = exprType(node.Right, state, ctx);
op = string(kind(node));
if any(op == ["ANDAND" "OROR"])
    t = verify.types.make("logical", ["1" "1"]);
elseif any(op == ["LT" "GT" "LE" "GE" "EQ" "NE" "AND" "OR"])
    t = verify.types.make("logical", verify.types.broadcast(a.dims, b.dims));
else
    t = verify.types.make(verify.types.arithClass(a.cls, b.cls, op), opShape(op, a.dims, b.dims), ...
                          constantFold(op, a.value, b.value));
end
end

function dims = opShape(op, a, b)
arguments (Input)
    op (1,1) string
    a (1,:) string
    b (1,:) string
end
arguments (Output)
    dims (1,:) string
end
sa = ~isempty(a) & all(a == "1");
sb = ~isempty(b) & all(b == "1");
elementwise = ~any(op == ["MUL" "DIV" "LDIV" "EXP"]) | (sa & sb) | (op == "MUL" & (sa | sb));
dims = strings(1, 0);
if elementwise
    dims = verify.types.broadcast(a, b);
elseif op == "MUL" & numel(a) == 2 & numel(b) == 2
    dims = [a(1) b(2)];
elseif op == "DIV" & sb
    dims = a;
elseif op == "LDIV" & sa
    dims = b;
end
end

function v = constantFold(op, a, b)
arguments (Input)
    op (1,1) string
    a (1,:) string
    b (1,:) string
end
arguments (Output)
    v (1,:) string
end
v = strings(1, 0);
x = str2double(a);
y = str2double(b);
if ~isscalar(x) || ~isscalar(y) || isnan(x) || isnan(y)
    return
end
folds = struct("PLUS", x + y, "MINUS", x - y, "MUL", x * y, "DOTMUL", x * y);
if isfield(folds, op)
    v = string(folds.(op));
end
end

function [outs, state] = callType(name, argNodes, callNode, nout, state, ctx)
%CALLTYPE Check a call to NAME and return the abstract values of its outputs.
%   Resolution order: known gaps (unchecked), local functions of the file,
%   functions/classes in the checked file set, the builtin starter table;
%   anything else is counted as unchecked.
arguments (Input)
    name (1,1) string
    argNodes (1,:) cell
    callNode (1,1) mtree
    nout (1,1) double
    state (1,1) struct
    ctx (1,1) struct
end
arguments (Output)
    outs (1,:) cell
    state (1,1) struct
end
n = numel(argNodes);
types = cell(1, n);
nvNames = strings(1, n);
for k = 1:n
    a = argNodes{k};
    if iskind(a, "NAMEVALUE")
        nvNames(k) = verify.mtree.nodeText(a.Left);
        a = a.Right;
    end
    [types{k}, state] = exprType(a, state, ctx);
end
outs = repmat({verify.types.make()}, 1, max(nout, 1));
call = struct("name", name, "nodes", {argNodes}, "types", {types}, "nvNames", nvNames, ...
              "line", lineno(callNode), "column", charno(callNode), "nout", nout);
gaps = ["feval" "eval" "evalin" "evalc" "cellfun" "arrayfun" "structfun"];
sig = lookupSig(name, ctx);
if any(name == gaps)
    state.unchecked = state.unchecked + 1;
elseif ~isempty(sig)
    state.issues = [state.issues; verify.types.checkCall(sig, call, ctx.file)];
    state.checked = state.checked + 1;
    outs = sigOutputs(sig, max(nout, 1));
elseif isKey(ctx.builtins, char(name))
    [outs, state] = builtinCall(ctx.builtins(char(name)), call, outs, state, ctx);
else
    state.unchecked = state.unchecked + 1;
end
for k = 1:numel(outs)
    if outs{k}.cls ~= "" && outs{k}.origin == ""
        outs{k}.origin = sprintf("returned by %s at line %d", name, call.line);
    end
end
end

function sig = lookupSig(name, ctx)
arguments (Input)
    name (1,1) string
    ctx (1,1) struct
end
arguments (Output)
    sig (:,1) struct
end
sig = repmat(struct(), 0, 1);
if isKey(ctx.local, char(name))
    sig = ctx.local(char(name));
elseif isKey(ctx.global, char(name))
    sig = ctx.global(char(name));
end
end

function outs = sigOutputs(sig, nout)
arguments (Input)
    sig (1,1) struct
    nout (1,1) double
end
arguments (Output)
    outs (1,:) cell
end
outs = repmat({verify.types.make()}, 1, nout);
for k = 1:min(nout, numel(sig.outNames))
    d = sig.outputs(string([sig.outputs.name]) == sig.outNames(k) & ~[sig.outputs.repeating]);
    if isscalar(d)
        outs{k} = verify.types.fromDecl(d);
    end
end
end

function [outs, state] = builtinCall(rule, call, outs, state, ctx)
arguments (Input)
    rule (1,1) struct
    call (1,1) struct
    outs (1,:) cell
    state (1,1) struct
    ctx (1,1) struct
end
arguments (Output)
    outs (1,:) cell
    state (1,1) struct
end
state.checked = state.checked + 1;
got = rule.fn(call.types, call.nodes, call.nout);
outs(1:numel(got)) = got;
nIn = numel(call.types);
if nIn > rule.maxIn
    msg = sprintf("'%s' accepts at most %d input(s) but this call passes %d. Remove the extra argument(s).", ...
                  call.name, rule.maxIn, nIn);
    state.issues(end + 1, 1) = verify.issue(ctx.file, [call.line call.column], "error", "types", ...
                                            "tooManyInputs", msg);
end
end
