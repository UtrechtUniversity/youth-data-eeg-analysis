function bv_appendPLI(inputStr)

eval('setPaths')
eval('setOptions')

subjectdirs = dir([PATHS.SUBJECTS filesep OPTIONS.sDirString '*']);
subjectnames = {subjectdirs.name};
pseudocodes = cellfun(@(v) v(1:6), {subjectdirs.name}, 'Un', 0);
uniquesubjectnames = unique(pseudocodes, 'stable');

for i = 1:length(uniquesubjectnames)
    iSubjectFolders = find(contains(subjectnames, uniquesubjectnames{i}));
    nSubjectFolders = length(iSubjectFolders);
    if nSubjectFolders > 1
        disp(uniquesubjectnames{i})
        fprintf('\t %1.0f subject folders found, merging %s ... ', nSubjectFolders, inputStr)
        subjectFolderPath1 = [PATHS.SUBJECTS filesep subjectnames{iSubjectFolders(1)}];
        [subjectdata, connectivity] = bv_check4data(subjectFolderPath1, inputStr);
        counter = 1;
        while counter < length(iSubjectFolders)
             counter = counter + 1;
             subjectFolderPath_tmp = [PATHS.SUBJECTS filesep subjectnames{iSubjectFolders(counter)}];
             [~, connectivity_tmp] = bv_check4data(subjectFolderPath_tmp, inputStr);
             plispctrm1 = connectivity.plispctrm .* length(connectivity.trialinfo);
             plispctrm2 = connectivity_tmp.plispctrm .* length(connectivity_tmp.trialinfo);
             pli_out = (plispctrm1 + plispctrm2) ./ (length(connectivity.trialinfo) + length(connectivity_tmp.trialinfo));
             connectivity.plispctrm = pli_out;
             connectivity.trialinfo = cat(1, connectivity.trialinfo, connectivity_tmp.trialinfo);
             movefile(subjectFolderPath_tmp, PATHS.REMOVED, 'f')

        end
        fprintf('done! \n')
        fprintf('\t saving to %s ... ', subjectdata.PATHS.(upper(inputStr)))
        save(subjectdata.PATHS.(upper(inputStr)), 'connectivity')
        fprintf('done! \n')
    end
end
        


