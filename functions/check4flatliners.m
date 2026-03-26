cfg = [];
cfg.fields = 'flatliners';
cfg.structFileName = 'Subject.mat';
cfg.structVarFname = 'subjectdata';

[flatlinersQC, names] = bv_readOutStructFromFile(cfg);

allFlats = flatlinersQC(not(cellfun(@isempty, flatlinersQC)));
[uFlats, b,c] = unique(allFlats);
[dFlats,e] = hist(c, length(uFlats));

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

chanFlatData = zeros(1,length(chans));

for i = 1:length(dFlats)
    chanIndx = find(ismember(chanSort,uFlats{i}));
    chanFlatData(chanIndx) = dFlats(i);
end
    
figure(1)
hold on
scatter(lay.pos(:,1), lay.pos(:,2), (chanFlatData*100)+0.01, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r')
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
bar((chanFlatData / size(flatlinersQC,1)) * 100)
set(gca, 'XTick', 1:length(chans), 'XTickLabel', chans)
legend({'Bad Chans', 'Flats'})