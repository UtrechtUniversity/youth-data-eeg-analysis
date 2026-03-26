function [W,i] = bv_sortMatrixBasedOnCommunities(W)

ci = community_louvain(normalizeW(W));
W2 = W + repmat(ci, [1 size(W,1)]);
[~,i] = sort(mean(W2,2), 'descend');
W = W(i,i);