classdef (TestTags = {'fast'}) FailingTest < matlab.unittest.TestCase
    %FAILINGTEST A fast-tagged test that fails.

    methods (Test)

        function sumIsWrong(testCase)
            testCase.verifyEqual(sum([1 2 3]), 7);
        end

    end
end
