function [Ci, Q] = gr_calculateQModularity(Ws, edgeType)

sz = size(Ws);
N = sz(1);
ndims = length(sz);

if ndims > 3
    extraDims = sz(3:end);
    nwsz = [sz(1) sz(2) prod(sz(3:end))];
    Ws = reshape(Ws, nwsz);
end

m = size(Ws, 3);

Ci = zeros(N, m);
Q = zeros(1, m);

for i = 1:m
    W = Ws(:,:,i);
    % find removed channels
    rmChannels = sum(isnan(W)) == (size(W,2) - 1);
    if ~sum(rmChannels)==0
        
        Ci(:,i) = nan(1,n);
        Q(i) = NaN;
        continue
        
    end
    
    switch edgeType
        case 'binary'
            [Ci(:,i),Q(i)] = community_louvain(W);
        case 'weighted'
            Wnrm = gr_normalizeW(W);
            [Ci(:,i),Q(i)] = community_louvain(Wnrm);
    end
end

if ndims > 3
    Q = reshape(Q, extraDims);
    Ci = reshape(Ci, [N, extraDims]);
end




