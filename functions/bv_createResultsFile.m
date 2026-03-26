function bv_createResultsFile(cfg)

inputStr    = ft_getopt(cfg, 'inputStr');
optionsFcn  = ft_getopt(cfg, 'optionsFcn', 'setOptions');
pathsFcn    = ft_getopt(cfg, 'pathsFcn', 'setPaths');

eval(optionsFcn)
eval(pathsFcn)

folders = dir([PATHS.SUBJECTS filesep '*' OPTIONS.sDirString '*']);
nFolders = {folders.name};
subjectNames = cellfun(@(v) v(1:5), nFolders, 'Un', 0);
subjectNames = unique(subjectNames);
noSubject = 0;

for i = 1:length(subjectNames);
    currSubjectName = subjectNames{i};
    disp(currSubjectName)
    
    subjectFolderIndx = not(cellfun(@isempty, strfind(nFolders, currSubjectName)));
    switch sum(subjectFolderIndx)
        case 2
            
            noSession = 0;
            noSubject = noSubject + 1;
            sessionsFound = 0;
            for iSession = find(subjectFolderIndx);
                
                noSession = noSession + 1;
                
                subjectFolderPath = [PATHS.SUBJECTS filesep nFolders{iSession}];
                
                try
                    [subjectdata, connectivity] = bv_check4data(subjectFolderPath, inputStr);
                    sessionsFound = sessionsFound + 1;
                catch
                    fprintf('\t session not found, skipping complete subject \n')
                    noSubject = noSubject - 1;
                    continue
                end
                fnames = fieldnames(connectivity);
                spctrmname = fnames(not(cellfun(@isempty, strfind(fnames, 'spctrm'))));
                subjWs(:,:,:, noSession) =  connectivity.(spctrmname{:});
                subjtrials(noSession) = length(connectivity.trialinfo);
                
            end
            
            if sessionsFound == 2;
                Ws(:,:,:,noSubject,:) = subjWs;
                subjects{noSubject} = currSubjectName;
                ntrls(noSubject,:) = subjtrials;
            end
            
            
        otherwise
            fprintf('\t %1.0f session(s) found, skipping ... \n', ...
                sum(subjectFolderIndx))
            continue
    end
    
end
dims = 'chan_chan_freq_subj_ses';
chans = connectivity.label;
% subjects = subjectNames;
freq = connectivity.freq;
date = datetime('now');
wpliflag = 0;
if contains(lower(inputStr), {'coh', 'wpli'})
    wpliflag = 1;
end
if wpliflag
    fprintf('saving results file ... ')
    save([PATHS.RESULTS filesep lower(inputStr) '.mat'],'-v7.3', 'Ws', ...
        'dims', 'subjects', 'freq','chans', 'date', 'ntrls')
    fprintf('done! \n')
else
    freqRng = connectivity.freqRng;
    fprintf('saving results file ... ')
    save([PATHS.RESULTS filesep lower(inputStr) '.mat'],'-v7.3', 'Ws', ...
        'dims', 'subjects', 'freq', 'freqRng', 'chans', 'date', 'ntrls')
    fprintf('done! \n')
end
