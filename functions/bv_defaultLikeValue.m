function val = bv_defaultLikeValue(reference)
% bv_defaultLikeValue returns a class-appropriate placeholder value
% (NaN/''/{}/struct) matching the class of reference, used whenever a
% field exists on one side of a subjectdata/SubjectSummary merge but not
% the other.
%
% Use as
%   val = bv_defaultLikeValue(reference)
%
% See also BV_RECONCILESUBJECTFIELDS, BV_RECONCILESUMMARYARRAY

switch class(reference)
    case 'struct'
        val = struct;
    case 'double'
        val = NaN;
    case 'logical'
        val = false;
    case 'char'
        val = '';
    case 'cell'
        val = cell(0);
    otherwise
        val = [];
end
