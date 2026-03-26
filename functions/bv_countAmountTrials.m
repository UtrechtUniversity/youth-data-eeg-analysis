function [trlCount, trlVals] = bv_countAmountTrials(cfg)
% input cfg, with cfg.trl

if ~isfield(cfg,'trl')
    error('cfg.trl not found')
end

trlVals = unique(cfg.trl(:,4));
[trlCount] = histc(cfg.trl(:,4),trlVals);

