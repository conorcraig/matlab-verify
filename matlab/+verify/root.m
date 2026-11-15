function r = root()
%ROOT Repository root (parent of the matlab/ folder holding +verify).
arguments (Output)
    r (1,1) string
end
here = fileparts(mfilename("fullpath"));
r = string(fileparts(fileparts(here)));
end
