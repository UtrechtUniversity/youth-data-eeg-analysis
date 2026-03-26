function trlCount = bv_showTrialAmount(cfg)
% input cfg, with cfg.trl

if ~isfield(cfg,'trl')
    error('cfg.trl not found')
end

trlVals = unique(cfg.trl(:,4));
[trlCount] = histc(cfg.trl(:,4),trlVals);

fprintf(repmat('\t\t %1.0f trials with number %1.0f\n',1,length(trlVals)), [trlCount trlVals ]');
