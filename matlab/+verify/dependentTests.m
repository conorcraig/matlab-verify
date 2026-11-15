function testFiles = dependentTests(files)
%DEPENDENTTESTS Tests to run for the selected file set.
%   Selected files that are themselves tests are kept. Other candidates come
%   from git grep of the function and class names the selected files define.
%   A candidate stays only when it is a test and
%   matlab.codetools.requiredFilesAndProducts(candidate, 'toponly')
%   intersects the selected set. That call is never made on the whole repo.
arguments
    files (:,1) string
end
arguments (Output)
    testFiles (:,1) string
end
files = unique(files(files ~= ""));
% Callers resolve names only after these folders are on the path.
verify.addSourcePaths(files);
selected = foldPaths(files);
testFiles = strings(0, 1);
for f = reshape(files, 1, [])
    if verify.isTestFile(f)
        testFiles(end + 1, 1) = verify.relPath(f); %#ok<AGROW>
    end
end
names = strings(0, 1);
for f = reshape(files, 1, [])
    names = [names; verify.definedNames(f)]; %#ok<AGROW>
end
candidates = verify.gitGrep(names);
for c = reshape(candidates, 1, [])
    rel = verify.relPath(c);
    if any(testFiles == rel) || ~verify.isTestFile(rel)
        continue
    end
    if dependsOnSelected(rel, selected)
        testFiles(end + 1, 1) = rel; %#ok<AGROW>
    end
end
testFiles = unique(testFiles);
end

function tf = dependsOnSelected(testFile, selected)
arguments
    testFile (1,1) string
    selected (:,1) string
end
arguments (Output)
    tf (1,1) logical
end
tf = false;
testPath = char(verify.absPath(testFile));
try
    [required, ~] = matlab.codetools.requiredFilesAndProducts(testPath, "toponly");
catch err
    if string(err.identifier) == "MATLAB:depfun:req:BadSyntax"
        return
    end
    rethrow(err);
end
tf = any(ismember(foldPaths(string(required(:))), selected));
end

function folded = foldPaths(paths)
arguments
    paths (:,1) string
end
arguments (Output)
    folded (:,1) string
end
folded = strings(0, 1);
for p = reshape(paths, 1, [])
    if p == ""
        continue
    end
    folded(end + 1, 1) = lower(replace(verify.absPath(p), "\", "/")); %#ok<AGROW>
end
end
