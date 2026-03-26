function visualArtefactRemoval(cfg)
% cuts the data in 2s trials to start interactive trial removals dased on
% ft_rejectvisual
%
% needed input variables:
%   cfg.overwrite:          [bool] set to 1 to overwrite previous data 
%                               files (default: 0)
%   cfg.prevDataString:     [string] last part of filename of datafile to 
%                               be analyzed (e.g 'reref')
%   cfg.filenameAddition:   [string] add this string to the end of the
%                               created filenames (default: 'cleaned')
%
%   cfg.continuousData:     [bool] set to 1 to if data is continuous (not
%                               cut into trials). This causes the data to
%                               be cut into trials either with your own
%                               trialfun or into a standard given length.
%                               If not given, this will be automatically
%                               optained from the data.trial structure.
%       cfg.trialfun        [bool] needed if continuousData is set to 1. 
%                               set to 1 to use your own trial function,
%                               which cuts the trials according to your
%                               events.
%                               If set to 1, please add the name of your
%                               trialfun to cfg.trialfunName. 
%                               If set to 0, please add a cfg.triallength 
%                               in seconds, to cut the continuous data in
%                               even trials
%       cfg.trialfunName    [str] If trialfun is set to 1, add the name of
%                               your trialfun (and add your trialfun to the
%                               subfunctions folder
%       cfg.triallength     [double] if cfg.trialfun = 0, set the length of
%                               the default cut trials in seconds
%
%
% Copyright (C) 2015-2016, Bauke van der Velde
%
%   visualArtefactRemoval(sDir, subjectDirString, overwrite, prevDatStr)

prevDataString      = ft_getopt(cfg, 'prevDataString');
overwrite           = ft_getopt(cfg, 'overwrite',0);
subjects            = ft_getopt(cfg, 'subjects', 'all');
filenameAddition    = ft_getopt(cfg, 'filenameAddition', 'cleaned');
continuousData      = ft_getopt(cfg, 'continuousData');
trialfun            = ft_getopt(cfg, 'trialfun');
trialfunName        = ft_getopt(cfg, 'trialfunName');
triallength         = ft_getopt(cfg, 'triallength');
analysisTree        = ft_getopt(cfg, 'analysisTree');

if isempty(prevDataString)
    error('No prevDataString found in the config file, please add...') 
end

% gather standards
setStandards()

% find individual subject folders
subjectFolders = dir([PATHS.SUBJECTS filesep sDirString '*']);
subjectFolderNames = {subjectFolders.name};

if ~strcmp(subjects, 'all')
    subjectFolderNames = subjectFolderNames(subjects);
end
  
for iFolName = 1:length(subjectFolderNames)
    % load subject file and go to folder
    cd([PATHS.SUBJECTS filesep subjectFolderNames{iFolName} filesep analysisTree])
    
    try
        load('Subject.mat')
    catch
        error('ERROR: no Subject.mat found for %s in %s \n please run preprocessBabyConnectivity first' ... 
            , subjectFolderNames{iFolName}, analysisTree)
    end
    
    disp(subjectdata.subjectName)
    subjectdata.cfgs.visualArtefactRemoval = cfg;
    
    fileExist = dir(filenameAddition);
    doAnalysis = overwrite || isempty(fileExist);
    if doAnalysis
        % load datafile
        try
            load( subjectdata.PATHS.MYPREPROCESSFILE )
        catch
            error( '%s: previous data file not found', previousDataFile.name)
        end
        
        if strcmp(prevDataString, 'ICA')
            data = comp;
            previousData = data;
        else
            previousData = data;
            cfg = [];
            cfg.channel = {'EEG', '-A2'};
            evalc('data = ft_selectdata(cfg, data);');
        end
        
        if isempty(continuousData) && length(data.trial) == 1
            continuousData = 1;
        end
        
        if continuousData
            disp('continuous data detected')
            if isempty(trialfun)
                error(['please add whether the data' ...
                    'needs to be cut into trials using your own trial fun' ...
                    'or not into the trialfun variable in your config file'])
            end
            if trialfun
                
                % check whether correct trialfunName is given
                if isempty(trialfunName)
                    error('trialfun set to 1, but trialfunName not set')
                elseif which([trialfunName 'asd.m'])
                    error('trialfunName given: %s not found', trialfunName)
                end
                
                disp('Used your own trialfun to cut continuous data into trials')
                cfg = [];
                cfg.trialfun = trialfunName;
                cfg.channel = 'EEG';
                cfg.sampleinfo = data.sampleinfo;
                cfg = ft_definetrial(cfg);
                evalc('data = ft_redefinetrial(cfg, data);');
            else
                if continuousData && ~trialfun && isempty(triallength)
                    error(['no triallength found in your config file, please' ...
                        'add if not using trialfun'])
                end
                
                fprintf('Used general trialfun to cut continuous data into %d s. trials \n', ...
                    triallength)
                cfg = [];
                cfg.length = triallength;
                cfg.overlap = 0;
                evalc('data = ft_redefinetrial(cfg, data);');
            end
        end
        
        cfg = [];
        if strcmp(prevDataString, 'ICA')
            cfg.viewmode = 'components';
        else
            cfg.viewmode = 'vertical';
        end 
        ft_databrowser(cfg, data)
        
        % reject trials
        cfg = [];
        cfg.method = 'summary';
        data = ft_rejectvisual(cfg, data);
        
        fileAddition = 'visualArtefactRejection';
        if ~isfield(previousData,'preprocessOrder')
            data.preprocessOrder = fileAddition;
        else
            data.preprocessOrder = [previousData.preprocessOrder,'_',fileAddition];
        end
        
        fprintf('\t Saving %s ...', [subjectdata.PATHS.ANALYSISTREE filesep subjectdata.subjectName '_' filenameAddition '.mat'])
        save([subjectdata.PATHS.ANALYSISTREE filesep subjectdata.subjectName '_' filenameAddition '.mat'],'data')
        fprintf(' done \n')
        
        subjectdata.PATHS.MYCLEANEDFILE = [subjectdata.PATHS.ANALYSISTREE filesep subjectdata.subjectName '_' filenameAddition '.mat'];
        
        clear data dataSegmented previousData dataClean1 dataClean2
        
    end
    save([subjectdata.PATHS.ANALYSISTREE filesep 'Subject.mat'],'subjectdata')
    close all
end

cd( PATHS.ROOT )