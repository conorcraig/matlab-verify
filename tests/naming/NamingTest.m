classdef (TestTags = {'fast'}) NamingTest < matlab.unittest.TestCase
    %NAMINGTEST Every naming finding fires on its fixture line; clean files pass.

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
            issues = NamingTest.check(["cleanNaming.m" "CleanCounter.m"], struct());
            testCase.verifyEmpty(issues, strjoin(string({issues.message}), newline));
        end

        function functionAndVariableFindings(testCase)
            expected = ["1 fileName" "1 functionName" "2 variableName" "3 shadowsBuiltin" "8 functionName"];
            testCase.verifyEqual(NamingTest.keys(NamingTest.check("badNaming.m", struct())), sort(expected));
        end

        function classAndConstantFindings(testCase)
            expected = ["1 className" "3 constantName"];
            testCase.verifyEqual(NamingTest.keys(NamingTest.check("bad_counter.m", struct())), sort(expected));
        end

        function rulesAreConfigurable(testCase)
            cfg = struct("functionPattern", "^[A-Za-z_]+$", "variablePattern", "^[A-Za-z_]+$", ...
                "shadowing", false, "fileName", false);
            testCase.verifyEmpty(NamingTest.check("badNaming.m", cfg));
        end

        function suggestsAFix(testCase)
            issues = NamingTest.check("badNaming.m", struct());
            messages = string({issues.message});
            testCase.verifyTrue(any(contains(messages, "Rename it to 'myVar'")));
            testCase.verifyTrue(any(contains(messages, "Rename it to 'doThing'")));
        end
    end

    methods (Static)
        function issues = check(names, namingCfg)
            files = fullfile(NamingTest.FIXTURES, names(:));
            issues = verify.checks.naming(files, struct("naming", namingCfg));
        end

        function k = keys(issues)
            k = sort(string([issues.line]) + " " + [issues.id]);
        end
    end
end
