function bv_ICAComponentRemoval(overwrite, sDir, sDirString)
% starts interactive ICA component removal based on ft_rejectcomponent.
% Loads in *reref.mat as datafile and *comp.mat as component file. Run from
% parent folder of directory of all subjects
%
% input variables:
%   overwrite:  [boolean] overwrite previous data (default = false)
%   sDir:       [string] subject directory name
%   sDirString: [string] non-unique part all subject directories (e.g. 'pp')
%
% Copyright (C) 2015-2016, Bauke van der Velde
%
% ICAComponentRemoval(subjectDir, subjectDirString, overwrite)

if nargin < 1
    overwrite = 0;
end


% set paths
rootDir = pwd;
ftPath = '~/Matlab_Toolboxes/EEG/fieldtrip-20160120/';
path2SubjectDir = [rootDir filesep sDir];
path2removeDir = [path2SubjectDir filesep 'removed'];
addpath(ftPath)
addpath([rootDir filesep 'subfunctions'])
ft_defaults

% find subjectfoldernames
subjectFolders = dir([path2SubjectDir filesep sDirString '*']);
subjectFolderNames = {subjectFolders.name};

for iFolName = 1:length(subjectFolderNames)
    % load individual subject file and go to subject folder
    try
        load([path2SubjectDir filesep subjectFolderNames{iFolName} filesep 'Subject.mat'])
    catch
        error('ERROR: no Subject.mat found for %s', subjectFolderNames{iFolName})
    end
    cd(subjectdata.subjectpath)
    
    fileExist = dir('*compRemoved.mat');
    doAnalysis = overwrite || isempty(fileExist);
    
    if ~doAnalysis
        continue
    end
    
    fprintf('%s', subjectdata.subjectdir)
        
    % load component and data file
    compMatFile = dir([subjectdata.subjectdir '*ICA.mat']);
    load( compMatFile.name )
    datMatFile = dir([subjectdata.subjectdir '*reref.mat']);
    load( datMatFile.name )
    
    % run view modes
    cfg = [];
    cfg.layout = 'EEG1010';
    cfg.viewmode = 'component';
    cfg.channel = 'all';
    cfg.ylim      = [-0.005 0.005];
    cfg.interactive = 'no';
    evalc('ft_databrowser(cfg,comp);');
    
    cfg = [];
    cfg.component = 1:30; % specify the component(s) that should be plotted
    cfg.layout    = 'EEG1010'; % specify the layout file that should be used for plotting
    cfg.comment   = 'no';
    cfg.compscale = 'local';
    cfg.interactive = 'no';
    figure();
    evalc('ft_topoplotIC(cfg, comp);');
    
    fprintf('component removal for %s \n', subjectdata.subjectdir)
    
    % ask which components need to be deleted or whether the complete
    % subject needs to be moved to removed folder (if subject data is
    % bad)
    removComps = input(...
        'type the components that should be removed in a vector? or type ''delete'' to remove subject based on ICA data \n');
    
    if strcmp(removComps, 'delete');
        % if subject data is bad, create if necessary removeDir
        if ~exist(path2removeDir, 'dir')
            mkdir(path2removeDir)
        end
        
        % move subject to remove dir and warn examinor and save error
        % message to individual WhyRemoved.txt-file, to summary
        % removeLog.mat
        movefile([subjectdata.subjectpath filesep], path2removeDir);
        subjectdata.subjectpath   = [path2removeDir filesep subjectFolderNames{iFolName}];
        errorstr = 'Subject ICA not good enough, moved to removed directory';
        fprintf('%s: %s \n', subjectdata.subjectdir, errorstr)
        
        fid = fopen([subjectdata.subjectpath filesep 'WhyRemoved.txt'],'w');
        fprintf(fid, errorstr);
        fclose( fid );
        
        if exist([path2removeDir filesep 'removeLog.mat'], 'file')
            load([path2removeDir filesep 'removeLog.mat'])
            nrSubjectSoFar = size(removeLog, 1);
        else
            removeLog = {};
        end
        removeLog{nrSubjectSoFar + 1, 1} = subjectdata.subjectdir;
        removeLog{nrSubjectSoFar + 1, 2} = errorstr;
        
        save([path2removeDir filesep 'removeLog'],'removeLog');
        clear removeLog
    else
        % if subject data is good enough
        previousData = data;
        
        % remove bad given bad components
        cfg = [];
        cfg.component = removComps;
        data = ft_rejectcomponent(cfg, comp, previousData);
        
        % change preprocessOrder for new datafile
        fileAddition = 'compRemoved';
        if ~isfield(previousData,'preprocessOrder')
            data.preprocessOrder = fileAddition;
        else
            data.preprocessOrder = [previousData.preprocessOrder,'_',fileAddition];
        end
        
        % save new data-file
        fprintf('Saving %s ...', [subjectdata.subjectdir '_' data.preprocessOrder])
        save([subjectdata.subjectdir '_' data.preprocessOrder '.mat'],'data')
        fprintf(' done \n')
    end
    
    save([subjectdata.subjectpath filesep 'Subject.mat'],'subjectdata')
    
    close all
end     % for iFolName = 1:length(subjectFolderNames)

cd( rootDir )
