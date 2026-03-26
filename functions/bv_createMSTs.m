function msts = bv_createMSTs(As)

sz = size(As);
ndims = length(sz);

if ndims > 3
    extraDims = sz(3:end);
    nwsz = [sz(1) sz(2) prod(sz(3:end))];
    As = reshape(As, nwsz);
end
    
m = size(As, 3);

for i = 1:m
    A = As(:,:,i);
    D = weight_conversion(A, 'lengths');
    msts(:,:,i) = minSpanTree(sparse(D));
end

if ndims > 3
    msts = reshape(msts, sz);
end


