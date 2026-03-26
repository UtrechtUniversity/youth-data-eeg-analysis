clear all
str = 'wpli_debiased5_alpha1';

a = dir([ str '.mat']);
resultStr = {a.name};

method = {'unitwise75'};

if strcmp(method{:}, 'all')
    method = {'cleanSessions', 'conMatrixCor', 'corrCorrMatrix', ...
        'corrGroupAvg', 'scanwise', 'globConn', 'globCoV', 'globConnICC', ...
        'unitwise', 'unitwise75', 'degrees'};
end

for i = 1:length(resultStr)
    disp(resultStr{i})
    fprintf('\t loading ... ')
    load(resultStr{i})
    fprintf('done! \n')

    for iMethod = 1:length(method)
        currMethod = method{iMethod};
        switch(currMethod)
            case 'cleanSessions'
                fprintf('\t cleaning data over sessions \n')
                Ws = bv_cleanWsOverSessions(Ws);
                fprintf('\t saving newly cleaned Ws to %s', resultStr{i})
                save(resultStr{i}, 'Ws', '-append')
                fprintf('done! \n')

            case 'conMatrixCor'
                fprintf('\t calculating correlation between connectivity matrices \n')
                Ws1 = Ws(:,:,:,1);
                Ws2 = Ws(:,:,:,2);
                indivCorrs(i,:) = correlateMultipleWs(Ws1, Ws2);
                results.conMatrices = indivCorrs(i,:);
                fprintf('\t adding variable to %s ... ', resultStr{i})
                save(resultStr{i}, 'results', '-append')
                fprintf('done! \n')

            case 'conMatrixCor75'
                fprintf(['\t calculating correlation between connectivity ' ...
                            'matrices with only strongest connections \n'])
                avgW = nanmean(nanmean(Ws,3),4);
                newWs = Ws.*(repmat(double(avgW>prctile(squareform(avgW),75)), 1,1,60,2));
                newWs(newWs == 0) = NaN;
                Ws1 = newWs(:,:,:,1);
                Ws2 = newWs(:,:,:,2);
                indivCorrs75(i,:) = correlateMultipleWs(Ws1, Ws2);
                results.conMatrices75 = indivCorrs75(i,:);
                fprintf('\t adding variable to %s ... ', resultStr{i})
                save(resultStr{i}, 'results', '-append')
                fprintf('done! \n')

            case 'corrCorrMatrix'
                fprintf('\t creating correlation between all connectivity matrices matrix \n')

                WsNeat = zeros([size(Ws,1) size(Ws,2) size(Ws,3)*size(Ws,4)]);

                WsNeat(:,:,1:2:end) = Ws(:,:,:,1);
                WsNeat(:,:,2:2:end) = Ws(:,:,:,2);

                results.corrCorrMatrix = createCorrCorrMatrix(WsNeat);
                fprintf('\t adding variable to %s ... ', resultStr{i})
                save(resultStr{i}, 'results', '-append')
                fprintf('done! \n')

            case 'corrGroupAvg'
                fprintf('\t correlating group averaged connectivity matrices \n')

                W1 = nanmean(Ws(:,:,:,1),3);
                W2 = nanmean(Ws(:,:,:,2),3);

                results.avgW1 = W1;
                results.avgW2 = W2;

                rGrpAvg(i) = correlateMatrices(W1, W2);

                results.rGrpAvg = rGrpAvg(i);

                fprintf('\t saving to %s ... ', resultStr{i})
                save(resultStr{i}, 'results', '-append')
                fprintf('done! \n')
            case 'scanwise'
                fprintf('\t calculating scanwise reliability ... ')
                results.r_scanwise = bv_scanwiseICC(Ws);
                fprintf('done! \n')

                fprintf('\t saving to %s ... ', resultStr{i})
                save(resultStr{i}, 'results', '-append')
                fprintf('done! \n')

            case 'unitwise'
                fprintf('\t calculating unitwise reliability ... ')

                pc = 0;
                results.r_unitwise = bv_unitwiseICC(Ws, pc);
                results.mr_unitwise = nanmedian(results.r_unitwise);
                fprintf('done! \n')

                fprintf('\t saving to %s ... ', resultStr{i})
                save(resultStr{i}, 'results', '-append')
                fprintf('done! \n')

            case 'unitwise75'
                fprintf('\t calculating top 25 perc unitwise reliability ... ')
                pc = 75;
                results.r_unitwise75 = bv_unitwiseICC(Ws, pc);
                results.mr_unitwise75 = nanmedian(results.r_unitwise75);
                fprintf('done! \n')

                fprintf('\t saving to %s ... ', resultStr{i})
                save(resultStr{i}, 'results', '-append')
                fprintf('done! \n')

            case 'globConn'
                fprintf('\t calculating global connectivity ... ')

                if isfield(results, 'globConn')
                    results = rmfield(results, 'globConn');
                end

                for iWs = 1:size(Ws,3)
                    for jWs = 1:size(Ws,4)
                        results.globConn(iWs, jWs) = nanmean(squareform(Ws(:,:,iWs, jWs)));
                    end
                end
                
                fprintf('done! \n')

                fprintf('\t saving to %s ... ', resultStr{i})
                save(resultStr{i}, 'results', '-append')
                fprintf('done! \n')

            case 'globCoV'
                fprintf('\t calculating CoV on global connectivity ... ')
                results.cov = calculateCoV(results.globConn(:,1));
                bootstat = bootstrp(10000,@calculateCoV, results.globConn(:,1));

                results.cov_CI(1) = prctile(bootstat, 2.5);
                results.cov_CI(2)  = prctile(bootstat, 97.5);

                fprintf('done! \n')

                fprintf('\t saving to %s ... ', resultStr{i})
                save(resultStr{i}, 'results', '-append')
                fprintf('done! \n')

            case 'globConnICC'
                fprintf('\t calculating global connectivity ICC ... ')
                results.globICC     = ICC(results.globConn, '1-k');
                fprintf('done! \n')

                fprintf('\t bootstrapping to calculate CI ... ')
                bootstat = bootstrp(10000,@(x) ICC(x, '1-k'), results.globConn);

                results.globICC_CI(1)  = prctile(bootstat, 2.5);
                results.globICC_CI(2)  = prctile(bootstat, 97.5);
                fprintf('done! \n')

                fprintf('\t saving to %s ... ', resultStr{i})
                save(resultStr{i}, 'results', '-append')
                fprintf('done! \n')
            case 'degrees'
                fprintf('\t calculting degree for averaged connectivity matrices ... ')
                results.degAvgW1 = strengths_und(results.avgW1);
                results.degAvgW2 = strengths_und(results.avgW2);
                fprintf('done! \n')

                fprintf('\t saving to %s ... ', resultStr{i})
                save(resultStr{i}, 'results', '-append')
                fprintf('done! \n')

            case 'correlateStrongestMatrices'
                avgW = squeeze(mean(mean(Ws,3),4));
                avgWStrong = double(avgW > prctile(squareform(avgW),75));

                WsStrong = Ws.*repmat(avgWStrong, 1,1, 39,2);
                WsStrong(WsStrong == 0) = NaN;

                R = correlateMultipleWs(WsStrong(:,:,:,1), WsStrong(:,:,:,2));

                results.conMatrices75 = R;

                fprintf('\t saving to %s ... ', resultStr{i})
                save(resultStr{i}, 'results', '-append')
                fprintf('done! \n')

            case 'randomizeWeightedNetworks'
                if exist('Wrandom', 'var')
                    clear Wrandom
                end

                m = size(Ws,4);
                for j = 1:m
                    fprintf('\t randomizing networks session %1.0f ... ', j)

                    currWs = Ws(:,:,:,j);
                    %         currWs_thr = double(currWs > 0.1);
                    Wrandom(:,:,:,:,j) = bv_randomizeWeightedMatrices(currWs, 100);
                end

                fprintf('\t saving to %s ... ', resultStr{i})
                save(resultStr{i}, 'Wrandom', '-append')
                fprintf('done! \n')


            case 'randomizeBinaryNetworks'
                if exist('Brandom', 'var')
                    clear Brandom
                end

                m = size(Ws,4);
                for j = 1:m

                    fprintf('\t randomizing networks session %1.0f ... ', j)

                    currWs = Ws(:,:,:,j);
                    nans = isnan(currWs);
                    currWs_thr = double(currWs > 0.15);
                    BrandMat = bv_randomizeBinaryMatrices(currWs_thr, 100);
                    BrandMat(nans) = NaN;
                    Brandom(:,:,:,:,j) = BrandMat;

                end

                fprintf('\t saving to %s ... ', resultStr{i})
                save(resultStr{i}, 'Brandom', '-append')
                fprintf('done! \n')

            otherwise
                error('Unknown method')
        end
    end
end
