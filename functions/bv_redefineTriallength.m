function data = bv_redefineTriallength(cfg, data)

currSubject = ft_getopt(cfg, 'currSubject');
triallength = ft_getopt(cfg, 'triallength');
saveData    = ft_getopt(cfg, 'saveData');
inputStr    = ft_getopt(cfg, 'inputStr');
outputStr   = ft_getopt(cfg, 'outputStr');
optionsFcn  = ft_getopt(cfg, 'optionsFcn');

eval(optionsFcn)

if isempty(currSubject)
    error('Please enter the subject foldername in cfg.currSubject')
end

try
    load([PATHS.SUBJECTS filesep currSubject filesep 'Subject.mat'])
catch
    error('Subject.mat file not found')
end

disp(subjectdata.subjectName)

if nargin < 2
    try 
        [~, filenameData, ~] = fileparts(subjectdata.PATHS.(inputStr));
        
        fprintf('\t loading %s ... ', [filenameData '.mat'])
        load(subjectdata.PATHS.(inputStr))
        fprintf('done! \n')
    catch
        error('No input data variable given and inputStr not given / found')
    end
end


fprintf('\t redefining triallength to %s seconds ... ', num2str(triallength))
cfg = [];
cfg.length = triallength;
cfg.overlap = 0;
evalc('data = ft_redefinetrial(cfg, data);');
fprintf('done! \n')

if strcmpi(saveData, 'yes')
    subjectdata.analysisOrder = cat(2, subjectdata.analysisOrder, '-cut');
    outputFilename = [subjectdata.subjectName '_' outputStr '.mat'];
    subjectdata.PATHS.CUTDATA = [subjectdata.PATHS.SUBJECTDIR filesep outputFilename];
    
    fprintf('\t Saving %s ... ', outputFilename)
    save(subjectdata.PATHS.CUTDATA, 'data')
    fprintf('done! \n')
end

fprintf('\t Saving subjectdata variable to Subject.mat file')
save([subjectdata.PATHS.SUBJECTDIR filesep 'Subject.mat'], 'subjectdata')
fprintf('done! \n')

    
