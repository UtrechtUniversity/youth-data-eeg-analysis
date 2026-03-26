function [Zi, h] = topoplotWrapper(dat, lay, lim) 
addpath('~/MatlabToolboxes/Colormaps/')

if nargin < 3
    lim = [min(dat), max(dat)];
end

chanX = lay.pos(:,1);
chanY = lay.pos(:,2);

opt = {'interpmethod','v4','interplim','mask','gridscale',1000,'outline',lay.outline, ...
    'shading','flat','isolines',10,'mask', lay.mask ,'style','isofill', 'conv', 'on', 'datmask', [], ...
    'clim', lim};

[Zi, h] = ft_plot_topo(chanX,chanY,dat,opt{:});

% evalc('chanlocs = readlocs(''~/MatlabToolboxes/eeglab14_1_2b/plugins/dipfit2.3/standard_BESA/standard-10-5-cap385.elp'');');
% 
% [~, order] = ismember(lay.label, {chanlocs.labels});
% 
% % figure;
% [h,Zi] = topoplot(dat, chanlocs(order), 'colormap', colormap('parula'), 'plotdisk', 'on', 'style', 'both', 'conv', 'on', 'gridscale', 1000, 'electrodes','labelpoint', 'maplimits', lim );

set(gca, 'CLim', lim)
colorbar
colormap plasma

axis equal
axis off