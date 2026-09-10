function [a, b] = bv_reconcileSubjectFields(a, b)
% bv_reconcileSubjectFields makes two scalar structs share the same set of
% field names at every level of nesting, backfilling whichever side is
% missing a field with a class-appropriate default (see
% BV_DEFAULTLIKEVALUE) inferred from the side that has it.
%
% Only intended for two plain (non-struct-array) scalar structs, or for
% reconciling one struct-valued FIELD of a struct array element at a time
% (e.g. subjectdatasummary(i).cfgs) - never for the struct array itself.
% A struct array requires every element to share identical top-level
% field names, which this function does not enforce; use
% BV_RECONCILESUMMARYARRAY for that (it calls this function for the
% nested part once top-level fields already match).
%
% Use as
%   [a, b] = bv_reconcileSubjectFields(a, b)
%
% See also BV_RECONCILESUMMARYARRAY, BV_DEFAULTLIKEVALUE

aFields = fieldnames(a);
bFields = fieldnames(b);

missingInB = aFields(~ismember(aFields, bFields));
for i = 1:length(missingInB)
    b.(missingInB{i}) = bv_defaultLikeValue(a.(missingInB{i}));
end

missingInA = bFields(~ismember(bFields, aFields));
for i = 1:length(missingInA)
    a.(missingInA{i}) = bv_defaultLikeValue(b.(missingInA{i}));
end

sharedFields = intersect(aFields, bFields);
for i = 1:length(sharedFields)
    f = sharedFields{i};
    if isstruct(a.(f)) && isstruct(b.(f)) && isscalar(a.(f)) && isscalar(b.(f))
        [a.(f), b.(f)] = bv_reconcileSubjectFields(a.(f), b.(f));
    end
end
