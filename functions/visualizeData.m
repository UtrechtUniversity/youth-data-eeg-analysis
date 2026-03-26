function visualizeData(dataType, overwrite, subjectDir, subjectDirString)
% Visualize fieldtrip data. Run in individual subject folders or in the
% rootfolder, but then give the SubjectDir[ectory name] and a string which
% is in the foldername of each subject (SubjectDirString). 
%
% Please select last analyses in dataType
% Possible dataTypes
%       'filter+reref'  : data has lastly either been filtered or
%                           rereferenced
%       'eogchannels'   : eogchannel preprocessing
%       'ICA'           : for the visualization of ICA data
%       'hjorth'        : for the visualization of the hjorth data
%       'compRemoved    : for the visualization after components have been
%                           removed
%
% visualizeData(dataType, overwrite, subjectDir, subjectDirString)

% set defaults
if nargin < 1
    dataType = 'all';
end
if nargin < 2
    overwrite = 0;
end
if nargin < 3
    subjectDir = 'Subjects';
end
if nargin < 4
    subjectDirString = 'pp';
end

% load in fixed variables and paths
rootdir = pwd;
figureDir = [rootdir filesep 'figures'];
dataType = {dataType};
doAll = false;
if strcmp(dataType, 'all')
    doAll = true;
end

% check whether script is ran from inside subject folder and change
% functionality of script accordingly
if exist(subjectDir, 'dir')
    multipleSubjects = 1;
else
    multipleSubjects = 0;
end

if multipleSubjects
    subjectDir = [rootdir filesep subjectDir];
    
    subjectFolders = dir([subjectDir filesep subjectDirString '*']);
    subjectFolderNames = {subjectFolders.name};
else
    [subjectDir, subjectFolderNames] = fileparts(rootdir);
    subjectFolderNames = {subjectFolderNames};
end

% start of visualization functionality
for iFolName = 1:length(subjectFolderNames)
    
    % load individual subject.mat file
    try
        load([subjectDir filesep subjectFolderNames{iFolName} filesep 'Subject.mat'])
    catch
        error('ERROR: no Subject.mat found for %s', subjectFolderNames{iFolName})
    end
    
    % find all mat dataFiles
    cd(subjectdata.subjectpath)
    dataMatFiles = dir([subjectdata.subjectdir '*.mat']);
    dataMatFileNames = {dataMatFiles.name};
    
    % create output figure dir
    if ~exist(figureDir, 'dir')
        mkdir(figureDir)
    end
    
    % run through all found matfiles 
    for iMatFile = 1:length(dataMatFileNames)
        clear comp data
        load(dataMatFileNames{iMatFile})
        
        % check whether the loaded matfile was a component file and check
        % for the analyses done on the particular file. Find the last done
        % analysis.
        if exist('comp', 'var')
            allAnalyses = strsplit(comp.preprocessOrder, '_');
        elseif exist('data','var')
            allAnalyses = strsplit(data.preprocessOrder, '_');
        else
            allAnalyses = 'dontanalyze';
        end
        lastAnalysis = allAnalyses(end);
        
        if doAll || ismember(lastAnalysis, dataType)
            switch lastAnalysis{:}
                case 'filter+reref'
                    filename = [subjectdata.subjectdir '_' lastAnalysis{:} ...
                        '_magResponse.png'];
                    if overwrite || ~exist(filename, 'file');
                        figure();
                        cfg                 = [];
                        cfg.channel         = {'EEG' '-A2'};
                        cfg.freqrange       = [0 50];
                        cfg.noverlap        = 50;
                        cfg.windowLength    = 1000;
                        evalc('magnitudeResponse(cfg, data);');
                        title(filename);
                        
                        fprintf('\n saving %s to \n %s \n', filename, figureDir)
                        saveas(gcf, [figureDir filesep filename])
                        disp('done')
                        
                        cfg = [];
                        cfg.viewmode = 'vertical';
                        ft_databrowser(cfg, data)
                    end
                    clear data
                    
                case 'eogchannels'
                    filename = [subjectdata.subjectdir '_' lastAnalysis{:} ...
                        '_magResponse.png'];
                    if overwrite || ~exist(filename, 'file');
                        figure();
                        cfg                 = [];
                        cfg.channel         = {'EEG', '-A2'};
                        cfg.freqrange       = [0 100];
                        cfg.noverlap        = 50;
                        cfg.windowLength    = 1000;
                        evalc('magnitudeResponse(cfg, data);');
                        title(filename)
                        
                        fprintf('\n saving %s to \n %s \n', filename, figureDir)
                        saveas(gcf, [figureDir filesep filename])
                        disp('done')
                    end
                    clear data
                    
                case 'ICA'
                    filenameBrainComps =  [subjectdata.subjectdir ...
                        '_' lastAnalysis{:} '_brain.png'];
                    filenameDatabrowser = [subjectdata.subjectdir ...
                        '_' lastAnalysis{:} '_databrowser.png'];
                    if overwrite || ~exist(filenameBrainComps, 'file');
                        figure();
                        cfg = [];
                        cfg.component = 1:30; % specify the component(s) that should be plotted
                        cfg.layout    = 'EEG1010'; % specify the layout file that should be used for plotting
                        cfg.comment   = 'no';
                        cfg.compscale = 'local';
                        evalc('ft_topoplotIC(cfg, comp);');
                        
                        fprintf('\n saving %s to \n %s \n', filenameBrainComps, figureDir)
                        saveas(gcf, [figureDir filesep filenameBrainComps])
                        disp('done')
                        
                    end
                    
                    if overwrite || ~exist(filenameDatabrowser, 'file');
                        cfg = [];
                        cfg.layout = 'EEG1010';
                        cfg.viewmode = 'component';
                        cfg.channel = 'all';
                        cfg.ylim      = [-3 3];
                        evalc('ft_databrowser(cfg,comp);');
                        
                        fprintf('\n saving %s to \n %s \n', filenameDatabrowser, figureDir)
                        saveas(gcf, [figureDir filesep filenameDatabrowser])
                        disp('done')
                        
                    end
                    clear comp
                    
                case 'hjorth'
                    filename = [subjectdata.subjectdir '_' lastAnalysis{:} ...
                        '_magResponse.png'];
                    if overwrite || ~exist(filename, 'file');
                        figure();
                        cfg                 = [];
                        cfg.channel         = {'EEG', '-A2'};
                        cfg.freqrange       = [0 100];
                        cfg.noverlap        = 50;
                        cfg.windowLength    = 1000;
                        evalc('magnitudeResponse(cfg, data);');
                        title(filename)
                        
                        fprintf('\n saving %s to \n %s \n', filename, figureDir)
                        saveas(gcf, [figureDir filesep filename])
                        disp('done')
                        
                    end
                    clear data
                    
                case 'compRemoved'
                    filename = [subjectdata.subjectdir '_' lastAnalysis{:} ...
                        '_magResponse.png'];
                    if overwrite || ~exist(filename, 'file');
                        figure();
                        cfg                 = [];
                        cfg.channel         = {'EEG', '-A2'};
                        cfg.freqrange       = [0 100];
                        cfg.noverlap        = 50;
                        cfg.windowLength    = 1000;
                        evalc('magnitudeResponse(cfg, data);');
                        title(filename)
                        
                        fprintf('\n saving %s to \n %s \n', filename, figureDir)
                        saveas(gcf, [figureDir filesep filename])
                        disp('done')
                        
                    end
                    clear data
                    
                case 'dontanalyze'
                    
                otherwise
                    warning('warning: lastpreprocessing step unknown: %s /n skipping...', lastAnalysis{:})
                    
            end % switch lastAnalyses
            
        end % if ismember(lastAnalyses, dataType)
        
    end % for iMatFile = 1:length(dataMatFileNames)
    
end % for iFolName = 1:kength(subjectFolderNames)

cd( rootdir )

