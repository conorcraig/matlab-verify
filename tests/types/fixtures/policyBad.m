function result = policyBad(a, b)
result = a + b;
end

function out = noOutputBlock(x)
arguments (Input)
    x (1,1) double
end
out = x;
end

function out = partial(x, y, z)
arguments (Input)
    x double
    y (1,1)
end
arguments (Output)
    out (1,1) double
end
out = x + y + z;
end

function skipped(x) %#verify:no-arguments
disp(x);
end

function noInputsIsFine()
disp("ok");
end
