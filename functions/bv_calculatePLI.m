function [ connectivity ] = bv_calculatePLI(cfg, data)
% Calculates PLI values for specified frequency ranges.
%
% Args:
%     cfg.currSubject (str): Subject folder name. Always required, since
%         the continuous data is read in again from the subject's raw file
%         (see ``cfg.preprocOptions``).
%     cfg.inputName (str): Field name in ``subjectdata.PATHS`` used to load
%         the clean-trial definitions (``data``). Required when no data is
%         provided.
%     cfg.saveData (str, optional): Whether to save output to disk
%         (``'yes'`` or ``'no'``). Subject.mat is saved whenever this
%         function runs, whatever this is set to. Defaults to ``'no'``.
%     cfg.outputName (str): Unique label for output file, its
%         ``subjectdata.PATHS`` entry, and this run's config in
%         ``subjectdata.cfgs``. Required when saving data.
%     cfg.ntrials (int or str, optional): Number of trials to use.
%         Defaults to ``'all'``.
%     cfg.condition (str, optional): Condition codes to include.
%         Defaults to ``'all'``.
%     cfg.freqBands (struct, optional): Fields are band labels, values are
%         ``[low high]`` Hz ranges used to band-pass filter the continuous
%         signal before PLI is computed for that band (matching the
%         cfg.freqBands convention used by bv_extractROIPower). Defaults to
%         the same bands used by the power-estimates steps: delta, theta,
%         alpha, beta, gamma, infantTheta, infantAlpha, total. Band order
%         (and therefore column order downstream) follows
%         fieldnames(cfg.freqBands), i.e. the order the fields were
%         assigned in.
%     cfg.preprocOptions (struct, optional): FieldTrip ``cfg`` struct
%         passed to ``bv_preprocResample`` before PLI calculation.
%         Defaults to ``[]``.
%     cfg.triallength (int, optional): Trial length in seconds for cutting
%         appended data before PLI calculation. Not applied when omitted.
%     cfg.keeptrials (str, optional): Whether to retain per-trial PLI values
%         (``'yes'`` or ``'no'``). Defaults to ``'no'``.
%     cfg.pathsFcn (str, optional): Paths function filename. Must resolve
%         to a valid file on the MATLAB path. Defaults to ``'setPaths'``.
%     cfg.overwrite (str, optional): Whether to overwrite existing output
%         (``'yes'`` or ``'no'``). Defaults to ``'no'``.
%     cfg.quiet (str, optional): Suppress command window output
%         (``'yes'`` or ``'no'``). Defaults to ``'no'``.
%     data (struct, optional): FieldTrip data structure containing
%         multiple trials. Only its ``sampleinfo`` and ``trialinfo`` are
%         used to cut the clean trials out of the re-read data. If omitted,
%         it is loaded from disk using ``cfg.currSubject`` and
%         ``cfg.inputName``.
%
% Returns:
%     connectivity (struct): PLI connectivity structure with fields
%         ``plispctrm`` (chan x chan x freq, or chan x chan x trial x freq
%         when ``cfg.keeptrials`` is ``'yes'``), ``dimord``, ``freq``,
%         ``freqRng``, ``freqBands``, ``label``, and ``trialinfo``. Returns
%         empty (``[]``) if output already exists and ``cfg.overwrite`` is
%         ``'no'``.
%
% Example:
%     Calculate PLI for the theta band and save to disk:
%
%     ```matlab
%     cfg = [];
%     cfg.currSubject = 'B12345_99m';
%     cfg.inputName   = 'CLEANED';
%     cfg.outputName  = 'PLI_THETA';
%     cfg.saveData    = 'yes';
%     cfg.freqBands.theta = [4 7];
%     connectivity = bv_calculatePLI(cfg);
%     ```

%% get options
ntrials         = ft_getopt(cfg, 'ntrials','all');
condition       = ft_getopt(cfg, 'condition', 'all');
currSubject     = ft_getopt(cfg, 'currSubject');
inputName       = ft_getopt(cfg, 'inputName');
saveData        = ft_getopt(cfg, 'saveData', 'no');
outputName      = ft_getopt(cfg, 'outputName');
pathsFcn        = ft_getopt(cfg, 'pathsFcn', 'setPaths');
triallength     = ft_getopt(cfg, 'triallength');
keeptrials      = ft_getopt(cfg, 'keeptrials', 'no');
quiet           = ft_getopt(cfg, 'quiet');
preprocOptions  = ft_getopt(cfg, 'preprocOptions', []);
overwrite       = ft_getopt(cfg, 'overwrite', 'no');

%% default frequency bands (matching the power-estimates steps' bands)
defaultFreqBands.delta       = [1 3];   % Hz
defaultFreqBands.theta       = [4 7];   % Hz
defaultFreqBands.alpha       = [8 12];  % Hz
defaultFreqBands.beta        = [13 25]; % Hz
defaultFreqBands.gamma       = [26 35]; % Hz
defaultFreqBands.infantTheta = [3 6];   % Hz
defaultFreqBands.infantAlpha = [6 9];   % Hz
defaultFreqBands.total       = [1 35];  % Hz

freqBands = ft_getopt(cfg, 'freqBands', defaultFreqBands);
freqLabel = fieldnames(freqBands);
freqRng   = struct2cell(freqBands);

if strcmpi(quiet, 'yes')
    quiet = true;
else
    quiet = false;
end

if isempty(currSubject)
    error('bv_calculatePLI: cfg.currSubject is required (the continuous data is read in again from the subject''s raw file)')
end
if strcmpi(saveData, 'yes') && isempty(outputName)
    error('bv_calculatePLI: cfg.outputName is required when cfg.saveData is ''yes''')
end

%% load in data (if necessary)
if nargin < 2
    if ~quiet; disp(currSubject); end
    eval(pathsFcn)

    subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];

    if ~quiet
        [subjectdata, check, data] = bv_check4data(subjectFolderPath, inputName);
        if ~check
            error('%s: input data not found', currSubject)
        end
    else
        evalc('[subjectdata, check, data] = bv_check4data(subjectFolderPath, inputName);');
        if ~check %#ok<NODEF>
            error('%s: input data not found', currSubject)
        end
    end

    if strcmpi(overwrite, 'no')
        if isfield(subjectdata.PATHS, upper(outputName))
            if exist(subjectdata.PATHS.(upper(outputName)), 'file')
                if ~quiet; fprintf('\t ⚠ %s already found, not overwriting ... \n', upper(outputName)); end
                connectivity = [];
                return
            end
        end
    end

    if ~isempty(outputName)
        subjectdata.cfgs.(outputName) = cfg;
    end
else

    eval(pathsFcn)

    subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];

    if ~quiet
        [subjectdata, check] = bv_check4data(subjectFolderPath);
        if ~check
            error('%s: Subject.mat not found', currSubject)
        end
    else
        evalc('[subjectdata, check] = bv_check4data(subjectFolderPath);');
        if ~check
            error('%s: Subject.mat not found', currSubject)
        end
    end

    if ~isempty(outputName)
        subjectdata.cfgs.(outputName) = cfg;
    end
end

if ~quiet; fprintf('\t loading in original data ...'); end
cfg = preprocOptions;
cfg.currSubject = currSubject;
cfg.saveData = 'no';
cfg.trialfun = '';
evalc('origdata = bv_preprocResample(cfg);');
if ~quiet; fprintf('done \n'); end

%% calculate PLIs
for iFreq = 1:length(freqLabel)
    currFreq = freqLabel{iFreq};
    currFreqRng = freqRng{iFreq};
    if ~quiet; fprintf('\t filtering for %s ... ' , currFreq); end
    cfg = [];
    cfg.lpfilter = 'yes';
    cfg.lpfreq = currFreqRng(2);
    cfg.lpinstabilityfix = 'reduce';
    cfg.hpfilter = 'yes';
    cfg.hpfreq = currFreqRng(1);
    cfg.hpinstabilityfix = 'reduce';
    evalc('origdata_filt = ft_preprocessing(cfg, origdata);');

    if ~quiet; fprintf('\t cut out clean data according to input file ... \n'); end
    trl = [data.sampleinfo, zeros(size(data.sampleinfo,1),1), data.trialinfo];
    cfg = [];
    cfg.trl = trl;
    evalc('origdata_filt = ft_redefinetrial(cfg, origdata_filt);');

    % cut, if needed data into trials
    if ~isempty(triallength)
        cfg = [];
        cfg.saveData = 'no';
        cfg.triallength = triallength;
        cfg.ntrials = ntrials;
        if ~quiet
            [dataCut, finished] = bv_cutAppendedIntoTrials(cfg, origdata_filt);
        else
            evalc('[dataCut, finished] = bv_cutAppendedIntoTrials(cfg, origdata_filt);');
        end

        if ~finished
            connectivity = [];
            return;
        end
    else
        dataCut = origdata_filt;
    end

    if not(strcmpi(condition, 'all'))
        cfg = [];
        cfg.trials = find(ismember(dataCut.trialinfo, condition));
        evalc('dataCut = ft_selectdata(cfg, dataCut);');
    end

    if ~quiet; fprintf('\t calculating PLI ... '); end
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

connectivity.freq      = freqLabel;
connectivity.freqRng   = freqRng;
connectivity.freqBands = freqBands;
connectivity.label     = dataCut.label;
connectivity.trialinfo = dataCut.trialinfo;

%% save data
if strcmpi(saveData, 'yes')

    outputFilename = [subjectdata.subjectName '_' outputName '.mat'];
    fieldname = upper(outputName);
    subjectdata.PATHS.(fieldname) = [subjectdata.PATHS.NETMETDIR filesep ...
        outputFilename];

    if ~quiet
        fprintf('\t saving %s ... ', outputFilename);
        save(subjectdata.PATHS.(fieldname), 'connectivity')
        fprintf('done \n')
        fprintf('\t saving subjectdata variable to Subject.mat ... ')
        save([subjectdata.PATHS.SUBJECTDIR filesep 'Subject.mat'], 'subjectdata')
        fprintf('done \n')
    else
        save(subjectdata.PATHS.(fieldname), 'connectivity')
        save([subjectdata.PATHS.SUBJECTDIR filesep 'Subject.mat'], 'subjectdata')
    end

else
    save([subjectdata.PATHS.SUBJECTDIR filesep 'Subject.mat'], 'subjectdata')
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
