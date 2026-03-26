function lambdas = gr_calculateNormalizedPathLength(As, edgeType)

sz = size(As);
N = sz(1);
ndims = length(sz);

if ndims > 3
    extraDims = sz(3:end);
    nAsz = [sz(1) sz(2) prod(sz(3:end))];
    As = reshape(As, nAsz);
end


switch edgeType
    case 'weighted'
        randAs = gr_randomizeWeightedMatrices(As, 10);
    case {'binary', 'mst'}
        evalc('randAs = bv_randomizeBinaryMatrices(As, 10);');
    otherwise
        error('unknown edgeType')
end

Ls = gr_calculatePathlengthWs(As, edgeType);
randLs = gr_calculatePathlengthWs(randAs, edgeType);

lambdas = nanmean(Ls' ./ randLs,2);

if ndims > 3
    lambdas = reshape(lambdas, extraDims);
end