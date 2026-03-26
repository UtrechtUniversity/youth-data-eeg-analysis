function [data, nxt]  = bv_quickVisualCheck(inputStr, startSubject)

if nargin < 2
    startSubject = '';
end

eval('setPaths')
eval('setOptions')

subjectdirflags = dir([PATHS.SUBJECTS filesep '*' OPTIONS.sDirString '*']);
subjectdirnames = {subjectdirflags.name};

if isempty(startSubject)
    startSubject = 1;
else
    startSubject = find(ismember(subjectdirnames, startSubject));
end

for iSubject = startSubject:length(subjectdirnames)
    currSubject = subjectdirnames{iSubject};
    data = bv_quickloadData(currSubject, inputStr);
    
    cfg = [];
    cfg.lpfreq = 45;
    cfg.hpfreq = 1;
    evalc('dataFilt = bv_filterEEGdata(cfg, data);');
    
    cfg = [];
    cfg.viewmode = 'vertical';
    cfg.ylim = [-80 80];
    cfg.blocksize = 30;
    cfg.continuous = 'yes';

    evalc('ft_databrowser(cfg, dataFilt);');
    
    mp = get(0, 'MonitorPosition');
    figPos = mp(size(mp,1),:);
    figPos = [figPos(1)+figPos(3)/2 figPos(2) figPos(3)/2 figPos(4)];
    set(gcf, 'Position', figPos);
    
    while 1
        dataCorrect = input('Data in order? [Yy/Nn]', 's');
        
        if strcmpi(dataCorrect, 'y')
            close all
            break
        elseif strcmpi(dataCorrect, 'n')
            nxt = subjectdirnames{iSubject+1};
            return
        else
            fprintf('unknown response\n')
        end
    end
end
