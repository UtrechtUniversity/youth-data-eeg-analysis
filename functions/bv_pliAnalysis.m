function bv_pliAnalysis(cfg)

currSubject = ft_getopt(cfg, 'currSubject');
cleanedStr = ft_getopt(cfg, 'cleanedStr');
outputStr = ft_getopt(cfg, 'outputStr');
freqbands = ft_getopt(cfg, 'freqbands', ...
    {'delta', 'theta', 'alpha1', 'alpha2', 'beta', 'gamma'});
saveData = ft_getopt(cfg, 'saveData');

eval('setOptions')
eval('setPaths')
disp(currSubject)
fprintf('\t preparation ... \n')

[subjectdata, cleanedData] = ...
    bv_check4data([PATHS.SUBJECTS filesep currSubject], cleanedStr);
load([PATHS.SUMMARY filesep 'SubjectSummary.mat'], 'subjectdatasummary')

rmChannels = subjectdatasummary(ismember({subjectdatasummary.subjectName}, currSubject)).rmChannels;
if not(iscell(rmChannels))
    rmChannels = cellstr(rmChannels);
end

trl = [cleanedData.sampleinfo, zeros(length(cleanedData.sampleinfo), 1), cleanedData.trialinfo];


fprintf('\t\tloading in raw data ... ')
cfg = [];
cfg.headerfile = subjectdata.PATHS.HDRFILE;
cfg.dataset = subjectdata.PATHS.DATAFILE;
cfg.channel = 'EEG';
evalc('data = ft_preprocessing(cfg);');
evalc('data = bv_sortBasedOnTopo(data);');
fprintf('done! \n')

if ~(isempty(rmChannels))
    fprintf(['\t\tremoving and intepolating the following channels: ', repmat('%s, ', 1, length(rmChannels)), ' ... '], rmChannels{:})
    cfg = [];
    cfg.layout = 'EEG1010';
    cfg.channel = 'all';
    cfg.feedback = 'no';
    cfg.skipcomnt = 'yes';
    cfg.skipscale = 'yes';
    evalc('lay = ft_prepare_layout(cfg, data);');
    
    cfg = [];
    cfg.method          = 'distance';
    cfg.neighbourdist   = 0.25;
    cfg.template        = 'EEG1010';
    cfg.layout          = lay;
    cfg.channel         = 'all';
    cfg.feedback        = 'no';
    cfg.skipcomnt       = 'yes';
    cfg.skipscale       = 'yes';
    evalc('neighbours = ft_prepare_neighbours(cfg, data);');
    
    cfg = [];
    cfg.badchannel = subjectdata.rmChannels;
    cfg.method = 'weighted';
    cfg.neighbours = neighbours;
    cfg.channel = 'all';
    cfg.layout = lay;
    evalc('data = ft_channelrepair(cfg, data);');
    fprintf('done! \n')
else
    fprintf('\t\tremoving channels unnecessary \n')
end

fprintf('\t\tresampling to %1.0f Hz ...', cleanedData.fsample)
cfg = [];
cfg.resamplefs = 512;
evalc('data = ft_resampledata(cfg, data);');
fprintf('done! \n')

fprintf('\t start PLI analysis ... \n')
cfgfilt = [];
cfgfilt.lpfilter = 'yes';
cfgfilt.hpfilter = 'yes';
cfgfilt.lpinstabilityfix = 'reduce';
cfgfilt.hpinstabilityfix = 'reduce';
cfgfilt.reref = 'yes';
cfgfilt.refchannel = 'all';
for i = 1:length(freqbands)
    switch freqbands{i}
        case 'delta'
            cfgfilt.hpfreq = 0.5;
            cfgfilt.lpfreq = 3;
            fprintf('\t\tfiltering data to delta band ... ')
        case 'theta'
            cfgfilt.hpfreq = 3;
            cfgfilt.lpfreq = 6;
            fprintf('\t\tfiltering data to theta band ... ')
        case 'alpha1'
            cfgfilt.hpfreq = 6;
            cfgfilt.lpfreq = 9;
            fprintf('\t\tfiltering data to alpha1 band ... ')
        case 'alpha2'
            cfgfilt.hpfreq = 9;
            cfgfilt.lpfreq = 12;
            fprintf('\t\tfiltering data to alpha2 band ... ')
        case 'beta'
            cfgfilt.hpfreq = 12;
            cfgfilt.lpfreq = 25;
            fprintf('\t\tfiltering data to beta band ... ')
        case 'gamma'
            cfgfilt.hpfreq = 25;
            cfgfilt.lpfreq = 45;
            fprintf('\t\tfiltering data to gamma band ... ')
        otherwise
            error('Unknown freqband label')
    end
    
    evalc('dataFilt = ft_preprocessing(cfgfilt, data);');
    fprintf('done! \n')

    fprintf('\t\tcutting into %1.0f trials ... ', size(trl,1))
    cfgcut = [];
    cfgcut.trl = trl;
    evalc('dataFiltCut = ft_redefinetrial(cfgcut, dataFilt);');
    fprintf('done! \n')    
    
    fprintf('\t\tPLI analysis ... ')
    tmp = PLI(dataFiltCut.trial, 1);
    connectivity.plispctrm(:,:,:,i) = cat(3, tmp{:});
    connectivity.freqs{i} = freqbands{i};
    fprintf('done! \n')
    
end

connectivity.dimord = 'chan_chan_trl_freq';
connectivity.label = data.label;
connectivity.sampleinfo = trl(:, 1:2);
connectivity.trialinfo = trl(:,4);

%%%%%% save data %%%%%%
if strcmpi(saveData, 'yes')
    bv_saveData(subjectdata, connectivity, outputStr)
    bv_updateSubjectSummary([PATHS.SUMMARY filesep 'SubjectSummary'], subjectdata)
end

