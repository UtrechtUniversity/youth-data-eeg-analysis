function bv_createLineplotWithTrend(table, grouping, xvar, yvar)

xpergroup = bv_prepareForMPlus(table, grouping, xvar);
yvarNames = table.Properties.VariableNames(contains(table.Properties.VariableNames, yvar));

figure;
nvars = 6;
for i = 1:6
    subplot(2, 3, i)

    currYVar = bv_prepareForMPlus(table, grouping, yvarNames{i});
    currYVar(isoutlier(currYVar)) = NaN;
    plot(xpergroup', currYVar', '-', 'color', [0.5 0.5 0.5 0.1])
    hold on
    scatter(xpergroup(:), currYVar(:), '.','MarkerFaceColor', [0 0 0], ...
        'MarkerEdgeColor', [0 0 0], 'MarkerFaceAlpha', 0.1, ...
        'MarkerEdgeAlpha', 0.1)
    x = xpergroup(:);
    y = currYVar(:);
    sel = not(any(isnan([x y]),2));
    x = x(sel);
    y = y(sel);
    p = polyfit(x,y,1);
    xp = min(x):1:max(x);
    yp = polyval(p,xp);
    plot(xp, yp, 'k', 'LineWidth', 3)
    
    currLabel = yvarNames{i};
    currLabel = strrep(currLabel, '_', '-');
    title(currLabel, 'FontSize', 20)
%     set(gca, 'YLim', [0.3 0.8])
end