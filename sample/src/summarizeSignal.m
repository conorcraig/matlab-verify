function stats = summarizeSignal(signal, opts)
%SUMMARIZESIGNAL Smoothed signal statistics and peak locations.
arguments
    signal (:,1) double
    opts.Window (1,1) double {mustBeInteger, mustBePositive} = 3
    opts.Threshold (1,1) double = 1
end
arguments (Output)
    stats (1,1) struct
end
smoothed = movingAverage(signal, opts.Window);
scores = normalizeSignal(smoothed);
stats = struct( ...
               "count", numel(signal), ...
               "mean", mean(signal), ...
               "smoothedMax", max([smoothed; -Inf]), ...
               "peaks", detectPeaks(scores, opts.Threshold));
end
