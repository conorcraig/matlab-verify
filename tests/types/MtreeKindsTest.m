classdef (TestTags = {'fast'}) MtreeKindsTest < matlab.unittest.TestCase
    %MTREEKINDSTEST Pin the undocumented mtree node kinds and links that verify.types/naming rely on.
    %   mtree has no compatibility promise. If a MATLAB release changes the
    %   tree, this fails first: review the diff against golden/*.golden.txt,
    %   adapt +verify/+mtree and +verify/+types, then regenerate the goldens
    %   with MtreeKindsTest.regenerate().

    properties (Constant)
        KINDS = ["FUNCTION" "ARGUMENTS" "ARGUMENT" "PROPTYPEDECL" "ATTRIBUTES" "ATTR" "ID" "FIELD" ...
            "INT" "DOUBLE" "STRING" "CHARVECTOR" "COLON" "LP" "CALL" "SUBSCR" "DOT" "CELL" "NAMEVALUE" ...
            "EQUALS" "EXPR" "PRINT" "DCALL" "IF" "IFHEAD" "ELSEIF" "ELSE" "FOR" "WHILE" "BREAK" "SWITCH" ...
            "CASE" "OTHERWISE" "TRY" "GLOBAL" "LB" "LC" "ROW" "ANON" "ANONID" "AT" "NOT" "UMINUS" "TRANS" ...
            "PLUS" "MUL" "LT" "GT" "ANDAND" "PARENS" "CLASSDEF" "PROPERTIES" "METHODS" "PROTO"]
        LINKS = ["Fname" "Ins" "Outs" "Arguments" "Attr" "Body" "ArgumentValidation" "VarName" "VarType" ...
            "VarDimensions" "VarValidators" "VarNamedField" "ArgumentInitialization" "Index" "Vector" ...
            "Try" "Catch" "CatchID" "Cexpr"]
    end

    methods (Static)
        function regenerate()
            for name = ["kindsFunction" "KindsClass"]
                writelines(MtreeKindsTest.dump(name), MtreeKindsTest.golden(name));
            end
        end

        function text = dump(name)
            file = fullfile(fileparts(mfilename("fullpath")), "golden", name + ".m");
            text = string(evalc("dumptree(mtree(char(file), '-file'))"));
            text = strip(splitlines(text), "right");
            text = text(text ~= "");
        end

        function path = golden(name)
            path = fullfile(fileparts(mfilename("fullpath")), "golden", name + ".golden.txt");
        end
    end

    methods (Test)
        function treesMatchGolden(testCase)
            for name = ["kindsFunction" "KindsClass"]
                expected = readlines(MtreeKindsTest.golden(name));
                expected = expected(expected ~= "");
                testCase.verifyEqual(MtreeKindsTest.dump(name), expected, ...
                    "mtree output for " + name + ".m changed; see the class help.");
            end
        end

        function pinnedKindsAndLinksPresent(testCase)
            text = strjoin([MtreeKindsTest.dump("kindsFunction"); MtreeKindsTest.dump("KindsClass")], newline);
            for k = unique(MtreeKindsTest.KINDS)
                testCase.verifyTrue(contains(text, ":  " + k + ":"), "missing node kind " + k);
            end
            for k = MtreeKindsTest.LINKS
                testCase.verifyTrue(contains(text, "*" + k + ":"), "missing link " + k);
            end
        end
    end
end
