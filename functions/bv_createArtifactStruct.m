function [artefactdef] = bv_createArtifactStruct(cfg, data)
% bv_createArtefactStruct is a helper function to detect levels used of 
% artifacts in EEG data. Data can be input as arg2 or by giving subject
% folder name (cfg.currSubject = {}). Can be used to remove channels using
% bv_removeChannels or to generate clean trials using bv_cleanData
%
% Use as
%   [artefactdef] = bv_createArtefactStruct(cfg)
% or
%   [artefactdef] = bv_createArtefactStruct(cfg, data)
%
% inputs:
%   cfg -> input configuration structure
%   data -> fieldtrip eeg data variable
%
% outputs: 
%   artefactdef -> structure with the artefact levels for every analyses
%   ran with cfg.analysis
%
% the following fields are required in the cfg variable
%   cfg.cutintrials     = 'yes/no': set to 'yes' if data needs to be cut 
%                           into trials. If 'yes', also set 
%                           cfg.triallength. Uses ft_redefinetrial  
%                           (default: 'no')
%   cfg.analyses        = 'string' or { cell } with strings. Determines
%                           which analyses on any given trial. Options are:
%                               'variance'  -> gives trial variance
%                               'kurtosis'  -> gives trial kurtosis (measure for
%                                               normality of trials
%                               'range'     -> gives trial uV range
%                               'flatline'  -> measure for flatlining based
%                                               on 1/range
%                               'abs'       -> gives trial max(abs(uV))
%                               'jump'      -> detects jumps in trial based on 
%                                               ft_artifact_jump
%                                               (time-consuming)
%                               'all'       -> all above analyses 
%                               
%
% the following fields are required for the config variable if no data
% variable is given:
%   cfg.inputName    = 'string': previous analysis to be used for this 
%                           function, as in subjectdata.PATHS.(inputName)
%   cfg.currSubject     = 'string': subject folder name to be analyzed
%   cfg.pathsFcn        = 'string': filename of m-file to be read with all
%                           necessary paths to run this function (default:
%                           'setPaths'). Take care to add your trialfun
%                           to your matlab path). For an example options
%                           fcn see setPaths.m
%   cfg.saveData        = 'yes/no': specifies whether data needs to be
%                           saved to personal folder (default: 'no')
%
% the following field is required if cutting into trials
%   cfg.triallength     = [ number ]: length of trials in seconds
%
% the following fields need to be set if the data is saved
%   cfg.outputName      = 'string': name for output file. Output will
%                           be called (currSubject)_(cfg.outputName).mat
%                           path will be added to subjectdata.PATHS as
%                           subjectdata.PATHS.(outputName)
%   cfg.overwrite       = 'yes/no': set to 'yes' if data is allowed to be
%                           overwritten (default: 'no')
% 
% the following fields are optional
%   cfg.quiet           = 'yes/no': set to 'yes' to prevent additional
%                           details in command window (default: false)
%
% 2015-2021, Bauke van der Velde
% See also BV_SAVEDATA BV_CHECK4DATA FT_REDEFINETRIAL FT_ARTIFACT_JUMP

inputName       = ft_getopt(cfg, 'inputName');
outputName      = ft_getopt(cfg, 'outputName');
saveData        = ft_getopt(cfg, 'saveData');
currSubject     = ft_getopt(cfg, 'currSubject');
pathsFcn        = ft_getopt(cfg, 'pathsFcn');
cutintrials     = ft_getopt(cfg, 'cutintrials', 'no');
triallength     = ft_getopt(cfg, 'triallength');
overwrite       = ft_getopt(cfg, 'overwrite', 'no');
quiet           = ft_getopt(cfg, 'quiet', 'no');
analyses        = ft_getopt(cfg, 'analyses');

if strcmpi(analyses, 'all')
    analyses = {'var', 'kurtosis', 'range', 'flatline', 'abs', 'jump'};
end

if ~iscell(analyses)
    analyses = {analyses};
end

if strcmpi(quiet, 'yes')
    quiet = true;
else
    quiet = false;
end

if nargin < 2
    
    if isempty(pathsFcn)
        error('please add options function cfg.pathsFcn')
    else
        eval(pathsFcn)
    end
    
    if ~quiet; disp(currSubject); end
    subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];
    if ~quiet
        [subjectdata] = bv_check4data(subjectFolderPath);
    else
        evalc('[subjectdata] = bv_check4data(subjectFolderPath);');
    end
    if strcmpi(overwrite, 'no')
        if isfield(subjectdata.PATHS, upper(outputName))
            if exist(subjectdata.PATHS.(upper(outputName)), 'file')
                if ~quiet; fprintf('\t !!!%s already found, not overwriting ... \n', upper(outputName)); end
                artefactdef = [];
                return
            end
        end
    end
    
    if ~quiet
        [~, data] = bv_check4data(subjectFolderPath, inputName);
    else
        evalc('[~, data] = bv_check4data(subjectFolderPath, inputName);');
    end
    
else
    saveData = 'no';
    overwrite = 'no';
end

if strcmpi(cutintrials, 'yes')
    cfg = [];
    cfg.length = triallength;
    cfg.overlap = 0;
    data = ft_redefinetrial(cfg, data);
end

if ~quiet; fprintf('\t calculating artefact levels ... '); end
for i = 1:length(data.trial)
    if contains('kurtosis', analyses)
        artefactdef.kurtosis.levels(:,i) = kurtosis(data.trial{i}, [], 2);
    end
    if contains('variance', analyses)
        artefactdef.variance.levels(:,i) = std(data.trial{i}, [], 2).^2;
    end
    if contains('flatline', analyses)
        artefactdef.flatline.levels(:,i) = 1./(abs(max(data.trial{i},[],2) - min(data.trial{i},[],2)));
    end
    if contains('range',analyses)
        artefactdef.range.levels(:,i) = max(data.trial{i}, [], 2) - min(data.trial{i}, [], 2);
    end
    if contains('abs',analyses)
        artefactdef.abs.levels(:,i) = max(abs(data.trial{i}), [],2);
    end
end

if contains('jump',analyses)
    artefactdef.jump.levels = zeros(length(data.label), length(data.trial));
    counter = 0;
    for i = 1:length(data.label)
        cfg = [];
        cfg.artfctdef.jump.channel = data.label{i};
        cfg.continuous = 'no';
        [tmp,artifact] = ft_artifact_jump(cfg, data);
        for j = 1:size(artifact,1)
            counter = counter + 1;
            [~,sel] = min(abs(mean(data.sampleinfo(:,1:2),2) - mean(artifact(j,:))));
            artefactdef.jump.levels(i,sel) = 1;
        end
    end
end
if ~quiet; fprintf('done! \n'); end

artefactdef.sampleinfo = data.sampleinfo;

if strcmpi(saveData, 'yes')
    
    if ~quiet
        bv_saveData(subjectdata, artefactdef, outputName);
    else
        evalc('bv_saveData(subjectdata, artefactdef, outputName);');
    end
    
    
end