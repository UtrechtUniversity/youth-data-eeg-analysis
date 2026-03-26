function mst = calculateMSTs(Ws)

for i = 1:size(Ws,3)
    W = Ws(:,:,i);
    
    rmChannels = (nansum(W) == 0);
    if ~isempty(rmChannels)
        
        W(rmChannels,:) = [];
        W(:,rmChannels) = [];
        
    end
    
    W( W<0 ) = 0;
    W( W>0 ) = 1 ./ W( W>0 );
    currMst = squareform(squareform(full(graphminspantree(sparse(W)))));
    
    if ~isempty(rmChannels)
        iChans = find(rmChannels);
        for j = 1:length(iChans)
            k = iChans(j);
            
            if k <= size(currMst,1)
                b = nan(1,size(currMst,2));
                currMst = [currMst(1:k,:); b; currMst(k+1:end,:)];
                c = nan(size(currMst,1),1);
                currMst = [currMst(:,1:k), c, currMst(:,k+1:end)];
            else
                b = nan(1,size(currMst,2));
                currMst(end+1,:) = b;
                c = nan(size(currMst,1),1);
                currMst(:,end+1) = c;

            end
        end
    end
    
    mst(:,:,i) = currMst;
end