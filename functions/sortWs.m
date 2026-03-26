function [sortedWs, sortedLabels] = sortWs(Ws, origChanorder, newChanorder)

if nargin < 3
    error('please input new channel order')
end
if nargin < 2
    error('please input old channel order')
end
if nargin < 1
    error('please input weighted matrices to be sorted')
end

if size(origChanorder,2) ~= size(newChanorder,2)
    error('original channel order and new trial order not same length')
end

if size(origChanorder, 1) == size(Ws, 3)
    individualChanorder = 1;
elseif  size(origChanorder, 1) == 1 || size(origChanorder, 2) == 1
    individualChanorder = 0;
    if size(origChanorder,2) == 1
        origChanorder = origChanorder';
    end
    origChanorders = repmat(origChanorder, size(Ws, 3), 1);
else
    error('amount of chanorders and subjects not equal')
end

for iChanorders = 1:size(origChanorders, 1)
    currOrigChanorder = origChanorders(iChanorders,:);
    currNewChanorder = newChanorder(ismember(newChanorder, currOrigChanorder));
    currW = Ws(:,:,iChanorders);
    
    sortIndx = zeros(1, size(origChanorders,2));
    counter = 0;
    for iLabel = 1:size(origChanorders,2)
        sortPos = find(ismember(currOrigChanorder, currNewChanorder{iLabel}));
        
        sortIndx(iLabel) = sortPos;
    end
    
    sortedWs(:,:,iChanorders) = currW(sortIndx, sortIndx);
    sortedLabels(:, iChanorders) = origChanorder(sortIndx);
    
end