function output = bv_summarizeDataStructs(cfg)

inputStr 	= ft_getopt(cfg, 'inputStr');
optionsFcn  = ft_getopt(cfg, 'optionsFcn','setOptions');
pathsFcn    = ft_getopt(cfg, 'pathsFcn','setPaths');

eval(pathsFcn)

subjectdirs = dir(PATHS.SUBJECTS);
subjectdirs = subjectdirs([subjectdirs.isdir] & ~ismember({subjectdirs.name}, {'.', '..'}));
subjectdirs = subjectdirs(~strcmp(fullfile(PATHS.SUBJECTS, {subjectdirs.name}), PATHS.REMOVED));
subjectdirnames = {subjectdirs.name};

clear output
for iSubject = 1:length(subjectdirnames) %:-1:1
    currSubject = subjectdirnames(iSubject);
    evalc('[~,output(iSubject)] = bv_check4data([PATHS.SUBJECTS filesep currSubject{:}], inputStr);');
end
[output.name] = subjectdirnames{:};

