clear all
str = 'coh5';

a = dir([str '_*.mat']);
resultStr = {a.name};

inputData = 'weighted';
randomflag = 0;

if strfind(inputData, 'Random') > 0
    randomflag = 1;
end

for i = 1:length(resultStr)
    disp(resultStr{i})
    fprintf('\t loading ... ')
    load(resultStr{i})
    fprintf('done! \n')
    if exist('ICCresults', 'var')
        if isfield(ICCresults, inputData)
            ICCresults = rmfield(ICCresults, inputData);
        end
    end
    
    metrics = fieldnames(graphResults.(inputData));
    metrics = metrics(cellfun(@isempty, strfind(metrics, 'thresholds')));
    metrics = metrics(cellfun(@isempty, strfind(metrics, 'degree')));
    for j = 1:length(metrics)
        currMetricName = metrics{j};
        currMetric = real(graphResults.(inputData).(currMetricName));

        if strcmpi(currMetricName, 'degree')
            for iN = 1:size(currMetric,1)
                fprintf('\t \t calculate ICC ... ')
                cThresh = squeeze(currMetric(iN,:,:));
                cThresh = cThresh(~any(isnan(cThresh),2),:);
                cThresh = cThresh(~any(isinf(cThresh),2),:);
                output(iN) =  ICC(cThresh, '1-k');
                fprintf('done! \n')
                
                fprintf('\t \t bootstrapping for CI ... ')
                bootstat = bootstrp(10000,@(x) ICC(x, '1-k'), cThresh);
                
                CI(iN,1)  = prctile(bootstat, 2.5);
                CI(iN,2)  = prctile(bootstat, 97.5);
                fprintf('done! \n')
            end
            
        else
            fprintf('\t %s \n', currMetricName)
            clear output CI
            for iT = 1:size(currMetric,3)
                
                if ~randomflag
                    
                    cThresh = squeeze(currMetric(:,:,iT));
                    
                    fprintf('\t \t calculate ICC ... ')
                    cThresh = cThresh(~any(isnan(cThresh),2),:);
                    cThresh = cThresh(~any(isinf(cThresh),2),:);
                    output(iT) = ICC(cThresh, '1-k');
                    fprintf('done! \n')
                    
                    fprintf('\t \t bootstrapping for CI ... ')
                    bootstat = bootstrp(10000,@(x) ICC(x, '1-k'), cThresh);
                    
                    CI(iT,1)  = prctile(bootstat, 2.5);
                    CI(iT,2)  = prctile(bootstat, 97.5);
                    fprintf('done! \n')
                    
                else
                    
                    for k = 1:size(currMetric,2)
                        tmp = squeeze(currMetric(:,k,:));
                        tmp = tmp(~any(isnan(tmp),2),:);
                        tmp = tmp(~any(isinf(tmp),2),:);
                        output(k,iT) = ICC(tmp, '1-k');
                    end
                    
                end
            end
        end
        ICCresults.(inputData).(currMetricName) = output;
        ICCresults.(inputData).([currMetricName '_CI']) = CI;

    end
    fprintf('\t saving to %s ... ', resultStr{i})
    save(resultStr{i}, 'ICCresults', '-append')
    fprintf('done! \n')
end
