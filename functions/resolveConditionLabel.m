function label = resolveConditionLabel(code, conditionLabels)
% Resolves a numeric condition code to a display label via conditionLabels
% (a containers.Map from code -> label), falling back to the stringified
% code when unmapped.
%
% Shared by the per-subject metric functions that accept a
% cfg.conditionLabels option (extractROIPower, calculateStrength,
% calculateSWP, calculateQModularity, calculateBetweennessCentrality,
% calculateClusteringWs, calculatePathlengthWs).
%
% Args:
%     code (numeric): Condition code to resolve (a scalar).
%     conditionLabels (containers.Map): Map from condition code (double
%         keys) to label.
%
% Returns:
%     label (str): The mapped label, or ``num2str(code)`` if unmapped.
%
% Example:
%     ```matlab
%     labels = containers.Map('KeyType', 'double', 'ValueType', 'any');
%     labels(129) = 'NonSocial';
%     resolveConditionLabel(129, labels)   % 'NonSocial'
%     resolveConditionLabel(139, labels)   % '139'
%     ```

if isa(conditionLabels, 'containers.Map') && isKey(conditionLabels, code)
    label = conditionLabels(code);
else
    label = num2str(code);
end
end
