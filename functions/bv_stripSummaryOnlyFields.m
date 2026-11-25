function s = bv_stripSummaryOnlyFields(s)
% Removes the fields that belong in Subject.mat but not in the summary.
%
% Some fields belong in a subject's own working data (Subject.mat) but
% shouldn't be duplicated into the aggregate summary (SubjectSummary.mat /
% SubjectSummary.csv), e.g. because they are large, or redundant
% bookkeeping rather than something worth comparing across subjects:
% ``rawFiles`` (the per-file details), ``trialfun``, ``cleanSampleInfo``
% and ``cleanSampleInfoPower``. To keep another field
% out of the summary, add it to ``excludeFields`` below.
%
% Works on a scalar subjectdata struct or a subjectdatasummary struct array
% (rmfield handles both identically, since struct arrays share field names
% across all elements). Fields that are not present are ignored.
%
% Args:
%     s (struct): subjectdata struct, or subjectdatasummary struct array.
%
% Returns:
%     s (struct): ``s`` without the summary-only fields.
%
% Example:
%     ```matlab
%     subjectdata = bv_stripSummaryOnlyFields(subjectdata);
%     ```

if ~isstruct(s)
    error('bv_stripSummaryOnlyFields:notAStruct', ...
        'Input must be a struct, got %s (e.g. from a subject without Subject.mat)', class(s))
end

excludeFields = {'rawFiles', 'trialfun', 'cleanSampleInfo', 'cleanSampleInfoPower'};

present = intersect(fieldnames(s), excludeFields);
if ~isempty(present)
    s = rmfield(s, present);
end
