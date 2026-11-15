function s = issue(file, line, column, severity, check, id, message)
%ISSUE Build one issue struct in the contract shape.
arguments
    file string
    line double = 0
    column double = 0
    severity string = "error"
    check string = ""
    id string = ""
    message string = ""
end
s = struct('file', file, 'line', line, 'column', column, ...
    'severity', severity, 'check', check, 'id', id, 'message', message);
end
