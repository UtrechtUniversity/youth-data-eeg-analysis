function data = bv_appendfieldtripdata(cfg, dataOld)
% appends data in fieldtrip data structure based on data.sampleinfo, output
% data can be used in concurrence with bv_cutAppendedIntoTrials to cut into
% trials of desired length
%
% can be used with data-input as:
%  [ appendeddata ] = bv_appendfieldtripdata(cfg, data)
%
% or without data-input as:
%  [ appendeddata ] = bv_appendfieldtripdata(cfg)
%
% INPUTS:
% needs the following fields in cfg-structure in the case of no data-input:
%   cfg.currSubject = 'string', subject folder name to analyze
%   cfg.inputName    = 'string', data to be loaded in, using bv_check4data,
%                       based on subjectdata.PATHS field name (f.e.
%                       'APPENDED')%
%   cfg.saveData    = 'yes/no', determines whether data is saved to disk in
%                       subjectfolder, based on cfg.outputName with
%                       bv_saveData
%   cfg.outputName   = 'string', used to save data to unique file, with
%                       unique entry into subjectdata.PATHS
%   cfg.pathsFcn    = path to paths function needed to run
%                       analysis-pipeline (default: './setPaths')
%   cfg.optionsFcn  = path to options function needed to run
%                       analysis-pipeline (default: './setOptions')

%   data: fieldtrip data structure, which should consist of multiple trials
%
% OUTPUTS:
%   appenddata = data appended according to data.sampleinfo
%
% See also, BV_CUTAPPENDEDINTOTRIALS, FT_REDEFINETRIAL
%

%%%% get general options and load in data if necessary %%%%
currSubject = ft_getopt(cfg, 'currSubject');
inputName    = ft_getopt(cfg, 'inputName');
outputName   = ft_getopt(cfg, 'outputName');
saveData    = ft_getopt(cfg, 'saveData');
pathsFcn    = ft_getopt(cfg, 'pathsFcn', 'setPaths');
optionsFcn  = ft_getopt(cfg, 'optionsFcn', 'setOptions');
overwrite   = ft_getopt(cfg, 'overwrite', 'no');
quiet       = ft_getopt(cfg, 'quiet', 'no');

cfgIn = cfg;

if strcmpi(quiet, 'yes')
    quiet = true;
else
    quiet = false;
end

if nargin < 2
    eval(optionsFcn);
    eval(pathsFcn);
    
    subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];
    
    if strcmpi(overwrite, 'no') & strcmpi(saveData, 'yes') & ...
            exist([subjectFolderPath filesep currSubject '_' upper(outputName) '.mat'])
        if ~quiet
            fprintf('\t !!!%s already found, not overwriting ... \n', upper(outputName))
        end
        data = [];
        return
    end
    
    if ~quiet
        disp(currSubject)
        [subjectdata] = bv_check4data(subjectFolderPath);
    else
        evalc('[subjectdata] = bv_check4data(subjectFolderPath);');
    end

    if ~quiet
        [subjectdata, ~, dataOld] = bv_check4data(subjectFolderPath, inputName);
    else
        evalc('[subjectdata, ~, dataOld] = bv_check4data(subjectFolderPath, inputName);');
    end
else
    saveData = 'no';
end

%%%% calculating own trl for appending data %%%%
if ~quiet; fprintf('\t appending cleaned data based on data.sampleinfo ... '); end
fsample = dataOld.fsample;
triallength = size(dataOld.trial{1},2) ./ 512;
startTrial = dataOld.sampleinfo(:,1);
endTrial = dataOld.sampleinfo(:,2);
tmptrl(:,1) = startTrial(find([1; diff(startTrial) ~= length(dataOld.trial{1})]));
tmptrl(:,2) = endTrial(find([diff(startTrial) ~= length(dataOld.trial{1}); 1]));

if isfield(dataOld, 'trialinfo')
    trialinfo = dataOld.trialinfo;
    tmptrialinfo = dataOld.trialinfo(ismember(dataOld.sampleinfo(:,1), tmptrl(:,1)));
    
    trl = [tmptrl zeros(length(tmptrialinfo),1) tmptrialinfo];
else
    trl = [tmptrl zeros(length(tmptrl),1)];
end

%%%% redefining trials based on calculated trl %%%%
cfg = [];
cfg.trl = trl;
evalc('data = ft_redefinetrial(cfg, dataOld);');
if ~quiet; fprintf('done! \n'); end

if strcmpi(saveData, 'yes')
    if ~quiet
        bv_saveData(subjectdata, data, outputName);
    else
        evalc('bv_saveData(subjectdata, data, outputName);');
    end
end
