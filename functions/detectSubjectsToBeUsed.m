function subjectIndx = detectSubjectsToBeUsed(cfg)
% detects subjects to be rejected, based on amount of trials included

% rewrite input config file
subjects            = ft_getopt(cfg, 'subjects', 'all'); 
goodTrlFieldName    = ft_getopt(cfg, 'goodTrlFieldName');
minimumTrls         = ft_getopt(cfg, 'minimumTrls');
analysisTree        = ft_getopt(cfg, 'analysisFolderName');

setStandards;
currDir = pwd;

subjectFolders = dir([PATHS.SUBJECTS filesep sDirString '*']);  % gather subject folders
subjectFolderNames = {subjectFolders.name}; % create a cell of subject folder names 

subjectIndx = [];

if ~strcmp(subjects, 'all')
    % if not all subjects are needed to be anlalyzed, check whether
    % subjects variable is cell or string and if so convert to index vector
    % of given subject names.
    if iscell(subjects) || ischar(subjects)
        subjects = find(ismember(subjectFolderNames, subjects));
    end
    subjectFolderNames = subjectFolderNames(subjects);  
end

for iSubject = 1:length(subjectFolderNames)
    
    cd([PATHS.SUBJECTS filesep subjectFolderNames{iSubject} filesep ...
            analysisTree]) % go to subject/analysis folder
            
    try
        % try to load Subject.mat file of subject. Else throw error.
        load('Subject.mat')
    catch
        error('\t Subject.mat not found for subject %s', ...
            subjectFolderNames{iSubject})
    end
    
    if ~isfield(subjectdata,'trialremoval')
        % check whether artifact rejection has been done and saved in
        % Subject.mat file
        error(['no trialremoval field found in subjectdata, please run ' ...
            'artifact rejection first'])
    end
    
    if isfield(subjectdata.trialremoval, goodTrlFieldName)
        if length(subjectdata.trialremoval.(goodTrlFieldName)) >= minimumTrls
            subjectIndx = [subjectIndx iSubject];
        end
        
    else
        error('goodTrlFieldName not found in cfg.trialremoval')
    end
end
    
cd(currDir) 
    
