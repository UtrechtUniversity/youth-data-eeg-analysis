function [Ss, Cs, Ls] = gr_calculateSmallWorldnessHumphries(As, threshold)
addpath('~/MatlabToolboxes/SmallWorldNess/')

m = size(As, 3);
FLAG_Cws = 1;

[Ss, Cs, Ls] = deal(zeros(1,m));
for i = 1:m
    A = As(:,:,i);
    A = double(threshold_proportional(A, threshold)>0);
    
    % find removed channels
    rmChannels = sum(isnan(A)) == 31;
    if any(rmChannels)
        
        A(rmChannels,:) = [];
        A(:,rmChannels) = [];
        
    end
           
    k = sum(A);
    n = size(A,1);  % number of nodes
    K = mean(k); % mean degree of network
    
    [CR, LR] = ER_Expected_L_C(K,n);
    
    D = distance_bin(A);  % returns Distance matrix of all pairwise distances
    L = mean(D(:));  % mean shortest path-length: including self-loops
    
    C = clustering_coef_bu(A);  % vector of each node's C_ws
    C = mean(C);
    
    Ls(i) = L / LR;
    Cs(i) =  C / CR;
    Ss(i) = Cs(i) / Ls(i);
    
end