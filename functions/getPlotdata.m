function [plotData, limVect] = getPlotdata(trialdata, lim)

if nargin < 2
    lim = max(max(trialdata));
end

nChans = size(trialdata, 1);
nSamples = size(trialdata, 2);

limVect = 0:lim:lim*(nChans-1);

limMat = repmat(limVect', 1, nSamples);
plotData = trialdata + limMat;
