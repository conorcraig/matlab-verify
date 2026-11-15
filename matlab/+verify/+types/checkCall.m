function issues = checkCall(sig, call, file)
%CHECKCALL Compare one call's arguments with the callee's signature.
%   Reports tooManyInputs, missingInput, unknownNameValue and, through
%   verify.types.compareValue, wrongClass / wrongSize / wrongRank. A callee
%   without an input arguments block is only checked for too many inputs.
arguments (Input)
    sig (1,1) struct
    call (1,1) struct
    file (1,1) string
end
arguments (Output)
    issues (:,1) struct
end
issues = repmat(verify.issue(""), 0, 1);
pos = [call.line call.column];
nvStruct = reshape(unique(string([sig.inputs(string([sig.inputs.field]) ~= "").name])), 1, []);
posNames = reshape(setdiff(sig.inNames, [nvStruct "varargin"], "stable"), 1, []);
isOpen = any(sig.inNames == "varargin") || any([sig.inputs.repeating]);
call.nvNames = legacyNameValue(call, numel(posNames), ~isempty(nvStruct));
isPos = call.nvNames == "";
nPos = nnz(isPos);
if nPos > numel(posNames) && ~isOpen
    msg = sprintf("Call to '%s' passes %d positional input(s) but it accepts at most %d (%s). " + ...
                  "Remove the extra argument(s).", sig.name, nPos, numel(posNames), strjoin(posNames, ", "));
    issues(end + 1, 1) = verify.issue(file, pos, "error", "types", "tooManyInputs", msg);
end
if ~sig.hasInBlock
    return
end
issues = [issues; missingInputs(sig, call, posNames, nPos, file)];
types = call.types(isPos);
for k = 1:min(nPos, numel(posNames))
    d = sig.inputs(string([sig.inputs.name]) == posNames(k) & string([sig.inputs.field]) == "");
    if isscalar(d)
        label = sprintf("Input %d ('%s') of '%s'", k, posNames(k), sig.name);
        issues = [issues; verify.types.compareValue(d, types{k}, label, file, pos)]; %#ok<AGROW>
    end
end
issues = [issues; nameValues(sig, call, nvStruct, file)];
end

function nv = legacyNameValue(call, nPosDecl, hasNameValue)
%LEGACYNAMEVALUE Mark "Name", value pairs after the positional inputs.
arguments (Input)
    call (1,1) struct
    nPosDecl (1,1) double
    hasNameValue (1,1) logical
end
arguments (Output)
    nv (1,:) string
end
nv = call.nvNames;
if ~hasNameValue
    return
end
first = find(nv ~= "", 1);
if isempty(first)
    first = numel(nv) + 1;
end
for jj = nPosDecl + 1:2:first - 2
    node = call.nodes{jj};
    if ~iskind(node, "STRING") && ~iskind(node, "CHARVECTOR")
        return
    end
    nv(jj) = regexprep(verify.mtree.nodeText(node), "^[""']|[""']$", "");
    nv(jj + 1) = nv(jj) + "#value";
end
end

function issues = missingInputs(sig, call, posNames, nPos, file)
arguments (Input)
    sig (1,1) struct
    call (1,1) struct
    posNames (1,:) string
    nPos (1,1) double
    file (1,1) string
end
arguments (Output)
    issues (:,1) struct
end
issues = repmat(verify.issue(""), 0, 1);
expands = any(cellfun(@(n) iskind(n, "CELL") || iskind(n, "DOT"), call.nodes));
required = 0;
for k = 1:numel(posNames)
    d = sig.inputs(string([sig.inputs.name]) == posNames(k) & string([sig.inputs.field]) == "");
    if isempty(d) || ~d(1).hasDefault
        required = k;
    end
end
if nPos < required && ~expands
    absent = posNames(nPos + 1:required);
    msg = sprintf("Call to '%s' passes %d input(s) but needs %d; missing %s. Pass a value for each, " + ...
                  "or give them defaults in the arguments block of '%s'.", ...
                  sig.name, nPos, required, strjoin("'" + absent + "'", ", "), sig.name);
    issues = verify.issue(file, [call.line call.column], "error", "types", "missingInput", msg);
end
end

function issues = nameValues(sig, call, nvStruct, file)
arguments (Input)
    sig (1,1) struct
    call (1,1) struct
    nvStruct (1,:) string
    file (1,1) string
end
arguments (Output)
    issues (:,1) struct
end
issues = repmat(verify.issue(""), 0, 1);
nvFields = reshape(string([sig.inputs(string([sig.inputs.field]) ~= "").field]), 1, []);
for jj = find(call.nvNames ~= "" & ~endsWith(call.nvNames, "#value"))
    name = call.nvNames(jj);
    pos = [lineno(call.nodes{jj}) charno(call.nodes{jj})];
    d = sig.inputs(string([sig.inputs.field]) == name);
    if isempty(d)
        hint = "'" + sig.name + "' takes no name-value arguments; remove it";
        if ~isempty(nvStruct)
            hint = "Use one of: " + strjoin(nvFields, ", ");
        end
        msg = sprintf("'%s' is not a name-value argument of '%s'. %s.", name, sig.name, hint);
        issues(end + 1, 1) = verify.issue(file, pos, "error", "types", "unknownNameValue", msg); %#ok<AGROW>
        continue
    end
    value = call.types{min(jj + double(~iskind(call.nodes{jj}, "NAMEVALUE")), numel(call.types))};
    label = sprintf("Name-value argument '%s' of '%s'", name, sig.name);
    issues = [issues; verify.types.compareValue(d(1), value, label, file, pos)]; %#ok<AGROW>
end
end
