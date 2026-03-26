function comp = bv_compAnalysis(cfg, data)

method      = ft_getopt(cfg, 'method', 'runica');
extended    = ft_getopt(cfg, 'extended', 1);
saveData    = ft_getopt(cfg, 'saveData', 0);
outputStr   = ft_getopt(cfg, 'outputStr', 'comp');
inputStr    = ft_getopt(cfg, 'inputStr');
currSubject = ft_getopt(cfg, 'currSubject');
optionsFcn  = ft_getopt(cfg, 'optionsFcn');

if nargin < 2
    disp(currSubject)
    
    eval(optionsFcn)
    
    subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];
    [subjectdata, data] = bv_check4data(subjectFolderPath, inputStr);
    
    subjectdata.cfgs.(outputStr) = cfg;
    
end

cfgIn = cfg;
subjectdata.cfgs.(outputStr) = cfgIn;

fprintf('\t calculating component analysis ... ')

trialdata = [data.trial{:}];
trialdata(isnan(trialdata)) = [];
cfg = [];
cfg.method              = method;
cfg.(method).extended   = extended;
cfg.(method).pca        = rank(trialdata);
evalc('comp = ft_componentanalysis(cfg, data);');

subjectdata.analysisOrder = bv_updateAnalysisOrder(subjectdata.analysisOrder, cfgIn);

fprintf('done! \n')

compFilename = [currSubject '_' outputStr '.mat'];

if strcmpi(saveData, 'yes')
    
    bv_updateSubjectSummary([PATHS.SUMMARY filesep 'SubjectSummary.mat'], subjectdata)
    bv_saveData(subjectdata, comp, outputStr);
    
end

