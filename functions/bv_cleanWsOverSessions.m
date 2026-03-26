function output =  bv_cleanWsOverSessions(Ws)
% usage:
%  [ cleanedWs ] = bv_cleanWsOverSessions( Ws )
%
% cleans connectivity matrices over sessions, by removing channels from both
% sessions and setting diagonal to zero.


n = size(Ws,3);
m = size(Ws,4);
rmChannels = [];
output = zeros(size(Ws));
for iW = 1:n
    currWs = squeeze(Ws(:,:,iW,:));

    for jW = 1:m
        currW = currWs(:,:,jW);
        currW(isnan(currW)) = 0;
        nanChans = find(sum(currW==0) == (size(currW,2) -1));
        rmChannels = unique([rmChannels nanChans]);
    end

    if ~isempty(rmChannels)
        currWs(rmChannels,:,:,:) = NaN;
        currWs(:,rmChannels,:,:) = NaN;
    end

    rmChannels = [];
    for i = 1:size(currWs,3);
        W = currWs(:,:,i);
        ncols = size(W,2);
        W(1:ncols+1:end) = 0;
        currWs(:,:,i) = W;
    end

    output(:,:,iW,:) = currWs;

end
