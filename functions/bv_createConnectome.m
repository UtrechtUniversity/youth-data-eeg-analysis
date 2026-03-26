function bv_createConnectome(W, chans)

cfg = [];
cfg.layout = 'EEG1010';
cfg.channel = chans;
cfg.skipcomnt = 'yes';
cfg.skipscale = 'yes';
lay = ft_prepare_layout(cfg);

plot(lay.pos(:,1), lay.pos(:,2), '.', 'MarkerSize', 10)
hold on


W = W ./ max(W(:));
[x,y]=find(W>0.9);

for i = 1:length(x)

    line(lay.pos([x(i) y(i)],1), lay.pos([x(i) y(i)],2), 'LineWidth', W(x(i),y(i)), 'color', 'red')
    
end