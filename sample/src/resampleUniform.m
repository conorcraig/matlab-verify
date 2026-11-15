function [uniformTimes, uniformValues] = resampleUniform(times, values, step)
%RESAMPLEUNIFORM Linearly resample (times, values) onto a uniform grid.
arguments
    times (:,1) double {mustBeNonempty}
    values (:,1) double {mustBeNonempty}
    step (1,1) double {mustBePositive}
end
arguments (Output)
    uniformTimes (:,1) double
    uniformValues (:,1) double
end
if numel(times) ~= numel(values)
    error("sample:sizeMismatch", "times and values must have the same number of elements.");
end
uniformTimes = (times(1):step:times(end))';
uniformValues = interp1(times, values, uniformTimes, "linear");
end
