function tf = checkExists(name)
%CHECKEXISTS True if matlab/+verify/+checks/<name>.m exists.
arguments
    name (1,1) string
end
arguments (Output)
    tf (1,1) logical
end
tf = isfile(fullfile(fileparts(mfilename("fullpath")), "+checks", name + ".m"));
end
