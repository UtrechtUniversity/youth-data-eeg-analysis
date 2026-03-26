function randomWs = bv_randomizeBinaryMatrices(Ws, m)
% Creates a given amount of randomized binary adjacency matrices based on
% input adjacency matrices
%
% usage:
%   [Wrandomized] = bv_randomizeWeightedMatrices(Ws, m)
%
% With Ws being the adjecency matrices with dim(chan * chan * subject)
% and m the amount of randomized network per W

randomWs = zeros([size(Ws) m]);
counter = 0;
n = size(Ws,3);
for iW = 1:n
    currW = Ws(:,:,iW);
    
    for j = 1:m 
        if isempty(nonzeros(currW))
            randomWs(:,:,iW,j) = zeros(size(currW));
        else
            randomWs(:,:,iW,j) = randomizer_bin_und(currW, 10);
        end
        counter = counter + 1;
    end  
 
end

fprintf('\n')