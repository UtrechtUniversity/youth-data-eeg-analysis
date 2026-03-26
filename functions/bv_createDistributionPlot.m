function bv_createDistributionPlot(table, grouping, yvar)

addpath('~/MatlabToolboxes/distributionPlot/')
yvarNames = table.Properties.VariableNames(contains(table.Properties.VariableNames, yvar));
C = {'b','r','g','y','b','r','g','y'};

% figure;
hold on
nvars = length(yvarNames);
for i = 1:nvars
    currYVar = bv_prepareForMPlus(table, grouping, yvarNames{i});
    currYVar(isoutlier(currYVar)) = NaN;
    for j = 1:size(currYVar,2)
        distributionPlot(currYVar(:,j), 'showMM',0,'color', C{j}, 'xValues', i)
        alpha(0.2)
    end
    
    currLabel = yvarNames{i};
    currLabel = strrep(currLabel, '_', '-');
    set(gca, 'XTick', i, 'XTickLabel', currLabel)

end
set(gca, 'XTick', 1:length(strrep(yvarNames, '_', '-')), 'XTickLabel', strrep(yvarNames, '_', '-'))