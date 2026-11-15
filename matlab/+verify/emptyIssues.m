function s = emptyIssues()
%EMPTYISSUES 0x1 issue struct array with the contract fields.
arguments (Output)
    s (:,1) struct
end
s = repmat(verify.issue(""), 0, 1);
end
