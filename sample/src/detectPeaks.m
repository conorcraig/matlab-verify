function peakIndices = detectPeaks(signal, threshold)
%DETECTPEAKS Indices of strict local maxima at or above THRESHOLD.
arguments
    signal (:,1) double
    threshold (1,1) double = 0
end
arguments (Output)
    peakIndices (:,1) double
end
if numel(signal) < 3
    peakIndices = zeros(0, 1);
    return
end
inner = 2:numel(signal) - 1;
isPeak = signal(inner) > signal(inner - 1) & signal(inner) > signal(inner + 1) ...
    & signal(inner) >= threshold;
peakIndices = inner(isPeak)';
end
