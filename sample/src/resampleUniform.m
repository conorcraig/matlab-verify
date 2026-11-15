function [uniformTimes, uniformValues] = resampleUniform(sampleTimes, values, step)
%RESAMPLEUNIFORM Linearly resample (times, values) onto a uniform grid.
arguments
    sampleTimes (:,1) double {mustBeNonempty}
    values (:,1) double {mustBeNonempty}
    step (1,1) double {mustBePositive}
end
arguments (Output)
    uniformTimes (:,1) double
    uniformValues (:,1) double
end
if numel(sampleTimes) ~= numel(values)
    error("sample:sizeMismatch", "times and values must have the same number of elements.");
end
uniformTimes = (sampleTimes(1):step:sampleTimes(end))';
uniformValues = interp1(sampleTimes, values, uniformTimes, "linear");
end
