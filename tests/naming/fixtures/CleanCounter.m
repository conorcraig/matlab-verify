classdef CleanCounter < handle
    %CLEANCOUNTER Class, constant, method and variable names all follow the rules.
    properties (Constant)
        MAX_COUNT = 10
    end
    properties
        Count (1,1) double = 0
    end
    methods
        function increment(obj)
            arguments
                obj (1,1) CleanCounter
            end
            nextCount = min(obj.Count + 1, CleanCounter.MAX_COUNT);
            obj.Count = nextCount;
        end
    end
end
