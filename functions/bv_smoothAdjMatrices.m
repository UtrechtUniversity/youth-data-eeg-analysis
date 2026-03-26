function smoothAs = bv_smoothAdjMatrices(As, grpvector)

grpNrs = unique(grpvector);
grpNrs(grpNrs==0) = [];
for i = 1:length(grpNrs)
    for j = 1:length(grpNrs)
        allConns = As(grpvector == grpNrs(i), grpvector == grpNrs(j),:);
        allConns(allConns==0) = NaN;
        smoothAs(i,j,:) = squeeze(nanmean(nanmean(allConns,1),2)); 
    end
end


    
        

