function bv_mergeSubjects(preprocStr)

eval('setPaths')
eval('setOptions')

% find split files
subjectdirs = dir([PATHS.SUBJECTS filesep '*' OPTIONS.sDirString '*']);
subjectnames = {subjectdirs.name};
pseudocodes = cellfun(@(v) v(1:6), subjectnames, 'Un', 0);
a = unique(pseudocodes,'stable');
b = cellfun(@(x) sum(ismember(pseudocodes,x)),a);
merge_sel = find(b>1);

subjects2merge = pseudocodes(merge_sel);
for i = 1:length(merge_sel)
    disp(subjects2merge{i});
    currSubjectIndex = find(contains(pseudocodes,subjects2merge(i)));
    for j = 1:length(currSubjectIndex);
        subectfolderpath = [PATHS.SUBJECTS filesep subjectnames{currSubjectIndex(j)}];
        [~, data2merge(j)] = bv_check4data(subectfolderpath, preprocStr);
    end
    
    cfg = [];
    fprintf('\t appending data ...')
    switch length(currSubjectIndex)
        case 2
            evalc('data = ft_appenddata(cfg, data2merge(1), data2merge(2));');
        case 3
            evalc('data = ft_appenddata(cfg, data2merge(1), data2merge(2), data2merge(3));');
        case 4
            evalc('data = ft_appenddata(cfg, data2merge(1), data2merge(2), data2merge(3), data2merge(4));');
        otherwise
            error('more than 4 data files found for this subject, quitting')
    end
    % removing old files
    for j = 1:length(subjectdata2merge)
        delete(subjectdata2merge(j).PATHS.PREPROC)
        cfg = [];
        removingSubjects(cfg, subjectdata2merge(j).subjectName, 'merged')
    end
    fprintf('done! \n');
    newsubjectdir = [PATHS.SUBJECTS filesep subjects2merge{i}];
    mkdir(newsubjectdir)
    
    subjectdata.pseudocode = subjects2merge{i};
    subjectdata.subjectName = subjects2merge{i};
    subjectdata.PATHS.HDRFILE = 'multiple';
    subjectdata.PATHS.DATAFILE = 'multiple';
    subjectdata.PATHS.SUBJECTDIR = newsubjectdir;
    
    bv_saveData(subjectdata, data, 'PREPROC')
    
    clear subjectdata2merge data2merge
end