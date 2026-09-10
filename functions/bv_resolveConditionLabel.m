function label = bv_resolveConditionLabel(code, conditionLabels)
% Resolves a numeric condition code to a display label via conditionLabels
% (a containers.Map from code -> label), falling back to the stringified
% code when unmapped.
%
% Shared by the per-subject metric functions that accept a
% cfg.conditionLabels option (bv_extractROIPower, bv_calculateStrength,
% bv_calculateSWP, gr_calculateQModularity).
%
% Args:
%     code (numeric): Condition code to resolve.
%     conditionLabels (containers.Map): Map from condition code to label.
%
% Returns:
%     label (str): The mapped label, or ``num2str(code)`` if unmapped.

if isa(conditionLabels, 'containers.Map') && isKey(conditionLabels, code)
    label = conditionLabels(code);
else
    label = num2str(code);
end
end
