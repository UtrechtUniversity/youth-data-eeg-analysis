function bv_topoPlotValues(data)

[freq,fd] = bvLL_frequencyanalysis(data, [1 100]);
% output = bv_getFrequencyInfo(data, 0);

cfg = [];
cfg.channel  = fd.label;
cfg.layout   = 'EEG1010';
cfg.feedback = 'no';
cfg.skipcomnt  = 'yes';
cfg.skipscale  = 'yes';
evalc('lay = ft_prepare_layout(cfg);');

[~, indxSort] = ismember(lay.label, fd.label);

% mDat = max(dat);
foi = [1:2:10];

nplots = length(foi);
nyplot = ceil(sqrt(length(foi)));
nxplot = ceil(nplots./nyplot);
figure; 

for i = 1:length(foi)
    [~,indx] = min(abs(fd.freq-foi(i)));
    dat = squeeze(mean(fd.powspctrm(:,:,indx)));
    dat = dat(indxSort);
    
    chanX = lay.pos(:,1);
    chanY = lay.pos(:,2);
    
    opt = {'interpmethod','nearest','interplim','mask','gridscale',67,'outline',lay.outline, ...
        'shading','flat','isolines',6,'mask', lay.mask ,'style','surfiso', 'datmask', []};
    
    subplot(nyplot, nxplot, i)
    ft_plot_topo(chanX,chanY,dat,opt{:});
    colorbar
    axis equal
    axis off
    title(num2str(foi(i)));
end