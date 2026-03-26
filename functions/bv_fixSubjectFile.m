function bv_fixSubjectFile

eval('setOptions')
eval('setPaths')

sDirs = dir([PATHS.SUBJECTS filesep '*' OPTIONS.sDirString '*']);
sNames = {sDirs.name};

for iS = 1:length(sNames)
    subjectdata = bv_check4data([PATHS.SUBJECTS filesep sNames{iS}]);
    disp(subjectdata.subjectName)
    
    fpnames = fieldnames(subjectdata.PATHS);
    fprintf(['\t following paths found in subject-file: ' repmat('%s ', 1, length(fpnames)) ' \n'], fpnames{:});
    
    datafiles = dir([subjectdata.PATHS.SUBJECTDIR filesep OPTIONS.sDirString '*.mat']);
    datanames = {datafiles.name};
    
    split1 = cellfun(@(x) strsplit(x, '.'), datanames, 'UniformOutput', false);
    celsel = cellfun(@(x) x{1}, split1, 'UniformOutput', false);
    split2 = cellfun(@(x) strsplit(x, '_'), celsel, 'UniformOutput', false);
    celsel2 = cellfun(@(x) x{end}, split2, 'UniformOutput', false);
    analysisNames = cellfun(@upper, celsel2, 'UniformOutput', false);
    fprintf(['\t following analyses found in subject-folder: ' repmat('%s ', 1, length(analysisNames)) ' \n'], analysisNames{:});
    
    anal2add = analysisNames(~contains(analysisNames, fpnames));
    
    if ~isempty(anal2add)
        fprintf(['\t adding: ', repmat('%s ', 1, length(anal2add))], anal2add{:})
        for ianal = 1:length(anal2add)
            fprintf(' \t \t adding %s ... ', anal2add{ianal})
            fname = dir([subjectdata.PATHS.SUBJECTDIR filesep '*' lower(anal2add{ianal}) '.mat']);
            if isempty(fname)
                error('no file found')
            else
                subjectdata.PATHS.(upper(anal2add{ianal})) = [fname.folder filesep fname.name];
                fprintf('done! \n')
            end
        end
        bv_saveData(subjectdata)
    else
        fprintf('\t no new analyses found, adding none \n')
    end
    
    clear subjectdata
    
end


