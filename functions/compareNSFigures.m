str = 's-vs-ns';

files = dir(['*' str '*']);
fileNames = {files.name};

for i = 1:length(fileNames)
    load(fileNames{i})
    
    splitfile = strsplit(fileNames{i}, '_');
    frq = splitfile{3};
    disp(frq)
    
    W1 = squeeze(nanmean(Ws(:,:,:,1,1),3));
    W2 = squeeze(nanmean(Ws(:,:,:,1,2),3));
    
%     fprintf('\t creating connectivity plots ... ')
%     figure;
%     
%     subplot(1,2,1)
%     imagesc(W1)
%     setAutoLimits(gca)
%     axis square
%     title([frq '-' conditions{1}])
%     
%     subplot(1,2,2)
%     imagesc(W2)
%     setAutoLimits(gca)
%     axis square
%     title([frq '-' conditions{2}])
%     
%     fprintf('done! \n')
%     
%     fprintf('\t creating scatter plots ... ')
%     figure;
%     scatter(squareform(W1), squareform(W2))
%     axis square
%     r = correlateMatrices(W1, W2);
%     title(['R^2 = ' num2str(r.^2)])
%     fprintf('done! \n')
    
    fprintf('\t creating average topoplots ... ')
    figure;
    subplot(1,2,1)
    evalc('bv_plotDataOnTopoplot(W1, chans, 0.15)');
    title([frq '-' conditions{1}])
    subplot(1,2,2)
    evalc('bv_plotDataOnTopoplot(W2, chans, 0.15)');
    title([frq '-' conditions{2}])
    fprintf('done! \n')
    
end
