function [data, finished] = bv_cutAppendedIntoTrials(cfg, dataOld)
% Cuts appended/continuous data into fixed-length trials.
%
% Only continuous (consecutive-sample) stretches of the input data are
% cut, via ft_redefinetrial; stretches shorter than cfg.triallength are
% dropped. Can be used with data passed in directly, or loaded from disk
% for a given subject (and optionally saved back).
%
% Args:
%     cfg.triallength (number): Length of each output trial, in seconds.
%     cfg.ntrials (int or str, optional): Number of trials to randomly
%         keep from the cut data. Defaults to ``'all'`` (keep every
%         trial). If fewer than this many trials were cut, returns
%         ``finished = false`` instead.
%     cfg.currSubject (str): Subject folder name. Required when no data
%         is provided.
%     cfg.inputStr (str): Field name in ``subjectdata.PATHS`` used to load
%         input data. Required when no data is provided.
%     cfg.saveData (str, optional): Whether to save output to disk
%         (``'yes'`` or ``'no'``). Only meaningful when no data is
%         provided - forced to ``'no'`` when ``dataOld`` is given.
%         Defaults to ``'no'``.
%     cfg.outputStr (str, optional): Unique label for output file and
%         ``subjectdata.PATHS`` entry. Defaults to
%         ``['triallength' num2str(cfg.triallength)]``.
%     cfg.overwrite (str, optional): Whether to overwrite existing output
%         (``'yes'`` or ``'no'``). Only checked when no data is provided.
%         Defaults to ``'no'``.
%     cfg.pathsFcn (str, optional): Paths function filename. Must resolve
%         to a valid file on the MATLAB path. Defaults to ``'setPaths'``.
%     cfg.optionsFcn (str, optional): Options function filename. Must
%         resolve to a valid file on the MATLAB path. Defaults to
%         ``'setOptions'``.
%     dataOld (struct, optional): FieldTrip data structure containing one
%         or more continuous trials/segments to cut. If omitted, data is
%         loaded from disk using ``cfg.currSubject`` and ``cfg.inputStr``.
%
% Returns:
%     data (struct): FieldTrip data cut into ``cfg.triallength``-second
%         trials. Empty (``[]``) if no continuous segment is at least
%         ``cfg.triallength`` long, if fewer than ``cfg.ntrials`` trials
%         were cut, or if output already exists and ``cfg.overwrite`` is
%         ``'no'``.
%     finished (bool): Whether cutting succeeded (``false`` in any of the
%         empty-``data`` cases above).
%
% Example:
%     Cut data provided directly:
%
%     ```matlab
%     cfg = [];
%     cfg.triallength = 5;
%     [data, finished] = bv_cutAppendedIntoTrials(cfg, appenddata);
%     ```
%
%     Load data from disk for a subject and save the cut trials:
%
%     ```matlab
%     cfg = [];
%     cfg.currSubject = 'B12345_99m';
%     cfg.inputStr    = 'APPENDED';
%     cfg.triallength = 5;
%     cfg.saveData    = 'yes';
%     [data, finished] = bv_cutAppendedIntoTrials(cfg);
%     ```

currSubject = ft_getopt(cfg, 'currSubject');
inputStr    = ft_getopt(cfg, 'inputStr');
triallength = ft_getopt(cfg, 'triallength');
outputStr   = ft_getopt(cfg, 'outputStr', ['triallength' num2str(triallength)]);
saveData    = ft_getopt(cfg, 'saveData', 'no');
ntrials     = ft_getopt(cfg, 'ntrials', 'all');
overwrite   = ft_getopt(cfg, 'overwrite', 'no');
pathsFcn    = ft_getopt(cfg, 'pathsFcn', 'setPaths');
optionsFcn  = ft_getopt(cfg, 'optionsFcn', 'setOptions');

cfgIn = cfg;

if isempty(triallength)
    error('config struct does not contain triallength')
end

if nargin < 2
    disp(currSubject)

    eval(pathsFcn)
    eval(optionsFcn)

    subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];
    [subjectdata, check] = bv_check4data(subjectFolderPath);
    if ~check
        error('%s: Subject.mat not found', currSubject)
    end
    if strcmpi(overwrite, 'no')
        if isfield(subjectdata.PATHS, upper(outputStr))
            if exist(subjectdata.PATHS.(upper(outputStr)), 'file')
                fprintf('\t %s already found, not overwriting ... \n', upper(outputStr))
                data = [];
                finished = false;
                return
            end
        end
    end

    [subjectdata, check, dataOld] = bv_check4data(subjectFolderPath, inputStr);
    if ~check
        error('%s: input data not found', currSubject)
    end
else
    saveData = 'no';
end

continuousSeconds = (diff(dataOld.sampleinfo') + 1) ./ dataOld.fsample;
trialparts2use = find(continuousSeconds >= triallength);

if isempty(trialparts2use)
    fprintf('\t \t no trials found, skipping ... \n')
    data = [];
    finished = false;
    return;
end

sampleinfo = [];
trialinfo = [];
for i = 1:length(trialparts2use)
    trl = trialparts2use(i);
    nTrls = floor(continuousSeconds(trl) / triallength);

    for j = 1:nTrls
        currsampleinfoStart = (dataOld.sampleinfo(trl,1) + triallength*dataOld.fsample*(j-1));
        currsampleinfoEnd = dataOld.sampleinfo(trl,1) + triallength*dataOld.fsample*(j) - 1;
        currsampleinfo = [currsampleinfoStart currsampleinfoEnd];

        sampleinfo = cat(1, sampleinfo, currsampleinfo);
        trialinfo = cat(1, trialinfo, dataOld.trialinfo(trl));

    end
end


trl = [sampleinfo zeros(size(sampleinfo,1),1) trialinfo];

fprintf('\t redefining triallength to %1.0fs ... ', triallength)
cfg = [];
cfg.trl = trl;
evalc('data = ft_redefinetrial(cfg, dataOld);');
fprintf('done! \n')

fprintf('\t\t %1.0f trials created \n', length(trialinfo))

if not(strcmpi(ntrials, 'all'))
    if length(data.trial) < ntrials
        fprintf('\t not enough trials found, skipping ... \n')
        data = [];
        finished = false;
        return
    else
        cfg = [];
        cfg.trials = sort(randperm(length(data.trial), ntrials));
        fprintf('\t selecting %1.0f cut trials ... ', length(cfg.trials))
        evalc('data = ft_selectdata(cfg, data);');
        fprintf('done! \n')
    end
end

if strcmpi(saveData, 'yes')
    subjectdata.nTrialsCleaned = length(data.trial);
    subjectdata.analysisOrder = bv_updateAnalysisOrder(subjectdata.analysisOrder, cfgIn);
    bv_updateSubjectSummary([PATHS.SUMMARY filesep 'SubjectSummary.mat'], bv_stripSummaryOnlyFields(subjectdata))

    bv_saveData(subjectdata, data, outputStr);
end
finished = true;
