function strength = calculateStrengthWs(Ws)

strength = zeros(1, size(Ws,3));
for iW = 1:size(Ws,3)
    currW = Ws(:,:,iW);

    % find removed channels
    rmChannels = sum(isnan(currW))==(size(currW,2) - 1);
    if ~isempty(rmChannels)
        
        currW(rmChannels,:) = [];
        currW(:,rmChannels) = [];
        
    end
    
    ncols = size(currW, 2);
    currW(1:ncols+1:end) = 0;
    squareformW = squareform(currW);
    strength(iW) = nanmean(nonzeros(squareformW));
end