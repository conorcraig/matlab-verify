function r = root()
%ROOT Folder that holds config/verify.json, walking up from pwd.
%   The checker does not assume a fixed project folder name.
arguments (Output)
    r (1,1) string
end
r = string(pwd);
while ~isfile(fullfile(r, "config", "verify.json"))
    parent = string(fileparts(r));
    if parent == "" || parent == r
        error("verify:noConfig", "No config/verify.json found at or above '%s'.", string(pwd));
    end
    r = parent;
end
end
