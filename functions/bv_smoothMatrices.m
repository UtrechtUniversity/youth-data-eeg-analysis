load('corrMatrices_pli_alpha.mat');

for i = 1:size(allSubjectResults.corrMatrices, 3);
    W = allSubjectResults.corrMatrices(:,:,i);
    
    frontal = {'Fp1', 'Fp2', 'AF3', 'AF4', 'F3', 'Fz', 'F4'};
    occipital = {'P3', 'Pz', 'P4', 'PO3', 'PO4', 'O1', 'Oz', 'O2'};
    central = {'FC1', 'FC2', 'C3', 'Cz', 'C4', 'CP1', 'CP2'};
    left = {'F7', 'FC5', 'T7', 'CP5', 'P7'};
    right = {'F8', 'FC6', 'T8', 'CP6', 'P8'};
    
    labels = dataClean.label;
    
    frontalIndx = ismember(labels, frontal);
    occipitalIndx = ismember(labels, occipital);
    centralIndx = ismember(labels, central);
    leftIndx = ismember(labels, left);
    rightIndx = ismember(labels, right);
    
    W_front_occ = W(frontalIndx,:);
    W_front_occ = W_front_occ(:,occipitalIndx);
    
    W_front_central =  W(frontalIndx,:);
    W_front_central =  W_front_central(:,centralIndx);
    
    W_front_left =  W(frontalIndx,:);
    W_front_left =  W_front_left(:,leftIndx);
    
    W_front_right =  W(frontalIndx,:);
    W_front_right =  W_front_right(:,rightIndx);
    
    W_occ_central = W(occipitalIndx,:);
    W_occ_central = W_occ_central(:,centralIndx);
    
    W_occ_left = W(occipitalIndx,:);
    W_occ_left = W_occ_left(:,leftIndx);
    
    W_occ_right = W(occipitalIndx,:);
    W_occ_right = W_occ_right(:,rightIndx);
    
    W_central_left = W(centralIndx,:);
    W_central_left = W_central_left(:,leftIndx);
    
    W_central_right = W(centralIndx,:);
    W_central_right = W_central_right(:,rightIndx);
    
    W_left_right = W(leftIndx,:);
    W_left_right = W_left_right(:,rightIndx);
    
    allW = [nanmean(W_front_occ(:)) nanmean(W_front_central(:)) nanmean(W_front_left(:)) ...
        nanmean(W_front_right(:)) nanmean(W_occ_central(:)) nanmean(W_occ_left(:)) ...
        nanmean(W_occ_right(:)) nanmean(W_central_left(:)) nanmean(W_central_right(:)) ...
        nanmean(W_left_right(:))];
    
    Ws(:,:,i) = squareform(allW);
    
end

figure;
imagesc(Ws(:,:,1))
set(gca, 'XTick', 1:size(Ws,2), 'XTickLabel', ...
    {'frontal', 'occipital', 'central', 'left', 'right'})
set(gca, 'YTick', 1:size(Ws,2), 'YTickLabel', ...
    {'frontal', 'occipital', 'central', 'left', 'right'})


Ws1 = Ws(:,:,1:4:end);
Ws2 = Ws(:,:,3:4:end);
R = correlateMultipleWs(Ws1, Ws2);
figure; bar(R)
title('correlation between unsmoothed connectivity matrices, Session1 vs Session 2')
set(gca, 'XTick', 1:size(Ws1,3))