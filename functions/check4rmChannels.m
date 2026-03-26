cfg = [];
cfg.fields = 'rmChannels';
cfg.structFileName = 'Subject.mat';
cfg.structVarFname = 'subjectdata';

[rmChannelsQC, names] = bv_readOutStructFromFile(cfg);

allRmChannels = rmChannelsQC(not(cellfun(@isempty, rmChannelsQC)));
[uRmChannels, b,c] = unique(allRmChannels);
[d,e] = hist(c, length(uRmChannels));

chans = {'Fp1';'Fp2';'AF3';'AF4';'F7';'F3';'Fz';'F4';'F8';'FC5';'FC1';'FC2';'FC6';'T7';'C3';'Cz';'C4';'T8';'CP5';'CP1';'CP2';'CP6';'P7';'P3';'Pz';'P4';'P8';'PO3';'PO4';'O1';'Oz';'O2'};

cfg = [];
cfg.channel  = chans;
cfg.layout   = 'EEG1010';
cfg.feedback = 'no';
cfg.skipcomnt  = 'yes';
cfg.skipscale  = 'yes';
evalc('lay = ft_prepare_layout(cfg);');

[~, indxSort] = ismember(lay.label, chans);
indxSort = indxSort(indxSort>0);

chanSort = chans(indxSort);

chanData = zeros(1,length(chans));

for i = 1:length(d)
    chanIndx = find(ismember(chanSort,uRmChannels{i}));
    chanData(chanIndx) = d(i);
end
  
figure(1)
scatter(lay.pos(:,1), lay.pos(:,2), (chanData*100)+0.01, 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'b')
    labeloffset = 0.02;
    text(double(lay.pos(:,1))+labeloffset, double(lay.pos(:,2)), lay.label , ...
        'fontsize',10,'fontname','helvetica', ...
        'interpreter','tex','horizontalalignment','left', ...
        'verticalalignment','middle','color','k');


line(lay.outline{1}(:,1), lay.outline{1}(:,2), 'LineWidth', 3, 'color', [0.5 0.5 0.5])

axis equal
axis off

figure(2)
hold on
bar((chanData / size(rmChannelsQC,1)) * 100)
set(gca, 'XTick', 1:length(chans), 'XTickLabel', chans)