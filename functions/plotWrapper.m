resultStr = {'wpli_debiased_alpha1', ...
    'wpli_debiased_alpha2', ...
    'wpli_debiased_beta', ...
    'wpli_debiased_delta', ... 
    'wpli_debiased_gamma', ... 
    'wpli_debiased_theta'};

vars = {'conMatrices'};
saveflag = 1;

for i = 1:length(resultStr)
    
    bv_plotResults(resultStr{i}, vars, saveflag);
%     close all
end



