function [data, finished] = bv_cutAppendedIntoTrials(cfg, dataOld)
% Cuts appended data into trials of given triallength, using
% ft_redefinetrial. Only cuts continuous / consecutive data.
%
% Can be used with data input:
%  [ cutdata ] = bv_cutAppendedIntoTrials(cfg, appenddata)
%
% which needs an cfg structure with the following fields:
%   cfg.triallength = [ number ], length (in s) of the trials
%
% or without data-input to be used in analysis-pipeline starting with
% bv_createSubjectFolders:
%  [ cutdata ] = bv_cutAppendedIntoTrials(cfg)
%
% which needs an cfg structure with the following fields:
%   cfg.triallength     = [ number ], length (in s) of the trials
%   cfg.currSubject     = 'string', subjectfoldername to analyze
%   cfg.inputStr        = 'string', string to find data to analyze (should
%                           be named after the field in the subjectdata.PATHS
%                           structure (f.e. 'APPEND'))
%   cfg.outputStr       = 'string', output string to save the file
%                           (default: ['triallength' num2str(triallength)])
%   cfg.saveData        = 'yes/no', check whether data needs to be saved to
%                           subject folder
%
% The second options loads in data using bv_check4data and saves data using
% bv_savedata
%
% See also BV_CREATESUBJECTFOLDERS, BV_CHECK4DATA, FT_REDEFINETRIAL,
% BV_SAVEDATA

currSubject = ft_getopt(cfg, 'currSubject');
inputStr    = ft_getopt(cfg, 'inputStr');
triallength = ft_getopt(cfg, 'triallength');
outputStr   = ft_getopt(cfg, 'outputStr', ['triallength' num2str(triallength)]);
saveData    = ft_getopt(cfg, 'saveData');
ntrials     = ft_getopt(cfg, 'ntrials', 'all');
overwrite   = ft_getopt(cfg, 'overwrite', 'no');

cfgIn = cfg;

if isempty(triallength)
    error('no config struct does not contain triallength')
end

if nargin < 2
    disp(currSubject)
    
    eval('setOptions');
    eval('setPaths');
    
    subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];
    [subjectdata] = bv_check4data(subjectFolderPath);
    if exist(PATHS.(outputStr), 'file') & strcmpi(overwrite, 'no')
        fprintf('\t file already exists, not overwriting ... \n')
    end

    [subjectdata, dataOld] = bv_check4data(subjectFolderPath, inputStr);
else
    saveData = 'no';
end

continuousSeconds = (diff(dataOld.sampleinfo') + 1) ./ dataOld.fsample;
trialparts2use = find(continuousSeconds >= triallength);

if isempty(trialparts2use)
    fprintf('\t \t no trials found, skipping ... \n')
    data = [];
    finished = 0;
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

subjectdata.nTrialsCleaned = length(data.trial);

if strcmpi(saveData, 'yes')
    
    subjectdata.analysisOrder = bv_updateAnalysisOrder(subjectdata.analysisOrder, cfgIn);
    bv_updateSubjectSummary([PATHS.SUMMARY filesep 'SubjectSummary.mat'], subjectdata)
    
    bv_saveData(subjectdata, data, outputStr);
end
finished = true;
