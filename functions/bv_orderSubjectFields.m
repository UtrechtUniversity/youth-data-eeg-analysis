function s = bv_orderSubjectFields(s)
% Reorders the top-level fields of a subjectdata struct to a canonical order.
%
% Works equally on a scalar subjectdata struct or a subjectdatasummary
% struct array (orderfields works on both identically, since struct
% arrays share one field order across all elements).
%
% Args:
%     s (struct): subjectdata struct, or subjectdatasummary struct array.
%
% Returns:
%     s (struct): Same struct(s), with top-level fields reordered to
%         match the canonical order below. Any canonical field that
%         isn't present is simply skipped (not created). Any field
%         present that isn't in the canonical list - e.g. a field a newer
%         pipeline step writes that hasn't been added here yet - is
%         appended at the end, in its current relative order, instead of
%         erroring or getting silently dropped.
%
% Example:
%     ```matlab
%     subjectdata = bv_orderSubjectFields(subjectdata);
%     ```

canonicalOrder = { ...
    'subjectName', 'wave', 'pseudo', ...
    'preprocDate', 'testDate', 'testTime', ...
    'PATHS', 'cfgs', ...
    'removed', 'removedDuring', 'removedReason', ...
    'nTrialsPreproc', 'resampleFs', 'nChannels', ...
    'flaggedChannels', 'flatChannels', 'noisyChannels', 'interpolatedChannels', ...
    'nEpochsArtefact', 'nCleanEpochsArtefact', 'nEpochsPower', 'nCleanEpochsPower', 'nEpochsPLI', 'nCleanEpochsPLI', ...
    'refElec', 'refMethod'};

presentFields = fieldnames(s);
orderedPresent = canonicalOrder(ismember(canonicalOrder, presentFields));
extraFields    = presentFields(~ismember(presentFields, canonicalOrder));

s = orderfields(s, [orderedPresent(:); extraFields(:)]);
