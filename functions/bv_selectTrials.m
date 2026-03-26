function T = bv_selectTrials(T, spctrmvar, ntrials)

data = T.(spctrmvar);

for i = 1:length(data)
    dat = data{i};
    trls = size(dat,3);
    trl_sel = sort(randperm(trls, ntrials));
    data{i} = dat(:,:,trl_sel,:);
end

T.(spctrmvar) = data;
