function cfg = loadConfig(root, reportDir)
%LOADCONFIG Decode config/verify.json and add the run's root and report dir.
arguments
    root (1,1) string
    reportDir (1,1) string
end
arguments (Output)
    cfg (1,1) struct
end
cfg = jsondecode(fileread(fullfile(root, "config", "verify.json")));
cfg.root = root;
cfg.reportDir = reportDir;
if cfg.reportDir == ""
    cfg.reportDir = string(fullfile(tempdir, "matlab-verify"));
end
if ~isfolder(cfg.reportDir)
    mkdir(cfg.reportDir);
end
end
