function issues = naming(files, cfg)
%NAMING Naming rules (check name "naming"), configurable through cfg.naming.
%   functionPattern  regexp for function names       (default lowerCamelCase)
%   variablePattern  regexp for variable names       (default lowerCamelCase)
%   classPattern     regexp for class names          (default UpperCamelCase)
%   constantPattern  regexp for Constant properties  (default UPPER_SNAKE_CASE)
%   shadowing        no function/variable/class may shadow a MATLAB function or class (default true)
%   fileName         file name must match the primary function or class (default true)
%   allow            names exempt from every rule (default varargin, varargout, ans)
%   Constructors, set./get. accessors and class methods (which overload by
%   design) are exempt from the function rules.
arguments (Input)
    files (:,1) string
    cfg (1,1) struct
end
arguments (Output)
    issues (:,1) struct
end
opts = options(cfg);
issues = repmat(verify.issue(""), 0, 1);
for k = 1:numel(files)
    [tree, errMsg] = verify.mtree.parseFile(verify.absPath(files(k)));
    if errMsg == ""
        issues = [issues; checkFile(files(k), tree, opts)]; %#ok<AGROW>
    end
end
end

function opts = options(cfg)
arguments (Input)
    cfg (1,1) struct
end
arguments (Output)
    opts (1,1) struct
end
camel = "^[a-z][a-zA-Z0-9]*$";
opts = struct("functionPattern", camel, "variablePattern", camel, ...
              "classPattern", "^[A-Z][a-zA-Z0-9]*$", "constantPattern", "^[A-Z][A-Z0-9]*(_[A-Z0-9]+)*$", ...
              "shadowing", true, "fileName", true, "allow", ["varargin" "varargout" "ans"]);
if ~isfield(cfg, "naming")
    return
end
for f = reshape(string(fieldnames(cfg.naming)), 1, [])
    if isfield(opts, f) && islogical(opts.(f))
        opts.(f) = logical(cfg.naming.(f));
    elseif isfield(opts, f)
        opts.(f) = reshape(string(cfg.naming.(f)), 1, []);
    end
end
end

function issues = checkFile(file, tree, opts)
arguments (Input)
    file (1,1) string
    tree (1,1) mtree
    opts (1,1) struct
end
arguments (Output)
    issues (:,1) struct
end
fns = verify.mtree.functionList(tree, readlines(verify.absPath(file)));
issues = [fileNameIssues(file, tree, fns, opts); classIssues(file, tree, opts)];
for k = 1:numel(fns)
    issues = [issues; functionIssues(file, fns(k), opts)]; %#ok<AGROW>
    vars = verify.mtree.variables(fns(k).node);
    for jj = 1:numel(vars)
        issues = [issues; nameIssues(file, vars(jj), "Variable", "variablePattern", ...
                                     " in '" + fns(k).name + "'", opts)]; %#ok<AGROW>
    end
end
end

function issues = fileNameIssues(file, tree, fns, opts)
arguments (Input)
    file (1,1) string
    tree (1,1) mtree
    fns (:,1) struct
    opts (1,1) struct
end
arguments (Output)
    issues (:,1) struct
end
issues = repmat(verify.issue(""), 0, 1);
[~, base, ext] = fileparts(file);
declared = verify.mtree.className(tree);
kindLabel = "class";
primary = fns(string([fns.role]) == "primary");
if declared == "" && isscalar(primary)
    declared = primary.name;
    kindLabel = "function";
end
if ~opts.fileName || declared == "" || declared == string(base)
    return
end
msg = sprintf("File '%s%s' defines %s '%s'. Rename the file to '%s%s' or the %s to '%s' " + ...
              "so MATLAB resolves it.", base, ext, kindLabel, declared, declared, ext, kindLabel, base);
issues = verify.issue(file, [1 1], "error", "naming", "fileName", msg);
end

function issues = classIssues(file, tree, opts)
arguments (Input)
    file (1,1) string
    tree (1,1) mtree
    opts (1,1) struct
end
arguments (Output)
    issues (:,1) struct
end
issues = repmat(verify.issue(""), 0, 1);
name = verify.mtree.className(tree);
if name ~= ""
    entry = struct("name", name, "line", 1, "column", 1);
    issues = nameIssues(file, entry, "Class", "classPattern", "", opts);
end
consts = verify.mtree.constants(tree);
noShadow = opts;
noShadow.shadowing = false;
for k = 1:numel(consts)
    issues = [issues; nameIssues(file, consts(k), "Constant property", "constantPattern", "", ...
                                 noShadow)]; %#ok<AGROW>
end
end

function issues = functionIssues(file, rec, opts)
arguments (Input)
    file (1,1) string
    rec (1,1) struct
    opts (1,1) struct
end
arguments (Output)
    issues (:,1) struct
end
issues = repmat(verify.issue(""), 0, 1);
if rec.isConstructor || rec.isAccessor || rec.role == "method"
    return
end
entry = struct("name", rec.name, "line", rec.line, "column", rec.column);
if rec.role == "primary" && contains(file, "+")
    opts.shadowing = false;
end
issues = nameIssues(file, entry, "Function", "functionPattern", "", opts);
end

function issues = nameIssues(file, entry, kindLabel, patternField, where, opts)
arguments (Input)
    file (1,1) string
    entry (1,1) struct
    kindLabel (1,1) string
    patternField (1,1) string
    where (1,1) string
    opts (1,1) struct
end
arguments (Output)
    issues (:,1) struct
end
issues = repmat(verify.issue(""), 0, 1);
name = entry.name;
pos = [entry.line entry.column];
if any(name == opts.allow)
    return
end
rule = opts.(patternField);
if isempty(regexp(name, rule, "once"))
    id = extractBefore(patternField, "Pattern") + "Name";
    msg = sprintf("%s '%s'%s does not match %s. Rename it to '%s' and update its uses.", ...
                  kindLabel, name, where, rule, suggest(name, patternField));
    issues(end + 1, 1) = verify.issue(file, pos, "error", "naming", id, msg);
end
if opts.shadowing && verify.mtree.shadowsBuiltin(name)
    msg = sprintf("%s '%s'%s shadows the MATLAB function or class '%s' (%s). Rename it, e.g. '%sValue'.", ...
                  kindLabel, name, where, name, which(name), name);
    issues(end + 1, 1) = verify.issue(file, pos, "error", "naming", "shadowsBuiltin", msg);
end
end

function s = suggest(name, patternField)
arguments (Input)
    name (1,1) string
    patternField (1,1) string
end
arguments (Output)
    s (1,1) string
end
words = lower(string(regexp(name, "[A-Z]+(?![a-z])|[A-Z]?[a-z]+|\d+", "match")));
if isempty(words)
    s = name;
    return
end
cap = upper(extractBefore(words, 2)) + extractAfter(words, 1);
switch patternField
    case "constantPattern"
        s = upper(strjoin(words, "_"));
    case "classPattern"
        s = strjoin(cap, "");
    otherwise
        s = strjoin([words(1) cap(2:end)], "");
end
end
