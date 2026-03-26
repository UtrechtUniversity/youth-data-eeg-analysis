function varargout = bv_randomizeMetric(randWs, metrics)

if ~iscell(metrics)
    metrics = {metrics};
end

k = size(randWs,4);
n = length(metrics);

counter = 0;
for j = 1:n
    currMetric = metrics{j};
    for i = 1:k
        counter = counter + 1;
        lng = printPercDone(n*k, counter);
        currRandW = randWs(:,:,:,i);
        
        switch currMetric
            
            case 'CPL'
                output{j}(:,i) = gr_calculatePathlengthWs(randWs, 'weighted');
                
                
            case 'CC'
                output{j}(:,i) = gr_calculateClusteringWs(randWs, 'weighted');

        end
        fprintf(repmat('\b', 1, lng))
    end
    
    varargout{j} = mean(output{j},2);
end

