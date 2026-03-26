function ERPdata = bv_calculateERP(cfg, data)

pathsFcn        = ft_getopt(cfg, 'pathsFcn', 'setPaths');
currSubject     = ft_getopt(cfg, 'currSubject');
overwrite       = ft_getopt(cfg, 'overwrite');
outputName      = ft_getopt(cfg, 'outputName');
saveData        = ft_getopt(cfg, 'saveData');
quiet           = ft_getopt(cfg, 'quiet');
resampleFs      = ft_getopt(cfg, 'resampleFs');
lpfreq          = ft_getopt(cfg, 'lpfreq');
hpfreq          = ft_getopt(cfg, 'hpfreq');
trialfun        = ft_getopt(cfg, 'trialfun');

if strcmpi(quiet, 'yes')
    quiet = true;
else
    quiet = false;
end

if nargin < 2 % data preprocessing + loading
    evalc(pathsFcn)
    disp(currSubject)
    subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];
    [subjectdata] = bv_check4data(subjectFolderPath);
    if strcmpi(overwrite, 'no')
        if isfield(subjectdata.PATHS, upper(outputName))
            if exist(subjectdata.PATHS.(upper(outputName)), 'file')
                fprintf('\t !!!%s already found, not overwriting ... \n', upper(outputName))
                ERPdata = [];
                return
            end
        end
    end

    cfg = [];
    cfg.resampleFs      = resampleFs; % [ number ]: resampling frequency.
    cfg.trialfun        = 'trialfun_YOUth_ERP'; % 'string': filename of trialfun to be used (please add trialfun to your path)
    cfg.hpfreq          = hpfreq; % [ number ]: high-pass filter frequency cut-off
    cfg.lpfreq          = lpfreq; % [ number ]: low-pass filter frequency cut-off
    cfg.pathsFcn        = pathsFcn;
    cfg.saveData        = 'no';
    cfg.reref           = 'yes'; % 'string': 'yes' to rereference data (default: 'no')
    cfg.refelec         = 'all'; % rereference electrode (string / number / cell of strings)
    cfg.interpolate     = 'yes';
    cfg.rmChannels      = 'yes';
    cfg.currSubject     = currSubject;
    cfg.quiet           = quiet;
    [ data ] = bv_preprocResample(cfg);
    
    
else
    cfg = [];
    cfg.hpfilter = 'yes';
    cfg.hpfreq = hpfreq;
    cfg.lpfilter = 'yes';
    cfg.lpfreq = lpfreq;
    data = ft_preprocessing(cfg, data);

end

if isempty(data.trial)
    fprintf('\t no trials found, skipping ... ')
    ERPdata = [];
    return
end

fprintf('\t demeaning and detrending ... ')
cfg = [];
cfg.detrend = 'yes';
cfg.demean = 'yes';
evalc('data = ft_preprocessing(cfg, data);');
fprintf('done! \n')

ERPdata.triggers = unique(data.trialinfo)';
fprintf('\t ERP analysis started ... \n')
for i = 1:length(ERPdata.triggers)
    fprintf('\t   calculating for trigger %1.0f ...', ERPdata.triggers(i))
    cfg = [];
    cfg.trials = find(ismember(data.trialinfo, ERPdata.triggers(i)));
    evalc('tmpERP = ft_timelockanalysis(cfg, data);');
    fprintf('done! \n')
    
    ERPdata.nTrls(i) = length(cfg.trials);
    
    fprintf('\t\tbaseline correction ... ')
    cfg = [];
    cfg.channel = 'all';
    cfg.baseline = [-0.2 0];
    evalc('tmpERP = ft_timelockbaseline(cfg, tmpERP);');
    fprintf('done! \n')
    
    ERPdata.time = tmpERP.time;
    ERPdata.label = tmpERP.label;
    ERPdata.avgs(:,:,i) = tmpERP.avg;
end
ERPdata.dimord = 'chan_time_trig';

% **** saving data
if strcmpi(saveData, 'yes')
       
    bv_saveData(subjectdata, ERPdata, outputName);              % save both data and subjectdata to the drive
    
    if ~quiet
        bv_updateSubjectSummary([PATHS.SUMMARY filesep 'SubjectSummary'], subjectdata)
    end
    
end
