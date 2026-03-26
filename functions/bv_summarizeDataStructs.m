function output = bv_summarizeDataStructs(cfg)

inputStr 	= ft_getopt(cfg, 'inputStr');
optionsFcn  = ft_getopt(cfg, 'optionsFcn','setOptions');
pathsFcn    = ft_getopt(cfg, 'pathsFcn','setPaths');

eval(optionsFcn)
eval(pathsFcn)

subjectdirs = dir([PATHS.SUBJECTS filesep '*' OPTIONS.sDirString '*']);
subjectdirnames = {subjectdirs.name};

clear output
for iSubject = 1:length(subjectdirnames) %:-1:1
    currSubject = subjectdirnames(iSubject);
    evalc('[~,output(iSubject)] = bv_check4data([PATHS.SUBJECTS filesep currSubject{:}], inputStr);');
end
[output.name] = subjectdirnames{:};

