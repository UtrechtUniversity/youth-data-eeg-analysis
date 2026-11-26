function [subjectdatasummary, subjectdata] = reconcileSummaryArray(subjectdatasummary, subjectdata)
% Makes a subjectdata struct and a subjectdatasummary struct array
% share field names.
%
% Aligns subjectdata with every element of the subjectdatasummary struct
% array, both at the top level and inside nested struct fields (e.g.
% ``cfgs``, ``PATHS``), so that a later whole-element assignment
% (``subjectdatasummary(idx) = subjectdata``) or a struct2table
% conversion doesn't fail with "Subscripted assignment between dissimilar
% structures."
%
% This uses two different mechanisms, because MATLAB struct arrays only
% allow one of them at a time:
%   1) Top-level fields: every element of a struct array must share
%      identical top-level field names at all times. A field can only be
%      added array-wide, via the classic
%      ``[subjectdatasummary(1:end).newfield] = deal(default)`` idiom -
%      assigning a struct with an extra top-level field into a single
%      element fails immediately, because every *other* element still
%      lacks that field.
%   2) Nested fields (inside struct-valued fields like cfgs/PATHS, which
%      pick up different sub-fields per subject depending on which
%      pipeline steps that subject reached): these are reconciled once
%      the top-level fields already match, via
%      RECONCILESUBJECTFIELDS, assigning into one element's nested
%      field at a time (``subjectdatasummary(i).cfgs = ...``). That is
%      NOT a whole-element replacement, so - unlike (1) - it carries no
%      array-wide consistency requirement.
%
% Note: the nested fields are reconciled in a single pass over the
% elements, so each row is only backfilled with the nested fields known at
% the moment it is visited. This leaves all rows consistent as long as
% the existing rows already agree with each other, which holds when rows
% are only ever added through this function (as CREATESUBJECTRESULTS
% and UPDATESUBJECTSUMMARY do).
%
% If subjectdatasummary is empty there is nothing to reconcile against,
% so it is returned as an empty array carrying subjectdata's fields. The
% caller can then append subjectdata right away.
%
% Args:
%     subjectdatasummary (struct array): Existing summary rows, one per
%         subject.
%     subjectdata (struct): Scalar struct for one subject.
%
% Returns:
%     subjectdatasummary (struct array): The same rows, plus every
%         top-level field that only ``subjectdata`` had (filled with a
%         class-appropriate default, see DEFAULTLIKEVALUE), with
%         nested fields backfilled.
%     subjectdata (struct): ``subjectdata``, plus every top-level field
%         that only the summary rows had (filled with a default), with
%         nested fields backfilled.
%
% Example:
%     ```matlab
%     [subjectdatasummary, subjectdata] = reconcileSummaryArray(subjectdatasummary, subjectdata);
%     subjectdatasummary(end+1) = subjectdata;
%     ```

if isempty(subjectdatasummary)
    subjectdatasummary = subjectdata(1:0);
    return
end

arrayFields   = fieldnames(subjectdatasummary);
subjectFields = fieldnames(subjectdata);

newForArray = setdiff(subjectFields, arrayFields);
for i = 1:numel(newForArray)
    f = newForArray{i};
    [subjectdatasummary(1:end).(f)] = deal(defaultLikeValue(subjectdata.(f)));
end

newForSubject = setdiff(arrayFields, subjectFields);
for i = 1:numel(newForSubject)
    f = newForSubject{i};
    subjectdata.(f) = defaultLikeValue(subjectdatasummary(1).(f));
end

topFields = fieldnames(subjectdata);
for i = 1:numel(subjectdatasummary)
    for k = 1:numel(topFields)
        f = topFields{k};
        if isstruct(subjectdata.(f)) && isscalar(subjectdata.(f)) && ...
                isstruct(subjectdatasummary(i).(f)) && isscalar(subjectdatasummary(i).(f))
            [subjectdata.(f), subjectdatasummary(i).(f)] = ...
                reconcileSubjectFields(subjectdata.(f), subjectdatasummary(i).(f));
        end
    end
end
