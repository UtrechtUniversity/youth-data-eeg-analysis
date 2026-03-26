function data = bv_averageReref(cfg, data)

currSubject = ft_getopt(cfg, 'currSubject');
inputStr    = ft_getopt(cfg, 'inputStr');
saveData    = ft_getopt(cfg, 'saveData');
outputStr   = ft_getopt(cfg, 'outputStr');
optionsFcn  = ft_getopt(cfg, 'optionsFcn', 'setPaths');
refElectrode = ft_getopt(cfg, 'refElectrode');
cfgIn = cfg;

if nargin < 2
    disp(currSubject)
    
    eval(optionsFcn)
    
    subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];
    [subjectdata, data] = bv_check4data(subjectFolderPath, inputStr);
    
    subjectdata.cfgs.(outputStr) = cfg;
    
end

fprintf('\t rereferencing data ...')

cfg = [];
cfg.reref = 'yes';
cfg.refchannel = refElectrode;
evalc('data = ft_preprocessing(cfg,data);');

fprintf('done! \n')

if strcmpi(saveData, 'yes')
%         subjectdata.analysisOrder = bv_updateAnalysisOrder(subjectdata.analysisOrder, cfgIn);
        bv_updateSubjectSummary([PATHS.SUMMARY filesep 'SubjectSummary.mat'], subjectdata);
        
        bv_saveData(subjectdata, data, outputStr);
end
