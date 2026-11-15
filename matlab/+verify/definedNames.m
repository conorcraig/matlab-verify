function names = definedNames(file)
%DEFINEDNAMES Function and class names defined in one MATLAB file.
%   Unparseable files contribute no names; the parse check reports them.
arguments
    file (1,1) string
end
arguments (Output)
    names (:,1) string
end
names = strings(0, 1);
absFile = verify.absPath(file);
[tree, errMsg] = verify.mtree.parseFile(absFile);
if errMsg ~= ""
    return
end
records = verify.mtree.functionList(tree, readlines(absFile));
for k = 1:numel(records)
    names(end + 1, 1) = records(k).name; %#ok<AGROW>
end
cls = verify.mtree.className(tree);
if cls ~= ""
    names(end + 1, 1) = cls; %#ok<AGROW>
end
names = unique(names(strlength(names) > 0));
end
