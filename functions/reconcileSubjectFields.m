function [a, b] = reconcileSubjectFields(a, b)
% Makes two scalar structs share the same field names, backfilling gaps.
%
% A field that exists on only one side is added to the other side with a
% class-appropriate default (see DEFAULTLIKEVALUE) inferred from the
% side that has it. Fields that exist on both sides and hold scalar
% structs on both (e.g. ``cfgs``, ``PATHS``) are reconciled recursively.
%
% Only intended for two plain scalar structs, or for reconciling one
% struct-valued FIELD of a struct array element at a time (e.g.
% ``subjectdatasummary(i).cfgs``) - never for the struct array itself. A
% struct array requires every element to share identical top-level field
% names, which this function does not enforce; use
% RECONCILESUMMARYARRAY for that (it calls this function for the
% nested part once the top-level fields already match).
%
% Note: a struct-valued field that exists on only one side is backfilled
% on the other side with an empty placeholder struct (no fields), and is
% not recursed into during the same call, so below that point the two
% sides can still differ. They get aligned the next time the two are
% reconciled, once the field exists on both sides.
%
% Args:
%     a (struct): First scalar struct.
%     b (struct): Second scalar struct.
%
% Returns:
%     a (struct): ``a``, plus every field that only ``b`` had.
%     b (struct): ``b``, plus every field that only ``a`` had.
%
% Example:
%     ```matlab
%     a.x = 1;       a.cfg.p = 'yes';
%     b.y = 'text';  b.cfg.q = 2;
%     [a, b] = reconcileSubjectFields(a, b);
%     % a and b now both have x, y and cfg; a.cfg and b.cfg both have p and q
%     ```

if ~(isstruct(a) && isstruct(b) && isscalar(a) && isscalar(b))
    error('reconcileSubjectFields:notScalarStructs', ...
        ['Both inputs must be scalar structs. To reconcile a struct array ' ...
        'use reconcileSummaryArray.'])
end

aFields = fieldnames(a);
bFields = fieldnames(b);

missingInB = aFields(~ismember(aFields, bFields));
for i = 1:length(missingInB)
    b.(missingInB{i}) = defaultLikeValue(a.(missingInB{i}));
end

missingInA = bFields(~ismember(bFields, aFields));
for i = 1:length(missingInA)
    a.(missingInA{i}) = defaultLikeValue(b.(missingInA{i}));
end

sharedFields = intersect(aFields, bFields);
for i = 1:length(sharedFields)
    f = sharedFields{i};
    if isstruct(a.(f)) && isstruct(b.(f)) && isscalar(a.(f)) && isscalar(b.(f))
        [a.(f), b.(f)] = reconcileSubjectFields(a.(f), b.(f));
    end
end
