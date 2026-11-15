function callsBad(m)
arguments (Input)
    m (3,3) double
end
target({1, 2}, 1);
target(m, 1);
target(ones(2, 2, 2), 1);
target([1 2 3], 1, 5);
target([1 2 3]);
target([1 2 3], 1, Mode = "fast");
s = makeLabel();
target(s, 1);
r = makeRow();
target(r, 1);
isempty(m, 1);
end

function target(v, k, opts)
arguments (Input)
    v (1,:) double
    k (1,1) double
    opts.Speed (1,1) double = 1
end
disp(v * k * opts.Speed);
end

function s = makeLabel()
arguments (Output)
    s (1,1) struct
end
s = struct("a", 1);
end

function r = makeRow()
arguments (Output)
    r (4,4) double
end
r = {1};
end
