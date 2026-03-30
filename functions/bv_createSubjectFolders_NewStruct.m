function bv_createSubjectFolders_NewStruct(cfg)
% bv_createSubjectFolders_YOUth2 creates the folder structure necessary to
% run analyses for infant EEG and adds an individual Subject.mat file in
% each folder with individual information and paths to important files.
%
% This version expects raw data in a nested folder structure:
%   PATHS.RAWS / WAVE / EXPERIMENT / PSEUDO / file.<dataType>
%
% The output folder structure (PATHS.SUBJECTS/PSEUDO_WAVE) and the contents
% of each Subject.mat are identical to bv_createSubjectFolders_YOUth.
%
% Use as
%   bv_createSubjectFolders_YOUth2( cfg )
%
% Required fields:
%   cfg.rawdelim        ' string ' delimiter used when joining the parts of
%                       the subject folder name (usually '_')
%   cfg.sfoldername     { cell } field names used to construct each subject
%                       folder name. Fields can come from cfg.folderlabel
%                       (folder levels) or cfg.rawlabel (filename parts).
%                       E.g. {'pseudo', 'wave'} creates a B00002_10m folder.
%   cfg.dataType        ' string ' raw data type: 'bdf', 'eeg', or 'mat'
%
% Optional fields:
%   cfg.folderlabel     { cell } names for each folder level below
%                       PATHS.RAWS, in order. These are stored as fields on
%                       the Subject struct.
%                       Default: {'wave', 'experiment', 'pseudo'}
%   cfg.rawlabel        { cell } names for parts of the filename, split by
%                       cfg.rawdelim. Use [] to skip a part. These are
%                       stored as fields on the Subject struct.
%                       Default: {} (filename is not parsed)
%   cfg.wavePattern     ' string ' regex applied to wave-level folder names.
%                       Default: '' (match all)
%   cfg.expPattern      ' string ' regex applied to experiment-level folder
%                       names. Default: '' (match all)
%   cfg.pseudoPattern   ' string ' regex applied to pseudo-level folder
%                       names. Default: '' (match all)
%   cfg.filePattern     ' string ' regex applied to filenames.
%                       Default: '' (match all)
%   cfg.pathsFcn        ' string ' m-file that sets PATHS and OPTIONS
%                       (default: 'setPaths')
%   cfg.overwrite       'yes'/'no' re-create subject folders that already
%                       exist in SubjectSummary (default: 'no')
%   cfg.prevAnalysis    ' string ' used with cfg.dataType = 'mat': label of
%                       the previous analysis step (default: 'preproc')


% --- read configuration ---
pathsFcn        = ft_getopt(cfg, 'pathsFcn', 'setPaths');
prevAnalysis    = ft_getopt(cfg, 'prevAnalysis', 'preproc');
rawdelim        = ft_getopt(cfg, 'rawdelim');
sfolderstruct   = ft_getopt(cfg, 'sfoldername');
inputnames      = ft_getopt(cfg, 'rawlabel', {});
folderlabel     = ft_getopt(cfg, 'folderlabel', {'wave', 'experiment', 'pseudo'});
wavePattern     = ft_getopt(cfg, 'wavePattern', '');
expPattern      = ft_getopt(cfg, 'expPattern', '');
pseudoPattern   = ft_getopt(cfg, 'pseudoPattern', '');
filePattern     = ft_getopt(cfg, 'filePattern', '');
dataType        = ft_getopt(cfg, 'dataType');
overwrite       = ft_getopt(cfg, 'overwrite', 'no');

% load paths and options
eval(pathsFcn);

% --- build list of already-processed data files (for overwrite='no') ---
if strcmpi(overwrite, 'no')
    subjectdatasummary = table2struct(bv_createSubjectResults());
    allDatafiles = cell(1, length(subjectdatasummary));
    for i = 1:length(subjectdatasummary)
        allDatafiles{i} = subjectdatasummary(i).PATHS.DATAFILE;
    end
else
    overwrite = 'yes';
end

% --- discover raw files ---
if strcmpi(dataType, 'mat')
    files = dir([PATHS.PREPROC filesep '*' prevAnalysis '.mat']);
    if isempty(files)
        error('no files found for inputstring: %s \n', prevAnalysis)
    end
else
    files = discoverFiles(PATHS.RAWS, dataType, wavePattern, expPattern, pseudoPattern, filePattern);
    if isempty(files)
        error('no %s files found under %s matching the given patterns', dataType, PATHS.RAWS)
    end
end

% --- filter out already-processed files ---
if strcmpi(overwrite, 'no')
    fullPaths = arrayfun(@(f) fullfile(f.folder, f.name), files, 'UniformOutput', false);
    files = files(~ismember(fullPaths, allDatafiles));
end

if ~exist(PATHS.SUBJECTS, 'dir'); mkdir(PATHS.SUBJECTS); end

nSubjects = 0;
for subjIndex = 1:length(files)
    subjectdata = struct();

    % --- extract metadata from folder levels ---
    relativePath = strrep(files(subjIndex).folder, PATHS.RAWS, '');
    if ~isempty(relativePath) && relativePath(1) == filesep
        relativePath = relativePath(2:end);
    end
    folderParts = strsplit(relativePath, filesep);

    for i = 1:min(length(folderParts), length(folderlabel))
        if ~isempty(folderlabel{i})
            subjectdata.(folderlabel{i}) = folderParts{i};
        end
    end

    % --- optionally extract metadata from filename parts ---
    [~, cFile] = fileparts(files(subjIndex).name);
    if ~isempty(inputnames)
        localInputnames = inputnames;
        splitFile = strsplit(cFile, rawdelim);

        inputdiff = length(splitFile) - length(localInputnames);
        if inputdiff > 0
            localInputnames = [localInputnames, cell(1, inputdiff)];
        elseif inputdiff < 0
            localInputnames = localInputnames(1:length(localInputnames) + inputdiff);
        end

        validIdx = ~cellfun(@isempty, localInputnames);
        splitFile       = splitFile(validIdx);
        localInputnames = localInputnames(validIdx);

        for i = 1:length(splitFile)
            subjectdata.(localInputnames{i}) = splitFile{i};
        end
    end

    % --- resolve data file paths ---
    switch dataType
        case 'eeg'
            israw    = 1;
            dataFile = fullfile(files(subjIndex).folder, [cFile '.eeg']);
            hdrFile  = fullfile(files(subjIndex).folder, [cFile '.vhdr']);
            if ~exist(dataFile, 'file')
                error('dataFile: %s not found!', dataFile)
            elseif ~exist(hdrFile, 'file')
                error('headerfile: %s not found!', hdrFile)
            end

        case {'edf', 'bdf', 'EDF', 'BDF'}
            israw    = 1;
            dataFile = fullfile(files(subjIndex).folder, files(subjIndex).name);
            hdrFile  = dataFile;
            if ~exist(dataFile, 'file')
                error('dataFile: %s not found!', dataFile)
            end

        case 'mat'
            israw    = 0;
            dataFile = 'unknown';
            hdrFile  = 'unknown';
            subjectdata.PATHS.(upper(prevAnalysis)) = fullfile(PATHS.PREPROC, [cFile '.mat']);
            if ~exist(subjectdata.PATHS.(upper(prevAnalysis)), 'file')
                error('dataFile: %s not found!', subjectdata.PATHS.(upper(prevAnalysis)))
            end

        otherwise
            error('unknown datatype: %s', dataType);
    end

    % --- construct subject folder name from sfolderstruct fields ---
    nameParts = cellfun(@(f) subjectdata.(f), sfolderstruct, 'UniformOutput', false);
    subjectdata.subjectName = strjoin(nameParts, rawdelim);

    % suffix with a counter if a folder with this name already exists
    existingFolders = dir(PATHS.SUBJECTS);
    existingFolders = existingFolders([existingFolders.isdir]);
    nMatches = sum(contains({existingFolders.name}, subjectdata.subjectName));
    if nMatches ~= 0
        subjectdata.subjectName = [subjectdata.subjectName '_' num2str(nMatches + 1)];
    end

    disp(subjectdata.subjectName);
    paths2SubjectFolder = fullfile(PATHS.SUBJECTS, subjectdata.subjectName);
    if ~exist(paths2SubjectFolder, 'dir')
        mkdir(paths2SubjectFolder);
    end

    subjectdata.PATHS.SUBJECTDIR = paths2SubjectFolder;
    subjectdata.PATHS.DATAFILE   = dataFile;
    subjectdata.PATHS.HDRFILE    = hdrFile;
    [~, subjectdata.filename, ~] = fileparts(subjectdata.PATHS.DATAFILE);

    subjectdata.date = date;
    [subjectdata.testdate, subjectdata.testtime] = bv_readOutDateAndTimeBdf(dataFile);

    subjectdata.removed       = false(1);
    subjectdata.removedDuring = '';
    subjectdata.removedreason = '';

    fprintf('\t saving Subject.mat...')
    save(fullfile(subjectdata.PATHS.SUBJECTDIR, 'Subject'), 'subjectdata');
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
save(fullfile(PATHS.SUMMARY, 'SubjectSummary'), 'subjectdatasummary')
fprintf('done \n')

logstrct.totalStartSubjects = nSubjects;
% bv_updateLog([PATHS.ROOT filesep 'log.txt'], logstrct);


% =========================================================================
function files = discoverFiles(rawsPath, dataType, wavePattern, expPattern, pseudoPattern, filePattern)
% Traverse WAVE/EXPERIMENT/PSEUDO folder levels under rawsPath and collect
% all files matching dataType and the given regex patterns.

fileList = {};

waveDirs = listFilteredDirs(rawsPath, wavePattern);
for w = 1:length(waveDirs)
    wPath   = fullfile(rawsPath, waveDirs(w).name);
    expDirs = listFilteredDirs(wPath, expPattern);
    for e = 1:length(expDirs)
        ePath      = fullfile(wPath, expDirs(e).name);
        pseudoDirs = listFilteredDirs(ePath, pseudoPattern);
        for p = 1:length(pseudoDirs)
            pPath    = fullfile(ePath, pseudoDirs(p).name);
            rawFiles = dir(fullfile(pPath, ['*.' dataType]));
            if ~isempty(filePattern)
                rawFiles = rawFiles(~cellfun(@isempty, regexp({rawFiles.name}, filePattern)));
            end
            if ~isempty(rawFiles)
                fileList{end+1} = rawFiles; %#ok<AGROW>
            end
        end
    end
end

if isempty(fileList)
    files = struct([]);
else
    files = vertcat(fileList{:});
end


% =========================================================================
function dirs = listFilteredDirs(parentPath, pattern)
% List immediate subdirectories of parentPath, optionally filtered by a
% regex pattern. An empty pattern matches all directories.

d    = dir(parentPath);
d    = d([d.isdir] & ~ismember({d.name}, {'.', '..'}));
if ~isempty(pattern)
    d = d(~cellfun(@isempty, regexp({d.name}, pattern)));
end
dirs = d;
