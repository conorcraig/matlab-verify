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
add({'PARENS'}, @(n, s, c) verify.types.exprType(n.Arg, s, c));
add({'LB', 'LC'}, @verify.types.concatType);
add({'COLON'}, @verify.types.rangeType);
add({'ANON', 'AT'}, @(~, s, ~) deal(verify.types.make("function_handle", ["1" "1"]), s));
add({'NOT', 'UMINUS', 'UPLUS', 'TRANS', 'DOTTRANS'}, @verify.types.unaryType);
add({'PLUS', 'MINUS', 'MUL', 'DIV', 'LDIV', 'EXP', 'DOTMUL', 'DOTDIV', 'DOTLDIV', 'DOTEXP', ...
    'LT', 'GT', 'LE', 'GE', 'EQ', 'NE', 'AND', 'OR', 'ANDAND', 'OROR'}, @verify.types.binaryType);
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
    [~, state] = verify.types.exprList(subs{k}, state, ctx);
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
    [outs, state] = verify.types.callType(name, cell(1, 0), node, 1, state, ctx);
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
        [t, state] = verify.types.indexType(state.env.(base), args, state, ctx);
        return
    end
    name = "";
end
if name == ""
    [~, state] = verify.types.exprList(node.Right, state, ctx);
    state.unchecked = state.unchecked + 1;
    t = verify.types.make();
    return
end
[outs, state] = verify.types.callType(name, args, node, 1, state, ctx);
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
[outs, state] = verify.types.callType(name, cell(1, 0), node, 1, state, ctx);
t = outs{1};
end
