function plotData = plotTrialdata(trialdata, timevector, lim)

if nargin < 3
    lim = max(max(trialdata));
end

nChans = size(trialdata, 1);
nSamples = size(trialdata, 2);

limVect = 0:lim:lim*(nChans-1);

limMat = repmat(limVect', 1, nSamples);
plotData = trialdata + limMat;

figure; plot(timevector, plotData)
set(gca, 'YLim', [(0-lim), (max(limVect) + lim)])
set(gca, 'YTick', limVect)
