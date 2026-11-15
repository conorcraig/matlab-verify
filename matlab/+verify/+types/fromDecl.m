function t = fromDecl(d)
%FROMDECL Abstract value guaranteed by an arguments-block declaration (":" -> "?").
arguments (Input)
    d (1,1) struct
end
arguments (Output)
    t (1,1) struct
end
dims = d.dims;
dims(dims == ":") = "?";
t = verify.types.make(d.cls, dims);
end
