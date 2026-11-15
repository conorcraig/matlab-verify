classdef (TestTags = {'fast'}) TypesTest < matlab.unittest.TestCase
    %TYPESTEST Every types finding fires on its fixture line; clean files pass.

    properties (Constant)
        FIXTURES = fullfile(fileparts(mfilename("fullpath")), "fixtures")
    end

    methods (TestClassSetup)
        function addSource(testCase)
            root = fileparts(fileparts(fileparts(mfilename("fullpath"))));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(root, "matlab")));
        end
    end

    methods (Test)
        function cleanFilesPass(testCase)
            issues = TypesTest.check(["cleanTypes.m" "ExemptTest.m"]);
            testCase.verifyEmpty(issues, strjoin(string({issues.message}), newline));
        end

        function policyFindings(testCase)
            expected = ["1 noInputBlock" "1 noOutputBlock" "5 noOutputBlock" "12 undeclared" ...
                "14 noSize" "15 noClass"];
            testCase.verifyEqual(TypesTest.keys(TypesTest.check("policyBad.m")), sort(expected));
        end

        function callSiteFindings(testCase)
            expected = ["5 wrongClass" "6 wrongSize" "7 wrongRank" "8 tooManyInputs" "9 missingInput" ...
                "10 unknownNameValue" "12 wrongClass" "14 wrongSize" "15 tooManyInputs" "36 wrongClass"];
            testCase.verifyEqual(TypesTest.keys(TypesTest.check("callsBad.m")), sort(expected));
        end

        function messagesSayHowToFix(testCase)
            issues = TypesTest.check(["policyBad.m" "callsBad.m"]);
            for k = 1:numel(issues)
                testCase.verifyMatches(issues(k).message, "(Add|Declare|Pass|Remove|Use|Reshape)", ...
                    issues(k).id);
                testCase.verifyEqual(issues(k).check, "types");
            end
        end

        function countsUncheckedCalls(testCase)
            [~, stats] = verify.checks.types(fullfile(TypesTest.FIXTURES, "callsBad.m"), ...
                struct("types", struct("summary", false)));
            testCase.verifyGreaterThan(stats.checked, 10);
            testCase.verifyGreaterThanOrEqual(stats.unchecked, 0);
        end

        function measuredConversionRules(testCase)
            testCase.verifyEqual(verify.types.classCompat("double", "string"), "ok");
            testCase.verifyEqual(verify.types.classCompat("single", "string"), "conflict");
            testCase.verifyEqual(verify.types.classCompat("char", "logical"), "conflict");
            testCase.verifyEqual(verify.types.sizeCompat(["1" "3"], ["3" "1"]), "ok");
            testCase.verifyEqual(verify.types.sizeCompat(["2" "2"], ["1" "1"]), "ok");
            testCase.verifyEqual(verify.types.sizeCompat([":" ":"], ["2" "2" "2"]), "wrongRank");
            testCase.verifyEqual(verify.types.sizeCompat(["1" "3"], ["1" "0"]), "wrongSize");
        end
    end

    methods (Static)
        function issues = check(names)
            files = fullfile(TypesTest.FIXTURES, names(:));
            issues = verify.checks.types(files, struct("types", struct("summary", false)));
        end

        function k = keys(issues)
            k = sort(string([issues.line]) + " " + [issues.id]);
        end
    end
end
