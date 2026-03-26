function bv_imModules(W, labels)

Wnrm = gr_normalizeW(W);
M = community_louvain(Wnrm);
[~, sortIndx] = sort(M);
figure;
imagesc(Wnrm(sortIndx, sortIndx));
bv_autoCorrSettings(gca, labels(sortIndx))
hold on
modIndx = find(diff(M(sortIndx)));

if length(modIndx) == 1
    warning('No Modules Found')
    return
end

for i = 1:length(modIndx)
    if i == 1
        x = 0.5;
        y = modIndx(1) + 0.5;
    elseif i == length(modIndx)
        x = modIndx(i-1) + 0.5;
        y = size(Wnrm,1) + 0.5;
    else
        x = modIndx(i-1) + 0.5;
        y = modIndx(i) + 0.5;
    end
    plot([x,y], [y,y], 'k', 'LineWidth', 3)
    plot([x,x], [x,y], 'k', 'LineWidth', 3)
    plot([y,y], [x,y], 'k', 'LineWidth', 3)
    plot([x,y], [x,x], 'k', 'LineWidth', 3)
end