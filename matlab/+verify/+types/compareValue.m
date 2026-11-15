function issues = compareValue(d, t, label, file, pos)
%COMPAREVALUE Report when abstract value T cannot satisfy declaration D.
%   Uses the measured conversion rules in classCompat/sizeCompat, and, when
%   no class is declared, the mustBeNumeric / mustBeText validators.
arguments (Input)
    d (1,1) struct
    t (1,1) struct
    label (1,1) string
    file (1,1) string
    pos (1,2) double
end
arguments (Output)
    issues (:,1) struct
end
issues = repmat(verify.issue(""), 0, 1);
got = verify.types.describe(t);
expected = d.cls;
bad = expected ~= "" && verify.types.classCompat(expected, t.cls) == "conflict";
if expected == ""
    [bad, expected] = failsValidator(d.validators, t.cls);
end
if bad
    msg = sprintf("%s must be %s but gets %s. Pass a %s value (convert it first if needed) " + ...
                  "or change the declaration.", label, expected, got, expected);
    issues(end + 1, 1) = verify.issue(file, pos, "error", "types", "wrongClass", msg);
end
status = verify.types.sizeCompat(d.dims, t.dims);
if any(status == ["wrongSize" "wrongRank"])
    aspect = "size";
    if status == "wrongRank"
        aspect = "number of dimensions";
    end
    msg = sprintf("%s must have size (%s) but gets %s; the %s cannot match. " + ...
                  "Reshape or index the value, or change the declared size.", ...
                  label, strjoin(d.dims, ","), got, aspect);
    issues(end + 1, 1) = verify.issue(file, pos, "error", "types", status, msg);
end
end

function [bad, expected] = failsValidator(validators, actual)
arguments (Input)
    validators (1,:) string
    actual (1,1) string
end
arguments (Output)
    bad (1,1) logical
    expected (1,1) string
end
nonNumeric = ["char" "string" "cell" "struct" "logical" "function_handle"];
numericOrLogical = ["double" "single" "logical" "int8" "int16" "int32" "int64" ...
                    "uint8" "uint16" "uint32" "uint64" "struct" "function_handle"];
bad = false;
expected = "";
if any(validators == "mustBeNumeric") && any(actual == nonNumeric)
    bad = true;
    expected = "numeric (mustBeNumeric)";
elseif any(validators == "mustBeText") && any(actual == numericOrLogical)
    bad = true;
    expected = "text (mustBeText)";
end
end
