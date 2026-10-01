function val = bv_defaultLikeValue(reference)
% Returns a class-appropriate placeholder value matching reference's class.
%
% Used by BV_RECONCILESUBJECTFIELDS and BV_RECONCILESUMMARYARRAY to
% backfill a field that exists on one side of a subjectdata/SubjectSummary
% merge but not the other, so both sides end up with the same field set.
%
% Args:
%     reference (any): Value whose class determines the placeholder.
%         Recognized classes: ``struct``, ``double``, ``logical``,
%         ``char``, ``cell``. Any other class (e.g. MATLAB's ``string``
%         type, which isn't used anywhere in this codebase) falls back
%         to ``[]``.
%
% Returns:
%     val (any): ``struct`` (scalar, no fields) for ``struct``;
%         ``NaN`` for ``double``; ``false`` for ``logical``; ``''`` for
%         ``char``; ``cell(0)`` for ``cell``; ``[]`` otherwise.
%
% Example:
%     ```matlab
%     val = bv_defaultLikeValue('some string'); % returns ''
%     ```
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
