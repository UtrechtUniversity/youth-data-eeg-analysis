function prettyCorrMatrix(ax_h, labels)

colorbar
set(ax_h, 'XTick', 1:length(labels), 'XTickLabel', labels)
set(ax_h, 'YTick', 1:length(labels), 'YTickLabel', labels)
