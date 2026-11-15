function state = analyzeFunction(rec, sig, ctx)
%ANALYZEFUNCTION Class-and-size dataflow over one function body.
%   The environment is seeded from the function's own arguments block; at
%   the end each declared output is compared with what the body assigned.
arguments (Input)
    rec (1,1) struct
    sig (1,1) struct
    ctx (1,1) struct
end
arguments (Output)
    state (1,1) struct
end
state = struct("env", struct(), "issues", repmat(verify.issue(""), 0, 1), "checked", 0, "unchecked", 0);
for name = sig.inNames(sig.inNames ~= "~")
    state.env.(name) = seed(name, sig.inputs);
end
state = verify.types.walk(rec.node.Body, state, ctx);
for k = 1:numel(sig.outNames)
    name = sig.outNames(k);
    d = sig.outputs(string([sig.outputs.name]) == name & ~[sig.outputs.repeating]);
    if isscalar(d) && isfield(state.env, name)
        label = sprintf("Output '%s' of '%s'", name, sig.name);
        state.issues = [state.issues; verify.types.compareValue(d, state.env.(name), label, ...
            ctx.file, [d.line d.column])];
    end
end
end

function t = seed(name, decls)
arguments (Input)
    name (1,1) string
    decls (:,1) struct
end
arguments (Output)
    t (1,1) struct
end
t = verify.types.make();
mine = decls(string([decls.name]) == name);
if name == "varargin"
    t = verify.types.make("cell", ["1" "?"]);
elseif isscalar(mine) && mine.field == ""
    t = verify.types.fromDecl(mine);
elseif ~isempty(mine) && all(string([mine.field]) ~= "")
    t = verify.types.make("struct", ["1" "1"]);
end
end
