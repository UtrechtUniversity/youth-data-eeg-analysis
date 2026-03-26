function diam = gr_calculateDiameter(As, edgetype)

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
            diam(i) = max(max(distance_bin(currA)));
            
        case 'weighted'
            lengths = weight_conversion(currA, 'lengths');
            D = distance_wei(lengths);
            diam(i) = max(max(D));

        otherwise
            error('Unknown edgetype')
    end
end

if ndims > 3
    diam = reshape(diam, [extraDims]);
end
