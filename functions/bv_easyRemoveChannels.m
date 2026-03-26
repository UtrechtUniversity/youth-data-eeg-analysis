function data = bv_easyRemoveChannels(subjectStr, inputStr, chans2remove)

eval('setPaths')
eval('setOptions')

if not(iscell(chans2remove))
    tmpChan = chans2remove;
    chans2remove = cell(1);
    chans2remove{1} = tmpChan;
end

try
    [subjectdata, data] = bv_check4data([PATHS.SUBJECTS filesep subjectStr], inputStr);
catch
    error('Data for given subjectstring not found')
    return
end

disp(subjectdata.subjectName)

if isfield(subjectdata, 'rmChannels')
    allRmChannels = unique(cat(1,subjectdata.rmChannels, chans2remove));
    if length(allRmChannels) > OPTIONS.maxbadchans
        cfg = [];
        removingSubjects(cfg, subjectdata.subjectName, 'Too many channels removed')
        return
    end 
    subjectdata.rmChannels = allRmChannels;
else
    subjectdata.rmChannels = chans2remove;
end

cfg = [];
cfg.layout = 'biosemi32.lay';
cfg.channel = 'all';
cfg.feedback = 'no';
cfg.skipcomnt = 'yes';
cfg.skipscale = 'yes';
evalc('lay = ft_prepare_layout(cfg, data);');

cfg = [];
cfg.method          = 'distance';
cfg.neighbourdist   = 0.25;
cfg.template        = 'biosemi32.lay';
cfg.layout          = lay;
cfg.channel         = 'all';
cfg.feedback        = 'no';
cfg.skipcomnt       = 'yes';
cfg.skipscale       = 'yes';
evalc('neighbours = ft_prepare_neighbours(cfg, data);');

cfg = [];
cfg.badchannel = chans2remove;
cfg.method = 'weighted';
cfg.neighbours = neighbours;
cfg.channel = 'all';
cfg.layout = lay;
evalc('data = ft_channelrepair(cfg, data);');


bv_saveData(subjectdata, data, inputStr)
bv_updateSubjectSummary([PATHS.SUMMARY filesep 'SubjectSummary.mat'], subjectdata)