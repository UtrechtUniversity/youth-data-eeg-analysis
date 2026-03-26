function T = bv_addArtefactLevels2ResultsTable(T, artifactStr)

eval('setPaths')
eval('setOptions')

for i = 1:height(T)
    cSubject = T.subjectName{i};
    path2subjectfolder = [PATHS.SUBJECTS filesep cSubject];
    disp(cSubject)
    try
        [~, artifactdef] = bv_check4data(path2subjectfolder, artifactStr);
    catch
        warning('No data found for subject %s\n', cSubject)
        continue;
    end
    
    fprintf('adding artifact data to table ... ')
    artfcFields = fieldnames(artifactdef);
    for j = 1:length(artfcFields)
        if isa(artifactdef.(artfcFields{j}), 'struct')
            T.([artfcFields{j} '_' lower(artifactStr)]){i} = artifactdef.(artfcFields{j}).levels;
        end

    end
    fprintf('done! \n')
end