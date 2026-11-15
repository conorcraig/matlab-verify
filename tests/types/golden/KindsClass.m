classdef KindsClass < handle
    properties (Constant)
        MAX_N = 3
    end
    properties
        Value (1,1) double = 0
    end
    methods (Abstract)
        r = absMethod(obj, x)
    end
    methods
        function obj = KindsClass(v)
            arguments
                v (1,1) double
            end
            obj.Value = v;
        end
        function set.Value(obj, v)
            obj.Value = v;
        end
    end
    methods (Static)
        function s = make()
            s = KindsClass(1);
        end
    end
end
