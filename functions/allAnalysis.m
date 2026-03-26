rawFileName = '10598B_ruweEEG';

cfg = [];
cfg.hpfilter    = 1;
cfg.hpfreq      = 0.5;
cfg.bsfilter    = 1;
cfg.bsfreq      = [48 52];
cfg.lpfilter    = 0;
cfg.lpfreq      = 70;
cfg.resample    = 1;
cfg.resamplefs  = 512;
cfg.headerfile  = [pwd filesep 'RAW' filesep rawFileName '.bdf']; %subjectdata.PATHS.HDRFILE;
cfg.dataset     = [pwd filesep 'RAW' filesep rawFileName '.bdf']; %subjectdata.PATHS.DATAFILE;
cfg.trigger     = [11 12];
cfg.channels    = {'eeg'};
cfg.reref       = 0;
cfg.refElectrode = {'all'};
cfg.trialfun    = 'trialfun_YOUth_testRetest';
data = bvLL_preprocessing(cfg);

% cfg = [];
% cfg.channel = {'EEG'};
% data = ft_selectdata(cfg, data);
% 
% cfg = [];
% cfg.viewmode = 'vertical';
% ft_databrowser(cfg, data)

cfg = [];
cfg.channel  = data.label;
cfg.layout   = 'EEG1010';
cfg.feedback = 'yes';
cfg.skipcomnt  = 'yes';
cfg.skipscale  = 'yes';
evalc('lay = ft_prepare_layout(cfg);');

[~, indxSort] = ismember(lay.label, data.label);

data.label = data.label(indxSort);
data.trial = cellfun(@(x) x(indxSort,:), data.trial, 'Un', 0);
%%
cfg = [];
cfg.method = 'runica';
cfg.runica.extended = 0;
comp = ft_componentanalysis(cfg, data);

cfg = [];
cfg.component = 1:30; % specify the component(s) that should be plotted
cfg.layout    = 'EEG1010'; % specify the layout file that should be used for plotting
cfg.comment   = 'no';
cfg.compscale = 'local';
cfg.interactive = 'no';
figure();
evalc('ft_topoplotIC(cfg, comp);');

cfg = [];
cfg.viewmode = 'component';
cfg.layout = lay;
ft_databrowser(cfg, comp)

%%

% cfg = [];
% cfg.component = [6];
% data = ft_rejectcomponent(cfg, comp, data);


nTrials = length(data.trial);
for iTrl = 1:nTrials
    currTrl = data.trial{iTrl};
    avg = mean(currTrl);
    
    data.trial{iTrl} = bsxfun(@minus,currTrl,avg);
end

%%
% 
% cfg = [];
% cfg.viewmode = 'vertical';
% ft_databrowser(cfg, data)
% 
% cfg = [];
% cfg.channel = {'eeg' '-T7'};
% data = ft_selectdata(cfg, data);
%%
cfg = [];
cfg.length = 5;
cfg.overlap = 0;
dataCut = ft_redefinetrial(cfg, data);

freq = bvLL_frequencyanalysis(dataCut, [0 100]);
figure; plot(freq.freq, squeeze(mean(freq.powspctrm))', 'LineWidth', 2)
legend(dataCut.label)
set(gca, 'YLim', [0 Inf])
%%
cfg = [];
cfg.channel = {'all', '-AF4'};
dataCut = ft_selectdata(cfg, dataCut);
%%
cfg = [];
% cfg.betaLim     = 20;
% cfg.gammaLim    = 20;
cfg.varLim      = 1000;
cfg.invVarLim   = 0.1;
cfg.kurtLim     = 5;

[artefactdef, counts] = bvLL_artefactDetection(cfg, interp, freq);

% figure;
addpath('~/git/eeg-graphmetrics-processing/figures/')
cfg = [];
cfg.badPartsMatrix  = artefactdef.badPartsMatrix;
cfg.horzLim         = 'full';
cfg.triallength     = 1;
cfg.scroll          = 0;
cfg.visible         = 'on';
cfg.triallength     = 5;
scrollPlot          = scrollPlotData(cfg, interp);
%%
cfg = [];
cfg.channel = {'all', '-C6'};
dataCut = ft_selectdata(cfg, dataCut);

cfg = [];
cfg.viewmode = 'vertical';
ft_databrowser(cfg, dataCut)

%%
cfg = [];
cfg.channel  = dataCut.label;
cfg.layout   = 'EEG1010';
cfg.feedback = 'yes';
cfg.skipcomnt = 'yes';
cfg.skipscale = 'yes';
evalc('lay = ft_prepare_layout(cfg);');

cfg = [];
cfg.method        = 'triangulation';
% cfg.neighbourdist = 0.2;
cfg.template      = 'EEG1010';
cfg.layout        = lay;
cfg.channel       = 'all';
cfg.feedback      = 'yes';
cfg.skipcomnt     = 'yes';
cfg.skipscale     = 'yes';
nbours = ft_prepare_neighbours(cfg, dataCut);

cfg = [];
% cfg.method = 'spline';
cfg.badchannel = 'T7';
cfg.neighbours = nbours;
cfg.trials = 'all';
cfg.layout = lay;
interp = ft_channelrepair(cfg, dataCut);
interp.fsample = dataCut.fsample;

% cfg = [];
% cfg.channel = {'all', '-AF4'};
% dataCut = ft_selectdata(cfg, dataCut);
%%
cfg = [];
cfg.trials = artefactdef.goodTrials;
dataClean = ft_selectdata(cfg, interp);

% cfg = [];
% cfg.channel = {'EEG', '-T8'};
% data = ft_selectdata(cfg, data);

freqClean = bvLL_frequencyanalysis(dataClean, [0 100]);
figure; plot(freqClean.freq, squeeze(mean(freqClean.powspctrm))', 'LineWidth', 2)
legend(dataClean.label)
set(gca, 'XLim', [0 100]);
set(gca, 'YLim', [0 Inf]);

cfg = [];
cfg.freqrange = [1 100];
pxx = magnitudeResponse(cfg, dataClean);
set(gca, 'YLim', [0 Inf])

plot(squeeze(mean(pxx,2)), 'LineWidth', 3)
set(gca, 'XLim', [0 100])

cfg = [];
cfg.viewmode = 'vertical';
ft_databrowser(cfg, dataClean);

%%

dataTypeStr = 'RS';
% freqband = {[0.5 3], [3 6], [6 9], [9 12], [12 25], [1 100]};
% freqbandStr = {'delta', 'theta', 'alpha1', 'alpha2', 'beta', 'broadband'};

% vFreqband = 2:2:99;
% freqbandStr = strread(num2str(vFreqband),'%s');
% 
% for i = 1:length(vFreqband)
%     freqband{i} = [vFreqband(i)-1 vFreqband(i)+1];
% end

freqband = {[1 10], [11 20], [21 30], [31 40], [70 79], [90 99]};
freqbandStr = repmat({'1'},1,length(freqband));

dataClean.trialinfo = repmat(1, size(dataClean.sampleinfo,1),1);
trigger = [1];
triggerStr = {'RestingState'};

personalResultsFolder = ['results' filesep rawFileName];
if ~exist(personalResultsFolder, 'dir')
    mkdir(personalResultsFolder)
end

labels = dataClean.label;
dataTmp = dataClean;

counter = 0;
for iTrig = 1:length(trigger)
    currTrig = trigger(iTrig);
    currTrigStr = triggerStr{iTrig};
    
    for iFreq = 1:length(freqband)
        counter = counter + 1;
        currFreq = freqband{iFreq};
        currFreqStr = freqbandStr{iFreq};
   
        filt = bv_butterFilter(dataClean.trial(dataClean.trialinfo==currTrig), currFreq, dataClean.fsample);
        
        dataTmp.trial = filt;
        freq = bvLL_frequencyanalysis(dataTmp, [0 100]);
        figure; plot(freq.freq, squeeze(mean(freq.powspctrm))', 'LineWidth', 2)
        title(currFreqStr)
        
        Ws = PLI(filt,1);
        Ws = cat(3, Ws{:});
                
        Ws1 = Ws(:,:,1:2:end);
        Ws2 = Ws(:,:,2:2:end);
        
        currW1 = mean(Ws1,3);
        currW2 = mean(Ws2,3);
        
        W1s(:,:,counter) = currW1;
        W2s(:,:,counter) = currW2;
       
        figure; 
        subplot(1,2,1); imagesc(currW1); colorbar
        set(gca, 'CLim', [min(squareform(currW1)) max(squareform(currW1))])
        set(gca, 'XTick', 1:length(dataClean.label), 'XTickLabel', dataClean.label)
        set(gca, 'YTick', 1:length(dataClean.label), 'YTickLabel', dataClean.label)
        
        subplot(1,2,2); imagesc(currW2); colorbar
        set(gca, 'CLim', [min(squareform(currW2)) max(squareform(currW2))])
        set(gca, 'XTick', 1:length(dataClean.label), 'XTickLabel', dataClean.label)
        set(gca, 'YTick', 1:length(dataClean.label), 'YTickLabel', dataClean.label)
        
        figure; scatter(squareform(currW1), squareform(currW2));
        
        R(iFreq, iTrig) = corr(squareform(currW1)', squareform(currW2)');
        
%         title(['Coherence - ' currTrigStr ' - ' currFreqStr ' connectivity matrix'])
        
%         filename = [dataTypeStr '_' currTrigStr '_' currFreqStr];
%         print(gcf, '-dpng', [filename  '.png'])
%         
%         corMatrixFilename = [personalResultsFolder filesep filename ,'.mat'];
%         save(corMatrixFilename, 'Ws', 'labels')

        fprintf('%d \n',iFreq) 
    end
end

R_table = table(R, 'Rownames', freqbandStr);
disp(R_table)

% close all
%%
trialdata = [dataClean.trial{:}];
formatSpec = [repmat('%f \t ', 1, size(trialdata,1)) '\n'];
fid = fopen(['txtfiles' filesep '1.txt'], 'w');
fprintf(fid, formatSpec, trialdata)
fclose( 'all' )

trialdata2use = trialdata(:, 1:2048);
W = PLI(trialdata2use,1);

filt = bv_butterFilter(dataClean.trial, [6 10], 512);
Ws = PLI(filt,1);

filtdata = [filt{:}];
filtdata2Use = filtdata(:,1:512);
W = PLI(filtdata2Use,1);

trialdataTmp = trialdata(:, 1:4098);

trialdata = [dataClean.trial{:}];
fid = fopen('tmp.txt', 'w');
formatSpec = repmat('%f\t', size(trialdataTmp,1), size(trialdataTmp,2));
formatSpec = formatSpec(1:end-2);
formatSpec = [formatSpec '\n'];

fprintf(fid, formatSpec, trialdataTmp)
fclose( 'all' )

Ws = PLI(dataClean.trial,1);

dataTmp = dataClean;
[filt] = bv_butterFilter(dataClean.trial, [2 5], 512);

dataTmp.trial = filt;

cfg = [];
cfg.freqrange = [1 100];
magnitudeResponse(cfg, dataTmp);

cfg =[];
cfg.viewmode = 'vertical';
ft_databrowser(cfg, dataTmp)

% freqTmp = bvLL_frequencyanalysis(dataTmp, [0 100]);
% figure; plot(freqTmp.freq, squeeze(mean(freqTmp.powspctrm))', 'LineWidth', 2)
 

filt1 = filt(1:40);
filt2 = filt(41:80);

% remain = mod(length(filt),5);
% filt = filt(1:end-remain);
% 
% filt = reshape(filt, length(filt)/5, 5);
% 
% for i = 1:size(filt,1)
%     currW = PLI(filt(i,:),1);
%     currW = cat(3, currW{:});
%     
%     W(:,:,i) = mean(currW,3);
%     
% %     figure;
% %     imagesc(W(:,:,i))
% end
Ws = PLI(filt, 1);
Ws = cat(3, Ws{:});
W = mean(Ws,3);

n = size(W,2);
W(1:n+1:end) = NaN;

figure; imagesc(W)

Ws1 = PLI(filt1, 1);
Ws2 = PLI(filt2, 1);
Ws1 = cat(3, Ws1{:});
Ws2 = cat(3, Ws2{:});

W1 = mean(Ws1,3);
W2 = mean(Ws2,3);

n = size(W1,2);
W1(1:n+1:end) = NaN;
W2(1:n+1:end) = NaN;

figure; imagesc(W1); colorbar
set(gca, 'XTick', 1:length(dataClean.label), 'XTickLabel', dataClean.label)
set(gca, 'YTick', 1:length(dataClean.label), 'YTickLabel', dataClean.label)

figure; imagesc(W2); colorbar
set(gca, 'XTick', 1:length(dataClean.label), 'XTickLabel', dataClean.label)
set(gca, 'YTick', 1:length(dataClean.label), 'YTickLabel', dataClean.label)

trialFilt = [filt{:}]';
trialFilt = trialFilt(1:4096,:);

fid = fopen('tmp2.txt', 'w');
fprintf(fid, [repmat('%f\t', 1, size(trialFilt,2)) '\n'], trialFilt)
fclose( 'all' )



