function [ data, subjectdata ] = bv_preprocResample(cfg)
% bv_preprocResample reads-in, preprocesses (and resamples) raw EEG data,
% based on FT_PREPROCESSING of the fieldtrip toolbox and applies several
% user-specified preprocessing steps to the signals. The function uses
% subject information (stored in an individual Subject.mat file) gathered
% with the BV_CREATESUBJECTFOLDERS, so please run that function first.
% Order of preprocessing:
%           1) reading-in data
%           2) resampling
%           3) rereferencing
%           4) interpolating bad channels
%           5) filtering
%           6) cut data in trials
%
% Use as
% [ data ] = bv_preprocResample( cfg )
%
% The input argument cfg is a configuration structure, which contains all
% details for the preprocessing of the dataset.
%
% This function can be ran in two different ways. 1) After running
% BV_CREATESUBJECTFOLDERS, which creates unique subject folders for each
% participant and saves a unique Subject.mat file in each folder with
% subjectdata pertaining the experiment. 2) Running with a
% dataset and hdrfile input.
%
% For the first option the configuration structure needs to contain:
%   cfg.currSubject     = 'string': subject folder name of the subject to
%                           be analyzed (found in PATHS.SUBJECTS)
%   cfg.pathsFcn        = 'string': filename of m-file to be read with all
%                           necessary paths to run this function (default:
%                           'setPaths'). Take care to add your trialfun
%                           to your matlab path). For an example paths
%                           fcn see setPaths.m
%   cfg.saveData        = 'yes/no': specifies whether data needs to be
%                           saved to personal folder (default: 'no')
%   cfg.outputName      = 'string': addition to filename when saving, so
%                           that the output filename becomes [currSubject
%                           outputName .mat]. outputName is also used used to
%                           save path two outputfile in the individuals
%                           Subject.mat file (default: 'preproc')
%   cfg.quiet           = true/false: set to true to prevent additional
%                           details in command window (default: false)
%
% For the second option the configuration structure needs to contain:
%   cfg.dataset         = 'string': filename of the dataset to be used
%   cfg.headerfile      = 'string': filename of the headerfile to be used
%
%
% Optional arguments that can be specified in both use cases
%   cfg.quiet           = true/false: set to true to prevent additional
%                           details in command window (default: false)
%   cfg.overwrite       = 'yes/no': set to 'yes' if already existing data
%                           should not be overwritten (default: 'no')
%
% Input arguments that should be specified when cutting data in trials
%   cfg.trialfun        = 'string': filename of trialfun to be used for
%                           the preprocessing (take care to add your
%                           trialfun to your matlab path). See for example
%                           TRIALFUN_YOUTH_3Y. If the creation of trials is
%                           unnecessary, leave empty.
%
% Input arguments that should be specified when resampling data
%   cfg.resampleFs      = [ double ]: specify new sampling rate (default:
%                           no resampling)
%
% Input arguments that should be specified when filtering data
%   cfg.hpfreq          = [ double ]: high-pass filter frequency cut-off,
%                           (default: [])
%   cfg.lpfreq          = [ double ]: low-pass filter frequency cut-off,
%                           (default: [])
%   cfg.notchfreq       = [ double ]: notch filter frequency, (default: [])
%   cfg.filttype        = 'string': filter type, possible options 'but'
%                           (two-pass butterworth filter) or 'firws' (fir
%                           windowed sync). (default: 'but')
%
% Input arguments that should be specified when referencing data
%   cfg.reref           = 'yes/no': specifies whether data needs to be
%                           rereference (default: 'no')
%   cfg.refelec         = 'string' or { cell }: with EEG rereference
%                           channel(s), can be 'all' for common average
%                           reference (default: 'all')
%
%
% Input arguments that should be specificied when removing channels
%   cfg.rmChannels      = 'yes/no': Set to yes if channels need to be
%                           removed (default: 'no').
%   cfg.channels2remove = 'string': or {cell} with strings. Labels of
%                           channels to be removed. If empty (''), channels
%                           will be removed based on
%                           subjectdata.channels2remove. In that case,
%                           make sure you run bv_removeChannels first
%   cfg.interpolate     = 'yes/no': specifies whether missing channels need
%                           to be interpolated (triangulation neighbors,
%                           weighted method)
%   cfg.mandatoryChans  = { cell }, with all channel labels that are
%                           mandatory (subject will be removed if these
%                           are absent), (default: {})
%
% See also BV_CREATESUBJECTFOLDERS, BV_SORTBASEDONTOPO,
% BV_RESAMPLEEEGDATA, BV_SAVEDATA, BV_FILTEREEGDATA, FT_CHANNELSELECTION,
% FT_PREPROCESSING,FT_RESAMPLEDATA

global PATHS

% read in data from configuration file and (if necessary) set defaults
currSubject         = ft_getopt(cfg, 'currSubject');
pathsFcn            = ft_getopt(cfg, 'pathsFcn');
trialfun            = ft_getopt(cfg, 'trialfun');
pretrig             = ft_getopt(cfg, 'pretrig');
posttrig            = ft_getopt(cfg, 'pretrig');
saveData            = ft_getopt(cfg, 'saveData', 'no');
outputName          = ft_getopt(cfg, 'outputName', 'preproc');
resampleFs          = ft_getopt(cfg, 'resampleFs');
hpfreq              = ft_getopt(cfg, 'hpfreq');
lpfreq              = ft_getopt(cfg, 'lpfreq');
notchfreq           = ft_getopt(cfg, 'notchfreq');
filttype            = ft_getopt(cfg, 'filttype');
reref               = ft_getopt(cfg, 'reref', 'no');
refelec             = ft_getopt(cfg, 'refelec', 'all');
refmethod           = ft_getopt(cfg, 'refmethod', 'avg');
removechans         = ft_getopt(cfg, 'removechans', 'no');
channels2remove     = ft_getopt(cfg, 'channels2remove');
dataset             = ft_getopt(cfg, 'dataset');
hdrfile             = ft_getopt(cfg, 'hdrfile');
overwrite           = ft_getopt(cfg, 'overwrite', 'no');
interpolate         = ft_getopt(cfg, 'interpolate', 'no');
quiet               = ft_getopt(cfg, 'quiet', 'no');
waveletThresh       = ft_getopt(cfg, 'waveletThresh', 'no');
channels            = ft_getopt(cfg, 'channels');
chanindx            = ft_getopt(cfg, 'chanindx');

quiet = strcmpi(quiet, 'yes');

if ~isempty(dataset) && ~isempty(hdrfile)
    if ~quiet
        fprintf('running with raw \n \t dataset: %s and \n \t hdrfile: %s \n ', ...
            dataset, hdrfile)
        fprintf('**********************************************************\n')
        fprintf('\n')
    end
    hasdata = 1;
    if strcmpi(saveData, 'yes')
        warning('data can not be saved when given dataset and hdrfile inputs, not saving ... ')
        saveData = 'no';
    end
else
    if isempty(currSubject)
        error('no dataset and hdrfile given, while no currSubject is known')
    end
    %     fprintf('running with subject.mat file of %s ', currSubject)
    hasdata = 0;
    saveSubjectData = 'yes';
end

if ~hasdata % check whether data needs to be loaded from subject.mat file
    
    eval(pathsFcn) % get paths necessary to run function
    
    if ~quiet; disp(currSubject); end
    if strcmpi(overwrite, 'no') & strcmpi(saveData, 'yes') & ...
            exist([PATHS.SUBJECTS filesep currSubject filesep currSubject '_' upper(outputName) '.mat'])
        if ~quiet
            fprintf('\t !!!%s already found, not overwriting ... \n', upper(outputName))
        end
        data = [];
        return
    end


    % Try to load in individuals Subject.mat. If unknown --> throw error.
    try
        load([PATHS.SUBJECTS filesep currSubject filesep 'Subject.mat'], 'subjectdata')
    catch
        error('Subject.mat file not found')
    end
    
    if ~quiet; fprintf('\t Setting up for preprocessing ... '); end
    
    hdrfile = subjectdata.PATHS.HDRFILE;
    dataset = subjectdata.PATHS.DATAFILE;
    
    fid = fopen(dataset, 'r');
    ln1 = fgetl(fid);
    ln2 = fgetl(fid);
    
    if ln2 == -1
        if ~quiet; fprintf('\n \t \t bdf file incomplete, removing subject and continueing ... \n'); end
        subjectdata.nTrialsPreproc = 0;
        
        if ~quiet
            bv_saveData(subjectdata)
        else
            evalc('bv_saveData(subjectdata);');
        end
        cfg = [];
        cfg.optionsFcn = 'setOptions';
        cfg.pathsFcn = 'setPaths';
        removingSubjects(cfg, currSubject, 'preprocessing - incomplete bdf file')
        data = [];
        return
    end
    if ~quiet; fprintf('done! \n'); end
else
    
    if ~quiet; fprintf('done! \n'); end
end

if ~isempty(chanindx)
    evalc('hdr = ft_read_header(hdrfile, ''chanindx'', chanindx);');
elseif length(channels)>1
    chanindx = bv_checkChannels(hdrfile, channels);
    evalc('hdr = ft_read_header(hdrfile, ''chanindx'', chanindx);');
else
    evalc('hdr = ft_read_header(hdrfile);');
    chanindx = 1:length(hdr.label);
end

removingChans = strcmpi(removechans, 'yes');
if removingChans && ~isempty(channels2remove)
    if isfield(subjectdata, 'channels2remove')
        if ~isempty(subjectdata.channels2remove)
            warning('\t overwriting subjectdata.channels2remove with given cfg.channels2remove \n')
        end
    end
    subjectdata.channels2remove = channels2remove;
end

% If channels should be interpolated, but no channels are to be removed, no
% new file will be created (compared to already existing file). Therefore,
% skip this subject
if strcmpi(interpolate, 'yes')
    if isempty(subjectdata.channels2remove) & isfield(subjectdata.PATHS, 'PREPROC')
        subjectdata.PATHS.(outputName) = subjectdata.PATHS.PREPROC;
        if ~quiet; fprintf('\t no channels found to remove, continueing...'); end
        evalc('[~,~, data] = bv_check4data(subjectdata.PATHS.SUBJECTDIR, ''PREPROC'');');
        
        if strcmpi(saveData, 'yes')
            
            if ~quiet
                bv_saveData(subjectdata);              % save both data and subjectdata to the drive
                bv_updateSubjectSummary([PATHS.SUMMARY filesep 'SubjectSummary'], subjectdata)
            else
                evalc('bv_saveData(subjectdata);');
            end
        end
        
        return
    end
end

subjectdata.cfgs.(outputName) = cfg; % save used config file in subjectdata
subjectdata.trialfun = trialfun;

if ~quiet; fprintf('\t loading in data ... '); end

cfg = [];

% only read in EEG data (without possible removed channels)
if removingChans && isfield(subjectdata, 'channels2remove')
    if ~isempty(subjectdata.channels2remove)

        layout = bv_getLayoutType(hdr);

        cfg.channel = channels;
        cfg.layout = layout;
        cfg.method = 'triangulation';
        cfg.feedback = 'no';
        evalc('neighbours = ft_prepare_neighbours(cfg);');
        
        if ~quiet; fprintf(['\n \t\t skipping following channel(s): ' ...
            repmat('%s, ', 1,length(subjectdata.channels2remove))], subjectdata.channels2remove{:}); end
        cfg = [];
        cfg.channel = cat(2, channels{:}, strcat('-',subjectdata.channels2remove'));
        
    else
        cfg.channel = channels;
    end
else
    cfg.channel = channels;
end

cfg.dataset = dataset;
cfg.headerfile = hdrfile;
cfg.continuous = 'yes';
cfg.chanindx = chanindx;

evalc('data = ft_preprocessing(cfg);');

if ~quiet; fprintf('done! \n'); end

if strcmpi(interpolate, 'yes')
    if isfield(subjectdata, 'channels2remove')
        if ~isempty(subjectdata.channels2remove)
            if ~quiet
                fprintf(['\t the following channels will be interpolated ... ', ...
                    repmat('%s, ',1, length(subjectdata.channels2remove))], subjectdata.channels2remove{:})
            end
            layout = bv_getLayoutType(hdr);

            cfg = [];
            cfg.missingchannel = subjectdata.channels2remove';
            cfg.method = 'average';
            cfg.neighbours = neighbours;
            cfg.layout = layout;
            evalc('data = ft_channelrepair(cfg, data);');
            if ~quiet; fprintf('done! \n'); end
        end
    end
end

% if ~quiet
%     data = bv_sortBasedOnTopo(data); % sorting data based on actual place of the electrodes. See function for more detail.
% else
%     evalc('data = bv_sortBasedOnTopo(data);');
% end

% *** Resampling (if a resampleFs is given)
if ~isempty(resampleFs)
    
    if ~quiet; fprintf('\t Resampling data from %s to %s ... ', num2str(data.fsample), num2str(resampleFs)); end
    cfg = [];
    cfg.resamplefs  = resampleFs;
    % cfg.detrend     = 'yes';
    evalc('data = ft_resampledata(cfg, data);');
    
    if ~quiet; fprintf('done! \n'); end
end

% *** Filtering data (if a hpfreq, lpfreq, or notchfreq is given).
% See BV_FILTEREEGDATA for more info
if ~(isempty(hpfreq) && isempty(lpfreq) && isempty(notchfreq))
    
    cfg.hpfreq      = hpfreq;
    cfg.lpfreq      = lpfreq;
    cfg.notchfreq   = notchfreq;
    cfg.filttype    = filttype;
    
    if ~quiet
        data = bv_filterEEGdata(cfg, data);
    else
        evalc('data = bv_filterEEGdata(cfg, data);');
    end
end


if strcmpi(reref, 'yes')
    if ~quiet; fprintf('\t rereferencing to %s electrode ... ', refelec); end
    
    cfg = [];
    cfg.reref = 'yes';
    cfg.refchannel = refelec;
    cfg.refmethod = refmethod;
    evalc('data = ft_preprocessing(cfg, data);');
    
    if ~quiet; fprintf('done!\n'); end
end

wavelet_thresholding = strcmpi(waveletThresh, 'yes');
if wavelet_thresholding
    if ~quiet; fprintf('\t Wavelet thresholding, based on HAPPE_v3 ...'); end
    
    wavFam = 'bior4.4' ;
    if data.fsample > 500
        wavLvl = 10;
    elseif data.fsample > 250 && data.fsample <= 500 
        wavLvl = 9;
    elseif data.fsample <=250 
        wavLvl = 8;
    end
    
    ThresholdRule = 'Hard' ;
    
    artfcs = wdenoise(data.trial{1}', wavLvl, ...
        'Wavelet', wavFam, 'DenoisingMethod', 'Bayes', 'ThresholdRule', ...
        ThresholdRule, 'NoiseEstimate', 'LevelDependent')' ;
    
    preEEG = reshape(data.trial{1}, size(data.trial{1},1), []) ;
    postEEG = preEEG - artfcs;
    data.trial{1} = postEEG;
    if ~quiet; fprintf('done! \n'); end
end

% *** cut data into trials based on trialfun
% Your trialfun detects the epochs in your data and adds them to a trl
% variable. It's very important that if you've resampled your data, you use your
% updated sample info. See for example trialfun_YOUth_3Y. In this trialfun
% the event codes (and sample info) are read in from the raw EEG files and
% converted to resampled values. These are used in ft_redefinetrial to
% redefine the trialstructure of the data file
if ~isempty(trialfun)
    if ~quiet; fprintf('\t Redefining trialstructure based on %s ... \n', trialfun); end
    
    subjectdata.trialfun = trialfun;
    
    cfg = [];
    cfg.dataset = dataset;
    cfg.headerfile = hdrfile;
    cfg.trialfun = trialfun;
    cfg.trialdef.pretrig = pretrig; % when to make a cut before stim presentation
    cfg.trialdef.posttrig = posttrig; % when to make a cut after stim presentation
    if isempty(resampleFs)
        cfg.Fs = hdr.Fs;
    else
        cfg.Fs = resampleFs;
    end
    
    eval(['[trl] = ' trialfun '(cfg);'])
    
    if isempty(trl)
        if ~quiet; fprintf('\n \t \t no trials found, removing subject and continueing ... \n'); end
        subjectdata.nTrialsPreproc = 0;
        if ~quiet
            bv_saveData(subjectdata)
        else
            evalc('bv_saveData(subjectdata);');
        end
        cfg = [];
        cfg.optionsFcn = 'setOptions';
        cfg.pathsFcn = 'setPaths';
        removingSubjects(cfg, currSubject, 'preprocessing - no trials found')
        return
    else
        evalc('cfg = ft_definetrial(cfg);');
    end
            
    if~quiet
        trlCount = bv_showTrialAmount(cfg);
    else
        evalc('trlCount = bv_showTrialAmount(cfg);');
    end
    subjectdata.nTrialsPreproc = sum(trlCount);
    evalc('data = ft_redefinetrial(cfg, data);');
    
    
end

% saving data
if strcmpi(saveData, 'yes')
    if ~quiet
        bv_saveData(subjectdata, data, outputName);              % save both data and subjectdata to the drive
    else
        evalc('bv_saveData(subjectdata, data, outputName);');              % save both data and subjectdata to the drive
    end
elseif strcmpi(saveSubjectData, 'yes')
    if ~quiet
        bv_saveData(subjectdata);              % save subjectdata to the drive
    else
        evalc('bv_saveData(subjectdata);');              % save subjectdata to the drive
    end
end