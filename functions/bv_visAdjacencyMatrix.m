function bv_visAdjacencyMatrix(As, labels)

addpath('~/MyScripts/')
if nargin < 2
    labels = [];
end
if ~exist('numSubplots')
    error('Please add numSubplots to your path')
end

figure;
m = size(As,3);
s = numSubplots(m);
for i = 1:m
    subplot(s(1),s(2), i)
    imagesc(As(:,:,i))
    
    bv_autoCorrSettings(gca, labels)
    
end

