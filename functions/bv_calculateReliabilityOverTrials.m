function [ICCout, ICCout_CI, N, vTrls] = bv_calculateReliabilityOverTrials(T, groupvar, var2group)

pliPerSes = bv_prepareForMPlus(T, groupvar, var2group);
pliPerSes(any(cellfun(@isempty,pliPerSes),2),:) = [];
trlsPerSes = cellfun(@(x) size(x,3), pliPerSes);
[~,indx] = sort(mean(trlsPerSes,2), 'descend');
trlMax = min(min(trlsPerSes(indx(1:2), :)));
vTrls = 2:trlMax;

fprintf('\t preparing variable for given triallength ... ')
str = zeros(length(vTrls), size(pliPerSes,1), size(pliPerSes,2), size(pliPerSes{1},4));
counter = 0;
for i = 1:length(vTrls)
    
    counter = counter + 1;
    lng = printPercDone(length(vTrls), counter);
    plisel = all(trlsPerSes>=vTrls(i),2);
    currPliPerSes = pliPerSes(plisel,:);
    N(i) = size(currPliPerSes,1);
    
    for j = 1:N(i)
        for k = 1:size(pliPerSes,2)
            currWs = squeeze(mean(currPliPerSes{j,k}(:,:,datasample(1:size(currPliPerSes{j,k},3),vTrls(i), 'Replace', false),:),3));
            str(i,j,k,:) = squeeze(mean(mean(currWs),2));            
        end
    end
    
    fprintf(repmat('\b', 1, lng))
    
end
fprintf('done! \n')

fprintf('\t calculating ICC for given triallength ... ')
str(str==0) = NaN;
counter = 0;
ICCout = zeros(size(str,1), size(str,4));
ICCout_CI = zeros(size(str,1), size(str,4), 2);
for i = 1:size(str,1)
    for j = 1:size(str,4)
        counter = counter + 1;
        lng = printPercDone(size(str,1)*size(str,4), counter);
        currStr = squeeze(str(i,:,:,j));
        currStr(any(isnan(currStr),2),:) = [];
        ICCout(i,j) = ICC(currStr, '1-k');
        bootstat = bootstrp(1000,@(x) ICC(x, '1-k'), currStr);
        ICCout_CI(i,j,:) = prctile(bootstat, [2.5, 97.5]);        
        fprintf(repmat('\b', 1, lng))
    end
end
fprintf('done! \n')
