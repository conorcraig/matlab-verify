function tf = isTestFile(file)
%ISTESTFILE True when FILE is a MATLAB test.
%   A test subclasses matlab.unittest.TestCase, calls functiontests, or
%   declares a methods block with the Test attribute.
arguments
    file (1,1) string
end
arguments (Output)
    tf (1,1) logical
end
body = fileread(verify.absPath(file));
classTest = ~isempty(regexp(body, classPattern(), "once", "lineanchors"));
fnTests = ~isempty(regexp(body, functiontestsPattern(), "once", "lineanchors"));
methodTest = ~isempty(regexp(body, methodPattern(), "once", "lineanchors"));
tf = classTest || fnTests || methodTest;
end

function pat = classPattern()
%CLASSPATTERN classdef that derives from matlab.unittest.TestCase.
arguments (Output)
    pat (1,1) string
end
pat = "^\s*classdef[^\n]*<\s*matlab\.unittest\.TestCase\>";
end

function pat = functiontestsPattern()
%FUNCTIONTESTSPATTERN A functiontests call, with or without an assignment.
arguments (Output)
    pat (1,1) string
end
pat = "^\s*(?:[A-Za-z]\w*\s*=\s*)?functiontests\s*\(";
end

function pat = methodPattern()
%METHODPATTERN methods block whose attributes include Test, not TestMethodSetup.
arguments (Output)
    pat (1,1) string
end
pat = "^\s*methods\s*\([^)\n]*\<Test\>";
end
