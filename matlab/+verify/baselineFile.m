function f = baselineFile(check, root)
%BASELINEFILE Path of baselines/<check>.txt.
arguments
    check (1,1) string
    root (1,1) string = verify.root()
end
arguments (Output)
    f (1,1) string
end
f = string(fullfile(root, "baselines", check + ".txt"));
end
