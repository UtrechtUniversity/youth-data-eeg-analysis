function results = bv_createPowerResults(cfg)

optionsFcn  = ft_getopt(cfg, 'optionsFcn', 'setOptions');
pathsFcn    = ft_getopt(cfg, 'pathsFcn', 'setPaths');

eval(optionsFcn)
eval(pathsFcn)

folders = dir([PATHS.SUBJECTS filesep '*' OPTIONS.sDirString '*']);
nFolders = {folders.name};
subjectNames = cellfun(@(v) v(1:5), nFolders, 'Un', 0);
subjectNames = unique(subjectNames);

fun = @(s)~cellfun('isempty',strfind(nFolders,s));
out = cellfun(fun,subjectNames,'UniformOutput',false);
out = out(cellfun(@sum, out)==2);
allNames = nFolders(any(cat(1,(out{:})),1));

% out = out(cellfun(@sum, out')==2);
% subjectNames = subjectNames(cellfun(@sum, out)==2);
% 
% out = cellfun(fun,subjectNames,'UniformOutput',false);
% nFolders = any(cat(1,out{:}),2)

sessionString = {'A', 'B'};

noSubject = 0;
evalc('[~, data] = bv_check4data([PATHS.SUBJECTS filesep nFolders{1}], ''POWER'');');

fnames = fieldnames(data);

for j = 1:length(sessionString)
    currSes = sessionString{j};
    disp(currSes)
        
    currSubjects = allNames(~cellfun(@isempty, strfind(allNames, currSes)));
    
    
    for i = 1:length(fnames)
        
        cfg = [];
        cfg.subjects = currSubjects;
        cfg.fields = fnames{i};
        cfg.structFileName = 'power';
        cfg.structVarFname = 'powerdata';
        cfg.optionsFcn = 'setOptions';
        cfg.pathsFcn = 'setPaths';
        
        [results.(['session' num2str(j)]).(cfg.fields), names] = bv_readOutStructFromFile(cfg);
    end
end
results.subjects = names;
fprintf('saving results file ... ')
save([PATHS.RESULTS filesep 'power.mat'],'results')
fprintf('done! \n')
