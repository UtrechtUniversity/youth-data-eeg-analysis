function BC = gr_calculateBetweennessCentrality(As, edgetype)

sz = size(As);
N = sz(1);
ndims = length(sz);

if ndims > 3
    extraDims = sz(3:end);
    nwsz = [sz(1) sz(2) prod(sz(3:end))];
    As = reshape(As, nwsz);
end

for i = 1:size(As,3)
    currA = As(:,:,i);
    
    switch edgetype
        case 'binary'
            tmpBC = betweenness_bin(currA);
            
        case 'weighted'
            currA = gr_normalizeW(currA);
            lengths = weight_conversion(currA, 'lengths');
            D = distance_wei( lengths );
            tmpBC = betweenness_wei(D);
        otherwise
            error('Unknown edgetype')
    end
    BC(:,i) = tmpBC./((N-1)*(N-2));
end

if ndims > 3
    BC = reshape(BC, [sz(1) extraDims]);
end
