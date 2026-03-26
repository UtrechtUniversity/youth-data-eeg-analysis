function [C] = gr_calculateClusteringWs(As, edgeType)
% Function to calculate clustering coefficient on multiple adjecency
% matrices. 
%
% usage:
%   [Cs] = gr_calculateClusteringAs(As, edgeType)
%
% inputs:
%   As:         adjacency matrices with dim( nchans * nchans * nsubjects )
%   edgeType:   type of edges ('weighted', 'binary', or 'mst' (for minimum
%               spelling tree graphs))
%
% See also CLUSTERING_COEF_BU, CLUSTERING_COEF_WU
%

sz = size(As);
N = sz(1);
ndims = length(sz);

if ndims > 3
    extraDims = sz(3:end);
    nAsz = [sz(1) sz(2) prod(sz(3:end))];
    As = reshape(As, nAsz);
end

m = size(As, 3);
C = zeros(1, m);
for i = 1:m
    A = As(:,:,i);
    
    % find removed channels
    rmChannels = (nansum(A)==0);
    if ~isempty(rmChannels)
        
        A(rmChannels,:) = [];
        A(:,rmChannels) = [];
        
    end
    
    A(isnan(A)) = 0;
    
    if isempty(A)
        C(i) = NaN;
        continue
    end
    
    switch edgeType
        case 'binary'
            C(i) = mean(clustering_coef_bu(A));
        case 'weighted'
            Anrm = gr_normalizeW(A);
            C(i) = mean(clustering_coef_wu(Anrm));
        case 'mst'
            Anrm = double(A>0);
            C(i) = mean(clustering_coef_bu(Anrm));
    end
end

if ndims > 3
    C = reshape(C, [extraDims]);
end
