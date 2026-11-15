function key = baselineKey(s)
%BASELINEKEY Line-number-free identity of an issue, as stored in baselines.
arguments
    s (1,1) struct
end
arguments (Output)
    key (1,1) string
end
key = sprintf("%s: %s: [%s/%s] %s", s.file, s.severity, s.check, s.id, s.message);
end
