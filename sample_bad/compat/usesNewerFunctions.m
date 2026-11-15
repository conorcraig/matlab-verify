function inputCount = usesNewerFunctions(values)
%USESNEWERFUNCTIONS Uses a validator and a function added after R2024a.
arguments
    values {mustBeRow, mustBeNumeric}
end
arguments (Output)
    inputCount (1,1) double
end
info = metafunction("movingAverage");
inputCount = numel(info.Signature.Inputs) + numel(values);
end
