function layout = bv_getLayoutType(hdr)
% Determines the FieldTrip channel layout matching a header's channels.
%
% Tries, in order: (1) a bundled BioSemi ``.lay`` template whose channel
% labels fully cover the header's EEG channels (for BioSemi-recorded
% data, detected via ``hdr.orig.VERSION``), (2) BV_CREATEBIPOLARLAYOUT
% for bipolar montages (channel labels containing a hyphen, e.g.
% ``'EEG Fp2-C4'``), (3) a standard EEG1010 layout for regular
% single-electrode montages (channel labels prefixed with ``'EEG '``,
% e.g. ``'EEG Fp1'``).
%
% Args:
%     hdr (struct): FieldTrip header structure (e.g. from
%         ``ft_read_header``), with ``hdr.label`` (channel labels) and
%         ``hdr.chantype``. For BioSemi detection, also needs
%         ``hdr.orig.VERSION``.
%
% Returns:
%     layout (struct): FieldTrip layout structure for the header's
%         channels (plus a non-standard ``channel`` field recording the
%         original, unstripped channel labels, for the EEG1010 case).
%
% Example:
%     ```matlab
%     hdr = ft_read_header(hdrfile);
%     layout = bv_getLayoutType(hdr);
%     ```

layoutfolder = fileparts(which('EEG1020.lay'));

% check for biosemi
isBiosemi = isfield(hdr, 'orig') && isfield(hdr.orig, 'VERSION') && ...
    contains(hdr.orig.VERSION, 'BIOSEMI');
if isBiosemi
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
    error('bv_getLayoutType:noBiosemiMatch', ...
        ['BioSemi header detected (hdr.orig.VERSION contains ''BIOSEMI''), ' ...
        'but no bundled biosemi*.lay template in %s covers all of its EEG ' ...
        'channels.'], layoutfolder)
end

% check for bipolar brainz
if any(contains(hdr.label, 'EEG'))
    if any(contains(hdr.label, '-'))
        labels = bv_getNEOChannels('bipolar');

        evalc('lay = bv_createBipolarLayout(labels, ''EEG1020'', ''BipolarBrainz'');');
        layout = lay;
        return
    else
        idxT3 = find(contains(hdr.label, 'T3'));
        idxT4 = find(contains(hdr.label, 'T4'));
        hdr.label(idxT3) = {'EEG T7'};
        hdr.label(idxT4) = {'EEG T8'};

        hasPrefix = startsWith(hdr.label, 'EEG');
        currlabels = hdr.label;
        currlabels(hasPrefix) = cellfun(@(x) x(5:end), currlabels(hasPrefix), 'un', 0);

        cfg = [];
        cfg.layout = 'EEG1010';
        cfg.channel = currlabels;
        cfg.skipcomnt = 'yes';
        cfg.skipscale = 'yes';
        evalc('layout = ft_prepare_layout(cfg);');
        layout.channel = hdr.label;
        return
    end
end

error('bv_getLayoutType:unrecognizedHeader', ...
    ['Could not determine a channel layout for this header: it is not ' ...
    'BioSemi-formatted (no hdr.orig.VERSION containing ''BIOSEMI'') and ' ...
    'none of hdr.label contains ''EEG''.'])
