function data = bv_cleanData(cfg, data, artefactdef)
% bv_cleanData removes artifact-ridden trials and creates clean data file.
% Adds clean trial sample info to subjectdata (subjectdata.cleanSampleInfo)
%
% Use as
%   [data] = bv_cleanData(cfg)
%
% or as
%   [data] = bv_cleanData(cfg, data, artefactdef)
%
% inputs:
%   cfg             : input configuration structure
%   data            : fieldtrip eeg data variable
%   artefactdef     : structure with artefact information calculated with
%                       bv_createArtefactStruct
%
% outputs:
%   data            : fieldtrip data without removed channels (or with
%                       repaired channels)
%
% the following fields are required in the cfg variable
%   cfg.lims                = . struct . with limits in number for values 
%                               found in the artefacts struct. Possible 
%                               fields: 'kurtosis', 'variance', 'jump', 
%                               'abs', 'range', 'flatline'. Example 
%                               (cfg.lims.kurtosis = 7)
%   cfg.calculateDataloss   = 'yes/no'. Set to 'yes' if data loss
%                               percentage should be calculated and added 
%                               to subjectdata. Also add cfg.expectedtrials
%                               (default: 'no')
%
% the following fields are only required if no data&artefactdef input
%
%   cfg.pathsFcn        = 'string': filename of m-file to be read with all
%                           necessary paths to run this function (default:
%                           'setPaths').
%   cfg.currSubject     = 'string': subject folder name to be analyzed
%   cfg.inputName       = 'string': name of previous analysis to be used 
%                           for this function, as in 
%                           subjectdata.PATHS.(prevAnalysis)
%   cfg.artefactData    = 'string': name of artefact data to be used for 
%                           this function, as in
%                           subjectdata.PATHS.(artefactData)
%   cfg.saveData        = 'yes/no': specifies whether subjectdata needs to 
%                           be saved to personal folder
%   cfg.saveCleanData   = 'yes/no': specifies whether subjectdata needs to 
%                           be saved to personal folder
%   cfg.overwrite       = 'yes/no': set to 'yes' if data is allowed to be
%                           overwritten (default: 'no')
% 
% the following fields are required if cleaned data is saved
%   cfg.outputName      = 'string': name for output file. Output will
%                           be called (currSubject)_(cfg.outputName).mat
%                           path will be added to subjectdata.PATHS as
%                           subjectdata.PATHS.(outputName)
%
% the following fields are required if data loss is calculated
%   cfg.expectedtrials  = [ number ]: number of expected trials in dataset
%
% the following fields are optional
%   cfg.quiet           = 'yes/no': set to 'yes' to prevent additional
%                           details in command window (default: 'no')
%
% See also FT_REDEFINA_TRIAL
% Copyright (C) 2015-2021, Bauke van der Velde

lims                = ft_getopt(cfg, 'lims');
pathsFcn            = ft_getopt(cfg, 'pathsFcn');
currSubject         = ft_getopt(cfg, 'currSubject');
inputName           = ft_getopt(cfg, 'inputName');
outputName          = ft_getopt(cfg, 'outputName');
artefactData        = ft_getopt(cfg, 'artefactData');
saveData            = ft_getopt(cfg, 'saveData');
calculateDataloss   = ft_getopt(cfg, 'calculateDataloss', 'no');
expectedtrials      = ft_getopt(cfg, 'expectedtrials');
saveCleanData       = ft_getopt(cfg, 'saveCleanData');
quiet               = ft_getopt(cfg, 'quiet', 'no');
overwrite           = ft_getopt(cfg, 'overwrite', 'no');

if strcmpi(quiet, 'yes')
    quiet = true;
else
    quiet = false;
end

cfgIn = cfg;

if isempty(lims)
    error('Please give cfg.lims struct as input')
end

saveSubjectData = 'no';
if nargin < 2 % data loading
    if isempty(pathsFcn)
        error('please add options function cfg.optionsFcn')
    else
        eval(pathsFcn)
    end
    
    subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];
    if strcmpi(overwrite, 'no') & strcmpi(saveCleanData, 'yes') & ...
            exist([subjectFolderPath filesep currSubject '_' upper(outputName) '.mat'], 'file')
        if ~quiet
            fprintf('\t !!!%s already found, not overwriting ... \n', upper(outputName))
        end
        data = [];
        return
    end
    
    if ~quiet
        disp(currSubject);
        [subjectdata, ~, data, artefactdef] = bv_check4data(subjectFolderPath, inputName, artefactData);
    else
        evalc('[subjectdata, ~, data, artefactdef] = bv_check4data(subjectFolderPath, inputName, artefactData);');
    end
    
    subjectdata.cfgs.(outputName) = cfg;
elseif isfield(cfg, 'currSubject')
    if isempty(pathsFcn)
        error('please add options function cfg.optionsFcn')
    else
        eval(pathsFcn)
    end
    subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];
    if ~quiet
        disp(currSubject);
        [subjectdata] = bv_check4data(subjectFolderPath);
    else
        evalc('[subjectdata] = bv_check4data(subjectFolderPath);');
    end
    saveSubjectData = 'yes';
else
    subjectdata = struct;
    saveData = 'no';
end

% artefact detection
limFields = fieldnames(lims);
for i = 1:length(limFields)
    cField = limFields{i};
    
    out(:,:,i) = artefactdef.(cField).levels > lims.(cField);
    
end

% dataloss calculation
if strcmpi(calculateDataloss, 'yes')
    nBadTrials = sum(sum(sum(out,3)>0) > 0);
    nGoodTrials = size(out,2) - nBadTrials;
    subjectdata.(dataLossLabel) = (1 - min([nGoodTrials, expectedtrials]) / expectedtrials) * 100;
end

goodTrialIndx = find(sum(sum(out,3)>0) == 0);

cfg = [];
cfg.trl = [artefactdef.sampleinfo(goodTrialIndx,:), zeros(length(goodTrialIndx),1)];
if isempty(cfg.trl)
    removingSubjects([],currSubject, 'no clean trials found')
    return
end
evalc('data = ft_redefinetrial(cfg, data);');

if ~isfield(data, 'trialinfo')
    data.trialinfo = ones(length(data.trial),1);
end

cfg = [];
cfg.trl = data.cfg.trl;
cfg.trl(:,4) = data.trialinfo;
trlCount = bv_showTrialAmount(cfg);

subjectdata.cleanSampleInfo = artefactdef.sampleinfo(goodTrialIndx,:);

if strcmpi(saveData, 'yes')
    if ~quiet
        bv_saveData(subjectdata, data, outputName);             % save both data and subjectdata to the drive
    else
        evalc('bv_saveData(subjectdata, data, outputName);');
    end
elseif strcmpi(saveSubjectData, 'yes')
    if ~quiet
        bv_saveData(subjectdata);                               % save only subjectdata to the drive
    else
        evalc('bv_saveData(subjectdata);');
    end
end




