function s = bv_stripSummaryOnlyFields(s)
% bv_stripSummaryOnlyFields removes fields that belong in a subject's own
% working data (Subject.mat) but shouldn't be duplicated into the
% aggregate summary (SubjectSummary.mat / SubjectSummary.csv) - e.g.
% because they're large, or redundant bookkeeping rather than something
% worth comparing across subjects.
%
% Works on a scalar subjectdata struct or a subjectdatasummary struct
% array (rmfield handles both identically, since struct arrays share
% field names across all elements).
%
% Use as
%   s = bv_stripSummaryOnlyFields(s)
%
% See also BV_SYNCSUBJECTSUMMARY, BV_UPDATESUBJECTSUMMARY, REMOVINGSUBJECTS

excludeFields = {'filename', 'trialfun', 'cleanSampleInfo'};

present = intersect(fieldnames(s), excludeFields);
if ~isempty(present)
    s = rmfield(s, present);
end
