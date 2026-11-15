function total = cleanTypes(values, opts)
%CLEANTYPES Fully declared function whose calls all match their callees.
arguments (Input)
    values (1,:) double
    opts.Scale (1,1) double = 1
    opts.Label (1,1) string = "sum"
end
arguments (Output)
    total (1,1) double
end
grid = zeros(3, numel(values));
row = scaleRow(values, opts.Scale);
grid(1, :) = row;
n = size(grid, 1);
total = sum(row) + n;
label = describeTotal(total, Name = opts.Label);
fprintf("%s\n", label);
end

function out = scaleRow(row, factor)
arguments (Input)
    row (1,:) double
    factor (1,1) double = 1
end
arguments (Output)
    out (1,:) double
end
out = row * factor;
end

function text = describeTotal(total, opts)
arguments (Input)
    total (1,1) double
    opts.Name (1,1) string = "total"
end
arguments (Output)
    text (1,1) string
end
text = opts.Name + ": " + string(total);
end
