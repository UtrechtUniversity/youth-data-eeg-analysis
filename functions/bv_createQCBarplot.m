function bv_createQCBarplot(T, var2plot, var2group, N_min)
addpath('~/MatlabToolboxes/superbar/superbar/')

[g, gname] = findgroups(T.(var2group));
m = splitapply(@nanmean, T.(var2plot), g);
e = splitapply(@(x) 2.*nanstd(x)./sqrt(length(x)), T.(var2plot), g);
N = splitapply(@(x) sum(~isnan(x)), T.(var2plot), g);

if nargin == 4
    N_sel = N >= N_min;
    m = m(N_sel);
    e = e(N_sel);
    gname = gname(N_sel);
    N = N(N_sel);
end

figure;
superbar(m, 'E', e)

if ~iscell(gname)
    gname = cellstr(num2str(gname));
end
labelstr = strcat(gname, ' (N = ', cellstr(num2str(N)), ')');
set(gca, 'XTick', 1:length(labelstr), 'XTickLabel', labelstr) 
xtickangle(45)
set(gca, 'FontSize', 14)
ylabel('Mean of variable', 'FontSize', 20)
titlestr = strrep(['Barplot ' var2plot ' vs ' var2group], '_', '-');
title(titlestr, 'FontSize', 25)
