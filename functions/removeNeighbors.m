function [W_neighbRemoved, sortLabels] = removeNeighbors(corrMatStr, saveData)

corrMat = dir(['*' corrMatStr '.mat']);
load(corrMat.name)
Ws = allSubjectResults.corrMatrices;
channels = allSubjectResults.chanNames;

cfg = [];
cfg.channel  = channels;
cfg.layout   = 'EEG1010';
cfg.feedback = 'no';
cfg.skipscale  = 'yes';
cfg.skipcomnt  = 'yes';
evalc('lay = ft_prepare_layout(cfg);');

cfg =[];
cfg.method = 'distance';
cfg.neighbourdist = 0.2;
cfg.layout = lay;
cfg.feedback = 'no';
neighbors = ft_prepare_neighbours(cfg);

sorted_Ws = sortWs(Ws, channels, lay.label);

W_neighbRemoved = zeros(size(sorted_Ws));
for iW = 1:size(sorted_Ws,3)
    currW = sorted_Ws(:,:,iW);
        
    for iNeigh = 1:length(neighbors)
        currW(iNeigh, ismember(lay.label, neighbors(iNeigh).neighblabel)) = NaN;
    end
    
    W_neighbRemoved(:,:,iW) = currW;
end

sortLabels = lay.label;
allSubjectResults.corrMatrices = W_neighbRemoved;
allSubjectResults.chanNames = sortLabels;

if saveData 
    outputName = ['corrMatrices_' corrMatStr '_neighbRemoved.mat'];
    save(outputName, 'allSubjectResults')
end
