function tex = createTexFromSignal(signal)

signalNrm = signal - min(signal) + 1;
signalNrm = round(signalNrm);

tex = zeros(length(signalNrm), max(signalNrm));

linearIndx = sub2ind(size(tex), 1:length(signalNrm), signalNrm);
tex(linearIndx) = 255;

imagesc(abs(tex'-255)); colormap(gray)
