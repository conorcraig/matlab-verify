function smoothed = movingAverage(signal, window)
%MOVINGAVERAGE Trailing moving average; the first samples use a shorter window.
arguments
    signal (:,1) double
    window (1,1) double {mustBeInteger, mustBePositive} = 3
end
arguments (Output)
    smoothed (:,1) double
end
smoothed = movmean(signal, [window - 1, 0]);
end
