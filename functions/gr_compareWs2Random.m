function gr_compareWs2Random(Ws, WsRandom, edgeType)

WsRandom2Use = WsRandom;
Ws2Use = Ws;

for i = 1:size(WsRandom2Use,4)
    currWs1 = squeeze(WsRandom2Use(:,:,:,i,1));
    currWs2 = squeeze(WsRandom2Use(:,:,:,i,2));
    
    Cs1 = calculateClusteringWs(currWs1, edgeType);
    Cs2 = calculateClusteringWs(currWs2, edgeType);
    
    C_bothsessions = [Cs1' Cs2'];
    C_bothsessions = C_bothsessions(~any(isnan(C_bothsessions),2),:);
    
    rC_ICC(i) = ICC(C_bothsessions, '1-k');
    rC_r(i) = corr(C_bothsessions(:,1), C_bothsessions(:,2));
    
    Ls1 = calculatePathlengthWs(currWs1, edgeType);
    Ls2 = calculatePathlengthWs(currWs2, edgeType);
    
    L_bothsessions = [Ls1' Ls2'];
    L_bothsessions = L_bothsessions(~any(isinf(L_bothsessions),2),:);
    L_bothsessions = L_bothsessions(~any(isnan(L_bothsessions),2),:);

    rL_ICC(i) = ICC(L_bothsessions, '1-k');
    rL_r(i) = corr(L_bothsessions(:,1), L_bothsessions(:,2));

    Qs1 = calculateQModularityWs(currWs1, 10);
    Qs2 = calculateQModularityWs(currWs2, 10);
    
    Q_bothsessions = [Qs1 Qs2];
    Q_bothsessions = Q_bothsessions(~any(isnan(Q_bothsessions),2),:);
    
    rQ_ICC(i) = ICC(Q_bothsessions, '1-k');
    rQ_r(i) = corr(Q_bothsessions(:,1), Q_bothsessions(:,2));

    strength1 = calculateStrengthWs(currWs1);
    strength2 = calculateStrengthWs(currWs2);
    
    strength_bothsessions = [strength1', strength2'];
    strength_bothsessions = strength_bothsessions(~any(isnan(strength_bothsessions),2),:);
    
    rStrength_ICC(i) = ICC(strength_bothsessions, '1-k');
    rStrength_r(i) = corr(strength_bothsessions(:,1), strength_bothsessions(:,2));

    fprintf('%1.0f \n', i)
end

Wsingle1 = Ws2Use(:,:,:,1);
Wsingle2 = Ws2Use(:,:,:,2);

C_ses1 = calculateClusteringWs(Wsingle1, edgeType);
C_ses2 = calculateClusteringWs(Wsingle2, edgeType);

C = [C_ses1' C_ses2'];
C = C(~any(isnan(C),2),:);

C_ICC = ICC(C, '1-k');
C_r = corr(C(:,1), C(:,2));

L_ses1 = calculatePathlengthWs(Wsingle1, edgeType);
L_ses2 = calculatePathlengthWs(Wsingle2, edgeType);

L = [L_ses1' L_ses2'];
L = L(~any(isinf(L),2),:);
L = L(~any(isnan(L),2),:);

L_ICC = ICC(L, '1-k');
L_r = corr(L(:,1), L(:,2));

Q1 = calculateQModularityWs(Wsingle1, 10);
Q2 = calculateQModularityWs(Wsingle2, 10);

Q = [Q1 Q2];
Q = Q(~any(isnan(Q),2),:);

Q_ICC = ICC(Q, '1-k');
Q_r = corr(Q(:,1), Q(:,2));

str1 = calculateStrengthWs(Wsingle1);
str2 = calculateStrengthWs(Wsingle2);

strength = [str1', str2'];
strength = strength(~any(isnan(strength),2),:);

strength_ICC = ICC(strength_bothsessions, '1-k');
strength_r = corr(strength(:,1), strength(:,2));

figure; bar(rC_ICC)
set(gca, 'XLim', [0 length(rC_ICC) + 1])
set(gca, 'YLim', [0 1])
hold on 
plot([0 length(rC_ICC) + 1], repmat(C_ICC, 1, 2) ,'r', 'LineWidth',1)

figure; bar(rL_ICC)
set(gca, 'XLim', [0 length(rL_ICC) + 1])
set(gca, 'YLim', [0 1])
hold on 
plot([0 length(rL_ICC) + 1], repmat(L_ICC, 1, 2) ,'r', 'LineWidth',1)

figure; bar(rQ_ICC)
set(gca, 'XLim', [0 length(rQ_ICC) + 1])
set(gca, 'YLim', [0 1])
hold on 
plot([0 length(rQ_ICC) + 1], repmat(Q_ICC, 1, 2) ,'r', 'LineWidth',1)

figure; bar(rStrength_ICC)
set(gca, 'XLim', [0 length(rStrength_ICC) + 1])
set(gca, 'YLim', [0 1])
hold on 
plot([0 length(rStrength_ICC) + 1], repmat(strength_ICC, 1, 2) ,'r', 'LineWidth',1)
