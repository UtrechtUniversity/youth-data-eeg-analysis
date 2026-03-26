files = dir('*_*.mat');
filenames = {files.name};
a = cellfun(@(x) strsplit(x, '_'), filenames, 'UniformOutput', false);
b = cellfun(@(x) x(1:end-1), a, 'UniformOutput', false);
c = cellfun(@(x) sprintf('%s_',x{:}), b, 'UniformOutput', false);
d = unique(c);

for i = 1:length(d)
    bv_makeCSVOfResults(d{i})
end
    


