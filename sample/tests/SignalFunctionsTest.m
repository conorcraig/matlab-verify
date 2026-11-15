classdef (TestTags = {'fast'}) SignalFunctionsTest < matlab.unittest.TestCase
    %SIGNALFUNCTIONSTEST Unit tests for the signal helper functions.

    methods (Test)
        function movingAverageUsesTrailingWindow(testCase)
            testCase.verifyEqual(movingAverage([3; 6; 9; 12], 2), [3; 4.5; 7.5; 10.5]);
        end

        function normalizeSignalHandlesConstantInput(testCase)
            testCase.verifyEqual(normalizeSignal([5; 5; 5]), zeros(3, 1));
        end

        function normalizeSignalHasUnitSpread(testCase)
            normalized = normalizeSignal([1; 2; 3; 4]);
            testCase.verifyEqual(std(normalized), 1, AbsTol=1e-12);
            testCase.verifyEqual(mean(normalized), 0, AbsTol=1e-12);
        end

        function detectPeaksFindsLocalMaxima(testCase)
            testCase.verifyEqual(detectPeaks([0; 2; 0; 1; 0; 3; 0], 1.5), [2; 6]);
        end

        function clampValuesLimitsRange(testCase)
            testCase.verifyEqual(clampValues([-5; 0; 5], -1, 1), [-1; 0; 1]);
        end

        function resampleUniformInterpolates(testCase)
            [times, values] = resampleUniform([0; 2], [0; 4], 1);
            testCase.verifyEqual(times, [0; 1; 2]);
            testCase.verifyEqual(values, [0; 2; 4]);
        end
    end
end
