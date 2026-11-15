function issues = compat(files, cfg)
%COMPAT Ban calls to functions added after the minimum release.
%   The ban list is config/compat.json (release -> function names). Each
%   release becomes a Code Analyzer "functionCall" custom check, which also
%   catches validators in arguments blocks; the banned name is read back
%   from the source at the reported location.
arguments
    files (:,1) string
    cfg (1,1) struct
end
arguments (Output)
    issues (:,1) struct
end
spec = jsondecode(fileread(fullfile(cfg.root, "config", "compat.json")));
checks = struct();
for release = string(fieldnames(spec.banned))'
    names = string(spec.banned.(release));
    if ~isempty(names)
        checks.("compat" + release) = struct("rule", struct("template", "functionCall", "functionNames", names), ...
            "severity", "error", "messageText", "Added in " + release + ".", "enabled", true);
    end
end
config = struct("name", "matlab-verify compat", "baseConfiguration", "factory", "checks", checks);
configFile = string(fullfile(cfg.reportDir, "compat.codeAnalyzerConfiguration.json"));
writelines(jsonencode(config, PrettyPrint=true), configFile);

found = verify.codeAnalyzer(files, configFile, "compat");
issues = verify.emptyIssues();
for k = 1:numel(found)
    one = found(k);
    if startsWith(one.id, "compat")
        one.message = compatMessage(identifierAt(one.file, one.line, one.column), ...
            extractAfter(one.id, "compat"), spec);
        issues(end + 1, 1) = one; %#ok<AGROW>
    end
end
end

function message = compatMessage(name, release, spec)
arguments
    name (1,1) string
    release (1,1) string
    spec (1,1) struct
end
arguments (Output)
    message (1,1) string
end
advice = "Replace it with code that works in " + spec.minimumRelease;
if name ~= "" && isfield(spec.alternatives, name)
    advice = advice + ": " + spec.alternatives.(name);
end
message = sprintf("'%s' was added in %s but the minimum supported release is %s. %s.", ...
    name, release, spec.minimumRelease, advice);
end

function name = identifierAt(file, line, column)
arguments
    file (1,1) string
    line (1,1) double
    column (1,1) double
end
arguments (Output)
    name (1,1) string
end
name = "";
lines = readlines(verify.absPath(file));
if line >= 1 && line <= numel(lines)
    tok = regexp(extractAfter(lines(line), max(column - 1, 0)), "^[A-Za-z]\w*", "match", "once");
    if ~isempty(tok)
        name = string(tok);
    end
end
end
