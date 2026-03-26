function [L, eff, rad] = gr_calculateBetweennessWs(Ws, edgeType)
% Function to calculate characteristic path length on multiple adjecency
% matrices. 
%
% usage:
%   [CPLs] = gr_calculatePathlengthWs(Ws, edgeType)
%
% With Ws being the adjencency matrices with dim(chan * chan * subject)
% and edgeType options 'weighted', 'binary' and 'mst' (for minimum spanning
% tree graphs)

n = size(Ws, 1);
m = size(Ws, 3);

L = zeros(1, size(Ws,3));
for i = 1:m
    W = Ws(:,:,i);
    % find removed channels
    rmChannels = sum(isnan(W)) == 31;
    if ~isempty(find(rmChannels))
        
        W(rmChannels,:) = [];
        W(:,rmChannels) = [];
        
    end
    
    switch edgeType
        case 'binary'
            D = distance_bin( W );
            [L(i), eff(i), ~, rad(i)] = charpath( D );
            
        case 'weighted'
            lengths = weight_conversion( W, 'lengths' );
            D = distance_wei( lengths );
            L(i) = mean( squareform(D) );
            
        case 'mst'
            D = distance_wei( W );
            [L(i), eff(i), ~, rad(i)] = charpath( D );
            
        otherwise
            error('unknown adjacency matrix type')
            
    end
end
