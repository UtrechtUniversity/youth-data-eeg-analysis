function strength = bv_calculateStrength(cfg, connectivity)
% Computes functional connectivity strength from a PLI connectivity struct.
%
% FC strength is the mean off-diagonal (edge) weight of the connectivity
% matrix. It is computed per condition and per frequency band, for the whole
% network ('Global') and/or for each ROI, and returned as a tidy table
% (mirroring bv_extractROIPower). The NaN diagonal is never included, and
% edges are extracted with bv_multisquareform and nansquareform.
%
% Args:
%     cfg.currSubject (str): Subject folder name. Required when no
%         connectivity struct is provided.
%     cfg.inputName (str): Field in ``subjectdata.PATHS`` for the PLI file
%         (e.g. ``'PLI3'``). Required when no connectivity struct is provided.
%     cfg.outputName (str): Label for the output file and
%         ``subjectdata.PATHS`` entry. Required when saving.
%     cfg.saveData (str): ``'yes'``/``'no'`` (default ``'no'``).
%     cfg.conditions (numeric): Condition codes to process separately. A
%         pooled pass over all epochs (always labelled 'Global') is always
%         added. Set to ``[]`` for pooled only. Default ``[]``.
%     cfg.conditionLabels (cell array of str, optional): Display labels for
%         cfg.conditions' Condition column, matched *positionally* - the
%         i-th label is used for cfg.conditions(i), so this must be in the
%         same order and have the same number of elements as cfg.conditions
%         (e.g. ``cfg.conditions = [129 139]; cfg.conditionLabels =
%         {'NonSocial', 'Social'}`` labels 129 as 'NonSocial' and 139 as
%         'Social'). Codes without a label (or when this is omitted/empty)
%         fall back to the stringified condition code. The pooled pass is
%         always labelled 'Global'.
%     cfg.computeGlobal (str): ``'yes'``/``'no'`` include whole-network
%         strength (default ``'yes'``).
%     cfg.computeROI (str): ``'yes'``/``'no'`` include per-ROI strength
%         (default ``'yes'``).
%     cfg.ROI (struct): Fields are ROI labels, values are cell arrays of
%         channel labels. Defaults to the power estimate steps' ROI set.
%     cfg.spctrmfield (str): Connectivity field to use (default
%         ``'plispctrm'``).
%     cfg.pathsFcn (str): Paths function (default ``'setPaths'``).
%     cfg.optionsFcn (str): Options function (default ``'setOptionsNetmet'``).
%     cfg.overwrite (str): ``'yes'``/``'no'`` (default ``'no'``).
%     cfg.quiet (str): ``'yes'``/``'no'`` (default ``'no'``).
%     connectivity (struct, optional): PLI connectivity struct from
%         bv_calculatePLI. If omitted, loaded from disk.
%
% Returns:
%     strength (struct): Struct with fields ``table`` (columns Subject, Wave,
%         Condition, Region, plus one column per frequency band),
%         ``conditions``, ``ROI``, and ``bands``. Empty (``[]``) if output
%         already exists and ``cfg.overwrite`` is ``'no'``.

%% default ROI definitions 
defaultROI.Frontal       = {'Fp1','Fp2','AF3','AF4','Fz'};
defaultROI.LeftFrontal   = {'F3','F7','FC5','FC1'};
defaultROI.RightFrontal  = {'F4','F8','FC6','FC2'};
defaultROI.Central       = {'C3','C4','CP1','CP2','Cz'};
defaultROI.LeftParietal  = {'T7','CP5','P7','P3'};
defaultROI.RightParietal = {'T8','CP6','P8','P4'};
defaultROI.Occipital     = {'PO3','PO4','O1','Oz','O2','Pz'};

%% get options
currSubject          = ft_getopt(cfg, 'currSubject');
inputName            = ft_getopt(cfg, 'inputName');
saveData             = ft_getopt(cfg, 'saveData', 'no');
outputName           = ft_getopt(cfg, 'outputName');
conditions           = ft_getopt(cfg, 'conditions', []);
conditionLabelsList  = ft_getopt(cfg, 'conditionLabels', {});
computeGlobal        = ft_getopt(cfg, 'computeGlobal', 'yes');
computeROI           = ft_getopt(cfg, 'computeROI', 'yes');
ROI                  = ft_getopt(cfg, 'ROI', defaultROI);
spctrmfield          = ft_getopt(cfg, 'spctrmfield', 'plispctrm');
pathsFcn             = ft_getopt(cfg, 'pathsFcn', 'setPaths');
optionsFcn           = ft_getopt(cfg, 'optionsFcn', 'setOptionsNetmet');
overwrite            = ft_getopt(cfg, 'overwrite', 'no');
quiet                = ft_getopt(cfg, 'quiet', 'no');

quiet         = strcmpi(quiet, 'yes');
computeGlobal = strcmpi(computeGlobal, 'yes');
computeROI    = strcmpi(computeROI, 'yes');

if ~computeGlobal && ~computeROI
    error('bv_calculateStrength: both computeGlobal and computeROI are off; nothing to compute')
end

if ~isempty(conditionLabelsList) && length(conditionLabelsList) ~= length(conditions)
    error(['bv_calculateStrength: cfg.conditionLabels must have the same number of ' ...
        'elements as cfg.conditions (one label per condition code, in the same order)'])
end

conditionLabels = containers.Map('KeyType', 'double', 'ValueType', 'any');
for i = 1:length(conditionLabelsList)
    conditionLabels(conditions(i)) = conditionLabelsList{i};
end

%% load data (if necessary)
if nargin < 2
    if ~quiet; disp(currSubject); end
    eval(pathsFcn)
    eval(optionsFcn)

    subjectFolderPath = fullfile(PATHS.SUBJECTS, currSubject);

    if ~quiet
        [subjectdata, check, connectivity] = bv_check4data(subjectFolderPath, inputName);
        if ~check
            error('%s: input data not found', currSubject)
        end
    else
        evalc('[subjectdata, check, connectivity] = bv_check4data(subjectFolderPath, inputName);');
        if ~check %#ok<NODEF>
            error('%s: input data not found', currSubject)
        end
    end

    if strcmpi(overwrite, 'no')
        if isfield(subjectdata.PATHS, upper(outputName))
            if exist(subjectdata.PATHS.(upper(outputName)), 'file')
                if ~quiet; fprintf('\t %s already found, not overwriting ... \n', upper(outputName)); end
                strength = [];
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

%% pull fields from the connectivity struct
spctrm    = connectivity.(spctrmfield);   % chan x chan x epoch x freq
nfreq     = size(spctrm, 4);
labels    = connectivity.label;
bands     = connectivity.freq;            % cell of band-name strings
trialinfo = connectivity.trialinfo;

%% build region list (Global and/or ROIs)
regionNames = {};
regionChans = {};
if computeGlobal
    regionNames{end+1} = 'Global';       %#ok<AGROW>
    regionChans{end+1} = 1:numel(labels); %#ok<AGROW>
end
if computeROI
    roiFields = fieldnames(ROI);
    for r = 1:numel(roiFields)
        regionNames{end+1} = roiFields{r};                          %#ok<AGROW>
        regionChans{end+1} = find(ismember(labels, ROI.(roiFields{r}))); %#ok<AGROW>
    end
end

%% build condition list: each condition separately, plus a pooled pass (labelled 'Global')
if isempty(conditions)
    condList = {[]};
else
    condList = [num2cell(conditions), {[]}];
end

%% helper: resolve a display label for a condition code
resolveLabel = @(code) bv_resolveConditionLabel(code, conditionLabels);

%% compute strength per condition x region x band
Subject   = {};
Wave      = {};
Condition = {};
Region    = {};
band_vals = zeros(0, nfreq);

if ~quiet; fprintf('\t calculating FC strength ... '); end

for c = 1:numel(condList)
    cond = condList{c};

    if isempty(cond)
        sel       = true(size(trialinfo));
        condLabel = 'Global';
    else
        sel = (trialinfo == cond);
        if ~any(sel); continue; end
        condLabel = resolveLabel(cond);
    end

    % average connectivity over the selected epochs -> chan x chan x freq
    Wcond = nanmean(spctrm(:, :, sel, :), 3);
    Wcond = reshape(Wcond, size(spctrm, 1), size(spctrm, 2), nfreq);

    for r = 1:numel(regionNames)
        idx = regionChans{r};
        if numel(idx) < 2
            continue    % need at least two channels to form an edge
        end

        edges           = bv_multisquareform(Wcond(idx, idx, :)); % freq x nEdges
        strengthPerBand = nanmean(edges, 2)';                     % 1 x freq

        Subject{end+1,1}   = subjName;         %#ok<AGROW>
        Wave{end+1,1}      = waveLabel;        %#ok<AGROW>
        Condition{end+1,1} = condLabel;        %#ok<AGROW>
        Region{end+1,1}    = regionNames{r};   %#ok<AGROW>
        band_vals(end+1,:) = strengthPerBand;  %#ok<AGROW>
    end
end

if ~quiet; fprintf('done \n'); end

%% assemble output table
T = table(Subject, Wave, Condition, Region, ...
    'VariableNames', {'Subject', 'Wave', 'Condition', 'Region'});
for b = 1:nfreq
    bname   = bands{b};
    colName = [upper(bname(1)) bname(2:end)];
    T.(colName) = band_vals(:, b);
end

strength.table      = T;
strength.conditions = conditions;
strength.ROI        = ROI;
strength.bands      = bands;

%% save data
if strcmpi(saveData, 'yes')
    outputFilename = [subjectdata.subjectName '_' outputName '.mat']; %#ok<NODEF>
    fieldname = upper(outputName);
    subjectdata.PATHS.(fieldname) = fullfile(subjectdata.PATHS.NETMETDIR, outputFilename);

    if ~quiet
        fprintf('\t saving %s ... ', outputFilename);
        save(subjectdata.PATHS.(fieldname), 'strength')
        fprintf('done \n')
        fprintf('\t saving subjectdata variable to Subject.mat ... ')
        save(fullfile(subjectdata.PATHS.SUBJECTDIR, 'Subject.mat'), 'subjectdata')
        fprintf('done \n')
    else
        save(subjectdata.PATHS.(fieldname), 'strength')
        save(fullfile(subjectdata.PATHS.SUBJECTDIR, 'Subject.mat'), 'subjectdata')
    end
end
