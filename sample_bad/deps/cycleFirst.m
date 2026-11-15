function result = cycleFirst(depth)
%CYCLEFIRST Calls cycleSecond, which calls back into cycleFirst.
arguments
    depth (1,1) double
end
arguments (Output)
    result (1,1) double
end
if depth <= 0
    result = 0;
else
    result = 1 + cycleSecond(depth - 1);
end
end
