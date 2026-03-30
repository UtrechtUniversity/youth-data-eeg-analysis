function bv_createROutput(filestr)

setPaths
subjectDirs = dir(PATHS.SUBJECTS);
subjectDirs = subjectDirs([subjectDirs.isdir] & ~ismember({subjectDirs.name}, {'.', '..'}));
subjectDirs = subjectDirs(~strcmp(fullfile(PATHS.SUBJECTS, {subjectDirs.name}), PATHS.REMOVED));

for i = 1:length(subjectDirs)
    currSubject = subjectDirs(i).name;
    [conn, check] = bv_quickloadData(currSubject, filestr);

    if ~check
        fprintf('\t data not found, skipping')
        continue
    end

    connFields = fields(conn);
    spctrmfield = connFields{contains(connFields, 'spctrm')};

    for j = 1:length(conn.freq)
        dat = conn.(spctrmfield)(:,:,:,j);
        varname = [conn.freq{j} '_CIJs'];

        eval([varname '= dat;']);
    end

    labels = conn.label;

    allVars = who;
    vars2save = cat(1,allVars(~cellfun(@isempty, regexp(allVars, '_CIJs$'))), 'labels');
    filename = [PATHS.SUBJECTS filesep currSubject filesep currSubject ,'_R.mat'];

    save(filename, vars2save{:})
end
