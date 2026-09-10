function [data, subjectdata] = bv_removeChannels(cfg, data, artefactdef)
% bv_removeChannels removes and repairs channels 
%
% Use as
%   [data] = bv_removeChannels(cfg)
%
% or as
%   [data] = bv_removeChannels(cfg, data, artefactdef)
%
% inputs:
%   cfg             : input configuration structure
%   data            : fieldtrip eeg data variable
%   artefactdef     : structure with artefact information calculated with
%                       bv_createArtifactStruct
%
% outputs:
%   data            : fieldtrip data without removed channels (or with
%                       repaired channels)
%
% the following fields are required in the cfg variable
%   cfg.lims            = . struct . with limits in number for values found
%                           in the artefacts struct. Possible fields:
%                           'kurtosis', 'variance', 'jump', 'abs', 'range',
%                           'flatline'. Example (cfg.lims.kurtosis = 7)
%   cfg.maxpercbad      = [ number ]: max percentage of bad trials before a
%                           channel is removed (default = 40);
%   cfg.expectedtrials  = [ number ]: number of expected trials in dataset
%   cfg.repairchans     = 'yes/no': set to 'yes' to interpolate channels
%                           by weighting neighboring channels 
%                           (triangulation). Uses ft_channelrepair and
%                           ft_prepare_neighbours
%   cfg.quiet           = 'yes/no': set to 'yes' to prevent additional
%                           details in command window (default: false)
%
% the following fields are only required if no data&artefactdef input
%
%   cfg.pathsFcn        = 'string': filename of m-file to be read with all
%                           necessary paths to run this function (default:
%                           'setPaths'). Is created automatically by
%                           bv_createNewAnalysis
%   cfg.currSubject     = 'string': subject folder name to be analyzed
%   cfg.inputName       = 'string': name of previous analysis to be used 
%                           for this function, as in 
%                           subjectdata.PATHS.(prevAnalysis)
%   cfg.artefactData    = 'string': name of artefact data to be used for 
%                           this function, as in
%                           subjectdata.PATHS.(artefactData)
%   cfg.saveData        = 'yes/no': specifies whether data needs to be
%                           saved to personal folder
%   cfg.overwrite       = 'yes/no': set to 'yes' if data is allowed to be
%                           overwritten (default: 'no')
%
% the following fields are required if data is saved
%   cfg.outputName      = 'string': name for output file. Output will
%                           be called (currSubject)_(cfg.outputName).mat
%                           path will be added to subjectdata.PATHS as
%                           subjectdata.PATHS.(outputName)
% See also FT_PREPARE_NEIGHBOURS FT_CHANNELREPAIR
% Copyright (C) 2015-2021, Bauke van der Velde

lims            = ft_getopt(cfg, 'lims');
pathsFcn        = ft_getopt(cfg, 'pathsFcn');
currSubject     = ft_getopt(cfg, 'currSubject');
inputName       = ft_getopt(cfg, 'inputName');
outputName      = ft_getopt(cfg, 'outputName');
artefactData    = ft_getopt(cfg, 'artefactData');
saveData        = ft_getopt(cfg, 'saveData');
maxpercbad      = ft_getopt(cfg, 'maxpercbad', 40);
expectedtrials  = ft_getopt(cfg, 'expectedtrials');
repairchans     = ft_getopt(cfg, 'repairchans');
overwrite       = ft_getopt(cfg, 'overwrite');
quiet           = ft_getopt(cfg, 'quiet', false);
maxbadchans     = ft_getopt(cfg, 'maxbadchans', 3);

cfgIn = cfg;

if strcmpi(quiet, 'yes')
    quiet = true;
else
    quiet = false;
end

if isempty(lims)
    error('Please give cfg.lims struct as input')
end
if isempty(maxpercbad)
    error('Please set maximum percentage missing per channel in cfg.maxpercbad')
end

if nargin < 2 % data loading
    if isempty(pathsFcn)
        error('please add paths function cfg.pathsFcn')
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
                data = [];
                return
            end
        end
    end
    
    if ~quiet
        [subjectdata, ~, data, artefactdef] = bv_check4data(subjectFolderPath, inputName, artefactData);
    else
        evalc('[subjectdata, ~, data, artefactdef] = bv_check4data(subjectFolderPath, inputName, artefactData);');
    end
    
    subjectdata.cfgs.(outputName) = cfg;
elseif isfield(cfg, 'currSubject')
    if isempty(pathsFcn)
        error('please add paths function cfg.pathsFcn')
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
    saveData = 'no';
else
    subjectdata = struct;
    repairchans = 'yes';
    saveData = 'no';
end

if isempty(expectedtrials)
    expectedtrials = size(artefactdef.sampleinfo,1);
end

if ~quiet; fprintf('\t checking for channels to remove ... \n'); end
% artefact detection
limFields = fieldnames(lims);
for i = 1:length(limFields)
    cField = limFields{i};
    
    out(:,:,i) = artefactdef.(cField).levels > lims.(cField);
    
end

allOut = any(out,3);

% badchannel calculation
badchans = data.label(((sum(sum(out,3)>0,2) / expectedtrials) * 100 ) > maxpercbad);
subjectdata.flaggedChannels = badchans;
subjectdata.flatChannels = ...
    data.label(((sum(sum(out(:,:, ...
    contains(limFields, 'flat')),3)>0,2) / expectedtrials) * 100 ) > ...
    maxpercbad);
subjectdata.noisyChannels = ...
    data.label(((sum(sum(out(:,:, ...
    not(contains(limFields, 'flat'))),3)>0,2) / expectedtrials) * 100 ) > ...
    maxpercbad);
subjectdata.nChannels = length(data.label);
subjectdata.interpolatedChannels = cell(0);

if length(subjectdata.flaggedChannels) > maxbadchans
    % removingSubjects reloads subjectdata fresh from Subject.mat, so the
    % channel-list fields just set above (flaggedChannels/flatChannels/
    % noisyChannels/nChannels) need to be on disk first, or they're lost -
    % this subject never reaches the bv_saveData call at the bottom of
    % this function otherwise.
    if ~quiet
        bv_saveData(subjectdata);
    else
        evalc('bv_saveData(subjectdata);');
    end
    removingSubjects([], currSubject, 'too many noisy channels')
    data = [];
    return
end

if not(isempty(subjectdata.flaggedChannels))
    if ~quiet; fprintf(['\t \t bad channels detected: ' repmat('%s,', 1, length(badchans)) '\n'], badchans{:}); end
    
    % unreachable: the identical check above (~line 173) already returns
    % whenever this condition holds, so execution never reaches here with
    % length(flaggedChannels) > maxbadchans. Pre-existing dead code, left
    % as-is/harmless.
    if length(subjectdata.flaggedChannels) > maxbadchans
        removingSubjects([], currSubject, 'too many noisy channels')
        data = [];
        return
    end


    % badchannel interpolation
    if strcmpi(repairchans, 'yes') 
        if ~quiet; fprintf('\t repairing ... '); end
        cfg = [];
        cfg.method          = 'triangulation';
        cfg.template        = 'EEG1010';
        cfg.layout          = 'biosemi32.lay';
        cfg.feedback        = 'no';
        evalc('neighbours = ft_prepare_neighbours(cfg, data);');
        
        cfg = [];
        cfg.missingchannel = subjectdata.flaggedChannels';
        cfg.method = 'weighted';
        cfg.neighbours = neighbours;
        cfg.layout = 'biosemi32.lay';
        evalc('data = ft_channelrepair(cfg, data);');
        subjectdata.interpolatedChannels = subjectdata.flaggedChannels;
        if ~quiet; fprintf('done! \n'); end
    else
        if ~quiet; fprintf('\t added to subjectdata struct \n'); end
    end
end

if strcmpi(saveData, 'yes')
    if ~quiet
        if strcmpi(repairchans, 'yes')
            bv_saveData(subjectdata, data, outputName); % save both data and subjectdata to the drive
        else
            bv_saveData(subjectdata);
        end
    else
        if strcmpi(repairchans, 'yes')
            evalc('bv_saveData(subjectdata, data, outputName);'); % save both data and subjectdata to the drive
        else
            evalc('bv_saveData(subjectdata);');
        end
    end
else
    bv_saveData(subjectdata)
end

