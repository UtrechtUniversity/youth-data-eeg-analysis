function data = bv_redefineTriallength(cfg, data)
% bv_redefineTriallength cuts existing trials into (optionally
% overlapping) sub-windows of a fixed length, using FT_REDEFINETRIAL.
% Each original trial is segmented independently, so trialinfo (e.g.
% condition labels) carries over correctly to every resulting epoch, and
% trials don't need to be adjacent/continuous.
%
% Use as
%   [data] = bv_redefineTriallength(cfg)
% or as
%   [data] = bv_redefineTriallength(cfg, data)
%
% the following fields are required in the cfg variable
%   cfg.triallength     = [ number ]: length (in s) of the resulting
%                           epochs
%
% the following fields are only required if no data input is given
%   cfg.pathsFcn        = 'string': filename of m-file to be read with all
%                           necessary paths to run this function (default:
%                           'setPaths')
%   cfg.currSubject     = 'string': subject folder name to be analyzed
%   cfg.inputName       = 'string': name of previous analysis step to be
%                           used for this function, as in
%                           subjectdata.PATHS.(inputName)
%   cfg.saveData        = 'yes/no': specifies whether data needs to be
%                           saved to personal folder (default: 'no')
%   cfg.overwrite       = 'yes/no': set to 'yes' if data is allowed to be
%                           overwritten (default: 'no')
%
% the following fields are required if data is saved
%   cfg.outputName      = 'string': name for output file. Output will
%                           be called (currSubject)_(cfg.outputName).mat
%                           path will be added to subjectdata.PATHS as
%                           subjectdata.PATHS.(outputName)
%
% the following fields are optional
%   cfg.overlap         = [ number ]: fraction (0-1, exclusive) of overlap
%                           between consecutive epochs (default: 0, i.e.
%                           no overlap). E.g. for 3s epochs with a 1s
%                           step, use cfg.triallength = 3 and
%                           cfg.overlap = 2/3.
%   cfg.quiet           = 'yes/no': set to 'yes' to prevent additional
%                           details in command window (default: 'no')
%
% See also FT_REDEFINETRIAL, BV_CREATEARTEFACTSTRUCT, BV_CLEANDATA

pathsFcn    = ft_getopt(cfg, 'pathsFcn', 'setPaths');
currSubject = ft_getopt(cfg, 'currSubject');
inputName   = ft_getopt(cfg, 'inputName');
outputName  = ft_getopt(cfg, 'outputName');
saveData    = ft_getopt(cfg, 'saveData', 'no');
overwrite   = ft_getopt(cfg, 'overwrite', 'no');
quiet       = ft_getopt(cfg, 'quiet', 'no');
triallength = ft_getopt(cfg, 'triallength');
overlap     = ft_getopt(cfg, 'overlap', 0);

quiet = strcmpi(quiet, 'yes');

if isempty(triallength)
    error('please specify cfg.triallength')
end

saveSubjectData = 'no';
if nargin < 2 % data loading
    if isempty(pathsFcn)
        error('please add paths function cfg.pathsFcn')
    else
        eval(pathsFcn)
    end

    subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];
    if strcmpi(overwrite, 'no') && strcmpi(saveData, 'yes') && ...
            exist([subjectFolderPath filesep currSubject '_' upper(outputName) '.mat'], 'file')
        if ~quiet
            fprintf('\t !!!%s already found, not overwriting ... \n', upper(outputName))
        end
        data = [];
        return
    end

    if ~quiet
        disp(currSubject);
        [subjectdata, check, data] = bv_check4data(subjectFolderPath, inputName);
        if ~check
            error('%s: input data not found', currSubject)
        end
    else
        evalc('[subjectdata, check, data] = bv_check4data(subjectFolderPath, inputName);');
        if ~check %#ok<NODEF>
            error('%s: input data not found', currSubject)
        end
    end

    subjectdata.cfgs.(outputName) = cfg;
elseif isfield(cfg, 'currSubject')
    if isempty(pathsFcn)
        error('please add paths function cfg.pathsFcn')
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

% ft_redefinetrial silently drops any trial shorter than cfg.length when
% cutting into fixed-length (sub-)windows. If *every* trial is too short,
% it's left with nothing to redefine and throws a generic, misleading
% "you should specify at least one configuration option" error instead of
% saying so directly - check for that case up front instead.
trialDurations = (data.sampleinfo(:,2) - data.sampleinfo(:,1) + 1) ./ data.fsample;
if max(trialDurations) < triallength
    error('no trials long enough for %ss epoching (longest available trial: %.2fs)', ...
        num2str(triallength), max(trialDurations))
end

if ~quiet; fprintf('\t redefining triallength to %ss (overlap %s) ... ', num2str(triallength), num2str(overlap)); end
ftcfg         = [];
ftcfg.length  = triallength;
ftcfg.overlap = overlap;
evalc('data = ft_redefinetrial(ftcfg, data);');
if ~quiet; fprintf('done! \n'); end

if strcmpi(saveData, 'yes')
    if ~quiet
        bv_saveData(subjectdata, data, outputName);
    else
        evalc('bv_saveData(subjectdata, data, outputName);');
    end
elseif strcmpi(saveSubjectData, 'yes')
    if ~quiet
        bv_saveData(subjectdata);
    else
        evalc('bv_saveData(subjectdata);');
    end
end
