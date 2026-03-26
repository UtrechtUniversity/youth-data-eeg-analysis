function bv_createSubjectFolders(cfg)
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
optionsFcn  = ft_getopt(cfg, 'optionsFcn','setOptions');
pathsFcn    = ft_getopt(cfg, 'pathsFcn','setPaths');
inputStr    = ft_getopt(cfg, 'inputStr', 'preproc');

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

subjectName = cellfun(@(x) x(regexp(x,'[AB0-9]')), fileNames, 'Un', 0);

% noExtfileNames = cellfun(@(x) strsplit(x, '.'), fileNames, 'Un', 0);
% noExtfileNames = cellfun(@(x) x{1}, noExtfileNames, 'Un', 0);
% 
% splitFilenames = cellfun(@(x) strsplit(x, '_'), noExtfileNames, 'Un', 0);
% subjectName = cellfun(@(v) v{1}, splitFilenames, 'Un', 0);
% subjectAge = cellfun(@(a) a{2}, splitFilenames, 'Un',0);
% % testDate = cellfun(@(d) d{5}, splitFilenames, 'Un',0);


if ~exist(PATHS.SUBJECTS,'dir'); mkdir PATHS.SUBJECTS; end % create, if necessary, Subject folder

removeIdx = 0;
for subjIndex = 1:length(subjectName)
    
    cSubjectName = [subjectName{subjIndex} '_' subjectAge{subjIndex}]; % find current subject name
    [~,fname,~] = fileparts(fileNames{subjIndex});
    
    switch OPTIONS.dataType % find raw EEG files (can be 'bdf' or 'eeg' datatype')
        case 'eeg'
            israw = 1;
            dataFile = [PATHS.RAWS filesep fname  '.eeg'];
            hdrFile = [PATHS.RAWS filesep fname  '.vhdr'];
            
        case 'bdf'
            israw = 1;
            dataFile = [PATHS.RAWS filesep fname  '.bdf'];
            hdrFile = [PATHS.RAWS filesep fname  '.bdf'];
            
        case 'mat'
            israw = 0;
            dataFile = 'unknown';
            hdrFile = 'unknown';
            
            subjectdata
            
        otherwise
            error(sprintf('unknown datatype %s', OPTIONS.dataType));
    end    
    
    if ~exist(dataFile, 'file')
        error('dataFile: %s not found!', dataFile)
    elseif ~exist(hdrFile, 'file')
        error('headerfile: %s not found!', hdrFile)
    end
    
    paths2SubjectFolder = [PATHS.SUBJECTS filesep cSubjectName]; % create a path to current subject folder
    if ~exist(paths2SubjectFolder,'dir')
        mkdir(paths2SubjectFolder); % create, if necessary, individual subject folder
    end
    
    subjectdata.subjectName = cSubjectName;
    disp(subjectdata.subjectName)
    
    subjectdata.PATHS.SUBJECTDIR = [PATHS.SUBJECTS filesep subjectdata.subjectName]; % save path to subject folder in subjectdata
    
    subjectdata.PATHS.DATAFILE = dataFile; % save both dataset and hdrfile to subjectdata structures
    subjectdata.PATHS.HDRFILE = hdrFile;
    [~, subjectdata.filename, ~] = fileparts(subjectdata.PATHS.DATAFILE);
    
    subjectdata.date = date;
    
    fprintf('\t saving Subject.mat...')
    save([subjectdata.PATHS.SUBJECTDIR filesep 'Subject'],'subjectdata'); % save individual subjectdata structure to individual folder
    fprintf('done \n')
    clear subjectdata
    
end

