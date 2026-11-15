function usesCoderProduct(entryPoint)
%USESCODERPRODUCT Depends on MATLAB Coder, which is not in deps.allowedProducts.
arguments
    entryPoint (1,1) string
end
codegen(entryPoint);
end
