function plotWs(Ws)

for i = 1:size(Ws,3)
    figure;
    
    for j = 1:size(Ws,4)
        subplot(2,1,j)
        imagesc(Ws(:,:,i,j))
        setAutoLimits(gca)
        colorbar
        colormap hot
    end
end