cfg = [];
cfg.layout = 'biosemi32.lay';
cfg.channel = labels;
cfg.feedback ='yes';
cfg.skipcomnt = 'yes';
cfg.skipscale = 'yes';
lay = ft_prepare_layout(cfg);

[~,indx] = ismember(labels, lay.label);

lay.pos = lay.pos(indx,:);
lay.width = lay.width(indx);
lay.height = lay.height(indx);
lay.label = lay.label(indx);
