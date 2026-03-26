function bv_comparePowerPlot(cfg)

inputStr    = ft_getopt(cfg, 'inputStr');
outputStr   = ft_getopt(cfg, 'outputStr', 'comparePower');
optionsFcn  = ft_getopt(cfg, 'optionsFcn', 'setOptions');
pathsFcn    = ft_getopt(cfg, 'pathsFcn', 'setPaths');
saveFigures = ft_getopt(cfg, 'saveFigures', 'no');
channel    = ft_getopt(cfg, 'channel', 'all');

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
            
            fig = figure;
            hold on
            for iSession = find(subjectFolderIndx);
                currSubject = nFolders{iSession};
                
                subjectFolderPath = [PATHS.SUBJECTS filesep currSubject];
                
                cfg             = [];
                cfg.inputStr    = inputStr;
                cfg.currSubject = currSubject;
                cfg.channel     = channel;
                
                bv_plotPower(cfg);
            end
            
            title([currSubjectName 'power'])
            legend({'Session 1', 'Session 2'})
            set(gca, 'FontSize', 20)
            
            if strcmpi(saveFigures, 'yes')
                fprintf('\t saving ... ')
                set(gcf, 'Position', get(0, 'Screensize'));
                saveas(gcf, [PATHS.FIGURES filesep currSubjectName '_' outputStr '.png'])
                fprintf('done! \n')
                close all
            end
    end
end

            
                
