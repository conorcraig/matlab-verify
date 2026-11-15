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
ins = reshape(setdiff(sig.inNames, ["~" "varargin"], "stable"), 1, []);
outs = reshape(setdiff(sig.outNames, "varargout", "stable"), 1, []);
issues = [issues; side(fnRec, sig, file, ins, sig.hasInBlock, sig.inputs, "input")];
issues = [issues; side(fnRec, sig, file, outs, sig.hasOutBlock, sig.outputs, "output")];
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

function issues = side(fnRec, sig, file, names, hasBlock, decls, direction)
arguments (Input)
    fnRec (1,1) struct
    sig (1,1) struct
    file (1,1) string
    names (1,:) string
    hasBlock (1,1) logical
    decls (:,1) struct
    direction (1,1) string
end
arguments (Output)
    issues (:,1) struct
end
issues = repmat(verify.issue(""), 0, 1);
if isempty(names)
    return
end
pos = [fnRec.line fnRec.column];
blockKw = "arguments";
if direction == "output"
    blockKw = "arguments (Output)";
end
if ~hasBlock
    id = "noInputBlock";
    if direction == "output"
        id = "noOutputBlock";
    end
    issues = verify.issue(file, pos, "error", "types", id, sprintf( ...
        "Function '%s' has %ss (%s) but no '%s' block. Add one declaring class and size for each, " + ...
        "e.g. '%s (1,1) double', or put %%#verify:no-arguments on the function line to opt out.", ...
        sig.name, direction, strjoin(names, ", "), blockKw, names(1)));
    return
end
for name = names
    issues = [issues; declIssues(sig.name, file, pos, name, decls, direction, blockKw)]; %#ok<AGROW>
end
end

function issues = declIssues(fname, file, pos, name, decls, direction, blockKw)
arguments (Input)
    fname (1,1) string
    file (1,1) string
    pos (1,2) double
    name (1,1) string
    decls (:,1) struct
    direction (1,1) string
    blockKw (1,1) string
end
arguments (Output)
    issues (:,1) struct
end
issues = repmat(verify.issue(""), 0, 1);
mine = decls(string([decls.name]) == name & ~[decls.repeating]);
if isempty(mine)
    issues = verify.issue(file, pos, "error", "types", "undeclared", sprintf( ...
        "The %s '%s' of '%s' is missing from its '%s' block. Add a line such as '%s (1,1) double' " + ...
        "with its real class and size.", direction, name, fname, blockKw, name));
    return
end
for d = reshape(mine, 1, [])
    label = d.name;
    if d.field ~= ""
        label = d.name + "." + d.field;
    end
    absent = [repmat("class", 1, d.cls == "") repmat("size", 1, ~d.hasSize)];
    if ~isempty(absent)
        issues(end + 1, 1) = verify.issue(file, [d.line d.column], "error", "types", ...
            "no" + upper(extractBefore(absent(1), 2)) + extractAfter(absent(1), 1), sprintf( ...
            "The %s '%s' of '%s' declares no %s. Declare both, e.g. '%s (1,:) double'.", ...
            direction, label, fname, strjoin(absent, " or "), label)); %#ok<AGROW>
    end
end
end
