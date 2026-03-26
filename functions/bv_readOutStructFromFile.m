function [output, names] = bv_readOutStructFromFile(cfg)

subjects        = ft_getopt(cfg, 'subjects', 'all');
fields          = ft_getopt(cfg, 'fields');
analysisTree    = ft_getopt(cfg, 'analysisTree');
structFileName  = ft_getopt(cfg, 'structFileName');
structVarFname  = ft_getopt(cfg, 'structVarFname');
namesOnly       = ft_getopt(cfg, 'namesOnly', 'no');
parentFolder    = ft_getopt(cfg, 'parentFolder', 'Subjects');
optionsFcn      = ft_getopt(cfg, 'optionsFcn', 'setOptions');
pathsFcn        = ft_getopt(cfg, 'pathsFcn', 'setPaths');

eval(optionsFcn)
eval(pathsFcn)

if ~exist(parentFolder, 'dir')
    error('Cannot find parent folder')
else
    PATHS.PARENTFOLDER = [PATHS.ROOT filesep parentFolder];
end

folders = dir([ PATHS.PARENTFOLDER filesep '*' OPTIONS.sDirString '*']);
names = {folders.name};
names = names';

if strcmpi(namesOnly, 'yes')
    return
end

if ischar(fields)
    fields = {fields};
end

if strcmpi(subjects, 'all')
    subjectsVect = 1:length(names);
else
    
    fun = @(s)~cellfun('isempty',strfind(names,s));
    out = cellfun(fun,subjects','UniformOutput',false);
    subjectsVect = find(any(horzcat(out{:}),2));
    
    if isempty(subjectsVect)
        error('Subject names not found')
    end
end

counter = 0;

for iSubject = 1:length(subjectsVect)
    counter = counter + 1;
    
    currSubjectName = names{subjectsVect(iSubject)};
    %     disp(currSubjectName)
    file2load = dir([PATHS.PARENTFOLDER filesep currSubjectName filesep analysisTree filesep '*' structFileName '*']);
    fileName = file2load.name;
    try
        load([PATHS.PARENTFOLDER filesep currSubjectName filesep analysisTree filesep fileName])
    catch
        error('\t %s file not found for %s', structFileName, currSubjectName)
    end
    
    try
        outputVar = eval(strjoin([structVarFname, fields], '.'));
    catch
        warning('fields not found for subject %s, continue without value for current subject', currSubjectName)
        continue
    end
    
    if isempty(outputVar)
        continue
    end
    
    switch class(outputVar)
        case 'char'
            if ~exist('output', 'var')
                output = cell(length(folders), 1);
            end
            output{counter} = outputVar;
        case 'struct'
            output(counter) = outputVar;
        case 'double'

            if iscell(output)
                output = zeros(length(subjectsVect),1);
            end
            output(counter) = outputVar;
        case 'cell'
            outputVar = reshape(outputVar, [ 1 numel(outputVar) ] );
            if ~exist('output', 'var')
                output = cell(length(folders), size(outputVar, 2));
            else
                if size(outputVar, 2) > size(output, 2)
                    output = cat(2, output, cell(length(folders), size(outputVar, 2) - size(output, 2)));
                end
            end
            output(counter,1:size(outputVar,2)) = outputVar;
    end
    clear outputVar
end
names = names(subjectsVect);

