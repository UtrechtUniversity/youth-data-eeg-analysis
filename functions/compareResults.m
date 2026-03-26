clear all

compareStrings = {'s', 'ns'};
stemstr = 'wpli_debiased5';

sdirs = dir([compareStrings{1} '_' stemstr '_*.mat']);
nsdirs = dir([compareStrings{2} '_' stemstr '_*.mat']);
alldirs = cat(1,sdirs,nsdirs);

names = {alldirs.name};

extremoval = cellfun(@(z) strsplit(z, '.'), names, 'Un', 0);
extremoved = cellfun(@(v) v{1}, extremoval, 'Un', 0);

splitNames = cellfun(@(x) strsplit(x, '_'), extremoved, 'Un', 0);
condition = cellfun(@(v) v{1}, splitNames, 'Un', 0);
frequency = cellfun(@(y) y{end}, splitNames, 'Un', 0);
allfreqs = unique(frequency);

currWs = [];
conditions = [];
for i = 1:length(allfreqs)
    currFreq = allfreqs{i};
    disp(currFreq)
    freqIndx = find(not(cellfun(@isempty, strfind(frequency, allfreqs{i}))));
    
    for ifreq = 1:length(freqIndx)
        file2load = names{freqIndx(ifreq)};
        fprintf('\t loading %s ... ', file2load)
        load(file2load)
        fprintf('done! \n')
        
        currWs = cat(length(size(Ws))+1, currWs, Ws);
%         clear Ws
        
        conditions{ifreq} = condition{freqIndx(ifreq)};
    end
    
    Wsdims = [Wsdims '_condition'];
    Ws = currWs;
    
    savename = [stemstr '_' currFreq '_' strjoin(compareStrings, '-vs-')];
    fprintf('\t saving compare file: %s ... ', savename)
    save(savename, 'Wsdims', 'Ws', 'chans', 'subjects', 'conditions', 'freqband')
    fprintf('done! \n')
   
    currWs = [];
end
