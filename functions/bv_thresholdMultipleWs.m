function [ AsTrh ] = bv_thresholdMultipleWs(As, propThr)

sz = size(As);
N = sz(1);
ndims = length(sz);

if ndims > 3
    extraDims = sz(3:end);
    nAsz = [sz(1) sz(2) prod(sz(3:end))];
    As = reshape(As, nAsz);
end

for i = 1:size(As,3)
    currA = As(:,:,i);
    if sum(isnan(currA(:))) == numel(currA)
        AsTrh(:,:,i) = currA;
    end
    AsTrh(:,:,i) = threshold_proportional(currA, propThr);
end

if ndims > 3
    AsTrh = reshape(AsTrh, sz);
end