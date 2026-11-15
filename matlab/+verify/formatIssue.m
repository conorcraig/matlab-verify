function issueLine = formatIssue(s)
%FORMATISSUE "file:line:col: severity: [check/id] message"
arguments
    s (1,1) struct
end
arguments (Output)
    issueLine (1,1) string
end
issueLine = sprintf("%s:%d:%d: %s: [%s/%s] %s", s.file, s.line, s.column, s.severity, s.check, s.id, s.message);
end
