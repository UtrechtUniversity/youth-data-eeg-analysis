function [ connectivity ] = bv_calculateConnectivity(cfg, data)
% Calculates connectivity between EEG sensors with the following methods
% implemented (pli, wpli, wpli_debiased). Weighted PLI measures are
% calculated based on fieldtrip ft_connectivityanalysis. PLI is calculated
% using the PLI.m function included.
%
% can be used with data-input as:
%  [ connectivity ] = bv_calculateConnectivity(cfg, data)
%
% with input data being a standard fieldtrip eeg-data-structure
%
% or without data-input as:
%  [ connectivity ] = bv_calculateConnectivity(cfg)
%
% always needs the following fields in the cfg structure:
%   cfg.method      = 'string', connectivity will be calculated based on
%                       given method ('wpli_debiased', 'wpli', 'pli')
%   cfg.ntrials     = [ number ] of trials to be randomly included in
%                       connectivity calculation. Can be a number or 'all'
%                       to include all trials (default: 'all')
%   cfg.condition   = [ number ], number of condition to be analyzed (taken
%                       from data.trialinfo. Can also be 'all' to include
%                       all conditions (default: 'all');
%
% also needs the following field in cfg-structure in the case of no data-input:
%   cfg.currSubject = 'string', subjectfoldername to analyze (looks in
%                       PATHS.SUBJECTS given in cfg.pathsFcn given)
%   cfg.inputStr    = 'string', data to be loaded in, using bv_check4data,
%                       based on subjectdata.PATHS field name (f.e.
%                       'APPENDED')
%   cfg.saveData    = 'yes/no', determines whether data is saved to disk in
%                       subjectfolder, based on cfg.outputStr with
%                       bv_saveData
%   cfg.outputStr   = 'string', used to save data to unique file, with
%                       unique entry into subjectdata.PATHS
%   cfg.pathsFcn    = path to paths function needed to run
%                       analysis-pipeline (default: './setPaths')
%   cfg.optionsFcn  = path to options function needed to run
%                       analysis-pipeline (default: './setOptions')
%
% optional fields:
%   cfg.triallength = [ number ], cut data into trials with given length,
%                       using bv_cutAppendedIntoTrials. Leave empty to
%                       leave the trialstructure of input file
%   cfg.keeptrials  = 'yes/no' (method = 'PLI' only). To keep trials in
%                       output (default: 'no');
%
% See also BV_CUTAPPENDEDINTOTRIALS, BV_SAVEDATA, BV_CHECK4DATA,
% FT_CONNECTIVITYANALYSIS, BV_SETDIAG

%%%%%% general check for inputs %%%%%%
ntrials     = ft_getopt(cfg, 'ntrials','all');
method      = ft_getopt(cfg, 'method');
condition   = ft_getopt(cfg, 'condition', 'all');
currSubject = ft_getopt(cfg, 'currSubject');
inputName   = ft_getopt(cfg, 'inputName');
saveData    = ft_getopt(cfg, 'saveData', 'no');
outputName  = ft_getopt(cfg, 'outputName');
pathsFcn    = ft_getopt(cfg, 'pathsFcn', 'setPaths');
optionsFcn  = ft_getopt(cfg, 'optionsFcn', 'setOptions');
triallength = ft_getopt(cfg, 'triallength');
keeptrials  = ft_getopt(cfg, 'keeptrials', 'no');
quiet       = ft_getopt(cfg, 'quiet');

if strcmpi(quiet, 'yes')
    quiet = true;
else
    quiet = false;
end

if isempty(method)
    error('no cfg.method given')
end

if ~contains(method,{'pli', 'pte'}) && strcmpi(keeptrials, 'yes')
    error('cannot keep trials with method: %s', method)
end

% load in data if no input data is given
if nargin < 2
    if ~quiet; disp(currSubject); end
    eval(pathsFcn)
    eval(optionsFcn)
    
    subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];
    try
        if ~quiet
            [subjectdata, check, data] = bv_check4data(subjectFolderPath, inputName);
        else
            evalc('[subjectdata,check, data] = bv_check4data(subjectFolderPath, inputName);');
        end
    catch
        fprintf('\t previous GRNGR not found, skipping ... \n')
        connectivity = [];
        return
    end
    subjectdata.cfgs.(method) = cfg;
    
else
    quiet = false;
end

%%%%%% start connectivity analysis based on given method %%%%%%
switch(method)
    case {'wpli_debiased', 'wpli', 'coh', 'granger', 'plv'} % based on ft_connectivityanalysis with cfg.method = 'wpli_debiased'
        
        % cut, if needed data into trials
        if ~isempty(triallength)
            cfg = [];
            cfg.saveData = 'no';
            cfg.triallength = triallength;
            if ~quiet
                [dataCut] = bv_cutAppendedIntoTrials(cfg, data);
            else
                evalc('[dataCut] = bv_cutAppendedIntoTrials(cfg, data);');
            end
        end
        
        if isempty(dataCut)
            warning('Only 1 trial present, skipping')
            connectivity = [];
            return
        end
        
        % select data based on condition and select random trials
        cfg = [];
        if strcmpi(condition, 'all')
            if strcmpi(ntrials, 'all')
                cfg.trials = 1:length(dataCut.trial);
            else
                cfg.trials = sort(randperm(length(dataCut.trial), ntrials));
            end
        else
            itrl = find(ismember(dataCut.trialinfo, condition));
            if ~isempty(itrl)
                if strcmpi(ntrials, 'all')
                    cfg.trials = itrl;
                else
                    cfg.trials = itrl(randperm(numel(itrl),ntrials));
                end
            else
                connectivity = [];
                return;
            end
            
        end
        
        if ~quiet; fprintf('\t connectivity analysis started for %s... \n', method); end
        % frequency analysis
        cfg.method      = 'mtmfft';
        cfg.taper       = 'hanning';
        cfg.output      = 'fourier';
        cfg.keeptrials  = 'yes';
        cfg.tapsmofrq   = 1;
        cfg.pad         = 'nextpow2';
        cfg.foilim      = [0 70];
        
        evalc('freq = ft_freqanalysis(cfg, dataCut);');
        cfg = [];
        evalc('fd = ft_freqdescriptives(cfg, freq);');
        
        if ~quiet; fprintf('\t\t with %1.0f trials ... ', size(freq.trialinfo,1)); end
        
        % connectivity analysis
        cfg             = [];
        cfg.method      = method;
        evalc('connectivity = ft_connectivityanalysis(cfg, freq);');
        if ~quiet; fprintf('done! \n'); end
        
        fnames = fieldnames(connectivity);
        fnameindx = find(contains(fnames, 'spctrm'));
        
        connectivity = renameStructField(connectivity, fnames{fnameindx}, 'spctrm');
        
        if strcmpi(method, 'wpli')
            connectivity.spctrm = abs(connectivity.spctrm);
        end
        
        connectivity.method = method;
        connectivity.label = freq.label;
        connectivity.trialinfo = freq.trialinfo;
        connectivity.dimord = 'chan_chan_freq';
        
        % set diagonal at zero if needed
        connectivity.spctrm = bv_setDiag(connectivity.spctrm, 0);
        
    case 'pli' % based on PLI.m
        
        freqLabel = {'delta', 'theta', 'alpha1', 'alpha2', 'beta', 'gamma'};
        freqRng = {[1 3], [3 6], [6 9], [9 12], [12 25], [25, 45]};
        
        for iFreq = 1:length(freqLabel)
            currFreq = freqLabel{iFreq};
            currFreqRng = freqRng{iFreq};
            
            if ~quiet; fprintf('\t filtering to for %s Hz... \n' , currFreq); end
            
            cfg = [];
            cfg.lpfilter = 'yes';
            cfg.lpfreq = currFreqRng(2);
            cfg.hpfilter = 'yes';
            cfg.hpfreq = currFreqRng(1);
            cfg.hpinstabilityfix = 'reduce';
            
            evalc('dataFilt = ft_preprocessing(cfg, data);');
            
            % cut, if needed data into trials
            if ~isempty(triallength)
                cfg = [];
                cfg.saveData = 'no';
                cfg.triallength = triallength;
                cfg.ntrials = ntrials;
                if ~quiet
                    [dataCut, finished] = bv_cutAppendedIntoTrials(cfg, dataFilt);
                else
                    evalc('[dataCut, finished] = bv_cutAppendedIntoTrials(cfg, dataFilt);');
                end
                
                if ~finished
                    connectivity = [];
                    return;
                end
            else
                dataCut = dataFilt;
            end
            
            if not(strcmpi(condition, 'all'))  
                if ismember(condition, dataCut.trialinfo)
                    cfg = [];
                    cfg.trials = find(ismember(dataCut.trialinfo, condition));
                    
                    evalc('dataCut = ft_selectdata(cfg, dataCut);');
                else
                    connectivity = [];
                    return
                end
            end
            
            if ~quiet
                fprintf('\t %1.0f trials found\n', length(dataCut.trial))
                fprintf('\t calculating PLI ... ')
            end
            
            PLIs = PLI(dataCut.trial,1);
            PLIs = cat(3,PLIs{:});
            
            if strcmpi(keeptrials, 'yes')
                connectivity.plispctrm(:,:,:, iFreq) = PLIs;
                connectivity.dimord = 'chan_chan_trl_freq';
                connectivity.sampleinfo = dataCut.sampleinfo;
                connectivity.time = dataCut.time;
            else
                connectivity.plispctrm(:,:,iFreq) = mean(PLIs,3);
                connectivity.dimord = 'chan_chan_freq';
            end
            
            if ~quiet; fprintf('done!\n'); end
        end
        
        connectivity.freq = freqLabel;
        connectivity.freqRng = freqRng;
        connectivity.label = dataCut.label;
        connectivity.trialinfo = dataCut.trialinfo;
        
    case 'pte' % based on PhaseTE.m
        
        freqLabel = {'delta', 'theta', 'alpha1', 'alpha2', 'beta', 'gamma'};
        freqRng = {[1 3], [3 6], [6 9], [9 12], [12 25], [25, 45]};
        
        for iFreq = 1:length(freqLabel)
            currFreq = freqLabel{iFreq};
            currFreqRng = freqRng{iFreq};
            
            if ~quiet; fprintf('\t filtering to for %s Hz... \n' , currFreq); end
            
            cfg = [];
            cfg.lpfilter = 'yes';
            cfg.lpfreq = currFreqRng(2);
            cfg.hpfilter = 'yes';
            cfg.hpfreq = currFreqRng(1);
            cfg.hpinstabilityfix = 'reduce';
            
            evalc('dataFilt = ft_preprocessing(cfg, data);');
            
            % cut, if needed data into trials
            if ~isempty(triallength)
                cfg = [];
                cfg.saveData = 'no';
                cfg.triallength = triallength;
                cfg.ntrials = ntrials;
                if ~quiet
                    [dataCut, finished] = bv_cutAppendedIntoTrials(cfg, dataFilt);
                else
                    evalc('[dataCut, finished] = bv_cutAppendedIntoTrials(cfg, dataFilt);');
                end
                if ~finished
                    connectivity = [];
                    return;
                end
                if isempty(dataCut)
                    warning('Only 1 trial present, skipping')
                    connectivity = [];
                    return
                end
            else
                dataCut = dataFilt;
            end
            
            if not(strcmpi(condition, 'all'))
                cfg = [];
                cfg.trials = find(ismember(dataCut.trialinfo, condition));
                evalc('dataCut = ft_selectdata(cfg, dataCut);');
            end
            
            if ~quiet
                fprintf('\t %1.0f trials found\n', length(dataCut.trial));
                
                fprintf('\t calculating PTE ... ')
            end
            
            try
                for iTrl = 1:length(dataCut.trial)
                    evalc('[PTEsNrm(:,:,iTrl) PTEs(:,:,iTrl)]= PhaseTE_MF(dataCut.trial{iTrl}'');');
                end
            catch
                connectivity = [];
                return
            end
            
            if strcmpi(keeptrials, 'yes')
                connectivity.ptespctrm(:,:,:, iFreq) = PTEs;
                connectivity.ptenrmspctrm(:,:,:, iFreq) = PTEsNrm;
                connectivity.dimord = 'chan_chan_trl_freq';
                connectivity.sampleinfo = dataCut.sampleinfo;
                connectivity.time = dataCut.time;
            else
                connectivity.ptespctrm(:,:,iFreq) = mean(PTEs,3);
                connectivity.ptenrmspctrm(:,:,:, iFreq) = mean(PTEsNrm,3);
                connectivity.dimord = 'chan_chan_freq';
            end
            
            if ~quiet; fprintf('done!\n'); end
        end
        
        connectivity.freq = freqLabel;
        connectivity.freqRng = freqRng;
        connectivity.label = dataCut.label;
        connectivity.trialinfo = dataCut.trialinfo;
        
        % find removed channels and add a row of nans
        cfg = [];
        cfg.layout = 'biosemi32.lay';
        cfg.skipcomnt = 'yes';
        cfg.skipscale = 'yes';
        evalc('layout = ft_prepare_layout(cfg);');
        rmChannels = layout.label(not(ismember(layout.label, connectivity.label)));
        if not(isempty(rmChannels))
            connectivity = addRemovedChannels(connectivity, rmChannels);
        end
end

%%%%%% save data %%%%%%
if strcmpi(saveData, 'yes')
    
    outputFilename = [subjectdata.subjectName '_' outputName '.mat'];
    fieldname = upper(outputName);
    subjectdata.PATHS.(fieldname) = [subjectdata.PATHS.SUBJECTDIR filesep ...
        outputFilename];
    
    if ~quiet
        fprintf('\t saving %s ... ', outputFilename)
        save(subjectdata.PATHS.(fieldname), 'connectivity')
        fprintf('done! \n')
        
        fprintf('\t saving subjectdata variable to Subject.mat ... ')
        save([subjectdata.PATHS.SUBJECTDIR filesep 'Subject.mat'], 'subjectdata')
        fprintf('done! \n')
    else
        save(subjectdata.PATHS.(fieldname), 'connectivity')
        
        save([subjectdata.PATHS.SUBJECTDIR filesep 'Subject.mat'], 'subjectdata')
    end
    if isfield(PATHS, 'SUMMARY')
        if ~quiet
            bv_updateSubjectSummary([PATHS.SUMMARY filesep 'SubjectSummary'], subjectdata)
        end
    end
    
end
end
%%%%%% extra functions %%%%%%
function connectivity = addRemovedChannels(connectivity, trueRmChannels)

connectivity.label = cat(1,connectivity.label, trueRmChannels);

fnames = fieldnames(connectivity);
fname2use = fnames{not(cellfun(@isempty, strfind(fnames, 'spctrm')))};

currSpctrm = connectivity.(fname2use);
startRow = (size(currSpctrm,1) + 1);
endRow = (size(currSpctrm,1)) + length(trueRmChannels);
currSpctrm(1:size(currSpctrm,1), startRow:endRow, :) = NaN;
currSpctrm(startRow:endRow, 1:size(currSpctrm,2), :) = NaN;

cfg = [];
cfg.channel  = connectivity.label;
cfg.layout   = 'EEG1010';
cfg.feedback = 'no';
cfg.skipcomnt   = 'yes';
cfg.skipscale   = 'yes';
evalc('lay = ft_prepare_layout(cfg);');

[~, indxSort] = ismember(lay.label, connectivity.label);
indxSort = indxSort(any(indxSort,2));

currSpctrm = currSpctrm(indxSort, indxSort,:,:);
connectivity.label = connectivity.label(indxSort);
connectivity.(fname2use) = currSpctrm;
end