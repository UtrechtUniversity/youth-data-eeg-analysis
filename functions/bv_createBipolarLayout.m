function layout = bv_createBipolarLayout(labels, layout, layoutname)

if any(contains(labels, 'EEG'))
    labels2 = cellfun(@(x) x(5:end), labels, 'un',0);
end

cfg = [];
cfg.layout = layout;
cfg.skipcomnt = 'yes';
cfg.skipscale = 'yes';
cfg.feedback = 'no';
standard_lay = ft_prepare_layout(cfg);

for i = 1:length(labels2)
    clabels = strsplit(labels2{i}, '-');
    idx = find(ismember(standard_lay.label, clabels));
    if length(idx) == 2
        lay.pos(i,:) = sum(standard_lay.pos(idx,:),1)/2;
    else
        lay.pos(i,:) = NaN;
    end
end

layout = [];
layout.label = labels;
layout.pos = lay.pos;
layout.width = repmat(standard_lay.width(1), 1, length(lay.pos))';
layout.height = repmat(standard_lay.width(1), 1, length(lay.pos))';
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
