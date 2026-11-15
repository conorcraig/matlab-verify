function total = badlySpaced(values)
%BADLYSPACED Formatting MISS_HIT rejects (and `just fix` repairs).
arguments
    values (:,1) double
end
arguments (Output)
    total (1,1) double
end
total=0;
for k = 1:numel(values)
      total = total+values(k);
end
end
