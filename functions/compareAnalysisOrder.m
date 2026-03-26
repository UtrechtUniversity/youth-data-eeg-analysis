load('10274B_appended.mat');
triallength = 20;

dataAppend = data;

cfg = [];
cfg.lpfilter    = 'yes';
cfg.lpfreq      = 12;
cfg.hpfilter    = 'yes';
cfg.hpfreq      = 9;
evalc('dataAppendFilt  = ft_preprocessing(cfg, dataAppend);');

cfg = [];
cfg.triallength = triallength;
dataAppendFiltCut = bv_cutAppendedIntoTrials(cfg, dataAppendFilt);

cfg = [];
cfg.triallength = triallength;
dataAppendCut   = bv_cutAppendedIntoTrials(cfg, dataAppend);

cfg = [];
cfg.lpfilter    = 'yes';
cfg.lpfreq      = 12;
cfg.hpfilter    = 'yes';
cfg.hpfreq      = 9;
evalc('dataAppendCutFilt = ft_preprocessing(cfg, dataAppendCut);');

PLIsFiltThenCut = PLI(dataAppendFiltCut.trial, 1);
PLIsCutThenFilt = PLI(dataAppendCutFilt.trial, 1);

WsFiltThenCut = cat(3, PLIsFiltThenCut{:});
WsCutThenFilt = cat(3, PLIsCutThenFilt{:});

W_FTC = squeeze(mean(WsFiltThenCut,3));
W_CTF = squeeze(mean(WsCutThenFilt,3));

figure(1)
subplot(1,2,1)
imagesc(W_FTC)
setAutoLimits(gca)
axis square
colorbar
colormap viridis
title('Filter then Cut')

subplot(1,2,2)
imagesc(W_CTF)
setAutoLimits(gca)
axis square
colorbar
colormap viridis

title('Cut then Filter')

figure(2)
scatter(squareform(W_FTC), squareform(W_CTF))
R = corr([squareform(W_FTC); squareform(W_CTF)]')
title(['R^2 = ' num2str(R(2))])





