function result = cycleSecond(depth)
%CYCLESECOND Calls cycleFirst, closing the cycle.
arguments
    depth (1,1) double
end
arguments (Output)
    result (1,1) double
end
if depth <= 0
    result = 0;
else
    result = 2 + cycleFirst(depth - 1);
end
end
