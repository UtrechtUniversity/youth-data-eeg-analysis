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
% Several raw files can belong to one session (e.g. a recording that was
% interrupted and continued in a second file). With ``cfg.stitchFiles =
% 'yes'`` (bdf/edf only), all files that resolve to the same subject name
% become the parts of one subject. Their headers are read and compared
% (see ``bv_matchRawFiles``): parts that can't be matched (unreadable,
% truncated, other sampling rate or channels, too far away in time,
% overlapping) are dropped, the others are sorted by the start time in
% their header. Everything is recorded in the Subject.mat, see Fields set
% below. If no part is usable, the subject is removed. With
% ``cfg.stitchFiles = 'no'``, every file is a subject of its own, and a
% second file with the same name gets the suffix ``_2``.
%
% Args:
%     cfg.rawdelim (str): Delimiter used when joining parts of the
%         subject folder name (usually ``'_'``).
%     cfg.sfoldername (cell array of str): Field names used to construct
%         each subject folder name. Fields can come from
%         ``cfg.folderlabel`` (folder levels) or ``cfg.rawlabel``
%         (filename parts), e.g. ``{'pseudo', 'wave'}`` creates a
%         ``B00002_10m`` folder.
%     cfg.dataType (str): Raw data type: ``'bdf'``, ``'edf'``, ``'eeg'``,
%         or ``'mat'``. The recording start date/time (``testDate``,
%         ``testTime``) is only read from bdf/edf headers; for the other
%         types both are set to ``'unknown'``.
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
%         ``'no'``). When ``'no'``, a subject whose raw files (paths and
%         sizes) were all processed before is skipped, and a resolved
%         subject is merged into ``SubjectSummary`` by ``subjectName``
%         (replacing an existing row rather than duplicating it). If the
%         raw files of an existing subject changed (a part was added,
%         removed or replaced; only with ``cfg.stitchFiles = 'yes'``), the
%         subject is created again under the same name, and its old folder
%         with all results is deleted, so that no later step reuses
%         results of the old file set. Defaults to ``'no'``. Does not
%         apply to ``'mat'``.
%     cfg.stitchFiles (str, optional): ``'yes'`` to treat the files that
%         resolve to the same subject name as parts of one session
%         (bdf/edf only), ``'no'`` to make a subject of every file.
%         Defaults to ``'yes'``.
%     cfg.maxGap (number, optional): Widest gap (s) allowed between two
%         consecutive parts of a session; a part further away is dropped.
%         Defaults to ``7*24*3600`` (one week).
%     cfg.seamTolerance (number, optional): Gaps and overlaps between
%         parts up to this size (s) are treated as 0, because the header
%         start times only have a resolution of 1 s. Defaults to ``1``.
%     cfg.inputName (str): Required when ``cfg.dataType`` is ``'mat'``.
%         Name of the analysis step whose saved output is the input, e.g.
%         ``'PREPROC'``. The ``.mat`` files are found under
%         ``PATHS.RAWS`` like the other data types (same
%         ``cfg.folderlabel``/``cfg.folderPattern``/``cfg.filePattern``),
%         and of those only files named ``<subjectName>_<inputName>.mat``
%         (case-insensitive) are used. The file's path is stored in
%         ``subjectdata.PATHS.(upper(inputName))``.
%
% Fields set in Subject.mat for the raw files:
%     ``PATHS.DATAFILES`` and ``PATHS.HDRFILES`` hold the used raw files
%     (cell arrays, sorted by start time; empty for ``'mat'``).
%     ``rawFiles`` is a struct array with one element per file found for
%     the session: ``file``, ``bytes``, ``startTime``, ``duration`` (s),
%     ``nChannels``, ``fs``, ``status`` (``'used'`` or ``'dropped'``),
%     ``reason`` (why it was dropped) and ``gapToPrevious`` (s since the
%     end of the previous used file; 0 if contiguous). ``nRawFiles`` and
%     ``nRawFilesUsed`` count the files found and used.
%     ``rawFileSignature`` identifies the file set for the
%     ``overwrite = 'no'`` check.
%
% Example:
%     ```matlab
%     cfg = [];
%     cfg.rawdelim      = '_';
%     cfg.sfoldername   = {'pseudo', 'wave'};
%     cfg.dataType      = 'bdf';
%     cfg.folderlabel   = {'wave', 'pseudo'};
%     cfg.overwrite     = 'yes';
%     cfg.stitchFiles   = 'yes';
%     bv_createSubjectFolders_NewStruct(cfg);
%     ```

% --- read configuration ---
pathsFcn        = ft_getopt(cfg, 'pathsFcn', 'setPaths');
inputName       = ft_getopt(cfg, 'inputName');
rawdelim        = ft_getopt(cfg, 'rawdelim');
sfolderstruct   = ft_getopt(cfg, 'sfoldername');
inputnames      = ft_getopt(cfg, 'rawlabel', {});
folderlabel     = ft_getopt(cfg, 'folderlabel', {'wave', 'pseudo'});
folderPattern   = ft_getopt(cfg, 'folderPattern', []);
filePattern     = ft_getopt(cfg, 'filePattern', '');
dataType        = ft_getopt(cfg, 'dataType');
overwrite       = ft_getopt(cfg, 'overwrite', 'no');
stitchFiles     = ft_getopt(cfg, 'stitchFiles', 'yes');
maxGap          = ft_getopt(cfg, 'maxGap', 7*24*3600);
seamTolerance   = ft_getopt(cfg, 'seamTolerance', 1);

% stitching needs the start time in the header, which only bdf/edf have
isBdfEdf = any(strcmpi(dataType, {'bdf', 'edf'}));
stitch   = strcmpi(stitchFiles, 'yes') && isBdfEdf;

% load paths and options
eval(pathsFcn);

% --- read the existing summary (for overwrite='no') ---
% a raw file set that is already processed is recognised by its signature
% (see fileSignature); a subject whose raw files changed since is redone
existingNames      = {};
existingSignatures = {};
if strcmpi(overwrite, 'no')
    subjectdatasummary = table2struct(bv_createSubjectResults());
    existingNames      = cell(1, length(subjectdatasummary));
    existingSignatures = cell(1, length(subjectdatasummary));
    for i = 1:length(subjectdatasummary)
        existingNames{i}      = subjectdatasummary(i).subjectName;
        existingSignatures{i} = '';
        if isfield(subjectdatasummary, 'rawFileSignature') && ischar(subjectdatasummary(i).rawFileSignature)
            existingSignatures{i} = subjectdatasummary(i).rawFileSignature;
        end
    end
else
    overwrite = 'yes';
    subjectdatasummary = struct([]);
end

% --- discover raw files ---
if strcmpi(dataType, 'mat') && isempty(inputName)
    error('cfg.inputName is required when cfg.dataType is ''mat''')
end

files = discoverFiles(PATHS.RAWS, dataType, folderPattern, filePattern);

if strcmpi(dataType, 'mat') && ~isempty(files)
    % several .mat files can sit side by side (one per analysis step, named
    % <subjectName>_<outputName>.mat): keep only those of the requested input
    files = files(endsWith({files.name}, ['_' inputName '.mat'], 'IgnoreCase', true));
end

if isempty(files)
    if strcmpi(dataType, 'mat')
        error('no mat files for input ''%s'' found under %s matching the given patterns', inputName, PATHS.RAWS)
    else
        error('no %s files found under %s matching the given patterns', dataType, PATHS.RAWS)
    end
end

% --- resolve the subject name of every file and group the files ---
% with stitching, the files that resolve to the same subject are the
% parts of one session; otherwise every file is a session of its own
nFiles    = length(files);
fileMeta  = cell(1, nFiles);
resolved  = false(1, nFiles);
groupKeys = cell(1, nFiles);
for f = 1:nFiles
    [fileMeta{f}, resolved(f)] = resolveSubjectMeta(files(f), PATHS.RAWS, folderlabel, ...
        inputnames, rawdelim, sfolderstruct);
    if stitch && resolved(f)
        groupKeys{f} = fileMeta{f}.subjectName;
    else
        groupKeys{f} = fullfile(files(f).folder, files(f).name);
    end
end
[~, ~, groupOfFile] = unique(groupKeys, 'stable');
nGroups = max(groupOfFile);

if ~exist(PATHS.SUBJECTS, 'dir'); mkdir(PATHS.SUBJECTS); end

removingSubjectsCfg = [];
removingSubjectsCfg.pathsFcn = pathsFcn;

nSubjects = 0;
for groupIndex = 1:nGroups
    groupFiles = files(groupOfFile == groupIndex);
    firstMeta  = fileMeta{find(groupOfFile == groupIndex, 1)};
    nameResolved = resolved(find(groupOfFile == groupIndex, 1));

    subjectdata = firstMeta;
    signature   = fileSignature(groupFiles);

    % --- skip or redo sessions that were processed before (overwrite='no') ---
    replacing = false;
    if strcmpi(overwrite, 'no') && ~strcmpi(dataType, 'mat')
        if any(strcmp(signature, existingSignatures))
            continue
        end
        if stitch && nameResolved && any(strcmp(subjectdata.subjectName, existingNames))
            % same session, different raw files: parts were added, removed
            % or replaced, so everything made from the old set is outdated
            replacing = true;
        end
    end

    if replacing
        fprintf('%s: the raw files changed since the last run, redoing the subject\n', subjectdata.subjectName)
        for staleDir = {fullfile(PATHS.SUBJECTS, subjectdata.subjectName), ...
                fullfile(PATHS.REMOVED, subjectdata.subjectName)}
            if exist(staleDir{1}, 'dir')
                rmdir(staleDir{1}, 's');
            end
        end
    else
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

    % epoch counts of the power and connectivity (PLI) stages; NaN until
    % the subject reaches that stage.
    subjectdata.nEpochsPower      = NaN;
    subjectdata.nCleanEpochsPower = NaN;
    subjectdata.nEpochsPLI        = NaN;
    subjectdata.nCleanEpochsPLI   = NaN;

    if ~nameResolved
        save(fullfile(paths2SubjectFolder, 'Subject'), 'subjectdata');
        removingSubjects(removingSubjectsCfg, subjectdata.subjectName, ...
            'subject name could not be resolved from raw file/folder structure');
        clear subjectdata
        continue
    end

    % --- resolve data file paths and read out acquisition date/time ---
    subjectdata.rawFileSignature = signature;
    try
        switch dataType
            case 'eeg'
                % one session per file, see above
                [~, cFile] = fileparts(groupFiles(1).name);
                dataFile = fullfile(groupFiles(1).folder, [cFile '.eeg']);
                hdrFile  = fullfile(groupFiles(1).folder, [cFile '.vhdr']);
                if ~exist(dataFile, 'file')
                    error('dataFile: %s not found!', dataFile)
                elseif ~exist(hdrFile, 'file')
                    error('headerfile: %s not found!', hdrFile)
                end
                subjectdata.rawFiles = placeholderFileInfo(dataFile, groupFiles(1).bytes);
                usedFiles = {dataFile};
                hdrFiles  = {hdrFile};

            case {'edf', 'bdf', 'EDF', 'BDF'}
                % read the headers, then keep the files that match each
                % other and put them in order of their start time
                paths = arrayfun(@(f) fullfile(f.folder, f.name), groupFiles, 'UniformOutput', false);
                infos = bv_readRawFileInfo(paths{1});
                for k = 2:numel(paths)
                    infos(k) = bv_readRawFileInfo(paths{k});
                end
                matchCfg = [];
                matchCfg.maxGap        = maxGap;
                matchCfg.seamTolerance = seamTolerance;
                matched = bv_matchRawFiles(infos, matchCfg);

                subjectdata.rawFiles = rmfield(matched, ...
                    {'readable', 'nRecords', 'recordDuration', 'labels', 'samplesPerRecord'});
                isUsed = strcmp({matched.status}, 'used');
                for k = find(~isUsed)
                    [~, droppedName, droppedExt] = fileparts(matched(k).file);
                    fprintf('\t dropping %s%s: %s\n', droppedName, droppedExt, matched(k).reason)
                end
                if ~any(isUsed)
                    reasons = cell(1, numel(matched));
                    for k = 1:numel(matched)
                        [~, droppedName, droppedExt] = fileparts(matched(k).file);
                        reasons{k} = sprintf('%s%s: %s', droppedName, droppedExt, matched(k).reason);
                    end
                    error('no usable raw file (%s)', strjoin(reasons, '; '))
                end
                usedFiles = {matched(isUsed).file};
                hdrFiles  = usedFiles;

            case 'mat'
                matFile = fullfile(groupFiles(1).folder, groupFiles(1).name);
                subjectdata.PATHS.(upper(inputName)) = matFile;
                if ~exist(matFile, 'file')
                    error('dataFile: %s not found!', matFile)
                end
                subjectdata.rawFiles = placeholderFileInfo(matFile, groupFiles(1).bytes);
                usedFiles = {};
                hdrFiles  = {};

            otherwise
                error('unknown datatype: %s', dataType);
        end

        subjectdata.PATHS.DATAFILES = usedFiles;
        subjectdata.PATHS.HDRFILES  = hdrFiles;
        subjectdata.nRawFiles       = numel(subjectdata.rawFiles);
        subjectdata.nRawFilesUsed   = sum(strcmp({subjectdata.rawFiles.status}, 'used'));

        % the recording start date/time can only be read from the header of
        % a bdf/edf file (of the first used one); for other data types it
        % is not available here
        if isBdfEdf
            [subjectdata.testDate, subjectdata.testTime] = bv_readOutDateAndTimeBdf(usedFiles{1});
        else
            subjectdata.testDate = 'unknown';
            subjectdata.testTime = 'unknown';
        end
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
        % index by nSubjects+1 (not groupIndex) so that sessions skipped via
        % continue above never leave gaps with subjectName = [] in the
        % struct array - those gaps corrupt every later
        % ismember(...subjectName) lookup against SubjectSummary.mat
        strippedData = bv_stripSummaryOnlyFields(subjectdata);
        if isempty(subjectdatasummary)
            % first subject: assign directly, because an empty struct without
            % fields cannot take an element that has fields
            subjectdatasummary = strippedData;
        else
            subjectdatasummary(nSubjects + 1) = strippedData;
        end
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
function [subjectdata, nameResolved] = resolveSubjectMeta(file, rawsPath, folderlabel, inputnames, rawdelim, sfolderstruct)
% Collect the metadata of a raw file from its folder levels and file name
% and build the subject name from it. If the name cannot be resolved, the
% raw file name is used instead, so the failure is still recorded.

subjectdata = struct();
[~, cFile] = fileparts(file.name);
try
    % extract metadata from folder levels
    if startsWith(file.folder, rawsPath)
        relativePath = file.folder(length(rawsPath)+1:end);
    else
        relativePath = file.folder;
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
    subjectdata = struct();
    subjectdata.subjectName = cFile;
    nameResolved = false;
end


% =========================================================================
function signature = fileSignature(groupFiles)
% One string that identifies a set of raw files: the sorted full paths and
% sizes. When it changes (a file added, removed, replaced), the session
% has to be processed again.

parts = cell(1, numel(groupFiles));
for i = 1:numel(groupFiles)
    parts{i} = sprintf('%s|%d', fullfile(groupFiles(i).folder, groupFiles(i).name), groupFiles(i).bytes);
end
signature = strjoin(sort(parts), ';');


% =========================================================================
function info = placeholderFileInfo(file, bytes)
% File record for raw files without a readable start time (eeg, mat), in
% the same form bv_matchRawFiles gives for bdf/edf files.

info = struct('file', file, 'bytes', bytes, 'reason', '', 'startTime', NaT, 'duration', NaN, ...
    'nChannels', NaN, 'fs', NaN, 'status', 'used', 'gapToPrevious', NaN);


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
