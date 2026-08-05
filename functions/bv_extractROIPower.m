function power = bv_extractROIPower(cfg, freq)
% Extracts ROI- and band-specific power from a FieldTrip frequency structure.
%
% For each condition, ROI, and frequency band specified in cfg, the function
% computes absolute log10 power and relative power (band vs total range).
% A 'Global' entry using all channels is appended after the named ROIs.
% Results are returned as a MATLAB table within the output struct.
%
% Args:
%     cfg.currSubject (str): Subject folder name. Required when no freq is
%         provided.
%     cfg.inputName (str): Field name in ``subjectdata.PATHS`` used to load
%         the frequency data. Required when no freq is provided.
%     cfg.saveData (str): Whether to save output to disk (``'yes'`` or
%         ``'no'``). Defaults to ``'no'``.
%     cfg.outputName (str): Unique label for output file and
%         ``subjectdata.PATHS`` entry. Required when saving data.
%     cfg.conditions (numeric, optional): Condition codes to process
%         separately. Set to ``[]`` to pool all trials (condLabel = 0 in
%         output). Defaults to ``[]``.
%     cfg.ROI (struct, optional): Struct where each field name is an ROI
%         label and its value is a cell array of channel labels to average.
%         Defaults to a set of standard frontal, central, parietal, and
%         occipital ROIs.
%     cfg.freqBands (struct, optional): Struct defining frequency bands.
%         Must contain a ``total`` field (used as the denominator for
%         relative power). All other fields are treated as named bands.
%         Each value is a ``[low high]`` vector in Hz. Defaults to
%         theta [3 6], alpha [6 9], total [1 35].
%     cfg.calcMethod (str, optional): Whether to store absolute/relative
%         power as raw values (``'raw'``) or log10 values (``'log10'``).
%         Defaults to ``'raw'``.
%     cfg.pathsFcn (str, optional): Paths function filename. Defaults to
%         ``'setPaths'``.
%     cfg.optionsFcn (str, optional): Options function filename. Defaults to
%         ``'setOptionsPower'``.
%     cfg.overwrite (str, optional): Whether to overwrite existing output
%         (``'yes'`` or ``'no'``). Defaults to ``'no'``.
%     cfg.quiet (str, optional): Suppress command window output
%         (``'yes'`` or ``'no'``). Defaults to ``'no'``.
%     freq (struct, optional): FieldTrip frequency structure from
%         ``bv_calculateFrequency``. If omitted, loaded from disk.
%
% Returns:
%     power (struct): Struct with fields ``table`` (MATLAB table with columns
%         Subject, Wave, Condition, ROI, plus one ``_abs`` and one ``_rel``
%         column per named band, and Total), ``freqBands``, ``ROI``,
%         ``conditions``, and ``calcMethod``. Returns empty (``[]``) if
%         output already exists and ``cfg.overwrite`` is ``'no'``.
%
% Example:
%     ```matlab
%     cfg             = [];
%     cfg.currSubject = 'B12345_10m';
%     cfg.inputName   = 'FREQ';
%     cfg.outputName  = 'POWER';
%     cfg.saveData    = 'yes';
%     cfg.conditions  = [129 139];
%     power = bv_extractROIPower(cfg);
%     ```

%% default ROI and frequency band definitions
defaultROI.Frontal       = {'Fp1','Fp2','AF3','AF4','Fz'};
defaultROI.LeftFrontal   = {'F3','F7','FC5','FC1'};
defaultROI.RightFrontal  = {'F4','F8','FC6','FC2'};
defaultROI.Central       = {'C3','C4','CP1','CP2','Cz'};
defaultROI.LeftParietal  = {'T7','CP5','P7','P3'};
defaultROI.RightParietal = {'T8','CP6','P8','P4'};
defaultROI.Occipital     = {'PO3','PO4','O1','Oz','O2','Pz'};

defaultBands.delta = [1 3];
defaultBands.theta = [3 5];
defaultBands.alpha = [5 15];
defaultBands.total = [1 15];

%% get options
currSubject = ft_getopt(cfg, 'currSubject');
inputName   = ft_getopt(cfg, 'inputName');
saveData    = ft_getopt(cfg, 'saveData', 'no');
outputName  = ft_getopt(cfg, 'outputName');
conditions  = ft_getopt(cfg, 'conditions', []);
ROI         = ft_getopt(cfg, 'ROI', defaultROI);
freqBands   = ft_getopt(cfg, 'freqBands', defaultBands);
calcMethod  = ft_getopt(cfg, 'calcMethod', 'raw');
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
        [subjectdata, check, freq] = bv_check4data(subjectFolderPath, inputName);
        if ~check
            error('%s: input data not found', currSubject)
        end
    else
        evalc('[subjectdata, check, freq] = bv_check4data(subjectFolderPath, inputName);');
        if ~check %#ok<NODEF>
            error('%s: input data not found', currSubject)
        end
    end

    if strcmpi(overwrite, 'no')
        if isfield(subjectdata.PATHS, upper(outputName))
            if exist(subjectdata.PATHS.(upper(outputName)), 'file')
                if ~quiet; fprintf('\t ⚠ %s already found, not overwriting ... \n', upper(outputName)); end
                power = [];
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

%% resolve subject and wave labels for table output
if exist('subjectdata', 'var') && isfield(subjectdata, 'subjectName')
    subjName = subjectdata.subjectName;
else
    subjName = currSubject;
end

if exist('subjectdata', 'var') && isfield(subjectdata, 'wave')
    waveLabel = subjectdata.wave;
else
    waveLabel = 'unknown';
end

%% validate freqBands contains a 'total' field
if ~isfield(freqBands, 'total')
    error('cfg.freqBands must contain a ''total'' field used as denominator for relative power')
end

%% build condition loop list
% empty conditions → single pass over all trials (condLabel = 0 in table)
if isempty(conditions)
    condList = {[]};
else
    condList = num2cell(conditions);
end

%% identify non-total band names
bandNames     = fieldnames(freqBands);
bandPairNames = bandNames(~strcmp(bandNames, 'total'));
nBands        = length(bandPairNames);

totalRng  = freqBands.total;
total_idx = find(freq.freq >= totalRng(1) & freq.freq < totalRng(2));

%% initialise output table columns
Subject   = {};
Wave      = {};
Condition = {};
ROIcol    = {};
abs_vals  = zeros(0, nBands);
rel_vals  = zeros(0, nBands);
Total     = [];

ROI_names    = fieldnames(ROI);
roi_all_names = [ROI_names; {'Global'}];

if ~quiet; fprintf('\t extracting ROI power ... '); end

eps_val = 1e-12;

for c = 1:length(condList)
    cond = condList{c};

    if isempty(cond)
        freq_sel  = freq;
        condLabel = 0;
    else
        if ~isfield(freq, 'trialinfo')
            error('%s: no trialinfo found in freq structure', currSubject)
        end
        trial_idx = find(freq.trialinfo == cond);
        if isempty(trial_idx)
            continue
        end
        ftcfg        = [];
        ftcfg.trials = trial_idx;
        evalc('freq_sel = ft_selectdata(ftcfg, freq);');
        condLabel = cond;
    end

    if isempty(freq_sel.powspctrm)
        continue
    end

    for r = 1:length(roi_all_names)
        roi_name = roi_all_names{r};

        if strcmp(roi_name, 'Global')
            roi_pow = freq_sel.powspctrm;
        else
            chan_idx = find(ismember(freq.label, ROI.(roi_name)));
            if isempty(chan_idx); continue; end
            roi_pow = freq_sel.powspctrm(:, chan_idx, :);
        end

        total_roi = mean(roi_pow(:, :, total_idx), 'all');

        row_abs = zeros(1, nBands);
        row_rel = zeros(1, nBands);
        for b = 1:nBands
            bname   = bandPairNames{b};
            brng    = freqBands.(bname);
            bidx    = find(freq.freq >= brng(1) & freq.freq < brng(2));
            bpow    = mean(roi_pow(:, :, bidx), 'all');
            if strcmpi(calcMethod, 'log10')
                row_abs(b) = log10(bpow + eps_val);
                row_rel(b) = log10(bpow + eps_val) - log10(total_roi + eps_val); % eps guards against log10(0) = -Inf
            elseif strcmpi(calcMethod, 'raw')
                row_abs(b) = bpow;
                row_rel(b) = bpow / (total_roi + eps_val); % eps guards against division by 0
            else
                error("calcMethod must be 'raw' or 'log10'");
            end
        end

        Subject{end+1,1}   = subjName;   %#ok<AGROW>
        Wave{end+1,1}      = waveLabel;  %#ok<AGROW>
        Condition{end+1,1} = condLabel;  %#ok<AGROW>
        ROIcol{end+1,1}    = roi_name;   %#ok<AGROW>
        abs_vals(end+1,:)  = row_abs;    %#ok<AGROW>
        rel_vals(end+1,:)  = row_rel;    %#ok<AGROW>
        if strcmpi(calcMethod, 'log10')
            Total(end+1,1) = log10(total_roi + eps_val);    %#ok<AGROW>
        else % 'raw'
            Total(end+1,1) = total_roi;    %#ok<AGROW>
        end

    end
end

if ~quiet; fprintf('done \n'); end

%% assemble output table
T = table(Subject, Wave, Condition, ROIcol, ...
    'VariableNames', {'Subject', 'Wave', 'Condition', 'ROI'});
for b = 1:nBands
    bname = bandPairNames{b};
    colBase = [upper(bname(1)) bname(2:end)];
    T.([colBase '_abs']) = abs_vals(:, b);
    T.([colBase '_rel']) = rel_vals(:, b);
end
T.Total = Total;

power.table      = T;
power.freqBands  = freqBands;
power.ROI        = ROI;
power.conditions = conditions;
power.calcMethod = calcMethod;

%% save data
if strcmpi(saveData, 'yes')
    outputFilename = [subjectdata.subjectName '_' outputName '.mat']; %#ok<NODEF>
    fieldname = upper(outputName);
    subjectdata.PATHS.(fieldname) = fullfile(subjectdata.PATHS.POWERDIR, outputFilename);

    if ~quiet
        fprintf('\t saving %s ... ', outputFilename);
        save(subjectdata.PATHS.(fieldname), 'power')
        fprintf('done \n')
        fprintf('\t saving subjectdata variable to Subject.mat ... ')
        save(fullfile(subjectdata.PATHS.SUBJECTDIR, 'Subject.mat'), 'subjectdata')
        fprintf('done \n')
    else
        save(subjectdata.PATHS.(fieldname), 'power')
        save(fullfile(subjectdata.PATHS.SUBJECTDIR, 'Subject.mat'), 'subjectdata')
    end
end
