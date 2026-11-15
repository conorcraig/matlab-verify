function issues = policy(fnRec, sig, file)
%POLICY Every function declares class and size for each input and output.
%   Exempt: %#verify:no-arguments on the function line, nested functions and
%   handle-class delete methods (MATLAB forbids arguments blocks there),
%   set./get. property accessors, matlab.unittest test/setup/teardown
%   methods, ignored inputs (~), varargin and varargout. A function with no
%   inputs needs no input block.
arguments (Input)
    fnRec (1,1) struct
    sig (1,1) struct
    file (1,1) string
end
arguments (Output)
    issues (:,1) struct
end
issues = repmat(verify.issue(""), 0, 1);
if isExempt(fnRec)
    return
end
where = struct("fname", sig.name, "file", file, "pos", [fnRec.line fnRec.column], ...
               "direction", "input", "blockKw", "arguments", "id", "noInputBlock");
ins = reshape(setdiff(sig.inNames, ["~" "varargin"], "stable"), 1, []);
issues = [issues; side(where, ins, sig.hasInBlock, sig.inputs)];
where.direction = "output";
where.blockKw = "arguments (Output)";
where.id = "noOutputBlock";
outs = reshape(setdiff(sig.outNames, "varargout", "stable"), 1, []);
issues = [issues; side(where, outs, sig.hasOutBlock, sig.outputs)];
end

function tf = isExempt(fnRec)
arguments (Input)
    fnRec (1,1) struct
end
arguments (Output)
    tf (1,1) logical
end
tf = fnRec.optOut || fnRec.role == "nested" || fnRec.isTest || fnRec.isAccessor || ...
    (fnRec.role == "method" && fnRec.name == "delete");
end

function issues = side(where, names, hasBlock, decls)
arguments (Input)
    where (1,1) struct
    names (1,:) string
    hasBlock (1,1) logical
    decls (:,1) struct
end
arguments (Output)
    issues (:,1) struct
end
issues = repmat(verify.issue(""), 0, 1);
if isempty(names)
    return
end
if ~hasBlock
    msg = sprintf("Function '%s' has %ss (%s) but no '%s' block. Add one declaring class and size " + ...
                  "for each, e.g. '%s (1,1) double', or put %%#verify:no-arguments on the function " + ...
                  "line to opt out.", ...
                  where.fname, where.direction, strjoin(names, ", "), where.blockKw, names(1));
    issues = verify.issue(where.file, where.pos, "error", "types", where.id, msg);
    return
end
for name = names
    issues = [issues; declIssues(where, name, decls)]; %#ok<AGROW>
end
end

function issues = declIssues(where, name, decls)
arguments (Input)
    where (1,1) struct
    name (1,1) string
    decls (:,1) struct
end
arguments (Output)
    issues (:,1) struct
end
mine = decls(string([decls.name]) == name & ~[decls.repeating]);
if isempty(mine)
    msg = sprintf("The %s '%s' of '%s' is missing from its '%s' block. " + ...
                  "Add a line such as '%s (1,1) double' with its real class and size.", ...
                  where.direction, name, where.fname, where.blockKw, name);
    issues = verify.issue(where.file, where.pos, "error", "types", "undeclared", msg);
    return
end
issues = repmat(verify.issue(""), 0, 1);
for d = reshape(mine, 1, [])
    label = d.name;
    if d.field ~= ""
        label = d.name + "." + d.field;
    end
    absent = [repmat("class", 1, d.cls == "") repmat("size", 1, ~d.hasSize)];
    if isempty(absent)
        continue
    end
    id = "no" + upper(extractBefore(absent(1), 2)) + extractAfter(absent(1), 1);
    msg = sprintf("The %s '%s' of '%s' declares no %s. Declare both, e.g. '%s (1,:) double'.", ...
                  where.direction, label, where.fname, strjoin(absent, " or "), label);
    issues(end + 1, 1) = verify.issue(where.file, [d.line d.column], "error", "types", id, msg); %#ok<AGROW>
end
end
