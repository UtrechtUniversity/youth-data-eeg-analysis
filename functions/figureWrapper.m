resultStr = {'wpli_debiased_delta.mat',...
    'wpli_debiased_theta.mat', ...
    'wpli_debiased_alpha1.mat', ...
    'wpli_debiased_alpha2.mat', ...
    'wpli_debiased_beta.mat', ...
    'wpli_debiased_gamma.mat', };

figureStr = 'conMatrixCor';

for i = 1:length(resultStr)
    disp(resultStr{i})
    fprintf('\t loading ... ')
    load(resultStr{i})
    fprintf('done! \n')
    
    switch(figureStr)
        case '