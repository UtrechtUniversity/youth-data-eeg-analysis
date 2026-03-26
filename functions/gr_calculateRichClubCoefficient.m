function [k_RC, k_RC_nrm, m_rand_k_RC] = gr_calculateRichClubCoefficient(Ws, edgeType)
% Function to calculate rich club coefficients of adjacency matrices
% matrices.
%
%  usage:
%   [SWPs, delta_Cs, delta_Ls] = gr_calculateSmallworldPropensityWs(Ws)
%
% with the following necessary inputs:
%  Ws:          adjacency matrix with dim(chan x chan x subject)
%  edgeType:    'weighted', 'binary', 'mst'
%
% and the following options inputs:
%  randWs:      randomized Ws based on input Ws with dim (chan x chan x subject x nrandomizations)
%  Cs:          earlier calculated clustering coefficients for all Ws
%  CPL:         earlier calculated characteristic path lengths for all Ws
%
% If options inputs are not given, they will be calculated in the function,
% which makes the function take longer.

n = size(Ws, 1);
m = size(Ws, 3);
nrand = 10;

k = n-1;
for i = 1:m
    currW = Ws(:,:,i);
    rand_k_RC = zeros(m, nrand, k);
    
    switch edgeType
        case 'weighted'
            k_RC(:,i) = rich_club_wu(currW,k);
            evalc('randWs = squeeze(gr_randomizeWeightedMatrices(currW, nrand));');
            for j = 1:nrand
                currWRand = randWs(:,:,j);
                rand_k_RC(i,j,:) = rich_club_wu(currWRand,k);
            end
        case 'binary'
            k_RC(:,i) = rich_club_bu(currW,k);
            for j = 1:nrand
                randWs(:,:,j) = randmio_und(currW, 10);
            end
            for j = 1:nrand
                currWRand = randWs(:,:,j);
                rand_k_RC(i,j,:) = rich_club_bu(currWRand,k);
            end
        otherwise
            error('Unknown edgetype %s', edgeType)
    end
    
    m_rand_k_RC(:,i) = squeeze(nanmean(rand_k_RC(i,:,:)));
    k_RC_nrm(:,i) = k_RC(:,i)./m_rand_k_RC(:,i);
end
