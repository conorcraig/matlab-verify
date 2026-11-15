function total = cleanNaming(values)
%CLEANNAMING Every name follows the default rules.
arguments (Input)
    values (1,:) double
end
arguments (Output)
    total (1,1) double
end
runningTotal = 0;
for k = 1:numel(values)
    runningTotal = addOne(runningTotal + values(k));
end
total = runningTotal;
end

function out = addOne(x)
arguments (Input)
    x (1,1) double
end
arguments (Output)
    out (1,1) double
end
out = x + 1;
end
