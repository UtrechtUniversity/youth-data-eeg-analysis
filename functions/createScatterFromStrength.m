Ws = allSubjectResults.corrMatrices(:,:,:,1);

autismIndx = find(ismember(allSubjectResults.session, 'autism'));
controlIndx = find(ismember(allSubjectResults.session, 'control'));

for iW = 1:size(Ws,3)
    currW = Ws(:,:,iW);
    strength(iW) = mean(squareform(currW));
end

strength_autism_control = [strength(controlIndx)'; strength(autismIndx)'];

X = [ones(length(strength(controlIndx)),1); ones(length(strength(autismIndx)),1).*2];
Y = strength_autism_control;

scatter(X,Y)
set(gca, 'XLim', [0 3], 'YLim', [0.2 0.3])
