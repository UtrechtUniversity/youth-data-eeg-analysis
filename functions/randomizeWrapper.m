resultStr = {'wpli_debiased_alpha1.mat', ...
    'wpli_debiased_alpha2.mat', ...
    'wpli_debiased_beta.mat', ...
    'wpli_debiased_delta.mat', ... 
    'wpli_debiased_gamma.mat', ... 
    'wpli_debiased_theta.mat'};

for i = 1:length(resultStr)
    disp(resultStr{i})
    fprintf('\t loading ... ')
    load(resultStr{i})
    fprintf('done! \n')
    
    Ws = bv_cleanWsOverSessions(Ws);
    m = size(Ws,4);
    for j = 1:m
        fprintf('\t randomizing networks session %1.0f ... ', j)

        currWs = Ws(:,:,:,j);
%         currWs_thr = double(currWs > 0.1);
        WrandomWeighted(:,:,:,:,j) = bv_randomizeWeightedMatrices(currWs);
    end
    
    fprintf('\t saving to %s ... ', resultStr{i})
    save(resultStr{i}, 'Ws', 'chans' ,'dims', 'freqband', 'subjects','WrandomWeighted')
    fprintf('done! \n')
end
