function output = randomizeMetric(Ws, metric, edgeType, noPermutations)

m = size(Ws, 3);
n = size(Ws, 1);
Wrnd = cell(1, m);
for i = 1:m
    W = Ws(:,:,i);
    
    % find removed channels
    rmChannels = sum(isnan(W))==(size(W,2) - 1);
    if ~isempty(rmChannels)
        
        W(rmChannels,:) = [];
        W(:,rmChannels) = [];
        
    end
    
    
    if isempty(W)
        Wrnd(:,:,i) = nan(n,n);
        continue
    end
    
    switch edgeType
        case 'weighted'
            for k = 1:noPermutations
                n = size(W,1);
                W(1:n+1:end) = 0;
                weights = squareform(W);
                I = find(weights > 0);
                weights(I) = weights(I(randperm(numel(I))));
                Wrnd = squareform(weights);
                
                switch metric
                    case 'pathlength'
                        L = weight_conversion(Wrnd, 'lengths');
                        Drnd = distance_wei(L);
                        output(i,k) = mean(squareform(Drnd));
                    case 'clustering'
                        Wrnd_nrm = weight_conversion(Wrnd, 'normalize');
                        output(i,k) = mean(clustering_coef_wu(Wrnd_nrm));
                    case 'QModularity'
                        try
                            [~, output(i,k)] = modularity_und(W);
                        catch
                            output(i,k) = NaN;
                        end
                        
                end
                
            end
            
        case 'binary'
            for k = 1:noPermutations
                n = size(W,1);
                W(1:n+1:end) = 0;
                Wrnd = randmio_und(W, 0.8);
                
                switch metric
                    case 'pathlength'
                        Drnd = distance_bin(Wrnd);
                        output(i,k) = mean(squareform(Drnd));
                    case 'clustering'
                        output(i,k) = mean(clustering_coef_bu(Wrnd));
                    case 'QModularity'
                        try
                            [~, output(i,k)] = modularity_und(W);
                        catch
                            output(i,k) = NaN;
                        end
                end
            end
    end
    
end

output = mean(output,2);