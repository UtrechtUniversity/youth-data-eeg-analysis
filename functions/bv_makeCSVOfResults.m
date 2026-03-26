function bv_makeCSVOfResults(sResults)

disp(sResults)

eval('setOptions')
eval('setPaths')

PATHS.CSV = [PATHS.RESULTS filesep 'csv'];
if ~exist(PATHS.CSV, 'dir')
    mkdir(PATHS.CSV)
end

freqorder = {'delta', 'theta', 'alpha1', 'alpha2', 'beta', 'gamma'};
files2use = dir([PATHS.RESULTS filesep sResults '*.mat']);
names2use = {files2use.name};

k = cellfun(@(x) strsplit(x, '_'), names2use, 'UniformOutput',false);
l = cellfun(@(x) x(end), k);
m = cellfun(@(x) strsplit(x, '.'), l,'UniformOutput', false);
allfreqs = cellfun(@(x) x(1), m);

[a,indx] = ismember(freqorder, allfreqs);
indx = indx(a);

namesinorder = names2use(indx);
counter = 0;
for i = 1:length(namesinorder)
    load(namesinorder{i})
    if i == 1
        counter = counter + 1;
        fprintf('\t setting up csv file ...')
        csvOut = {};
        csvOut{1,counter} = 'Subjects';
        csvOut(2:length(subjects)+1,counter) =  num2cell(cellfun(@str2num, subjects)');
        fprintf('done! \n')
    end
    
    fprintf('\t adding data... \n')
    try
    input = results.globConn;
    counter = counter + size(results.globConn,2);
    indx = (size(csvOut, 2) + 1):counter;
    csvOut(1,indx) = {[freqband '_globConn_ses1'], [freqband '_globConn_ses2']};
    csvOut(2:length(subjects)+1,indx) = num2cell(input);
    fprintf('\t \t globConn added \n')
    catch
        fprintf('\t \t globConn not found, skipping \n')
    end
    
    try
        input = graphResults.weighted.CC;
        counter = counter + size(results.globConn,2);
        indx = (size(csvOut, 2) + 1):counter;
        csvOut(1,indx) = {[freqband '_CC_ses1'], [freqband '_CC_ses1']};
        csvOut(2:length(subjects)+1,indx) = num2cell(input);
        fprintf('\t \t CC added \n')
    catch
        fprintf('\t \t  CC not found, skipping \n')
    end
    
    try
        input = graphResults.weighted.CPL;
        counter = counter + size(results.globConn,2);
        indx = (size(csvOut, 2) + 1):counter;
        csvOut(1,indx) = {[freqband '_CPL_ses1'], [freqband '_CPL_ses1']};
        csvOut(2:length(subjects)+1,indx) = num2cell(input);
        fprintf('\t \t CPL added \n')
    catch
        fprintf('\t \t  CPL not found, skipping \n')
    end
    
    try
        input = graphResults.weighted.S;
        counter = counter + size(results.globConn,2);
        indx = (size(csvOut, 2) + 1):counter;
        csvOut(1,indx) = {[freqband '_S_ses1'], [freqband '_S_ses1']};
        csvOut(2:length(subjects)+1,indx) = num2cell(input);
        fprintf('\t \t S added \n')
    catch
        fprintf('\t S not found, skipping \n')
    end

    
end

filename = [PATHS.CSV filesep sResults 'results.csv'];
fprintf('\t saving all data to %s \n', [PATHS.CSV filesep sResults 'results.csv']);

fid = fopen(filename, 'w') ;
fprintf(fid, '%s,', csvOut{1,1:end-1}) ;
fprintf(fid, '%s\n', csvOut{1,end}) ;
fclose(fid) ;
dlmwrite(filename, csvOut(2:end,:), '-append') ;

fprintf('\t done!\n')

