function tf = shadowsBuiltin(name)
%SHADOWSBUILTIN True if NAME is a MATLAB built-in, or a function/class shipped under matlabroot.
%   Uses exist(name, 'builtin' | 'file' | 'class') and which(name); the
%   'file'/'class' forms ignore workspace variables. Results are cached.
arguments (Input)
    name (1,1) string
end
arguments (Output)
    tf (1,1) logical
end
persistent cache
if isempty(cache)
    cache = containers.Map("KeyType", "char", "ValueType", "logical");
end
key = char(name);
if isKey(cache, key)
    tf = cache(key);
    return
end
w = string(which(key));
shipped = startsWith(w, matlabroot) || startsWith(w, "built-in") || endsWith(w, "built-in method");
found = exist(key, "builtin") == 5 || any(exist(key, "file") == [2 3 6]) || exist(key, "class") == 8;
tf = found && shipped && sameCase(w, key);
cache(key) = tf;
end

function tf = sameCase(w, key)
%SAMECASE exist/which ignore case on Windows; require the resolved name to match exactly.
arguments (Input)
    w (1,1) string
    key (1,:) char
end
arguments (Output)
    tf (1,1) logical
end
resolved = regexprep(w, "\)$", "");
[~, base] = fileparts(resolved);
tf = startsWith(w, key + " ") || string(base) == key;
end
