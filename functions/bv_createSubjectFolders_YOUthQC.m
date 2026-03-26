function bv_createSubjectFolders_YOUthQC(cfg, varargin)
% bv_createSubjectFolders creates the folder structure necessary to run
% analyses for infant EEG and adds an individual Subject.mat file in each
% folder with individuals information and paths to important files.

% read out from configuration structure
optionsFcn = ft_getopt(cfg, 'optionsFcn','setOptions');
pathsFcn = ft_getopt(cfg, 'pathsFcn','setPaths');
inputStr = ft_getopt(cfg, 'inputStr', 'preproc');
rawdelim = ft_getopt(cfg, 'rawdelim');
sfolderstruct = ft_getopt(cfg, 'subjectfolderstructure');
overwrite = ft_getopt(cfg, 'overwrite', 'no');

% load in standard options and paths
eval(optionsFcn);
eval(pathsFcn);

if strcmpi(overwrite, 'no') && exist([PATHS.SUMMARY filesep 'SubjectSummary.mat'], 'file')
    load([PATHS.SUMMARY filesep 'SubjectSummary.mat'], 'subjectdatasummary')
    
    for i = 1:length(subjectdatasummary)
        dataFilePath = subjectdatasummary(i).PATHS.DATAFILE;
        [~, dataFile, ext] = fileparts(dataFilePath);
        allDatafiles{i} = strcat(dataFile,ext);
    end
else
    overwrite = 'yes';
end

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

if strcmpi(overwrite, 'no')
    fileNames = fileNames(not(ismember(fileNames, allDatafiles)));
end

if ~exist(PATHS.SUBJECTS,'dir'); mkdir PATHS.SUBJECTS; end % create, if necessary, Subject folder

removeIdx = 0;
nSubjects = 0;
for subjIndex = 1:length(fileNames)
    include = true;
    inputnames = varargin;
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
            error('unknown datatype %s', OPTIONS.dataType);
    end
    
    subjectdata.subjectName = strjoin(splitFile(ismember(inputnames, sfolderstruct)), rawdelim);
    subjectFoldersFound = dir([PATHS.SUBJECTS filesep 'B*']);
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
logstrct.totalStartSubjects = nSubjects;
bv_updateLog([PATHS.ROOT filesep 'log.txt'], logstrct);

fprintf('\n\n saving SubjectSummary.mat...')
save([PATHS.SUMMARY filesep 'SubjectSummary'], 'subjectdatasummary')
fprintf('done \n')

