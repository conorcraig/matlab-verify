classdef ExemptTest < matlab.unittest.TestCase
    %EXEMPTTEST Test methods cannot have arguments blocks; types must not ask for them.
    methods (TestMethodSetup)
        function prepare(testCase)
            testCase.assertTrue(true);
        end
    end
    methods (Test)
        function addsNumbers(testCase)
            testCase.verifyEqual(1 + 1, 2);
        end
    end
end
