function bv_showModules(Ws, threshold, chans)

if nargin < 2
    doThresh = 0
else
    doThresh = 1;
end

n = size(Ws,1);
m = size(Ws, 3);

for i = 1:m
    W = Ws(:,:,i);
    
    if doThresh
        W = threshold_proportional(W, threshold);
    end
    
    Ci = modularity_und(W);
    
    [ci_sort, isort] = sort(Ci);
    sortedW = W(isort, isort);
    
    clusterIndex = [0; find(diff(ci_sort)); 32] + 0.5;
    clusterWidth = diff(clusterIndex);
    
    figure;
    imagesc(sortedW)
    setAutoLimits(gca)
    if exist('chans', 'var')
        set(gca, 'XTick', 1:length(chans), 'XTickLabel', chans(isort))
        set(gca, 'YTick', 1:length(chans), 'YTickLabel', chans(isort))
    end
    hold on
        
    for j = 1:length(clusterWidth)
        rectangle('Position',[clusterIndex(j) clusterIndex(j) clusterWidth(j) clusterWidth(j)], 'LineWidth', 3)
    end
end
