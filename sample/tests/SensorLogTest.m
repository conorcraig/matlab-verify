classdef (TestTags = {'fast'}) SensorLogTest < matlab.unittest.TestCase
    %SENSORLOGTEST Unit tests for SensorLog.

    methods (Test)

        function startsEmpty(testCase)
            sensorLog = SensorLog("pump");
            testCase.verifyEqual(sensorLog.readingCount(), 0);
            testCase.verifyEqual(sensorLog.Name, "pump");
        end

        function keepsOnlyNewestReadings(testCase)
            sensorLog = SensorLog("pump");
            sensorLog.addReadings((1:SensorLog.MAX_READINGS + 5)');
            testCase.verifyEqual(sensorLog.readingCount(), SensorLog.MAX_READINGS);
            testCase.verifyEqual(sensorLog.Readings(1), 6);
        end

        function summarizeReportsPeaks(testCase)
            sensorLog = SensorLog("pump");
            sensorLog.addReadings([0; 0; 10; 0; 0; 0; 0]);
            summary = sensorLog.summarize(1);
            testCase.verifyEqual(summary.count, 7);
            testCase.verifyEqual(summary.peaks, 3);
            testCase.verifyEqual(summary.name, "pump");
        end

    end
end
