function data = bv_visualTrialRemoval(cfg, data)

currSubject = ft_getopt(cfg, 'currSubject');
inputStr    = ft_getopt(cfg, 'inputStr');
outputStr   = ft_getopt(cfg, 'outputStr', 'VISCLEAN');
saveData    = ft_getopt(cfg, 'saveData');
optionsFcn  = ft_getopt(cfg, 'optionsFcn', 'setOptions');
pathsFcn  = ft_getopt(cfg, 'optionsFcn', 'setPaths');


if nargin < 2
    disp(currSubject)

    eval(optionsFcn);
    eval(pathsFcn);

    subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];
    [subjectdata, data] = bv_check4data(subjectFolderPath, inputStr);
else
    saveData = 'no';
end

cfg = [];
cfg.length = 1;
cfg.overlap = 0;
evalc('data = ft_redefinetrial(cfg, data);');

cfg = [];
cfg.method = 'summary';
cfg.layout = 'biosemi32.lay';
evalc('data = ft_rejectvisual(cfg, data);');

data = bv_appendfieldtripdata([], data);

if strcmpi(saveData, 'yes')
    bv_saveData(subjectdata, data, outputStr)
end




