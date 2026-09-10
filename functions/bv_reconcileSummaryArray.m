function [subjectdatasummary, subjectdata] = bv_reconcileSummaryArray(subjectdatasummary, subjectdata)
% bv_reconcileSummaryArray makes subjectdata and every element of the
% subjectdatasummary struct array share the same set of field names, at
% every level of nesting, so that a later whole-element assignment
% (subjectdatasummary(idx) = subjectdata) or a struct2table conversion
% doesn't fail with "Subscripted assignment between dissimilar
% structures."
%
% This needs two different mechanisms, because MATLAB struct arrays only
% allow one of them:
%   1) TOP-LEVEL fields: every element of a struct array must share
%      identical top-level field names at all times. A field can only be
%      added array-wide, via the classic
%      [subjectdatasummary(1:end).newfield] = deal(default) idiom -
%      assigning a struct with an extra top-level field into a single
%      element fails immediately, because every *other* element still
%      lacks that field.
%   2) NESTED fields (inside struct-valued fields like cfgs/PATHS, which
%      pick up different sub-fields per subject depending on which
%      pipeline steps that subject reached): these are reconciled once
%      top-level fields already match, via BV_RECONCILESUBJECTFIELDS,
%      assigning into one element's nested field at a time
%      (subjectdatasummary(i).cfgs = ...). That is NOT a whole-element
%      replacement, so - unlike (1) - it carries no array-wide
%      consistency requirement or processing-order constraint.
%
% Use as
%   [subjectdatasummary, subjectdata] = bv_reconcileSummaryArray(subjectdatasummary, subjectdata)
%
% See also BV_RECONCILESUBJECTFIELDS, BV_UPDATESUBJECTSUMMARY, BV_CREATESUBJECTRESULTS

arrayFields   = fieldnames(subjectdatasummary);
subjectFields = fieldnames(subjectdata);

newForArray = setdiff(subjectFields, arrayFields);
for i = 1:numel(newForArray)
    f = newForArray{i};
    [subjectdatasummary(1:end).(f)] = deal(bv_defaultLikeValue(subjectdata.(f)));
end

newForSubject = setdiff(arrayFields, subjectFields);
for i = 1:numel(newForSubject)
    f = newForSubject{i};
    subjectdata.(f) = bv_defaultLikeValue(subjectdatasummary(1).(f));
end

topFields = fieldnames(subjectdata);
for i = 1:numel(subjectdatasummary)
    for k = 1:numel(topFields)
        f = topFields{k};
        if isstruct(subjectdata.(f)) && isscalar(subjectdata.(f)) && ...
                isstruct(subjectdatasummary(i).(f)) && isscalar(subjectdatasummary(i).(f))
            [subjectdata.(f), subjectdatasummary(i).(f)] = ...
                bv_reconcileSubjectFields(subjectdata.(f), subjectdatasummary(i).(f));
        end
    end
end
