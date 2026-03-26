function fig_handle = scrollPlotData(cfg, data)
% data inspection tool, which enables scrolling through fieldtrip eeg data,
% with possibility of marking artifacts in red. Use after bvLL_artifactDetection
% for best results
%
% usage:
%   [ fig_handle ] = scrollPlotData(cfg, data)
%
% general fieldtrip data structure is needed
% config structure with following fields is needed:
%   cfg.artifactdef = artifactdefinition from bvLL_artefactDetection
%   cfg.artifactdef.badPartsMatrix = only necessary field for this function.
%       Boolean matrix with zeros for each trial and each channel if data is
%       artifact-free or ones if artifact is present. For more information,
%       check bvLL_artifactDetection
%   cfg.horzLim     = [ number or 'full' ], blocksize of shown block in seconds
%       (default: 'full')
%   cfg.scroll      = 'yes/no', determines whether keyboard inputs can scroll
%       through data. Warning: psychtoolbox needs to be installed and added to
%       matlab path for this to work
%   cfg.visible     = 'on/off', set visibility of figure
%   cfg.channel     = channel selection based on FT_CHANNELSELECTION (default:
%       'all')

badPartsMatrix  = ft_getopt(cfg, 'badPartsMatrix');
horzLim         = ft_getopt(cfg, 'horzLim', 'full');
scroll          = ft_getopt(cfg, 'scroll', 'no');
visible         = ft_getopt(cfg, 'visible', 'on');
channel         = ft_getopt(cfg, 'channel', 'all');

mp = get(0, 'MonitorPositions');

if strcmpi(scroll, 'yes')
    doScroll = true;
else
    doScroll = false;
end

if nargin < 2
    error('no data structure found')
end

if strcmp(horzLim, 'full')
    horzLim = length([data.time{:}])/data.fsample - (1/data.fsample);
end

cfg =[];
cfg.channel = channel;
evalc('data = ft_selectdata(cfg, data);');

openFigures     = findall(0,'type','figure');
nrOpenFigures   = length(openFigures);
fignum = nrOpenFigures + 1;

trialData = [data.trial{:}];
endTime = length(trialData)./data.fsample;
labels = data.label;

if isempty(badPartsMatrix)
    vTime = 0:1/data.fsample:length(trialData)/data.fsample - (1/data.fsample);
    
    startVal    = 0;
    endVal      = horzLim;
    
    startIndx = find(vTime==startVal);
    endIndx = find(vTime==endVal);
    
    vertLim = mean(max(trialData)).*1.5;
    
    limVector = vertLim:vertLim:vertLim*(size(trialData,1));
    limMatrix = repmat(limVector', 1, size(trialData,2));
    
    newGoodData = trialData + limMatrix;
    newBadData  = nan(size(newGoodData));
    
    fig_handle = figure(fignum);
    figure(fignum);
    figpos = mp(size(mp,1),:);
    figpos = [figpos(1) + figpos(3)/2, figpos(2) figpos(3)/2 figpos(4)];
    set(gcf, 'Position', figpos);
    set(gca, 'FontSize', 20)
    plot(vTime, newGoodData, 'b')
    hold on
    plot(vTime , newBadData, 'b')
    hold off
    
    set(gca, 'YLim', [0 (max(limVector) + vertLim)], 'XLim', [startVal endVal])
    
    set(gca,'YTick',limVector)
    set(gca,'YTickLabel',labels)
    
    currPart = endVal / horzLim;
    nParts = endTime / horzLim;
    title(['part ' num2str(currPart) '/' num2str(nParts)])
    
    drawnow
    
    if doScroll
        set(gcf, 'KeyPressFcn', @scrollView);
    end
else
    badTrials               = unique(badPartsMatrix(:,1));
    
    goodTrials              = 1:1:length(data.trial);
    goodTrials(badTrials)   = [];
    
    tmpGoodData = data.trial;
    tmpGoodTime = data.time;
    
    for i = 1:size(badPartsMatrix,1)
        tmpGoodData{badPartsMatrix(i,1)}(badPartsMatrix(i,2),:) = nan(1, size(data.trial{badPartsMatrix(i,1)},2));
    end
    
    tmp = zeros(size(data.trial{1},1), length(data.trial));
    tmp(sub2ind(size(tmp), badPartsMatrix(:,2), badPartsMatrix(:,1))) = 1;
    
    [goodChannelsPerTrial, goodTrialsPerChannel] = find(tmp == 0);
    goodPartsMatrix = cat(2, goodTrialsPerChannel, goodChannelsPerTrial);
    
    tmpBadData = data.trial;
    tmpBadTime = data.time;
    
    for i = 1:size(goodPartsMatrix,1)
        tmpBadData{goodPartsMatrix(i,1)}(goodPartsMatrix(i,2),:) = nan(1, size(tmpBadData{goodPartsMatrix(i,1)},2));
    end
    
    for i = 1:length(goodTrials)
        tmpBadTime{goodTrials(i)} = nan(1, length(data.time{1}));
    end
    
    goodTrialData = [tmpGoodData{:}];
    goodTimeData = [tmpGoodTime{:}];
    
    if sum(not(isnan(goodTrialData(:)))) == 0
        fig_handle = figure;
        return
    end
    
    vTime = 0:1/data.fsample:length(trialData)/data.fsample - (1/data.fsample);
    
    badTrialData = [tmpBadData{:}];
    badTimeData = [tmpBadTime{:}];
    
    if isempty(goodTrials)
        tmp = max([data.trial{:}],[],2);
        vertLim = mean(tmp);
    else
        tmp = max(goodTrialData, [], 2);
        vertLim = nanmean(tmp);
    end
    
    limVector = vertLim:vertLim:vertLim*(size(trialData,1));
    limMatrix = repmat(limVector', 1, size(trialData,2));
    
    newGoodData = goodTrialData + limMatrix;
    newBadData = badTrialData + limMatrix;
    
    startVal    = 0;
    endVal      = horzLim;
    
    startIndx = find(vTime==startVal);
    endIndx = find(vTime==endVal);
    
    if strcmp(visible, 'off')
        fig_handle = figure('Visible','off');
    else
        fig_handle = figure(fignum);
    end
    figpos = mp(size(mp,1),:);
    figpos = [figpos(1) + figpos(3)/2, figpos(2) figpos(3)/2 figpos(4)];
    set(gcf, 'Position', figpos);
    set(gca, 'FontSize', 20)
%     plot(vTime(startIndx:endIndx), newGoodData(:,(startIndx:endIndx)), 'b')
    plot(vTime, newGoodData, 'b')
    hold on
%     plot(vTime(startIndx:endIndx), newBadData(:,(startIndx:endIndx)), 'r')
    plot(vTime, newBadData, 'r')
    hold off
    
    set(gca,'YTick',limVector)
    set(gca,'YTickLabel',labels)
    
    currPart = endVal / horzLim;
    nParts = endTime / horzLim;
    title(['part ' num2str(currPart) '/' num2str(nParts)])
    
    set(gca, 'YLim', [0 (max(limVector) + vertLim)], 'XLim', [0 horzLim])
    drawnow
    if doScroll
        set(gcf, 'KeyPressFcn', @scrollView)
    end
end
end

function scrollView(src, event)

XLim = get(gca, 'XLim');
horzLim = range(XLim);
figTitle = get(gca, 'Title');
figTitle = figTitle.String;
titlesplit = strsplit(figTitle, '/');
numerator = regexp(titlesplit{1},'\d*','Match');
numerator = str2double(numerator{1});
denominator = str2double(titlesplit{2});

if strcmpi(event.Key, 'rightarrow')
    numerator = numerator + 1;
    XLim = XLim + horzLim;
elseif strcmpi(event.Key, 'leftarrow')
    numerator = numerator - 1;
    XLim = XLim - horzLim;
elseif strcmpi(event.Key, 'hyphen')
    horzLim = horzLim ./ 2;
    denominator = denominator .* 2;
    numerator = numerator .* 2;
    XLim = [XLim(1) XLim(1) + horzLim];
elseif strcmpi(event.Key, 'equal')
    horzLim = horzLim .* 2;
    denominator = denominator ./ 2;
    numerator = numerator ./ 2;
    XLim = [XLim(1) XLim(1)+ horzLim];
elseif strcmpi(event.Key, 'q')
    close(src)
    return
end

set(gca, 'XLim', XLim);
title(['part ' num2str(numerator) '/', num2str(denominator)]);
hold off
end
