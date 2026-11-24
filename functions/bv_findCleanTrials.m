function [goodTrialIndx, badTrial] = bv_findCleanTrials(artefactdef, lims)
% Finds the trials whose artefact levels stay within all limits.
%
% A trial is noisy if, for any channel and any metric in ``lims``, its level
% is above the limit.
%
% Args:
%     artefactdef (struct): Artefact struct from BV_CREATEARTEFACTSTRUCT.
%         Must hold ``artefactdef.<metric>.levels`` (channel x trial) for
%         every field of ``lims``.
%     lims (struct): One field per artefact metric (``kurtosis``,
%         ``variance``, ``jump``, ``abs``, ``range``, ``flatline``), each
%         the number above which a trial is discarded.
%
% Returns:
%     goodTrialIndx (numeric): Row vector with the indices of the trials
%         within all limits.
%     badTrial (logical): Row vector, one entry per trial, true for the
%         trials above any limit.
%
% Example:
%     ```matlab
%     lims = struct('kurtosis', 10, 'abs', 250);
%     [good, bad] = bv_findCleanTrials(artefactdef, lims);
%     ```

limFields = fieldnames(lims);
badTrial  = false(1, size(artefactdef.(limFields{1}).levels, 2));
for i = 1:length(limFields)
    cField   = limFields{i};
    badTrial = badTrial | any(artefactdef.(cField).levels > lims.(cField), 1);
end
goodTrialIndx = find(~badTrial);
end
