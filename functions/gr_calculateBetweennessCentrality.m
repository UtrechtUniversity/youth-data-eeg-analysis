function bc = gr_calculateBetweennessCentrality(cfg, connectivity)
% Computes node betweenness centrality (reported as the mean over nodes)
% from per-epoch PLI.
%
% For every condition (and a pooled pass over all epochs) and every
% frequency band, the per-epoch connectivity matrices of the epochs involved
% are averaged, and betweenness centrality is computed on the whole network
% ('Global') and/or on each ROI's subgraph. It is a per-node measure, so the
% table holds its mean over the nodes of each region, normalised to [0, 1]
% with (n-1)(n-2), n being the number of nodes left after dropping removed
% channels. The per-node values are kept in ``nodeTable`` (tidy long format,
% one row per node per band per condition per region).
%
% Each averaged matrix is prepared the same way for all network metrics: the
% diagonal is set to 0, channels without data (all-NaN rows, i.e. removed
% channels) are dropped, and graphs with fewer than 3 nodes or without any
% non-zero weight give NaN. For 'weighted' the matrix is min-max normalised
% with GR_NORMALIZEW, converted to connection lengths (weight_conversion), and
% betweenness_wei is applied to the length matrix; for 'binary' and 'mst' it is
% thresholded at > 0 and betweenness_bin is used. If one matrix fails, its entry
% is NaN and a warning is issued, so the run is not stopped.
%
% The connectivity struct has to hold per-epoch PLI (chan x chan x epoch x
% freq), i.e. be computed by BV_CALCULATEPLI with ``cfg.keeptrials = 'yes'``;
% otherwise an error is raised.
%
% betweenness_bin, betweenness_wei and weight_conversion come from FieldTrip's
% bundled Brain Connectivity Toolbox (fieldtrip/external/bct), added to the path
% with ft_hastoolbox('BCT', 1). ROI-level betweenness centrality is computed on
% small subgraphs and should be interpreted with caution.
%
% Args:
%     cfg.currSubject (str): Subject folder name. Required when no
%         connectivity struct is provided.
%     cfg.inputName (str): Field name in ``subjectdata.PATHS`` used to load
%         the PLI file (e.g. ``'PLI3'``). Required when no connectivity
%         struct is provided.
%     cfg.outputName (str): Label for the output file and its
%         ``subjectdata.PATHS`` entry. Required when saving data.
%     cfg.saveData (str, optional): Whether to save the output to disk
%         (``'yes'`` or ``'no'``). Defaults to ``'no'``.
%     cfg.conditions (numeric, optional): Condition codes to process
%         separately. A pooled pass over all epochs (labelled 'Global') is
%         always added; use ``[]`` for the pooled pass only. Defaults to
%         ``[]``.
%     cfg.conditionLabels (cell array of str, optional): Display labels for
%         cfg.conditions' Condition column, matched *positionally* - the
%         i-th label is used for cfg.conditions(i), so this must be in the
%         same order and have the same number of elements as cfg.conditions
%         (e.g. ``cfg.conditions = [129 139]; cfg.conditionLabels =
%         {'NonSocial', 'Social'}`` labels 129 as 'NonSocial' and 139 as
%         'Social'). Codes without a label (or when this is omitted/empty)
%         fall back to the stringified condition code. The pooled pass is
%         always labelled 'Global'.
%     cfg.computeGlobal (str, optional): Whether to compute betweenness
%         centrality for the whole network (``'yes'`` or ``'no'``). Defaults
%         to ``'yes'``.
%     cfg.computeROI (str, optional): Whether to compute betweenness
%         centrality for each ROI (``'yes'`` or ``'no'``). At least one of
%         cfg.computeGlobal and cfg.computeROI has to be ``'yes'``. Defaults
%         to ``'yes'``.
%     cfg.ROI (struct, optional): Struct where each field name is a ROI
%         label and its value is a cell array of channel labels. Defaults to
%         the standard frontal, central, parietal and occipital ROIs also
%         used by BV_EXTRACTROIPOWER.
%     cfg.edgeType (str, optional): ``'weighted'`` (normalises with
%         GR_NORMALIZEW, converts to connection lengths, then
%         betweenness_wei) or ``'binary'``/``'mst'`` (thresholds at > 0,
%         then betweenness_bin). Defaults to ``'weighted'``.
%     cfg.spctrmfield (str, optional): Field of the connectivity struct that
%         holds the per-epoch connectivity. Defaults to ``'plispctrm'``.
%     cfg.pathsFcn (str, optional): Paths function filename. Must resolve to
%         a valid file on the MATLAB path. Defaults to ``'setPaths'``.
%     cfg.optionsFcn (str, optional): Options function filename. Must
%         resolve to a valid file on the MATLAB path. Defaults to
%         ``'setOptionsNetmet'``.
%     cfg.overwrite (str, optional): Whether to overwrite existing output
%         (``'yes'`` or ``'no'``). Only checked when no connectivity struct
%         is provided. Defaults to ``'no'``.
%     cfg.quiet (str, optional): Suppress command window output (``'yes'``
%         or ``'no'``). Defaults to ``'no'``.
%     connectivity (struct, optional): PLI connectivity struct from
%         BV_CALCULATEPLI, with per-epoch PLI. If omitted, loaded from disk
%         using ``cfg.currSubject`` and ``cfg.inputName``.
%
% Returns:
%     bc (struct): Struct with fields ``table`` (columns Subject, Wave,
%         Condition, Region, plus one column per frequency band with the
%         mean normalised betweenness centrality), ``nodeTable`` (tidy long
%         format with columns Subject, Wave, Condition, Region, Band,
%         Channel, Value: the normalised betweenness centrality of each
%         node), ``conditions``, ``ROI`` and ``bands``. Empty (``[]``) if
%         the output already exists and ``cfg.overwrite`` is ``'no'``.
%
% Example:
%     ```matlab
%     cfg                 = [];
%     cfg.currSubject     = 'B12345_99m';
%     cfg.inputName       = 'PLI3';
%     cfg.outputName      = 'BC';
%     cfg.saveData        = 'yes';
%     cfg.conditions      = [129 139];
%     cfg.conditionLabels = {'NonSocial', 'Social'};
%     bc = gr_calculateBetweennessCentrality(cfg);
%     ```

%% ensure betweenness_bin/betweenness_wei (FieldTrip's bundled BCT) is on the path
ft_hastoolbox('BCT', 1);

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
edgeType             = ft_getopt(cfg, 'edgeType', 'weighted');
spctrmfield          = ft_getopt(cfg, 'spctrmfield', 'plispctrm');
pathsFcn             = ft_getopt(cfg, 'pathsFcn', 'setPaths');
optionsFcn           = ft_getopt(cfg, 'optionsFcn', 'setOptionsNetmet');
overwrite            = ft_getopt(cfg, 'overwrite', 'no');
quiet                = ft_getopt(cfg, 'quiet', 'no');

quiet         = strcmpi(quiet, 'yes');
computeGlobal = strcmpi(computeGlobal, 'yes');
computeROI    = strcmpi(computeROI, 'yes');

if ~computeGlobal && ~computeROI
    error('gr_calculateBetweennessCentrality: both computeGlobal and computeROI are off; nothing to compute')
end

validEdgeTypes = {'weighted', 'binary', 'mst'};
if ~any(strcmp(edgeType, validEdgeTypes))
    error('gr_calculateBetweennessCentrality: unknown cfg.edgeType ''%s'' (valid: %s)', ...
        num2str(edgeType), strjoin(validEdgeTypes, ', '))
end

if strcmpi(saveData, 'yes') && isempty(outputName)
    error('gr_calculateBetweennessCentrality: cfg.outputName is required when cfg.saveData is ''yes''')
end
if strcmpi(saveData, 'yes') && nargin >= 2 && ~isfield(cfg, 'currSubject')
    error(['gr_calculateBetweennessCentrality: cfg.saveData is ''yes'' but the connectivity struct was ' ...
        'passed in directly and cfg.currSubject was not given - there is no subjectdata to ' ...
        'save the output against'])
end

if ~isempty(conditionLabelsList) && length(conditionLabelsList) ~= length(conditions)
    error(['gr_calculateBetweennessCentrality: cfg.conditionLabels must have the same number of ' ...
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
                bc = [];
                return
            end
        end
    end

    if ~isempty(outputName)
        subjectdata.cfgs.(outputName) = cfg;
    end

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

    if ~isempty(outputName)
        subjectdata.cfgs.(outputName) = cfg;
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

if size(spctrm, 3) ~= size(trialinfo, 1)
    error(['gr_calculateBetweennessCentrality: connectivity.%%s has %%d entries along its epoch dimension ' ...
        'but trialinfo has %%d: per-epoch PLI is required (bv_calculatePLI with ' ...
        'cfg.keeptrials = ''yes'')'], spctrmfield, size(spctrm, 3), size(trialinfo, 1))
end

%% build region list (Global and/or ROIs)
regionNames = {};
regionChans = {};
if computeGlobal
    regionNames{end+1} = 'Global';        %#ok<AGROW>
    regionChans{end+1} = 1:numel(labels); %#ok<AGROW>
end
if computeROI
    if ~quiet
        fprintf(['\t note: ROI-level betweenness centrality is computed on small ' ...
            'subgraphs and should be interpreted with caution \n']);
    end
    roiFields = fieldnames(ROI);
    for r = 1:numel(roiFields)
        regionNames{end+1} = roiFields{r};                              %#ok<AGROW>
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

%% compute betweenness centrality per condition x region x band
Subject   = {};
Wave      = {};
Condition = {};
Region    = {};
band_vals = zeros(0, nfreq);

% tidy per-node BC accumulators (one row per node per band)
nSubject   = {};
nWave      = {};
nCondition = {};
nRegion    = {};
nBand      = {};
nChannel   = {};
nValue     = [];

if ~quiet; fprintf('\t calculating betweenness centrality ... '); end

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
        regionLabels = labels(idx);

        bcPerBand = nan(1, nfreq);
        for b = 1:nfreq
            W = Wcond(idx, idx, b);

            % drop removed channels (all-NaN rows), never zero-fill them
            bad = all(isnan(W), 2);
            W(bad, :) = [];
            W(:, bad) = [];

            % structural self-loop-free convention
            W(1:size(W,1)+1:end) = 0;

            n = size(W, 1);
            if n < 3 || all(W(:) == 0)
                continue    % degenerate graph -> leave NaN
            end

            try
                switch edgeType
                    case 'weighted'
                        BC = betweenness_wei(weight_conversion(gr_normalizeW(W), 'lengths'));
                    case {'binary', 'mst'}
                        BC = betweenness_bin(W > 0);
                end
                % normalise to [0,1], per BCT's own convention (see
                % betweenness_bin/betweenness_wei), using the post-removal
                % node count so the bound holds regardless of dropped channels
                BCnorm = BC ./ ((n-1)*(n-2));
                bcPerBand(b) = mean(BCnorm);

                keepLabels = regionLabels(~bad);
                nNode      = numel(BCnorm);
                nSubject   = [nSubject;   repmat({subjName},       nNode, 1)]; %#ok<AGROW>
                nWave      = [nWave;      repmat({waveLabel},      nNode, 1)]; %#ok<AGROW>
                nCondition = [nCondition; repmat({condLabel},      nNode, 1)]; %#ok<AGROW>
                nRegion    = [nRegion;    repmat({regionNames{r}}, nNode, 1)]; %#ok<AGROW>
                nBand      = [nBand;      repmat({bands{b}},       nNode, 1)]; %#ok<AGROW>
                nChannel   = [nChannel;   keepLabels(:)];                     %#ok<AGROW>
                nValue     = [nValue;     BCnorm(:)];                         %#ok<AGROW>
            catch ME
                warning('gr_calculateBetweennessCentrality:failed', '%s %s/%s band %s: %s', ...
                    subjName, regionNames{r}, condLabel, bands{b}, ME.message);
            end
        end

        Subject{end+1,1}   = subjName;        %#ok<AGROW>
        Wave{end+1,1}      = waveLabel;       %#ok<AGROW>
        Condition{end+1,1} = condLabel;       %#ok<AGROW>
        Region{end+1,1}    = regionNames{r};  %#ok<AGROW>
        band_vals(end+1,:) = bcPerBand;       %#ok<AGROW>
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

nodeTable = table(nSubject, nWave, nCondition, nRegion, nBand, nChannel, nValue, ...
    'VariableNames', {'Subject', 'Wave', 'Condition', 'Region', 'Band', 'Channel', 'Value'});

bc.table      = T;
bc.nodeTable  = nodeTable;
bc.conditions = conditions;
bc.ROI        = ROI;
bc.bands      = bands;

%% save data
if strcmpi(saveData, 'yes')
    outputFilename = [subjectdata.subjectName '_' outputName '.mat']; %#ok<NODEF>
    fieldname = upper(outputName);
    subjectdata.PATHS.(fieldname) = fullfile(subjectdata.PATHS.NETMETDIR, outputFilename);

    if ~quiet
        fprintf('\t saving %s ... ', outputFilename);
        save(subjectdata.PATHS.(fieldname), 'bc')
        fprintf('done \n')
        fprintf('\t saving subjectdata variable to Subject.mat ... ')
        save(fullfile(subjectdata.PATHS.SUBJECTDIR, 'Subject.mat'), 'subjectdata')
        fprintf('done \n')
    else
        save(subjectdata.PATHS.(fieldname), 'bc')
        save(fullfile(subjectdata.PATHS.SUBJECTDIR, 'Subject.mat'), 'subjectdata')
    end
end
