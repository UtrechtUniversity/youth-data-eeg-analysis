function bv_createSubjectFolders_standard(cfg, varargin)
% bv_createSubjectFolders creates the folder structure necessary to run
% analyses for infant EEG and adds an individual Subject.mat file in each
% folder with individuals information and paths to important files.
% Currently set-up to find the following datatype: 'bdf', 'eeg'. Set used
% datatype in your setOptions file. Creates subject folders with a name based
% on the raw data filename, by using as foldername the  part of the
% filename before the first dash ('_'). f.e. 'A12345_raw.bdf' becomes
% subjectname: 'A12345'
%
% Use as:
%  bv_createSubjectFolders(cfg)
%
% The input argument cfg is a configuration structure, which contains all
% details for the create subject folders.
%
% Possible inputarguments in configuration structure:
%   cfg.optionsFcn      = 'string', filename to options m-file. (default:
%                           'setOptions'). For example see
%                           setOptions_empty.
%   cfg.pathsFcn        = 'string', filename to paths m-file. (default:
%                           'setPaths'). For example see
%                           setPaths_empty.
%
% Saves an Subject.mat file, with a subjectdata structure with the
% following fields:
%   subjectdata.subjectName         = 'string', given name of the subject
%   subjectdata.date                = 'string', time and data of creation
%   subjectdata.filename            = 'string', filename of dataset
%
%   subjectdata.PATHS               = .structure., with paths to all important
%                                       files
%   subjectdata.PATHS.SUBJECTDIR    = 'string', path to subjectdirectory
%   subjectdata.PATHS.DATAFILE      = 'string', path to dataset
%   subjectdata.PATHS.HDRFILE       = 'string', path to headerfile
%
%
% Copyright (C) 2015-2017, Bauke van der Velde
%
% See also SETPATHS_EMPTY, SETOPTIONS_EMPTY

% read out from configuration structure
optionsFcn      = ft_getopt(cfg, 'optionsFcn','setOptions');
pathsFcn        = ft_getopt(cfg, 'pathsFcn','setPaths');
inputStr        = ft_getopt(cfg, 'inputStr', 'preproc');
rawdelim        = ft_getopt(cfg, 'rawdelim');
sfolderstruct   = ft_getopt(cfg, 'subjectfolderstructure');
trialfun        = ft_getopt(cfg, 'trialfun');

% load in standard options and paths
eval(optionsFcn);
eval(pathsFcn);

% detect raw eeg files based on path to raws and the subject search string
% (OPTIONS.sDirString)
if strcmpi(OPTIONS.dataType, 'mat')
    files = dir([PATHS.PREPROC filesep '*' inputStr '.mat']);
    if isempty(files)
        error('no files found for inputstring: %s \n', inputStr)
    end
else
    files = dir([PATHS.RAWS filesep '*' OPTIONS.sDirString '*']);
end
fileNames = {files.name};

if ~exist(PATHS.SUBJECTS,'dir'); mkdir PATHS.SUBJECTS; end % create, if necessary, Subject folder

removeIdx = 0;
for subjIndex = 1:length(fileNames)
    include = true;
    inputnames = varargin;
    [~, cFile] = fileparts(fileNames{subjIndex});
    
    a = regexp(cFile, '[A-B,0-9]', 'Match');
    
    splitFile = {[a{:}]};
    
    inputdiff = length(splitFile) - length(inputnames);
    if inputdiff > 0
        inputnames = cat(2,inputnames, cell(1,inputdiff));
    elseif inputdiff < 0
        inputnames = inputnames(1:length(inputnames)+inputdiff);
    end
    
    splitFile = splitFile(not(cellfun(@isempty, inputnames)));
    inputnames = inputnames(not(cellfun(@isempty, inputnames)));
    
    for i = 1:length(splitFile)
        subjectdata.(inputnames{i}) = splitFile{i};
    end
    
    switch OPTIONS.dataType % find EEG files to start analysis with (can be 'bdf', 'eeg' or 'mat')
        case 'eeg'
            israw = 1;
            dataFile = [PATHS.RAWS filesep cFile  '.eeg'];
            hdrFile = [PATHS.RAWS filesep cFile  '.vhdr'];
            
            if ~exist(dataFile, 'file')
                error('dataFile: %s not found!', dataFile)
            elseif ~exist(hdrFile, 'file')
                error('headerfile: %s not found!', hdrFile)
            end
            
            
        case 'bdf'
            israw = 1;
            dataFile = [PATHS.RAWS filesep cFile  '.bdf'];
            hdrFile = [PATHS.RAWS filesep cFile  '.bdf'];
            
            if ~exist(dataFile, 'file')
                error('dataFile: %s not found!', dataFile)
            elseif ~exist(hdrFile, 'file')
                error('headerfile: %s not found!', hdrFile)
            end
            
        case 'mat'
            israw = 0;
            dataFile = 'unknown';
            hdrFile = 'unknown';
            
            subjectdata.PATHS.(upper(inputStr)) = ...
                [PATHS.PREPROC filesep cFile '.mat'];
            
            if ~exist(subjectdata.PATHS.(upper(inputStr)), 'file')
                error('dataFile: %s not found!', dataFile)
            end
            
            
        otherwise
            error(sprintf('unknown datatype %s', OPTIONS.dataType));
    end
    
    subjectdata.subjectName = strjoin(splitFile(ismember(inputnames, sfolderstruct)), rawdelim);
    disp(subjectdata.subjectName);
    
    if ~isempty(trialfun)
        fprintf('\t checking for trials based on %s ... \n', trialfun)
        cfg = [];
        cfg.headerfile = hdrFile;
        cfg.dataset = dataFile;
        cfg.trialfun = trialfun;
        cfg.Fs= 2048;
        try
            evalc('cfg = ft_definetrial(cfg);');
        catch
            fprintf('no trials found, skipping current subject\n')
            include = false;
            continue
        end
        
        fprintf('\t \t %1.0f trials found \n', size(cfg.trl,1))
    end
    
    paths2SubjectFolder = [PATHS.SUBJECTS filesep subjectdata.subjectName]; % create a path to current subject folder
    if ~exist(paths2SubjectFolder,'dir')
        mkdir(paths2SubjectFolder); % create, if necessary, individual subject folder
    end
    
    subjectdata.PATHS.SUBJECTDIR = paths2SubjectFolder; % save path to subject folder in subjectdata
    
    subjectdata.PATHS.DATAFILE = dataFile; % save both dataset and hdrfile to subjectdata structures
    subjectdata.PATHS.HDRFILE = hdrFile;
    [~, subjectdata.filename, ~] = fileparts(subjectdata.PATHS.DATAFILE);
    
    subjectdata.date = date;
    
    [subjectdata.testdate , subjectdata.testtime] = bv_readOutDateAndTimeBdf(dataFile);
    
    fprintf('\t saving Subject.mat...')
    save([subjectdata.PATHS.SUBJECTDIR filesep 'Subject'],'subjectdata'); % save individual subjectdata structure to individual folder
    fprintf('done \n')
    clear subjectdata
    
end

