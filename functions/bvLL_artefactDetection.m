function [artefactdef, counts] = bvLL_artefactDetection(cfg, data, freq)

% Get options for artefact detection from cfg-file
betaLim     = ft_getopt(cfg, 'betaLim');
gammaLim    = ft_getopt(cfg, 'gammaLim');
varLim      = ft_getopt(cfg, 'varLim');
invVarLim   = ft_getopt(cfg, 'invVarLim');
kurtLim     = ft_getopt(cfg, 'kurtLim');
rangeLim    = ft_getopt(cfg, 'rangeLim');
zScoreLim   = ft_getopt(cfg, 'zScoreLim');
vMaxLim     = ft_getopt(cfg, 'vMaxLim');
flatLim     = ft_getopt(cfg, 'flatLim');
jumpLim     = ft_getopt(cfg, 'jumpLim');

if nargin == 3
    freqFields  = fieldnames(freq);
    field2use   = freqFields{not(cellfun(@isempty, strfind(freqFields, 'spctrm')))};
end
if (~isempty(betaLim) || ~isempty(gammaLim)) && nargin < 3
    error('detecting artefacts based on frequency power, but no frequency input found in function')
end
if nargin < 2
    error('Please input data')
end
if nargin < 1
    error('Please input config file')
end

doStandardArtefacts = 0;
artefactMethods = {};
if ~isempty(betaLim)
    doStandardArtefacts = 1;
    artefactMethods = cat(2, artefactMethods, 'betaPower');
end
if ~isempty(gammaLim)
    doStandardArtefacts = 1;
    artefactMethods = cat(2, artefactMethods, 'gammaPower');
end
if ~isempty(kurtLim)
    doStandardArtefacts = 1;
    artefactMethods = cat(2, artefactMethods, 'kurtosis');
end
if ~isempty(varLim)
    doStandardArtefacts = 1;
    artefactMethods = cat(2, artefactMethods, 'variance');
end
if ~isempty(invVarLim)
    doStandardArtefacts = 1;
    artefactMethods = cat(2, artefactMethods, 'inverseVariance');
end
if ~isempty(rangeLim)
    doStandardArtefacts = 1;
    artefactMethods = cat(2, artefactMethods, 'range');
end
if ~isempty(zScoreLim)
    doStandardArtefacts = 1;
    artefactMethods = cat(2, artefactMethods, 'zScore');
end
if ~isempty(vMaxLim)
    doStandardArtefacts = 1;
    artefactMethods = cat(2, artefactMethods, 'vMax');
end
if ~isempty(flatLim)
    doStandardArtefacts = 1;
    artefactMethods = cat(2, artefactMethods, 'flatline');
end
if ~isempty(jumpLim)
    doStandardArtefacts = 1;
    artefactMethods = cat(2, artefactMethods, 'jumps');
end


badChannels = [];
badTrials = [];
artefactdef.allCounts = [];
fprintf('\t \t Calculating artefact levels ... ')
if doStandardArtefacts
    if ismember('kurtosis', artefactMethods)
        artefactdef.kurtosis.levels = zeros(length(data.label), length(data.trial));
    end
    if ismember('variance', artefactMethods)
        artefactdef.variance.levels = zeros(length(data.label), length(data.trial));
    end
    if ismember('inverseVariance', artefactMethods)
        artefactdef.invvariance.levels = zeros(length(data.label), length(data.trial));
    end
    if ismember('flatline', artefactMethods)
        artefactdef.flatline.levels = zeros(length(data.label), length(data.trial));
    end
    if ismember('range', artefactMethods)
        artefactdef.range.levels = zeros(length(data.label), length(data.trial));
    end
    if ismember('jumps', artefactMethods)
        artefactdef.jumps.levels = zeros(length(data.label), length(data.trial));
    end
    
    artefactdef.nan.levels = zeros(length(data.label), length(data.trial));
    
    for i = 1:length(data.trial)
        if ismember('kurtosis', artefactMethods)
            artefactdef.kurtosis.levels(:,i) = kurtosis(data.trial{i}, [], 2);
        end
        if ismember('variance', artefactMethods)
            artefactdef.variance.levels(:,i) = std(data.trial{i}, [], 2).^2;
        end
        if ismember('inverseVariance', artefactMethods)
            artefactdef.invvariance.levels(:,i) = 1./(std(data.trial{i}, [], 2).^2);
        end
        if ismember('flatline', artefactMethods)
            artefactdef.flatline.levels(:,i) = 1./(abs(max(data.trial{i},[],2) - min(data.trial{i},[],2)));
        end
        if ismember('range', artefactMethods)
            artefactdef.range.levels(:,i) = max(data.trial{i}, [], 2) - min(data.trial{i}, [], 2);
        end
        if ismember('jumps', artefactMethods)
            artefactdef.jumps.levels(:,i) = max(abs(diff(data.trial{i},[],2)), [], 2);
        end
        if ismember('vMax', artefactMethods)
            artefactdef.vMax.levels(:, i) = max(data.trial{i}, [], 2);
            artefactdef.vMin.levels(:, i) = min(data.trial{i}, [], 2);
            artefactdef.vAmp.levels(:, i) = artefactdef.vMax.levels(:, i) - artefactdef.vMin.levels(:, i);
        end
        artefactdef.nan.levels(:,i) = all(isnan(data.trial{i}),2);
        
    end
    
    if ismember('kurtosis', artefactMethods)
        
        [badChannelKurt, badTrialKurt] = find(artefactdef.kurtosis.levels > kurtLim);
        badChannels = [badChannels; badChannelKurt];
        badTrials = [badTrials; badTrialKurt];
        counts.Kurt = hist(badChannelKurt, 1:length(data.label));
        artefactdef.allCounts = [artefactdef.allCounts counts.Kurt'];
        
    end
    if ismember('variance', artefactMethods)
        
        [badChannelVar, badTrialVar] = find(artefactdef.variance.levels > varLim);
        badChannels = [badChannels; badChannelVar];
        badTrials = [badTrials; badTrialVar];
        counts.Var       = hist(badChannelVar, 1:length(data.label));
        artefactdef.allCounts = [artefactdef.allCounts counts.Var'];
        
        
    end
    if ismember('inverseVariance', artefactMethods)
        
        [badChannelInvVar, badTrialInvVar]  = find(artefactdef.invvariance.levels > invVarLim);
        badChannels = [badChannels; badChannelInvVar];
        badTrials = [badTrials; badTrialInvVar];
        counts.InvVar    = hist(badChannelInvVar, 1:length(data.label));
        artefactdef.allCounts = [artefactdef.allCounts counts.InvVar'];
        
    end
    
    if ismember('flatline', artefactMethods)
        
        [badChannelFlat, badTrialFlat]  = find(artefactdef.flatline.levels > flatLim);
        badChannels = [badChannels; badChannelFlat];
        badTrials = [badTrials; badTrialFlat];
        counts.flatline    = hist(badChannelFlat, 1:length(data.label));
        artefactdef.allCounts = [artefactdef.allCounts counts.flatline'];
        
    end
    
    if ismember('range', artefactMethods)
        
        [badChannelRange, badTrialRange]  = find(artefactdef.range.levels > rangeLim);
        badChannels = [badChannels; badChannelRange];
        badTrials = [badTrials; badTrialRange];
        counts.Range    = hist(badChannelRange, 1:length(data.label));
        artefactdef.allCounts = [artefactdef.allCounts counts.Range'];
        
    end
    
    if ismember('jumps', artefactMethods)
        
        [badChannelJumps, badTrialJumps]  = find(artefactdef.jumps.levels > jumpLim);
        badChannels = [badChannels; badChannelJumps];
        badTrials = [badTrials; badTrialJumps];
        counts.jumps = hist(badChannelJumps, 1:length(data.label));
        artefactdef.allCounts = [artefactdef.allCounts counts.jumps'];
        
    end
    
    if ismember('vMax', artefactMethods)
        
        [badChannelVMax, badTrialVMax]  = find(artefactdef.vAmp.levels > vMaxLim);
        badChannels = [badChannels; badChannelVMax];
        badTrials = [badTrials; badTrialVMax];
        counts.vMax = hist(badChannelVMax, 1:length(data.label));
        artefactdef.allCounts = [artefactdef.allCounts counts.vMax'];
    end
    
    [badChannelNan, badTrialNan]  = find(artefactdef.nan.levels == 1);
    badChannels = [badChannels; badChannelNan];
    badTrials = [badTrials; badTrialNan];
    counts.nan = hist(badChannelNan, 1:length(data.label));
    artefactdef.allCounts = [artefactdef.allCounts counts.nan'];
    
end

if doStandardArtefacts
    
    if ismember('betaPower', artefactMethods)
        betaStart   = find(freq.freq == 13);
        betaEnd     = find(freq.freq == 25);
        
        artefactdef.betaPower   = squeeze( mean( freq.(field2use)( :, :, betaStart:betaEnd), 3 ) );
        artefactdef.betaPower   = artefactdef.betaPower';
        
        [badChannelBeta, badTrialBeta]  = find(artefactdef.betaPower > betaLim);
        badChannels                     = [badChannels; badChannelBeta];
        badTrials                       = [badTrials; badTrialBeta];
        counts.Beta                     = hist(badChannelBeta, 1:length(data.label));
        artefactdef.allCounts           = [artefactdef.allCounts counts.Beta'];
        
    end
    if ismember('gammaPower', artefactMethods)
        
        gammaStart  = find(freq.freq == 25);
        gammaEnd    = find(freq.freq == 50);
        
        artefactdef.gammaPower  = squeeze( mean( freq.(field2use)( :, :, gammaStart:gammaEnd), 3 ) );
        artefactdef.gammaPower  = artefactdef.gammaPower';
        
        [badChannelGamma, badTrialGamma]    = find(artefactdef.gammaPower > gammaLim);
        badChannels                         = [badChannels; badChannelGamma];
        badTrials                           = [badTrials; badTrialGamma];
        counts.Gamma                        = hist(badChannelGamma, 1:length(data.label));
        artefactdef.allCounts               = [artefactdef.allCounts counts.Gamma'];
        
    end
    
    if ismember('zScore', artefactMethods)
        betaStart   = find(freq.freq == 13);
        betaEnd     = find(freq.freq == 25);
        gammaStart  = find(freq.freq == 25);
        gammaEnd    = find(freq.freq == 50);
        alphaStart  = find(freq.freq == 6);
        alphaEnd    = find(freq.freq == 13);
        thetaStart  = find(freq.freq == 3);
        thetaEnd    = find(freq.freq == 6);
        deltaStart  = find(freq.freq == 2);
        deltaEnd    = find(freq.freq == 3);
        
        artefactdef.delta.power = squeeze( mean( freq.(field2use)( :, :, deltaStart:deltaEnd), 3 ) )';
        artefactdef.theta.power = squeeze( mean( freq.(field2use)( :, :, thetaStart:thetaEnd), 3 ) )';
        artefactdef.alpha.power = squeeze( mean( freq.(field2use)( :, :, alphaStart:alphaEnd), 3 ) )';
        artefactdef.beta.power  = squeeze( mean( freq.(field2use)( :, :, betaStart:betaEnd), 3 ) )';
        artefactdef.gamma.power = squeeze( mean( freq.(field2use)( :, :, gammaStart:gammaEnd), 3 ) )';
        
        artefactdef.delta.zscore    = zscore(artefactdef.delta.power,[],1);
        artefactdef.theta.zscore    = zscore(artefactdef.theta.power,[],1);
        artefactdef.alpha.zscore    = zscore(artefactdef.alpha.power,[],1);
        artefactdef.beta.zscore     = zscore(artefactdef.beta.power,[],1);
        artefactdef.gamma.zscore    = zscore(artefactdef.gamma.power,[],1);
        
        [badChannelDeltaZscore, badTrialDeltaZscore]  = find(artefactdef.delta.zscore > zScoreLim);
        [badChannelThetaZscore, badTrialThetaZscore]  = find(artefactdef.theta.zscore > zScoreLim);
        [badChannelAlphaZscore, badTrialAlphaZscore]  = find(artefactdef.alpha.zscore > zScoreLim);
        [badChannelBetaZscore,  badTrialBetaZscore]   = find(artefactdef.beta.zscore > zScoreLim);
        [badChannelGammaZscore, badTrialGammaZscore]  = find(artefactdef.gamma.zscore > zScoreLim);
        
        badChannels     = [badChannels; badChannelDeltaZscore; ...
            badChannelThetaZscore; badChannelAlphaZscore; badChannelBetaZscore; ...
            badChannelGammaZscore];
        
        badTrials       = [badTrials; badTrialDeltaZscore; badTrialThetaZscore; ...
            badTrialAlphaZscore; badTrialBetaZscore; badTrialGammaZscore];
        
        counts.deltaZscore  = hist(badChannelDeltaZscore, 1:length(data.label));
        counts.thetaZscore  = hist(badChannelThetaZscore, 1:length(data.label));
        counts.alphaZscore  = hist(badChannelAlphaZscore, 1:length(data.label));
        counts.betaZscore   = hist(badChannelBetaZscore, 1:length(data.label));
        counts.gammaZscore  = hist(badChannelGammaZscore, 1:length(data.label));
        
        artefactdef.allCounts               = [artefactdef.allCounts counts.deltaZscore' ...
            counts.thetaZscore' counts.alphaZscore' counts.betaZscore' ...
            counts.gammaZscore'];
    end
    
end

artefactdef.badPartsMatrix = unique([ badTrials badChannels ], 'rows');

artefactdef.badTrials = unique(badTrials);
artefactdef.goodTrials = 1:length(data.trial);
artefactdef.goodTrials(ismember(artefactdef.goodTrials, artefactdef.badTrials)) = [];

artefactdef.pBadTrialsPerChannel = ceil(((hist(artefactdef.badPartsMatrix(:,2), 1:length(data.label)))./length(data.trial)) .* 100);
artefactdef.sampleinfo = data.sampleinfo(artefactdef.badTrials,:);

fprintf('done \n')
