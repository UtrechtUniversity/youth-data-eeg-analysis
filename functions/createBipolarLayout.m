function layout = createBipolarLayout(labels, layout, layoutname)
% Builds a FieldTrip layout for bipolar channels from a standard layout.
%
% Each bipolar channel position is the midpoint between its two source
% electrodes' positions in the standard layout.
%
% Args:
%     labels (cell array of str): Bipolar channel labels, each formatted
%         as ``'<source1>-<source2>'`` (e.g. ``'Fp2-C4'``). If any label
%         contains ``'EEG'``, the first 4 characters of every label are
%         stripped first (e.g. a leading ``'EEG '`` tag, as produced by
%         ``getNEOChannels('bipolar')``) before splitting on ``'-'``.
%     layout (str): FieldTrip layout identifier (e.g. ``'EEG1020'``)
%         passed to ``ft_prepare_layout`` via ``cfg.layout``, used as the
%         source of standard electrode positions.
%     layoutname (str, optional): If provided, the resulting layout is
%         also written to a FieldTrip ``.lay`` file with this name, saved
%         in the same folder as the built-in layout files.
%
% Returns:
%     layout (struct): Bipolar layout with fields ``label``, ``pos``
%         (midpoint between the two source electrodes per bipolar pair;
%         ``NaN`` for pairs where a source electrode isn't found in the
%         standard layout), ``width``, ``height``, ``outline``, and
%         ``mask``.
%
% Example:
%     ```matlab
%     labels = getNEOChannels('bipolar');
%     layout = createBipolarLayout(labels, 'EEG1020', 'BipolarBrainz');
%     ```

if any(contains(labels, 'EEG'))
    labels2 = cellfun(@(x) x(5:end), labels, 'un',0);
else
    labels2 = labels;
end

cfg = [];
cfg.layout = layout;
cfg.skipcomnt = 'yes';
cfg.skipscale = 'yes';
cfg.feedback = 'no';
standard_lay = ft_prepare_layout(cfg);

lay.pos = nan(length(labels2), 2);
for i = 1:length(labels2)
    clabels = strsplit(labels2{i}, '-');
    idx = find(ismember(standard_lay.label, clabels));
    if length(idx) == 2
        lay.pos(i,:) = sum(standard_lay.pos(idx,:),1)/2;
    end
end

layout = [];
layout.label = labels;
layout.pos = lay.pos;
layout.width = repmat(standard_lay.width(1), 1, length(lay.pos))';
layout.height = repmat(standard_lay.height(1), 1, length(lay.pos))';
layout.outline = standard_lay.outline;
layout.mask = standard_lay.mask;

if nargin == 3
    layoutfolder = fileparts(which('EEG1010.lay'));
    fid = fopen([layoutfolder filesep layoutname '.lay'], 'w');
    width = layout.width(1);
    height = layout.height(1);
    for i = 1:length(layout.pos)
        xpos = layout.pos(i,1);
        ypos = layout.pos(i,2);
        fprintf(fid, '%1.0f %1.6f %1.6f %1.6f %1.6f %s\n', i, xpos, ypos, width, height, layout.label{i});
    end
    fclose(fid);
end
