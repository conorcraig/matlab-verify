function normalized = normalizeSignal(signal)
%NORMALIZESIGNAL Zero-mean, unit-variance copy; constant signals become zeros.
arguments
    signal (:,1) double
end
arguments (Output)
    normalized (:,1) double
end
spread = std(signal);
if isempty(signal) || spread == 0
    normalized = zeros(size(signal));
    return
end
normalized = (signal - mean(signal)) / spread;
end
