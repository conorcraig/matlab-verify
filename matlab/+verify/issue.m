function s = issue(file, line, column, severity, check, id, message)
%ISSUE Build one issue struct in the contract shape.
arguments
    file (1,1) string
    line (1,1) double = 0
    column (1,1) double = 0
    severity (1,1) string = "error"
    check (1,1) string = ""
    id (1,1) string = ""
    message (1,1) string = ""
end
arguments (Output)
    s (1,1) struct
end
s = struct('file', file, 'line', line, 'column', column, ...
    'severity', severity, 'check', check, 'id', id, 'message', message);
end
