function dims = broadcast(a, b)
%BROADCAST Result shape of an elementwise operation on shapes A and B.
%   Scalars take the other operand's shape; otherwise dimensions combine
%   pairwise (equal kept, a 1 yields the other, anything else "?").
%   Adapted from Mc2For's elementwise shape-propagation equation
%   (github.com/Sable/Mc2For, Apache-2.0).
arguments (Input)
    a (1,:) string
    b (1,:) string
end
arguments (Output)
    dims (1,:) string
end
if ~isempty(a) && all(a == "1")
    dims = b;
    return
end
if ~isempty(b) && all(b == "1")
    dims = a;
    return
end
dims = strings(1, 0);
if isempty(a) || isempty(b)
    return
end
n = max(numel(a), numel(b));
a = [a repmat("1", 1, n - numel(a))];
b = [b repmat("1", 1, n - numel(b))];
dims = repmat("?", 1, n);
dims(a == b) = a(a == b);
dims(a == "1") = b(a == "1");
dims(b == "1") = a(b == "1");
end
