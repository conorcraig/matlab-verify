function s = issue(file, position, severity, check, id, message)
%ISSUE Build one issue struct in the contract shape.
%   POSITION is [line column]; use [0 0] when unknown.
arguments
    file (1,1) string
    position (1,2) double = [0 0]
    severity (1,1) string = "error"
    check (1,1) string = ""
    id (1,1) string = ""
    message (1,1) string = ""
end
arguments (Output)
    s (1,1) struct
end
s = struct('file', file, 'line', position(1), 'column', position(2), ...
           'severity', severity, 'check', check, 'id', id, 'message', message);
end
