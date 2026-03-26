path2figures = '~/surfdrive/PhD/DraftsForPublications/TestRetest/figures/';
close all
load pli5_alpha1.mat
bv_plotDataOnTopoplot(cat(3,results.avgW1,results.avgW2), chans, 0.12)
set(gcf, 'color', 'white')
print(gcf, [path2figures filesep 'topoAlpha1_1'], '-dpng', '-r1200')

load pli15_alpha2.mat
bv_plotDataOnTopoplot(cat(3,results.avgW1,results.avgW2), chans, 0.12)
set(gcf, 'color', 'white')
print(gcf, [path2figures filesep 'topoAlpha2'], '-dpng', '-r300')

load pli15_beta.mat
bv_plotDataOnTopoplot(cat(3,results.avgW1,results.avgW2), chans, 0.12)
set(gcf, 'color', 'white')
print(gcf, [path2figures filesep 'topoBeta'], '-dpng', '-r300')

load pli15_delta.mat
bv_plotDataOnTopoplot(cat(3,results.avgW1,results.avgW2), chans, 0.12)
set(gcf, 'color', 'white')
print(gcf, [path2figures filesep 'topoDelta'], '-dpng', '-r300')

load pli15_gamma.mat
bv_plotDataOnTopoplot(cat(3,results.avgW1,results.avgW2), chans, 0.12)
set(gcf, 'color', 'white')
print(gcf, [path2figures filesep 'topoGamma'], '-dpng', '-r300')

load pli15_theta.mat
bv_plotDataOnTopoplot(cat(3,results.avgW1,results.avgW2), chans, 0.12)
set(gcf, 'color', 'white')
print(gcf, [path2figures filesep 'topoTheta'], '-dpng', '-r300')






