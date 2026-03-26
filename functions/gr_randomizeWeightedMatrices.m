function Wrandomized = gr_randomizeWeightedMatrices(Ws, m)
% Creates a given amount of randomized weighted adjacency matrices based on
% input adjacency matrices
%
% usage:
%   [Wrandomized] = bv_randomizeWeightedMatrices(Ws, m)
%
% inputs
%  Ws:      adjacency matrices with dim(chan * chan * subject)
%  m:       amount of randomized networks per adjacency matrix

addpath('~/MyScripts/')

n = size(Ws,3);
Wrandomized = zeros([size(Ws,1) size(Ws,2) n m]);
rng(100000)
counter = 0;
updateWaitbar = waitbarParfor(n, 'randomize matrices');
parfor iS = 1:n
    currW = Ws(:,:,iS);

    for iM = 1:m
        weights = squareform(currW);
        I = find(weights > 0);
        for j = 1:10
            weights(I) = weights(I(randperm(numel(I))));
            I = find(weights > 0);
        end
        
        Wrandomized(:,:,iS,iM) = squareform(weights);
    end
    updateWaitbar()
end