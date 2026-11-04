function trlCount = bv_showTrialAmount(cfg)
% Prints how many trials there are per condition code in a trl matrix.
%
% Args:
%     cfg.trl (numeric): FieldTrip trial definition, one row per trial:
%         ``[begsample endsample offset code ...]``. The 4th column is
%         taken as the condition/trial code. Without a 4th column only the
%         total number of trials is reported.
%
% Returns:
%     trlCount (numeric): Number of trials per distinct code, as a column
%         vector in ascending order of the code. The total number of
%         trials if ``cfg.trl`` has no 4th column, ``0`` if it is empty.
%
% Example:
%     ```matlab
%     cfg = [];
%     cfg.trl = [1 100 0 129; 101 200 0 139; 201 300 0 129];
%     trlCount = bv_showTrialAmount(cfg);   % [2; 1], for codes 129 and 139
%     ```

if ~isfield(cfg,'trl')
    error('cfg.trl not found')
end

if isempty(cfg.trl)
    trlCount = 0;
    fprintf('\t\t 0 trials\n');
    return
end

if size(cfg.trl, 2) < 4
    trlCount = size(cfg.trl, 1);
    fprintf('\t\t %1.0f trials (cfg.trl has no condition column)\n', trlCount);
    return
end

trlVals = unique(cfg.trl(:,4));
[trlCount] = histc(cfg.trl(:,4),trlVals);

fprintf(repmat('\t\t %1.0f trials with number %1.0f\n',1,length(trlVals)), [trlCount trlVals ]');
