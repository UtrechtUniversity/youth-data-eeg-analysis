function freq = bv_calculateFrequency(cfg, data)
% Computes a frequency spectrum for EEG data using ft_freqanalysis.
%
% Args:
%     cfg.currSubject (str): Subject folder name. Required when no data
%         is provided.
%     cfg.inputName (str): Field name in ``subjectdata.PATHS`` used to load
%         input data. Required when no data is provided.
%     cfg.saveData (str): Whether to save output to disk (``'yes'`` or
%         ``'no'``). Defaults to ``'no'``.
%     cfg.outputName (str): Unique label for output file and
%         ``subjectdata.PATHS`` entry. Required when saving data.
%     cfg.method (str, optional): Spectral estimation method passed to
%         ``ft_freqanalysis``. Defaults to ``'mtmfft'``.
%     cfg.taper (str, optional): Tapering window. Defaults to ``'hanning'``.
%     cfg.foi (numeric, optional): Frequencies of interest in Hz.
%         Defaults to ``1:35``.
%     cfg.channel (cell array of str, optional): Channel selection passed to
%         ``ft_freqanalysis``. Defaults to ``{'EEG'}``.
%     cfg.keeptrials (str, optional): Whether to retain per-trial spectra
%         (``'yes'`` or ``'no'``). Defaults to ``'yes'``.
%     cfg.pathsFcn (str, optional): Paths function filename. Defaults to
%         ``'setPaths'``.
%     cfg.optionsFcn (str, optional): Options function filename. Defaults to
%         ``'setOptionsPower'``.
%     cfg.overwrite (str, optional): Whether to overwrite existing output
%         (``'yes'`` or ``'no'``). Defaults to ``'no'``.
%     cfg.quiet (str, optional): Suppress command window output
%         (``'yes'`` or ``'no'``). Defaults to ``'no'``.
%     data (struct, optional): FieldTrip data structure. If omitted, loaded
%         from disk using ``cfg.currSubject`` and ``cfg.inputName``.
%
% Returns:
%     freq (struct): FieldTrip frequency structure with ``powspctrm``,
%         ``freq``, ``label``, ``trialinfo``, and ``dimord`` fields. Returns
%         empty (``[]``) if output already exists and ``cfg.overwrite`` is
%         ``'no'``.
%
% Example:
%     ```matlab
%     cfg             = [];
%     cfg.currSubject = 'B12345_10m';
%     cfg.inputName   = 'APPEND';
%     cfg.outputName  = 'FREQ';
%     cfg.saveData    = 'yes';
%     freq = bv_calculateFrequency(cfg);
%     ```

%% get options
currSubject = ft_getopt(cfg, 'currSubject');
inputName   = ft_getopt(cfg, 'inputName');
saveData    = ft_getopt(cfg, 'saveData', 'no');
outputName  = ft_getopt(cfg, 'outputName');
method      = ft_getopt(cfg, 'method', 'mtmfft');
taper       = ft_getopt(cfg, 'taper', 'hanning');
foi         = ft_getopt(cfg, 'foi', 1:35);
channel     = ft_getopt(cfg, 'channel', {'EEG'});
keeptrials  = ft_getopt(cfg, 'keeptrials', 'yes');
pathsFcn    = ft_getopt(cfg, 'pathsFcn', 'setPaths');
optionsFcn  = ft_getopt(cfg, 'optionsFcn', 'setOptionsPower');
overwrite   = ft_getopt(cfg, 'overwrite', 'no');
quiet       = ft_getopt(cfg, 'quiet', 'no');

quiet = strcmpi(quiet, 'yes');

%% load data (if necessary)
if nargin < 2
    if ~quiet; disp(currSubject); end
    eval(pathsFcn)
    eval(optionsFcn)

    subjectFolderPath = fullfile(PATHS.SUBJECTS, currSubject);

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
                freq = [];
                return
            end
        end
    end

    subjectdata.cfgs.(outputName) = cfg;

elseif isfield(cfg, 'currSubject')
    eval(pathsFcn)
    subjectFolderPath = fullfile(PATHS.SUBJECTS, currSubject);

    if ~quiet
        [subjectdata, check] = bv_check4data(subjectFolderPath);
        if ~check
            error('%s: Subject.mat not found', currSubject)
        end
    else
        evalc('[subjectdata, check] = bv_check4data(subjectFolderPath);');
        if ~check %#ok<NODEF>
            error('%s: Subject.mat not found', currSubject)
        end
    end
end

%% run ft_freqanalysis
if ~quiet; fprintf('\t calculating frequency spectrum ... '); end
ftcfg            = [];
ftcfg.method     = method;
ftcfg.output     = 'pow';
ftcfg.taper      = taper;
ftcfg.foi        = foi;
ftcfg.channel    = channel;
ftcfg.keeptrials = keeptrials;
evalc('freq = ft_freqanalysis(ftcfg, data);');
if ~quiet; fprintf('done \n'); end

%% save data
if strcmpi(saveData, 'yes')
    outputFilename = [subjectdata.subjectName '_' outputName '.mat']; %#ok<NODEF>
    fieldname = upper(outputName);
    subjectdata.PATHS.(fieldname) = fullfile(subjectdata.PATHS.POWERDIR, outputFilename);

    if ~quiet
        fprintf('\t saving %s ... ', outputFilename);
        save(subjectdata.PATHS.(fieldname), 'freq')
        fprintf('done \n')
        fprintf('\t saving subjectdata variable to Subject.mat ... ')
        save(fullfile(subjectdata.PATHS.SUBJECTDIR, 'Subject.mat'), 'subjectdata')
        fprintf('done \n')
    else
        save(subjectdata.PATHS.(fieldname), 'freq')
        save(fullfile(subjectdata.PATHS.SUBJECTDIR, 'Subject.mat'), 'subjectdata')
    end
end
