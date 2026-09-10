function s = bv_orderSubjectFields(s)
% bv_orderSubjectFields reorders the top-level fields of a subjectdata
% struct (or a subjectdatasummary struct array - orderfields works on
% both identically, since struct arrays share one field order across all
% elements) to match a fixed canonical order.
%
% Any field in the canonical list that isn't present is simply skipped
% (not created). Any field present that isn't in the canonical list is
% appended at the end, in its current relative order - so new fields
% introduced by future pipeline steps show up after the known ones
% instead of erroring or getting silently dropped.
%
% Use as
%   s = bv_orderSubjectFields(s)
%
% See also BV_SAVEDATA, BV_UPDATESUBJECTSUMMARY, BV_CREATESUBJECTFOLDERS_NEWSTRUCT

canonicalOrder = { ...
    'subjectName', 'wave', 'pseudo', ...
    'preprocDate', 'testDate', 'testTime', ...
    'PATHS', 'cfgs', ...
    'removed', 'removedDuring', 'removedReason', ...
    'nTrialsPreproc', 'resampleFs', 'nChannels', ...
    'flaggedChannels', 'flatChannels', 'noisyChannels', 'interpolatedChannels', ...
    'nEpochsArtefact', 'nCleanEpochsArtefact', 'nEpochsPower', 'nCleanEpochsPower', ...
    'refElec', 'refMethod'};

presentFields = fieldnames(s);
orderedPresent = canonicalOrder(ismember(canonicalOrder, presentFields));
extraFields    = presentFields(~ismember(presentFields, canonicalOrder));

s = orderfields(s, [orderedPresent(:); extraFields(:)]);
