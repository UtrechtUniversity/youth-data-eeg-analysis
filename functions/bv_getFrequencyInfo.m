function output = bv_getFrequencyInfo(data, trials)

if trials
    cfg = [];
    cfg.length = 5;
    cfg.overlap = 0;
    data = ft_redefinetrial(cfg, data);
end

freq = bvLL_frequencyanalysis(data, [1 100]);
deltaFoi = [1 4];
thetaFoi = [4 6];
alphaFoi = [7 13];
betaFoi = [14 30];
gamma1Foi = [31 50];
gamma2Foi = [51 99];

for i = 1:2
    [~, deltaIndx(i)] = min(abs(freq.freq - deltaFoi(i)));
    [~, thetaIndx(i)] = min(abs(freq.freq - thetaFoi(i)));
    [~, alphaIndx(i)] = min(abs(freq.freq - alphaFoi(i)));
    [~, betaIndx(i)] = min(abs(freq.freq - betaFoi(i)));
    [~, gamma1Indx(i)] = min(abs(freq.freq - gamma1Foi(i)));
    [~, gamma2Indx(i)] = min(abs(freq.freq - gamma2Foi(i)));
end

output.label = freq.label;
output.power.avg = mean(freq.powspctrm,2);
output.power.delta = mean(freq.powspctrm(:,deltaIndx(1):deltaIndx(2)),2);
output.power.theta = mean(freq.powspctrm(:,thetaIndx(1):thetaIndx(2)),2);
output.power.alpha = mean(freq.powspctrm(:,alphaIndx(1):alphaIndx(2)),2);
output.power.beta = mean(freq.powspctrm(:,betaIndx(1):betaIndx(2)),2);
output.power.gamma1 = mean(freq.powspctrm(:,gamma1Indx(1):gamma1Indx(2)),2);
output.power.gamma2 = mean(freq.powspctrm(:,gamma2Indx(1):gamma2Indx(2)),2);