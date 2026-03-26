function plotConnectivityMatrix(W, chans)

figure; imagesc(W)
setTick(chans)
setAutoLimits(gcf)
colormap hot
colorbar