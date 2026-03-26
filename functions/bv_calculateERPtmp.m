function ERPdata = bv_calculateERP(cfg, data)

lims            = ft_getopt(cfg, 'lims');
pathsFcn        = ft_getopt(cfg, 'pathsFcn', 'setPaths');
currSubject     = ft_getopt(cfg, 'currSubject');
artfctStr       = ft_getopt(cfg, 'artfctStr');
saveData        = ft_getopt(cfg, 'saveData');
triggers        = ft_getopt(cfg, 'triggers');
outputLabels    = ft_getopt(cfg, 'outputLabels');
trialfun        = ft_getopt(cfg, 'trialfun');
resampleFs      = ft_getopt(cfg, 'resampleFs', 512);
filtrange       = ft_getopt(cfg, 'filtrange', [1 20]);

if not(iscell(triggers))
    tmp{1} = triggers;
    triggers = tmp;
end

if not(iscell(outputLabels))
    tmp{1} = triggers;
    outputLabels = tmp;
end

if length(outputLabels) ~= length(triggers)
    error('Output labels and trigger values length is not equal')
end

if nargin < 2 % data preprocessing + loading
    if isempty(pathsFcn)
        error('please add options function cfg.pathsFcn')
    else
        eval(pathsFcn)
    end
    
    subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];
    disp(currSubject)
    [subjectdata, artfct] = bv_check4data(subjectFolderPath, artfctStr);
    
    fprintf('\t Calculate amount of trials clean ... \n')
    % detect good trials
    limFields = fieldnames(lims);
    for i = 1:length(limFields)
        cField = limFields{i};
        out(:,:,i) = artfct.(cField).levels > lims.(cField);
    end
    goodTrials = not(any(sum(out,3)>0));
    fprintf('\t \t %1.0f clean trials found \n', sum(goodTrials))
    
    fprintf('\t Repreprocessing data ... \n')
    fprintf(['\t \t channels to be ignored: ', ...
        repmat('%s ',1, length(subjectdata.channels2remove)) '\n'], ...
        subjectdata.channels2remove{:})
    fprintf('\t \t rereferencing \n')
    cfg = [];
    cfg.channel = cat(2,'EEG', strcat('-',subjectdata.channels2remove'));
    cfg.dataset = subjectdata.PATHS.DATAFILE;
    cfg.headerfile = subjectdata.PATHS.HDRFILE;
    cfg.reref = 'yes';
    cfg.refchannel = 'all';
    evalc('data = ft_preprocessing(cfg);');
    fprintf('\t \t preprocessing and rereferencing done! \n')
    
    fprintf('\t Cutting filtered data into trials based on earlier found good trials ... ')
    evalc('hdr = ft_read_header(subjectdata.PATHS.HDRFILE);');
    cfg = [];
    cfg.trialfun = trialfun;
    cfg.dataset = subjectdata.PATHS.DATAFILE;
    cfg.headerfile = subjectdata.PATHS.HDRFILE;
    if not(isempty(resampleFs))
        cfg.Fs = resampleFs;
    else
        cfg.Fs = hdr.Fs;
    end
    evalc('cfg = ft_definetrial(cfg);');
    tmptrl = cfg.trl;
    
    cfg = [];
    cfg.trl = tmptrl(goodTrials,:);
    evalc('data = ft_redefinetrial(cfg, data);');
    fprintf('done! \n')
    
    fprintf('\t last check, removing too high amplitudes (>200uV) \n')
    check2_sel = find(not(isoutlier(cellfun(@(x) max(diff(minmax(x), [], 2)), data.trial))));
    fprintf('\t \t %1.0f trials found to be removed ... ', length(check2_sel))
    cfg = [];
    cfg.trials = check2_sel;
    evalc('data = ft_selectdata(cfg, data);');
    fprintf('done! \n')
    
    for i = 1:length(triggers)
        fprintf('\t ERP analysis for %s \n', outputLabels{i})
        fprintf('\t \t %1.0f trials used \n', length(find(ismember(data.trialinfo, triggers{i}))))
        fprintf('\t \t calculating average ... ')
        cfg = [];
        cfg.trials = find(ismember(data.trialinfo, triggers{i}));
        evalc('ERPdata = ft_timelockanalysis(cfg, data);');
        fprintf('done! \n')
        
        fprintf('\t \t baseline correction ... ')
        cfg = [];
        cfg.channel = 'all';
        cfg.baseline = [-0.2 0];
        evalc('ERPdata = ft_timelockbaseline(cfg, ERPdata);');
        fprintf('done! \n')
        
        bv_saveData(subjectdata, ERPdata, outputLabels{i})
        bv_updateSubjectSummary([PATHS.SUMMARY filesep 'SubjectSummary'], subjectdata)
        subjectdata = bv_check4data(subjectFolderPath);
    end
end


