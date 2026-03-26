%% randomization check

for h = 1:size(Wrandom,3)
    for i = 1:size(Wrandom,4)
        for j = 1:size(Wrandom,5)
            W = squareform(Ws(:,:,h,j));
            Wrand = squareform(Wrandom(:,:,h,i,j));
            
            W = W(~isnan(W));
            Wrand = Wrand(~isnan(Wrand));
            
            if not(sum(sort(W) == sort(Wrand)) == length(W))
                errorStr = sprintf(['random matrices not the same as original for '  ...
                    'subject %1.0f, randmat: %1.0f, session: %1.0f'], h,i,j);
                
                error(errorStr)
            end
            
            check(h,i,j) = sum(sort(W) == sort(Wrand));
            
        end
    end
end

                