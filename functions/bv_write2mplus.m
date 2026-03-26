function bv_write2mplus(filename, varargin)
% bv_write2mplus('SMPvsASQ', delta_SMP_AUC, theta_SMP_AUC, alpha1_SMP_AUC, ...
% alpha2_SMP_AUC, beta_SMP_AUC, gamma_SMP_AUC, ASQscore, ...
% 'splitBy', 'ageInMonths', 'grouplabel', {'4m', '5m', '6m', '9m', '10m', '11m'})

eval('setPaths')
allInputVars = varargin;

isgrouplabel = false;

catVars = cellfun(@(x) isa(x, 'double'), allInputVars);
for i = find(catVars)
    catVarNames{i} = inputname(i + 1);
    if ~exist('nSubjects', 'var')
        nSubjects = size(allInputVars{i},1);
    else
        if nSubjects ~= size(allInputVars{i},1)
            error('Not all input data files have the same nSubjects')
        end
    end
    if ~exist('nSessions', 'var')
        nSessions = size(allInputVars{i},2);
    else
        if nSessions ~= size(allInputVars{i},2)
            error('Not all input data files have the same nSessions')
        end
    end
end

fid = fopen([PATHS.MPLUS filesep filename '_info.txt'], 'w');
fprintf(fid, 'N_Subjects = %1.0f\n', nSubjects);
fprintf(fid, 'N_Sessions = %1.0f\n', nSessions);

var2write = cat(2, allInputVars{catVars});
allInputVars(catVars) = [];

keys = allInputVars(find(repmat([1 0], [1 length(allInputVars) ./ 2])));
vals = allInputVars(find(repmat([0 1], [1 length(allInputVars) ./ 2])));

for i = 1:length(keys)
    switch keys{i}
        case 'splitBy'
            fprintf(fid, 'Sessions split by: %s\n', vals{i});
        case 'grouplabel'
            isgrouplabel = true;
            grouplabels = vals{i};
            fprintf(fid, 'Session labels: %s\n', strjoin(grouplabels, ', '));           
    end
end

if isgrouplabel
    countGrpLabels = 0;
    for i = 1:length(catVarNames)
        for j = 1:length(grouplabels)
            countGrpLabels = countGrpLabels + 1;
            varlabels{countGrpLabels} = [catVarNames{i}, '_', grouplabels{j}]
        end
    end
else
    varlabels = catVarNames;
end

fprintf(fid, 'Variable labels: %s\n', strjoin(varlabels, ', '));           

if length(varlabels) ~= size(var2write,2)
    warning('Not enough variable labels given for amount of data')
end

dlmwrite([PATHS.MPLUS filesep filename '.dat'], var2write, '\t')

fclose('all');


