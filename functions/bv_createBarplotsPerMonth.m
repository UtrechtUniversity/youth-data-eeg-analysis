function bv_createBarplotsPerMonth(table, monthvar, yvar)
addpath('~/MatlabToolboxes/superbar/superbar/')
months2use = [4 5 6 9 10 11];
[g_months, monthstr] = findgroups(table.(monthvar));
yvarNames = table.Properties.VariableNames(contains(table.Properties.VariableNames, yvar));

figure;
nvars = length(yvarNames);
counter = 0;
for i = 2:3
    counter = counter + 1;

    subplot(1, 2, counter)
%     currYVar = table.(yvarNames{i});
%     currYVar(find(isoutlier(currYVar))) = NaN;
%     mVar = splitapply(@nanmean, currYVar, g_months);
%     mVar(not(ismember(monthstr, months2use))) = NaN;
%     seVar = splitapply(@(x) 2.*nanstd(x)/sqrt(length(x)), currYVar, g_months);
%     seVar(not(ismember(monthstr, months2use))) = NaN;
%     sdVar = splitapply(@nanstd, currYVar, g_months);
%     sdVar = max(sdVar);
    var = bv_prepareForMPlus(table, 'ageInMonths', yvarNames{i});
    var(isoutlier(var)) = NaN;
    var(:,not(ismember(monthstr, months2use))) = NaN;
    distributionPlot(var, 'XValues', monthstr);
%     superbar(monthstr, mVar, 'E', seVar)
    
%     set(gca, 'YLim', [min(mVar) - sdVar, max(mVar) + sdVar])
    set(gca, 'XTick', [4 5 6 9 10 11], 'XTickLabel', [4 5 6 9 10 11])
    xlabel('Age (in months)')
    set(gca, 'FontSize', 20)
    title(strrep(yvarNames{i}, '_', '-'), 'FontSize', 30)
    set(gca, 'XLim',[3 12])
%     currYVar(isoutlier(currYVar)) = NaN;
%     plot(xpergroup', currYVar', '-', 'color', [0.5 0.5 0.5 0.1])
%     hold on
%     scatter(xpergroup(:), currYVar(:), '.','MarkerFaceColor', [0 0 0], ...
%         'MarkerEdgeColor', [0 0 0], 'MarkerFaceAlpha', 0.1, ...
%         'MarkerEdgeAlpha', 0.1)
%     x = xpergroup(:);
%     y = currYVar(:);
%     sel = not(any(isnan([x y]),1));
%     x = x(sel);
%     y = y(sel);
%     p = polyfit(x,y,2);
%     xp = min(x):1:max(x);
%     yp = polyval(p,xp);
%     plot(xp, yp, 'k', 'LineWidth', 3)
%     
%     currLabel = yvarNames{i};
%     currLabel = strrep(currLabel, '_', '-');
%     title(currLabel, 'FontSize', 20)
% %     set(gca, 'YLim', [0.3 0.8])
end