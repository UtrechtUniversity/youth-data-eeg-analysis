function bv_createSubjectFolders_NewStruct(cfg)
% Creates the subject folder structure for infant EEG analyses from raw
% data in a nested folder layout, and writes a Subject.mat file (with
% per-subject metadata and paths) into each new subject folder.
%
% Raw data is expected under ``PATHS.RAWS`` in a nested structure, e.g.
% ``PATHS.RAWS/WAVE/PSEUDO/file.<dataType>``. The number of folder levels
% is controlled by ``cfg.folderlabel``; levels can be skipped by removing
% them from that list (and from ``cfg.folderPattern``). Subjects whose name
% or data file can't be resolved are skipped (logged via
% ``removingSubjects``) rather than aborting the run. Finishes by writing
% ``SubjectSummary.mat`` to ``PATHS.SUMMARY``.
%
% Args:
%     cfg.rawdelim (str): Delimiter used when joining parts of the
%         subject folder name (usually ``'_'``).
%     cfg.sfoldername (cell array of str): Field names used to construct
%         each subject folder name. Fields can come from
%         ``cfg.folderlabel`` (folder levels) or ``cfg.rawlabel``
%         (filename parts), e.g. ``{'pseudo', 'wave'}`` creates a
%         ``B00002_10m`` folder.
%     cfg.dataType (str): Raw data type: ``'bdf'``, ``'eeg'``, or
%         ``'mat'``.
%     cfg.rawlabel (cell array of str, optional): Names for parts of the
%         filename, split by ``cfg.rawdelim``. Use ``[]`` to skip a
%         part. Stored as fields on the Subject struct. Defaults to
%         ``{}`` (filename is not parsed).
%     cfg.folderlabel (cell array of str, optional): Names for each
%         folder level below ``PATHS.RAWS``, in order. Stored as fields
%         on the Subject struct. Defaults to ``{'wave', 'pseudo'}``.
%     cfg.folderPattern (cell array of str, optional): One regex string
%         per folder level, matching the order of ``cfg.folderlabel``.
%         Use ``''`` to match all directories at a given level. Omitting
%         a level from ``cfg.folderlabel`` (and this array) skips it
%         entirely. Defaults to ``''`` for every level.
%     cfg.filePattern (str, optional): Regex applied to filenames.
%         Defaults to ``''`` (match all).
%     cfg.pathsFcn (str, optional): Paths function filename that sets
%         ``PATHS``. Defaults to ``'setPaths'``.
%     cfg.overwrite (str, optional): Whether to re-create subject folders
%         that already exist in ``SubjectSummary`` (``'yes'`` or
%         ``'no'``). When ``'no'``, raw files already present in
%         ``PATHS.DATAFILE`` are skipped, and a resolved subject is
%         merged into ``SubjectSummary`` by ``subjectName`` (replacing an
%         existing row rather than duplicating it). Defaults to ``'no'``.
%     cfg.prevAnalysis (str, optional): Used when ``cfg.dataType`` is
%         ``'mat'``: label of the previous analysis step. Defaults to
%         ``'preproc'``.
%
% Example:
%     ```matlab
%     cfg = [];
%     cfg.rawdelim      = '_';
%     cfg.sfoldername   = {'pseudo', 'wave'};
%     cfg.dataType      = 'bdf';
%     cfg.folderlabel   = {'wave', 'pseudo'};
%     cfg.overwrite     = 'yes';
%     bv_createSubjectFolders_NewStruct(cfg);
%     ```


% --- read configuration ---
pathsFcn        = ft_getopt(cfg, 'pathsFcn', 'setPaths');
prevAnalysis    = ft_getopt(cfg, 'prevAnalysis', 'preproc');
rawdelim        = ft_getopt(cfg, 'rawdelim');
sfolderstruct   = ft_getopt(cfg, 'sfoldername');
inputnames      = ft_getopt(cfg, 'rawlabel', {});
folderlabel     = ft_getopt(cfg, 'folderlabel', {'wave', 'pseudo'});
folderPattern   = ft_getopt(cfg, 'folderPattern', []);
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
    subjectdatasummary = struct([]);
end

% --- discover raw files ---
if strcmpi(dataType, 'mat')
    files = dir([PATHS.PREPROC filesep '*' prevAnalysis '.mat']);
    if isempty(files)
        error('no files found for inputstring: %s \n', prevAnalysis)
    end
else
    files = discoverFiles(PATHS.RAWS, dataType, folderPattern, filePattern);
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

removingSubjectsCfg = [];
removingSubjectsCfg.pathsFcn = pathsFcn;

nSubjects = 0;
for subjIndex = 1:length(files)
    subjectdata = struct();
    [~, cFile] = fileparts(files(subjIndex).name);

    % --- resolve metadata and subject folder name ---
    try
        % extract metadata from folder levels
        if startsWith(files(subjIndex).folder, PATHS.RAWS)
            relativePath = files(subjIndex).folder(length(PATHS.RAWS)+1:end);
        else
            relativePath = files(subjIndex).folder;
        end
        if ~isempty(relativePath) && relativePath(1) == filesep
            relativePath = relativePath(2:end);
        end
        folderParts = strsplit(relativePath, filesep);

        for i = 1:min(length(folderParts), length(folderlabel))
            if ~isempty(folderlabel{i})
                subjectdata.(folderlabel{i}) = folderParts{i};
            end
        end

        % optionally extract metadata from filename parts
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

        % construct subject folder name from sfolderstruct fields
        nameParts = cellfun(@(f) subjectdata.(f), sfolderstruct, 'UniformOutput', false);
        subjectdata.subjectName = strjoin(nameParts, rawdelim);
        nameResolved = true;
    catch
        % subject name could not be resolved from folder/filename metadata:
        % fall back to the raw filename so the failure is still recorded
        subjectdata = struct();
        subjectdata.subjectName = cFile;
        nameResolved = false;
    end

    % suffix with a counter if a folder with this name already exists.
    % contains() is used deliberately (not strcmp/exact match) so that
    % earlier suffixed duplicates (e.g. 'B002_10m_2') are also counted
    % when a third 'B002_10m' comes in - exact matching would miss them
    % and start re-numbering from '_2' every time.
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

    preprocDir = fullfile(paths2SubjectFolder, 'preproc');
    powerDir   = fullfile(paths2SubjectFolder, 'power');
    netmetDir  = fullfile(paths2SubjectFolder, 'netmet');
    if ~exist(preprocDir, 'dir'); mkdir(preprocDir); end
    if ~exist(powerDir, 'dir');   mkdir(powerDir);   end
    if ~exist(netmetDir, 'dir');  mkdir(netmetDir);  end

    subjectdata.PATHS.SUBJECTDIR = paths2SubjectFolder;
    subjectdata.PATHS.PREPROCDIR = preprocDir;
    subjectdata.PATHS.POWERDIR   = powerDir;
    subjectdata.PATHS.NETMETDIR  = netmetDir;
    subjectdata.preprocDate      = datetime("today");
    subjectdata.removed          = false(1);
    subjectdata.removedDuring    = '';
    subjectdata.removedReason    = '';

    % reserved for the sliding-window epoching step, if/when one is added
    % to the power-estimate stage; NaN until then, or for any subject
    % that never reaches that step.
    subjectdata.nEpochsPower      = NaN;
    subjectdata.nCleanEpochsPower = NaN;

    if ~nameResolved
        save(fullfile(paths2SubjectFolder, 'Subject'), 'subjectdata');
        removingSubjects(removingSubjectsCfg, subjectdata.subjectName, ...
            'subject name could not be resolved from raw file/folder structure');
        clear subjectdata
        continue
    end

    % --- resolve data file paths and read out acquisition date/time ---
    try
        switch dataType
            case 'eeg'
                dataFile = fullfile(files(subjIndex).folder, [cFile '.eeg']);
                hdrFile  = fullfile(files(subjIndex).folder, [cFile '.vhdr']);
                if ~exist(dataFile, 'file')
                    error('dataFile: %s not found!', dataFile)
                elseif ~exist(hdrFile, 'file')
                    error('headerfile: %s not found!', hdrFile)
                end

            case {'edf', 'bdf', 'EDF', 'BDF'}
                dataFile = fullfile(files(subjIndex).folder, files(subjIndex).name);
                hdrFile  = dataFile;
                if ~exist(dataFile, 'file')
                    error('dataFile: %s not found!', dataFile)
                end

            case 'mat'
                dataFile = 'unknown';
                hdrFile  = 'unknown';
                subjectdata.PATHS.(upper(prevAnalysis)) = fullfile(PATHS.PREPROC, [cFile '.mat']);
                if ~exist(subjectdata.PATHS.(upper(prevAnalysis)), 'file')
                    error('dataFile: %s not found!', subjectdata.PATHS.(upper(prevAnalysis)))
                end

            otherwise
                error('unknown datatype: %s', dataType);
        end

        subjectdata.PATHS.DATAFILE = dataFile;
        subjectdata.PATHS.HDRFILE  = hdrFile;
        [~, subjectdata.filename, ~] = fileparts(subjectdata.PATHS.DATAFILE);
        [subjectdata.testDate, subjectdata.testTime] = bv_readOutDateAndTimeBdf(dataFile);
    catch ME
        save(fullfile(paths2SubjectFolder, 'Subject'), 'subjectdata');
        removingSubjects(removingSubjectsCfg, subjectdata.subjectName, ME.message);
        clear subjectdata
        continue
    end

    subjectdata = bv_orderSubjectFields(subjectdata);

    fprintf('\t saving Subject.mat...')
    save(fullfile(subjectdata.PATHS.SUBJECTDIR, 'Subject'), 'subjectdata');
    fprintf('done \n')

    if strcmpi(overwrite, 'no')
        % find-or-append by subjectName, mirroring the logic in bv_updateSubjectSummary.
        strippedData = bv_stripSummaryOnlyFields(subjectdata);
        if isempty(subjectdatasummary)
            % first subject on a cold start (no existing SubjectSummary
            % rows yet): assign directly so the array picks up
            % strippedData's own field set. bv_reconcileSummaryArray's
            % array-wide field-add only attaches a field to elements that
            % already exist, so calling it against a struct with zero
            % elements would leave subjectdatasummary without any fields
            % at all, and the ismember(...subjectName) lookup below would
            % then error with "no such field".
            subjectdatasummary = strippedData;
        else
            [subjectdatasummary, strippedData] = bv_reconcileSummaryArray(subjectdatasummary, strippedData);
            existingIndx = find(ismember({subjectdatasummary.subjectName}, strippedData.subjectName));
            if isempty(existingIndx)
                subjectdatasummary(end+1) = strippedData;
            else
                subjectdatasummary(existingIndx) = strippedData;
            end
        end
    else
        % index by nSubjects+1 (not subjIndex) so that files skipped via
        % continue above never leave gaps with subjectName = [] in the
        % struct array - those gaps corrupt every later
        % ismember(...subjectName) lookup against SubjectSummary.mat
        subjectdatasummary(nSubjects + 1) = bv_stripSummaryOnlyFields(subjectdata);
    end

    clear subjectdata
    nSubjects = nSubjects + 1;
end

subjectdatasummary = bv_orderSubjectFields(subjectdatasummary);

fprintf('\n\n saving SubjectSummary.mat...')
save(fullfile(PATHS.SUMMARY, 'SubjectSummary'), 'subjectdatasummary')
fprintf('done \n')

% logstrct.totalStartSubjects = nSubjects;
% bv_updateLog([PATHS.ROOT filesep 'log.txt'], logstrct);


% =========================================================================
function files = discoverFiles(rawsPath, dataType, folderPatterns, filePattern)
% Traverse an arbitrary number of folder levels under rawsPath and collect
% all files matching dataType. folderPatterns is a cell array with one
% regex string per level ('' matches everything). Fewer levels means a
% shallower directory traversal.

fileList = traverseLevel(rawsPath, dataType, folderPatterns, filePattern);

if isempty(fileList)
    files = struct([]);
else
    files = vertcat(fileList{:});
end


% =========================================================================
function fileList = traverseLevel(currentPath, dataType, remainingPatterns, filePattern)
% Recursively descend one folder level per call. When remainingPatterns is
% exhausted, collect matching files in the current directory.

fileList = {};

if isempty(remainingPatterns)
    rawFiles = dir(fullfile(currentPath, ['*.' dataType]));
    if ~isempty(filePattern)
        rawFiles = rawFiles(~cellfun(@isempty, regexp({rawFiles.name}, filePattern)));
    end
    if ~isempty(rawFiles)
        fileList = {rawFiles};
    end
else
    subDirs = listFilteredDirs(currentPath, remainingPatterns{1});
    for d = 1:length(subDirs)
        subList  = traverseLevel(fullfile(currentPath, subDirs(d).name), dataType, remainingPatterns(2:end), filePattern);
        fileList = [fileList, subList]; %#ok<AGROW>
    end
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
