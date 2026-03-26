function bv_createQCDistFigures(T, var2plot, var2group, N_min)

distMin = min(T.(var2plot));
distMax = max(T.(var2plot));
distVector = linspace(distMin, distMax, 100);

[g, gname] = findgroups(T.(var2group));
[dists] = splitapply(@(x) histcounts(x, distVector), T.(var2plot), g);
N = splitapply(@(x) sum(~isnan(x)), T.(var2plot), g);

if nargin == 4
    N_sel = N >= N_min;
    dists = dists(N_sel, :);
    gname = gname(N_sel);
    N = N(N_sel);
end

smoothDist = smoothdata(dists, 2, 'Gaussian', 40);
smoothDist = smoothDist ./ sum(dists,2) * 100;

figure;
hold on
for i = 1:size(smoothDist,1)
    area(smoothDist(i,:))
end
alpha(0.5)

if ~iscell(gname)
    gname = cellstr(num2str(gname));
end
% gname = cellstr(num2str([1:length(gname)]'));
labelstr = strcat(gname, ' (N = ', cellstr(num2str(N)), ')');
legend(labelstr, 'FontSize', 20)

set(gca, 'YLim', [0 max(max(smoothDist)) + 0.05])
% set(gca, 'XTick', linspace(1,length(distVector), 10), 'XTickLabel', distVector(linspace(1,length(distVector), 10)))
set(gca, 'FontSize', 14)
ylabel('Percentage subjects', 'FontSize', 20)
xlabel(['Percentage ' var2plot], 'FontSize', 20)
set(gca, 'XLim', [0 Inf])

titlestr = strrep(['Distribution ' var2plot ' vs ' var2group], '_', '-');
title(titlestr, 'FontSize', 25)
