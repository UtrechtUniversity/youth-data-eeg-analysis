function fig = bv_plotConnDistr(Ws, subjNr)

fig = figure; hold on
y = subjNr;
maxData = 0;
for i = 1:length(y);
    
    W1 = Ws(:,:,y(i),1);
    W2 = Ws(:,:,y(i),2);
    
    x = -0.2:0.1:1;
    a1 = hist(squareform(W1), x);
    a2 = hist(squareform(W2), x);
    
    a1nrm = a1/sum(a1);
    a2nrm = a2/sum(a2);
    
    col = 0.1 + i*0.2;
    
    plot(x, [a1nrm; a2nrm], 'LineWidth', 3, 'color', [col col col])
    subjectName{i} = ['subj' num2str(i)];
    maxData = max([maxData max(max([a1nrm; a2nrm]))]);
    
end

h = findobj(gca,'Type','line');
legend(h(1:2:end), subjectName, 'FontSize', 20)
set(gca, 'XLim', [-0.3 1.1], 'YLim', [-0.1 maxData+0.1])
legend('boxoff')
hold off
