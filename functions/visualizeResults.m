function visualizeResults(subjectDir, subjectDirString)
% Visualize connectivity results. Run in individual subject folders or in the
% rootfolder, but then give the SubjectDir[ectory name] and a string which
% is in the foldername of each subject (SubjectDirString)
%
% visualizeResults(subjectDir, subjectDirString)

% set defaults
if nargin < 1
    subjectDir = 'Subjects';
end
if nargin < 2
    subjectDirString = 'pp';
end

% add paths 
rootdir = pwd;
rootFigureDirPath = [rootdir filesep 'figures'];

if ~exist(rootFigureDirPath, 'dir')
    mkdir(rootFigureDirPath)
end

if exist(subjectDir, 'dir')
    multipleSubjects = 1;
else
    multipleSubjects = 0;
end

% check whether ran from root directory or from individual subject
% directory 
if multipleSubjects
    subjectDir = [rootdir filesep subjectDir];
    
    subjectFolders = dir([subjectDir filesep subjectDirString '*']);
    subjectFolderNames = {subjectFolders.name};
else
    
    [subjectDir, subjectFolderNames] = fileparts(rootdir);
    subjectFolderNames = {subjectFolderNames};
end


for iFolName = 1:length(subjectFolderNames)
    % load subject file and go to subject directory
    try
        load([subjectDir filesep subjectFolderNames{iFolName} filesep 'Subject.mat'])
    catch
        error('ERROR: no Subject.mat found for %s', subjectFolderNames{iFolName})
    end
    cd(subjectdata.subjectpath)
    
    % find results directory (throw error if not found)
    resultsDirPath = [subjectdata.subjectpath filesep 'results'];
    if ~exist(resultsDirPath, 'dir')
        error('%s: No results dir found \n %s', subjectdata.subjectdir, resultsDirPath)
    end
    
    % create if necessary figure directory
    figureDirPath = [resultsDirPath filesep 'figures'];
    if ~exist(figureDirPath, 'dir')
        mkdir(figureDirPath)
    end
    
    % find result files
    cd(resultsDirPath)
    dataMatFiles = dir([subjectdata.subjectdir '*.mat']);
    dataMatFileName = {dataMatFiles.name};
 
    
    for iMatFiles = 1:length(dataMatFileName)
        % check filename and split filename up in '_' parts to find
        % lastAnalysis, frequency range and pliType (e.g. 'nanbadchannels')
        [~, currFileName, ~] = fileparts([pwd filesep dataMatFileName{iMatFiles}]);
        splitFileName = strsplit(currFileName, '_');
        lastAnalysis = splitFileName{end};
        freqrange = splitFileName{2};
        pliType = splitFileName{end - 1};
        
        % set in this check which specific files need to be analyzed 
        doAnalysis = strcmp(pliType, 'nanbadchannels') && strcmp(freqrange, '[4-7]');
        if doAnalysis
            switch lastAnalysis
                case 'pli'
                    filename = [currFileName '_cMatrixPLI.png'];
                    
                    load(dataMatFileName{iMatFiles})
                    imagesc(cMatrixPLI)
                    title(['PLI correlation matrix for ' subjectdata.subjectdir '(freqrange: ' freqrange ')'])
                    
%                     fprintf('\n saving %s to \n %s \n', filename, figureDirPath)
%                     saveas(gcf, [figureDirPath filesep filename])
                    
                    fprintf('\n saving %s to \n %s \n', filename, figureDirPath)
                    saveas(gcf, [rootFigureDirPath filesep filename])
                    disp('done')
                    
                otherwise
                    error('%s: last analysis unknown', subjectdata.subjectdir)
            end
        end
    end
end


cd( rootdir )



