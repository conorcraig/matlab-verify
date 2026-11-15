function state = walk(first, state, ctx)
%WALK Abstractly execute a statement list, updating state.env.
%   Branches (if/switch/try) are evaluated from the same entry environment
%   and joined; loop bodies run once and join with the entry environment.
%   Nested functions are skipped here (they are analysed on their own).
arguments (Input)
    first (1,1) mtree
    state (1,1) struct
    ctx (1,1) struct
end
arguments (Output)
    state (1,1) struct
end
persistent handlers
if isempty(handlers)
    handlers = containers.Map("KeyType", "char", "ValueType", "any");
    add = @(keys, h) verify.types.addHandlers(handlers, keys, h);
    add({'EXPR', 'PRINT'}, @exprStmt);
    add({'IF'}, @ifStmt);
    add({'FOR', 'PARFOR'}, @forStmt);
    add({'WHILE'}, @whileStmt);
    add({'SWITCH'}, @switchStmt);
    add({'TRY'}, @tryStmt);
    add({'GLOBAL', 'PERSISTENT'}, @declStmt);
    add({'DCALL'}, @commandStmt);
end
stmts = verify.mtree.items(first);
for k = 1:numel(stmts)
    s = stmts{k};
    if isKey(handlers, kind(s))
        handler = handlers(kind(s));
        state = handler(s, state, ctx);
    end
end
end

function state = exprStmt(s, state, ctx)
arguments (Input)
    s (1,1) mtree
    state (1,1) struct
    ctx (1,1) struct
end
arguments (Output)
    state (1,1) struct
end
e = s.Arg;
if iskind(e, "EQUALS")
    state = verify.types.assign(e, state, ctx);
else
    [~, state] = verify.types.evaluate("expr", e, state, ctx);
end
end

function state = ifStmt(s, state, ctx)
arguments (Input)
    s (1,1) mtree
    state (1,1) struct
    ctx (1,1) struct
end
arguments (Output)
    state (1,1) struct
end
entry = state.env;
envs = {};
hasElse = false;
clauses = verify.mtree.items(s.Arg);
for k = 1:numel(clauses)
    c = clauses{k};
    hasElse = hasElse || iskind(c, "ELSE");
    [~, state] = verify.types.evaluate("expr", c.Left, state, ctx);
    state.env = entry;
    state = verify.types.walk(c.Body, state, ctx);
    envs{end + 1} = state.env; %#ok<AGROW>
end
if ~hasElse
    envs{end + 1} = entry;
end
state.env = verify.types.joinEnvs(envs);
end

function state = forStmt(s, state, ctx)
arguments (Input)
    s (1,1) mtree
    state (1,1) struct
    ctx (1,1) struct
end
arguments (Output)
    state (1,1) struct
end
[v, state] = verify.types.evaluate("expr", s.Vector, state, ctx);
v = v{1};
loopVar = verify.types.make();
if numel(v.dims) == 2 && v.dims(1) == "1"
    loopVar = verify.types.make(v.cls, ["1" "1"]);
elseif numel(v.dims) == 2
    loopVar = verify.types.make(v.cls, [v.dims(1) "1"]);
end
if iskind(s.Index, "ID")
    state.env.(verify.mtree.nodeText(s.Index)) = loopVar;
end
entry = state.env;
state = verify.types.walk(s.Body, state, ctx);
state.env = verify.types.joinEnvs({entry, state.env});
end

function state = whileStmt(s, state, ctx)
arguments (Input)
    s (1,1) mtree
    state (1,1) struct
    ctx (1,1) struct
end
arguments (Output)
    state (1,1) struct
end
[~, state] = verify.types.evaluate("expr", s.Left, state, ctx);
entry = state.env;
state = verify.types.walk(s.Body, state, ctx);
state.env = verify.types.joinEnvs({entry, state.env});
end

function state = switchStmt(s, state, ctx)
arguments (Input)
    s (1,1) mtree
    state (1,1) struct
    ctx (1,1) struct
end
arguments (Output)
    state (1,1) struct
end
[~, state] = verify.types.evaluate("expr", s.Left, state, ctx);
entry = state.env;
envs = {};
hasOtherwise = false;
cases = verify.mtree.items(s.Body);
for k = 1:numel(cases)
    c = cases{k};
    hasOtherwise = hasOtherwise || iskind(c, "OTHERWISE");
    [~, state] = verify.types.evaluate("expr", c.Left, state, ctx);
    state.env = entry;
    state = verify.types.walk(c.Body, state, ctx);
    envs{end + 1} = state.env; %#ok<AGROW>
end
if ~hasOtherwise
    envs{end + 1} = entry;
end
state.env = verify.types.joinEnvs(envs);
end

function state = tryStmt(s, state, ctx)
arguments (Input)
    s (1,1) mtree
    state (1,1) struct
    ctx (1,1) struct
end
arguments (Output)
    state (1,1) struct
end
entry = state.env;
state = verify.types.walk(s.Try, state, ctx);
afterTry = state.env;
state.env = entry;
if ~isnull(s.CatchID)
    state.env.(verify.mtree.nodeText(s.CatchID)) = verify.types.make("MException", ["1" "1"]);
end
state = verify.types.walk(s.Catch, state, ctx);
state.env = verify.types.joinEnvs({afterTry, state.env});
end

function state = commandStmt(~, state, ~)
arguments (Input)
    ~
    state (1,1) struct
    ~
end
arguments (Output)
    state (1,1) struct
end
state.unchecked = state.unchecked + 1;
end

function state = declStmt(s, state, ~)
arguments (Input)
    s (1,1) mtree
    state (1,1) struct
    ~
end
arguments (Output)
    state (1,1) struct
end
for name = verify.mtree.names(s.Arg)
    state.env.(name) = verify.types.make();
end
end
