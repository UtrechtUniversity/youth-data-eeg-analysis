function layout = bv_getLayoutType(hdr)

layoutfolder = fileparts(which('EEG1020.lay'));

% check for biosemi
if contains(hdr.orig.VERSION, 'BIOSEMI')
    labels = hdr.label(ismember(hdr.chantype, 'eeg'));
    biosemi_lays = dir([layoutfolder filesep 'biosemi*']);
    for i = 1:length(biosemi_lays)
        cfg = [];
        cfg.layout = biosemi_lays(i).name;
        cfg.skipcomnt = 'yes';
        cfg.skipscale = 'yes';
        evalc('lay = ft_prepare_layout(cfg);');
        
        if all(contains(labels, lay.label))
            layout = lay;
            return
        end
    end
end

% check for bipolar brainz
if any(contains(hdr.label, 'EEG'))
    if any(contains('-', hdr.label))
        labels = bv_getNEOChannels('bipolar');
        
        evalc('lay = bv_createBipolarLayout(labels, ''EEG1020'', ''BipolarBrainz'');');
        layout = lay;
        return
    else
        oldchk = any(contains(hdr.label, {'T3', 'T4'}));
        if oldchk
            hdr.label{contains(hdr.label,'T3')} = 'EEG T7';
            hdr.label{contains(hdr.label,'T4')} = 'EEG T8';
        end
               
        currlabels = cellfun(@(x) x(5:end), hdr.label, 'un',0);
        
        cfg = [];
        cfg.layout = 'EEG1010';
        cfg.channel = currlabels;
        cfg.skipcomnt = 'yes';
        cfg.skipscale = 'yes';
        evalc('layout = ft_prepare_layout(cfg);');
        layout.channel = hdr.label;
    end
end


        

        