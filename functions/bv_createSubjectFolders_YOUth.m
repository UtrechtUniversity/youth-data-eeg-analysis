function bv_createSubjectFolders_YOUth(cfg)
% bv_createSubjectFolders creates the folder structure necessary to run
% analyses for infant EEG and adds an individual Subject.mat file in each
% folder with individuals information and paths to important files.
%
% Use as
% bv_createSubjectFolders_YOUth( cfg )
%
% The input configuration (cfg) structures requires at least the following
% fields:
%   cfg.rawdelim:       ' string ' with the delimiter found in the raw EEG
%                       files (this is usually a '_' or a '-'
%   cfg.rawlabel:       { cell } with strings labeling the different
%                       elements of the raw file name. This information 
%                       will then be automatically added to the Subject.mat
%                       file in the function. As an example, look at this 
%                       file name of YOUth: 
%                       B00002_10m_facehouse_20181121_1019.bdf. So this
%                       would be {'pseudo', 'wave', 'task', 'date',
%                       'time'}. Note that you can also pick and choose 
%                       which ones you want to add to the Subject.mat. I
%                       usually just do {'pseudo', 'wave'}, but you could
%                       also do {'pseudo', [], 'task}
%   cfg.sfoldername     { cell } with strings telling Matlab how to name
%                       every subject folder based on the filename of the
%                       raw data file. The filename: 
%                       B00002_10m_facehouse_20181121_1019.bdf with
%                       cfg.subjectfoldername = {'pseudo', 'wave'} will
%                       create a B00002_10m folder in ./Subjects. 
%   cfg.pathsFcn        ' string ' filename of m-file to be read with all
%                       necessary paths to run this function (default:
%                       'setPaths').
%   cfg.sDirString      ' string ' to match raw eeg files with
%   cfg.dataType        ' string ' to set which type of raw data file is
%                       being used. Currently implemented are 'bdf' and
%                       'eeg'. You can use 'mat' if you want to start the
%                       analysis from existing fieldtrip data files. Please
%                       also give cfg.prevAnalysis if you use this option
%   cfg.overwrite       'yes/no' overwrite existing files? (default: 'no')
%
% optional fields:
%   cfg.prevAnalysis    ' string ' to use in combination with 
%                       cfg.dataType = mat. Give the label of the previous
%                       analysis (default: 'PREPROC')


% The following field


% read out from configuration structure
pathsFcn        = ft_getopt(cfg, 'pathsFcn','setPaths');
prevAnalysis    = ft_getopt(cfg, 'prevAnalysis', 'preproc');
rawdelim        = ft_getopt(cfg, 'rawdelim');
sfolderstruct   = ft_getopt(cfg, 'sfoldername');
inputnames      = ft_getopt(cfg, 'rawlabel');
sDirString      = ft_getopt(cfg, 'sDirString', 'no');
dataType        = ft_getopt(cfg, 'dataType');
overwrite       = ft_getopt(cfg, 'overwrite', 'no');

% load in standard options and paths
eval(pathsFcn);

if strcmpi(overwrite, 'no')
    subjectdatasummary = table2struct(bv_createSubjectResults());
    
    for i = 1:height(subjectdatasummary)
        dataFilePath = subjectdatasummary(i).PATHS.DATAFILE;
        [~, dataFile, ext] = fileparts(dataFilePath);
        allDatafiles{i} = strcat(dataFile,ext);
    end
else
    overwrite = 'yes';
end

% detect raw eeg files based on path to raws and the subject search string
% (sDirString)
if strcmpi(dataType, 'mat')
    files = dir([PATHS.PREPROC filesep '*' prevAnalysis '.mat']);
    if isempty(files)
        error('no files found for inputstring: %s \n', prevAnalysis)
    end
else
    files = dir([PATHS.RAWS filesep '*' sDirString '*']);
end
fileNames = {files.name};

if strcmpi(overwrite, 'no')
    fileNames = fileNames(not(ismember(fileNames, allDatafiles)));
end

if ~exist(PATHS.SUBJECTS,'dir'); mkdir PATHS.SUBJECTS; end % create, if necessary, Subject folder

removeIdx = 0;
nSubjects = 0;
for subjIndex = 1:length(fileNames)
    include = true;
    [~, cFile] = fileparts(fileNames{subjIndex});
    
    splitFile = strsplit(cFile, '_');
    
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
    
    switch dataType % find EEG files to start analysis with (can be 'bdf', 'eeg' or 'mat')
        case 'eeg'
            israw = 1;
            dataFile = [PATHS.RAWS filesep cFile  '.eeg'];
            hdrFile = [PATHS.RAWS filesep cFile  '.vhdr'];
            
            if ~exist(dataFile, 'file')
                error('dataFile: %s not found!', dataFile)
            elseif ~exist(hdrFile, 'file')
                error('headerfile: %s not found!', hdrFile)
            end
            
            
        case {'edf', 'bdf', 'EDF', 'BDF'}
            israw = 1;
            
            dataFile = [PATHS.RAWS filesep cFile '.' dataType];
            hdrFile = [PATHS.RAWS filesep cFile '.' dataType];
            
            if ~exist(dataFile, 'file')
                error('dataFile: %s not found!', dataFile)
            elseif ~exist(hdrFile, 'file')
                error('headerfile: %s not found!', hdrFile)
            end
            
        case 'mat'
            israw = 0;
            dataFile = 'unknown';
            hdrFile = 'unknown';
            
            subjectdata.PATHS.(upper(prevAnalysis)) = ...
                [PATHS.PREPROC filesep cFile '.mat'];
            
            if ~exist(subjectdata.PATHS.(upper(prevAnalysis)), 'file')
                error('dataFile: %s not found!', dataFile)
            end
            
            
        otherwise
            error('unknown datatype %s', dataType);
    end
    
    subjectdata.subjectName = strjoin(splitFile(ismember(inputnames, sfolderstruct)), rawdelim);
    subjectFoldersFound = dir([PATHS.SUBJECTS filesep sDirString '*']);
    subjectFoldersFoundNames = {subjectFoldersFound.name};
    
    currentFoldersFound = sum(contains(subjectFoldersFoundNames, subjectdata.subjectName));
    if currentFoldersFound~=0
        subjectdata.subjectName = [subjectdata.subjectName '_' num2str(currentFoldersFound+1)];
    end
    
    disp(subjectdata.subjectName);
    paths2SubjectFolder = [PATHS.SUBJECTS filesep subjectdata.subjectName];
    if ~exist(paths2SubjectFolder, 'dir')
        mkdir(paths2SubjectFolder);
    end
    
    subjectdata.PATHS.SUBJECTDIR = paths2SubjectFolder; % save path to subject folder in subjectdata
    
    subjectdata.PATHS.DATAFILE = dataFile; % save both dataset and hdrfile to subjectdata structures
    subjectdata.PATHS.HDRFILE = hdrFile;
    [~, subjectdata.filename, ~] = fileparts(subjectdata.PATHS.DATAFILE);
    
    subjectdata.date = date;
    
    [subjectdata.testdate , subjectdata.testtime] = bv_readOutDateAndTimeBdf(dataFile);
    
    subjectdata.removed = false(1);
    subjectdata.removedDuring = '';
    subjectdata.removedreason = '';
    
    fprintf('\t saving Subject.mat...')
    save([subjectdata.PATHS.SUBJECTDIR filesep 'Subject'],'subjectdata'); % save individual subjectdata structure to individual folder
    fprintf('done \n')
    
    if strcmpi(overwrite, 'no')
        subjectdatasummary = bv_addSubjectToSubjectsummary(subjectdatasummary, subjectdata);
    else
        subjectdatasummary(subjIndex) = subjectdata;
    end
    
    clear subjectdata
    nSubjects = nSubjects + 1;
end

fprintf('\n\n saving SubjectSummary.mat...')
save([PATHS.SUMMARY filesep 'SubjectSummary'], 'subjectdatasummary')
fprintf('done \n')

logstrct.totalStartSubjects = nSubjects;
% bv_updateLog([PATHS.ROOT filesep 'log.txt'], logstrct);

