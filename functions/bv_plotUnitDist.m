function h=bv_plotUnitDist(r_unitwise,colors)

if nargin < 2
    colors = [0.25 0.25 0.25];
end

x = [-1:0.1:1];
ynrm = hist(r_unitwise, x);

ynrm = ynrm/sum(ynrm);

plot(x,smooth(ynrm), 'LineWidth', 3) %, 'color', colors)
