classdef SensorLog < handle
    %SENSORLOG Bounded log of readings from one named sensor.

    properties (Constant)
        MAX_READINGS = 10000
    end

    properties (SetAccess = private)
        Name (1,1) string
        Readings (:,1) double = zeros(0, 1)
    end

    methods
        function obj = SensorLog(name)
            arguments
                name (1,1) string {mustBeNonzeroLengthText}
            end
            arguments (Output)
                obj (1,1) SensorLog
            end
            obj.Name = name;
        end

        function addReadings(obj, values)
            arguments
                obj (1,1) SensorLog
                values (:,1) double {mustBeFinite}
            end
            combined = [obj.Readings; values];
            obj.Readings = combined(max(1, end - SensorLog.MAX_READINGS + 1):end);
        end

        function n = readingCount(obj)
            arguments
                obj (1,1) SensorLog
            end
            arguments (Output)
                n (1,1) double
            end
            n = numel(obj.Readings);
        end

        function summary = summarize(obj, window)
            arguments
                obj (1,1) SensorLog
                window (1,1) double {mustBeInteger, mustBePositive} = 3
            end
            arguments (Output)
                summary (1,1) struct
            end
            summary = summarizeSignal(clampValues(obj.Readings, -1e6, 1e6), Window=window);
            summary.name = obj.Name;
        end
    end
end
