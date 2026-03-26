function bv_quickShowSubject(str, filestr, cfg)

if nargin < 3
    cfg = [];
end

if strcmpi(filestr,'RAW')
    israw = 1;
else
    israw = 0;
end

eval('setOptions')
eval('setPaths')

subjectFolders = dir([PATHS.REMOVED filesep '*' OPTIONS.sDirString '*']);
subjectFoldersName = {subjectFolders.name};
subject.name = subjectFoldersName{ismember(subjectFoldersName, str)};


disp(subject.name)
subjectFolderPath = [PATHS.REMOVED filesep subject.name];

if israw
    [subjectdata] = bv_check4data(subjectFolderPath);
    
    cfg.dataset = subjectdata.PATHS.DATAFILE;
    cfg.headerfile = subjectdata.PATHS.HDRFILE;
    cfg.preproc.hpfilter = 'yes';
    cfg.preproc.hpfreq = 1;
    cfg.preproc.hpinstabilityfix = 'reduce';
    cfg.preproc.bsfilter = 'yes';
    cfg.preproc.bsfreq = [48 52];
    cfg.preproc.bsinstabilityfix = 'reduce';
    cfg.preproc.reref = 'yes';
    cfg.preproc.refchannel = 'all';
    
    cfg.channel = 'EEG';
    cfg.viewmode = 'vertical';
    cfg.blocksize = 8;
    cfg.continuous = 'yes';
    cfg.ylim = [-100 100];
    fprintf('\t showing %s data \n', upper(filestr))
    evalc('ft_databrowser(cfg)');
    
else
    
    [~, data] = bv_check4data(subjectFolderPath, upper(filestr));
    cfg.viewmode = 'vertical';
    cfg.blocksize = 8;
    cfg.continuous = 'yes';
    
    cfg.ylim = [-100 100];
    fprintf('\t showing %s data \n', upper(filestr))
    evalc('ft_databrowser(cfg, data)');
end

