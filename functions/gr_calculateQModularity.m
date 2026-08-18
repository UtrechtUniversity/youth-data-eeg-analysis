function qmod = gr_calculateQModularity(cfg, connectivity)
% Computes Louvain community structure and modularity (Q) from a PLI
% connectivity struct.
%
% Ported from unused/gr_calculateQModularity.m (which took a raw N x N x m
% adjacency stack and an edgeType flag, and called community_louvain
% directly). This version keeps the same core computation -
% community_louvain on the (optionally normalised) adjacency matrix - but
% is wrapped in the cfg-based interface used by the similar network-metric
% steps (bv_calculateStrength, bv_calculateSWP), so it can plug into
% networkMetrics_standard.m the same way: per condition and per frequency
% band, for the whole network ('Global') and/or for each ROI, returned as
% a tidy table.
%
% For each connectivity matrix the diagonal is set to 0 (structural
% self-loop-free convention), any all-NaN channels (removed channels) are
% dropped, and community detection is run with community_louvain (weighted
% matrices are normalised with gr_normalizeW first, matching the original
% 'weighted' edgeType branch). Degenerate graphs (< 3 nodes / all-zero)
% yield NaN. Per-matrix failures are caught and yield NaN with a warning
% so the pipeline does not stop.
%
% NOTE: community_louvain is used from FieldTrip's bundled Brain
% Connectivity Toolbox copy (fieldtrip/external/bct) via
% ft_hastoolbox('BCT', 1), rather than bundling a separate copy. ROI-level
% modularity is computed on small subgraphs and should be interpreted with
% caution.
%
% Args:
%     cfg.currSubject (str): Subject folder name. Required when no
%         connectivity struct is provided.
%     cfg.inputName (str): Field in ``subjectdata.PATHS`` for the PLI file
%         (e.g. ``'PLI3'``). Required when no connectivity struct is provided.
%     cfg.outputName (str): Label for the output file and
%         ``subjectdata.PATHS`` entry. Required when saving.
%     cfg.saveData (str): ``'yes'``/``'no'`` (default ``'no'``).
%     cfg.conditions (numeric): Condition codes processed separately. A
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
%     cfg.computeGlobal (str): ``'yes'``/``'no'`` whole-network modularity
%         (default ``'yes'``).
%     cfg.computeROI (str): ``'yes'``/``'no'`` per-ROI modularity
%         (default ``'yes'``).
%     cfg.ROI (struct): Fields are ROI labels, values are cell arrays of
%         channel labels. Defaults to the power estimate steps' ROI set.
%     cfg.edgeType (str): ``'weighted'`` (normalises with gr_normalizeW
%         before community_louvain) or ``'binary'`` (uses the matrix as-is,
%         matching the original gr_calculateQModularity behaviour). Default
%         ``'weighted'``.
%     cfg.gamma (numeric): community_louvain resolution parameter
%         (default 1, classic modularity).
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
%     qmod (struct): Struct with fields ``table`` (columns Subject, Wave,
%         Condition, Region, plus one column per frequency band with Q
%         values), ``communityTable`` (a tidy long-format table with
%         columns Subject, Wave, Condition, Region, Band, Channel,
%         Community - one row per node per band per condition per region,
%         fully self-describing rather than requiring cross-referencing
%         against ``table``'s row order), ``conditions``, ``ROI``, and
%         ``bands``. Empty (``[]``) if output already exists and
%         ``cfg.overwrite`` is ``'no'``.

%% ensure community_louvain (FieldTrip's bundled BCT) is on the path
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
gamma                = ft_getopt(cfg, 'gamma', 1);
spctrmfield          = ft_getopt(cfg, 'spctrmfield', 'plispctrm');
pathsFcn             = ft_getopt(cfg, 'pathsFcn', 'setPaths');
optionsFcn           = ft_getopt(cfg, 'optionsFcn', 'setOptionsNetmet');
overwrite            = ft_getopt(cfg, 'overwrite', 'no');
quiet                = ft_getopt(cfg, 'quiet', 'no');

quiet         = strcmpi(quiet, 'yes');
computeGlobal = strcmpi(computeGlobal, 'yes');
computeROI    = strcmpi(computeROI, 'yes');

if ~computeGlobal && ~computeROI
    error('gr_calculateQModularity: both computeGlobal and computeROI are off; nothing to compute')
end

if ~isempty(conditionLabelsList) && length(conditionLabelsList) ~= length(conditions)
    error(['gr_calculateQModularity: cfg.conditionLabels must have the same number of ' ...
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
                qmod = [];
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
    regionNames{end+1} = 'Global';        %#ok<AGROW>
    regionChans{end+1} = 1:numel(labels); %#ok<AGROW>
end
if computeROI
    if ~quiet
        fprintf(['\t note: ROI-level modularity is computed on small subgraphs ' ...
            'and should be interpreted with caution \n']);
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

%% compute modularity per condition x region x band
Subject   = {};
Wave      = {};
Condition = {};
Region    = {};
band_vals = zeros(0, nfreq);

% tidy per-node community accumulators (one row per node per band)
cSubject   = {};
cWave      = {};
cCondition = {};
cRegion    = {};
cBand      = {};
cChannel   = {};
cCommunity = [];

if ~quiet; fprintf('\t calculating Q modularity ... '); end

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

        qPerBand = nan(1, nfreq);
        for b = 1:nfreq
            W = Wcond(idx, idx, b);

            % drop removed channels (all-NaN rows), never zero-fill them
            bad = all(isnan(W), 2);
            W(bad, :) = [];
            W(:, bad) = [];

            % structural self-loop-free convention
            W(1:size(W,1)+1:end) = 0;

            if size(W, 1) < 3 || all(W(:) == 0)
                continue    % degenerate graph -> leave NaN
            end

            try
                switch edgeType
                    case 'binary'
                        [Ci, Q] = community_louvain(W, gamma);
                    case 'weighted'
                        [Ci, Q] = community_louvain(gr_normalizeW(W), gamma);
                end
                qPerBand(b) = Q;

                keepLabels = regionLabels(~bad);
                nNode      = numel(Ci);
                cSubject   = [cSubject;   repmat({subjName},        nNode, 1)]; %#ok<AGROW>
                cWave      = [cWave;      repmat({waveLabel},       nNode, 1)]; %#ok<AGROW>
                cCondition = [cCondition; repmat({condLabel},       nNode, 1)]; %#ok<AGROW>
                cRegion    = [cRegion;    repmat({regionNames{r}},  nNode, 1)]; %#ok<AGROW>
                cBand      = [cBand;      repmat({bands{b}},        nNode, 1)]; %#ok<AGROW>
                cChannel   = [cChannel;   keepLabels(:)];                      %#ok<AGROW>
                cCommunity = [cCommunity; Ci(:)];                              %#ok<AGROW>
            catch ME
                warning('gr_calculateQModularity:%s %s/%s band %s: %s', ...
                    subjName, regionNames{r}, condLabel, bands{b}, ME.message);
            end
        end

        Subject{end+1,1}   = subjName;         %#ok<AGROW>
        Wave{end+1,1}      = waveLabel;        %#ok<AGROW>
        Condition{end+1,1} = condLabel;        %#ok<AGROW>
        Region{end+1,1}    = regionNames{r};   %#ok<AGROW>
        band_vals(end+1,:) = qPerBand;         %#ok<AGROW>
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

communityTable = table(cSubject, cWave, cCondition, cRegion, cBand, cChannel, cCommunity, ...
    'VariableNames', {'Subject', 'Wave', 'Condition', 'Region', 'Band', 'Channel', 'Community'});

qmod.table          = T;
qmod.communityTable = communityTable;
qmod.conditions     = conditions;
qmod.ROI            = ROI;
qmod.bands          = bands;

%% save data
if strcmpi(saveData, 'yes')
    outputFilename = [subjectdata.subjectName '_' outputName '.mat']; %#ok<NODEF>
    fieldname = upper(outputName);
    subjectdata.PATHS.(fieldname) = fullfile(subjectdata.PATHS.NETMETDIR, outputFilename);

    if ~quiet
        fprintf('\t saving %s ... ', outputFilename);
        save(subjectdata.PATHS.(fieldname), 'qmod')
        fprintf('done \n')
        fprintf('\t saving subjectdata variable to Subject.mat ... ')
        save(fullfile(subjectdata.PATHS.SUBJECTDIR, 'Subject.mat'), 'subjectdata')
        fprintf('done \n')
    else
        save(subjectdata.PATHS.(fieldname), 'qmod')
        save(fullfile(subjectdata.PATHS.SUBJECTDIR, 'Subject.mat'), 'subjectdata')
    end
end
