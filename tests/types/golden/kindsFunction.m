function [out, n] = kindsFunction(x, opts) %#verify:no-arguments
arguments (Input)
    x (1,:) double {mustBeA(x, "double"), mustBePositive} = [1 2]
    opts.Name (1,1) string = "a"
end
arguments (Output)
    out (1,1) double
    n (1,:) char
end
z = zeros(3, numel(x));
w = helperFn(z', "s", Name = 'q');
[r, c] = size(z);
if r < 2 && c > 1
    out = -1.5
elseif ~isempty(w)
    out = (r * c);
else
    out = 0;
end
for k = 1:2:5
    z(k) = k;
end
while false
    break
end
switch c
    case 1
        s.a = {1, 'b'};
        s.a{2} = 3;
    otherwise
        s = struct();
end
try
    f = @(t) t + 1;
    g = @sin;
catch err
    global G
end
hold on
n = 'x';
end
