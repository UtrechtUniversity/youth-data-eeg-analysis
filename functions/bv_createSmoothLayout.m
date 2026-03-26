function bv_createSmoothLayout(labels, grpvector, grplabels, layoutname)

ft_defaults();
layoutfolder = fileparts(which('EEG1010.lay'));
if isempty(layoutfolder)
    error('layout folder for fieldtrip not found')
end

cfg = [];
cfg.layout = 'EEG1010';
cfg.channel = labels;
cfg.feedback = 'no';
cfg.skipcomnt = 'yes';
cfg.skipscale = 'yes';
lay = ft_prepare_layout(cfg);

if ~all(ismember(labels, lay.label))
    error('Labels given not found in EEG1010 layout')
end

fid = fopen([layoutfolder filesep layoutname '.lay'], 'w');
grpNrs = unique(grpvector);
grpNrs(grpNrs==0) = [];
width = lay.width(1);
height = lay.height(1);
for i = 1:length(grpNrs)
    xpos = mean(lay.pos(ismember(lay.label, labels(grpvector == grpNrs(i))),1));
    ypos = mean(lay.pos(ismember(lay.label, labels(grpvector == grpNrs(i))),2));
    fprintf(fid, '%1.0f %1.6f %1.6f %1.6f %1.6f %s\n', i, xpos, ypos, width, height, grplabels{i});
end
fclose(fid);