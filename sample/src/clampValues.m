function clamped = clampValues(values, lowerBound, upperBound)
%CLAMPVALUES Limit VALUES to the closed interval [lowerBound, upperBound].
arguments
    values (:,1) double
    lowerBound (1,1) double
    upperBound (1,1) double {mustBeGreaterThanOrEqual(upperBound, lowerBound)}
end
arguments (Output)
    clamped (:,1) double
end
clamped = min(max(values, lowerBound), upperBound);
end
