function bv_showSubjectData(subjectName, inputData)

eval('setOptions')
eval('setPaths')

subjectFolderPath = [PATHS.SUBJECTS filesep subjectName];

[subjectdata, data] = bv_check4data(subjectFolderPath, inputData);

cfg = [];
cfg.viewmode = 'vertical';
cfg.ylim = [-30 30];
ft_databrowser(cfg, data)
set(gcf, 'units', 'normalized', 'Position', [0 0 1 1])
