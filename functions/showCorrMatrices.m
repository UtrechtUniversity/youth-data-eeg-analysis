function showCorrMatrices(Ws, chans)
% shows connectivity matrices as subplots in one figure
%
% usage:
%   showCorrMatrices(Ws, chans)
%
% INPUTS:
%   Ws: connectivity matrices in 3-dimensional matrix with the following
%       dimensions (nNodes x nNodes x nAmount)
%   chans (optional): channel (node) names to beautify endresult

figure;
subIndx1 = ceil(sqrt(size(Ws,3)));
subIndx2 = floor(sqrt(size(Ws,3)));
for iW = 1:size(Ws,3)
    subplot(subIndx2, subIndx1, iW)
    imagesc(Ws(:,:,iW))
    if nargin > 1
      bv_autoCorrSettings(gca, chans)
    end
    colorbar
end
