function bv_plotSignalData(signaldata, samplingrate, labels)

if nargin < 2
    samplingrate = 1;
end
if nargin < 3
    labels = 1:size(signaldata,1);
end

horzLim = length(signaldata);
vTime = 0:1/samplingrate:size(signaldata,2)/samplingrate - (1/samplingrate);

vertLim = max(max(signaldata));

limVector = vertLim:vertLim:vertLim*(size(signaldata,1));
limMatrix = repmat(limVector', 1, size(signaldata,2));

newData = signaldata + limMatrix;

figure;
mp = get(0, 'MonitorPositions');
figpos = mp(size(mp,1),:);
figpos = [figpos(1) + figpos(3)/2, figpos(2) figpos(3)/2 figpos(4)];
set(gcf, 'Position', figpos);
set(gca, 'FontSize', 20)
plot(vTime, newData, 'b')

set(gca, 'YLim', [0 (max(limVector) + vertLim)], 'XLim', [0 max(vTime)])

set(gca,'YTick',limVector)
set(gca,'YTickLabel',labels)
