function subjectresults = bv_createSubjectResults(inputStr, keepstruct)

eval('setPaths')
eval('setOptions')

fprintf('Creating subject results \n')
fprintf('\t Creating subjectsummary ... ')
subjectdirflags = dir([PATHS.SUBJECTS filesep '*' OPTIONS.sDirString '*']);
subjectrmflags = dir([PATHS.REMOVED filesep '*' OPTIONS.sDirString '*']);

subjectdirflags = [subjectdirflags; subjectrmflags];

for i = 1:length(subjectdirflags)
    lng = printPercDone(length(subjectdirflags), i);
    if i ==1
        evalc('subjectdatasummary = bv_check4data([subjectdirflags(1).folder filesep subjectdirflags(1).name]);');
    else
        evalc('subjectdata = bv_check4data([subjectdirflags(i).folder filesep subjectdirflags(i).name]);');
        subjectdatafields = fields(subjectdata);
        subjectdatasummaryfields = fields(subjectdatasummary);
        missingFieldsSummary = subjectdatafields(find(not(ismember(subjectdatafields, ...
            subjectdatasummaryfields))));
        
        if ~isempty(missingFieldsSummary)
            for j = missingFieldsSummary'
                switch class(subjectdata.(j{:}))
                    case 'struct'
                        [subjectdatasummary(1:end).(j{:})] = deal(struct);
                    case 'double'
                        [subjectdatasummary(1:end).(j{:})] = deal(NaN);
                    case 'char'
                        [subjectdatasummary(1:end).(j{:})] = deal('');
                    case 'cell'
                        [subjectdatasummary(1:end).(j{:})] = deal(cell(0));
                end
            end
        end
        
        missingFieldsSubjectdata = subjectdatasummaryfields(find(not(ismember(subjectdatasummaryfields, ...
            subjectdatafields))));
        
        if ~isempty(missingFieldsSubjectdata)
            for j = missingFieldsSubjectdata'
                switch class(subjectdatasummary(1).(j{:}))
                    case 'struct'
                        subjectdata.(j{:}) = struct;
                    case 'double'
                        subjectdata.(j{:}) = NaN;
                    case 'char'
                        subjectdata.(j{:}) = '';
                    case 'cell'
                        subjectdata.(j{:}) = cell(0);
                end
            end
        end
        
        subjectdatasummary(i) = subjectdata;
        
    end
    fprintf(repmat('\b', 1, lng))
end
fprintf('done! \n')
% end
subjectdatasummary = struct2table(subjectdatasummary);

if nargin > 0
    fprintf('\t loading results into subjectsummary ... ')
    counter = 0;
    while 1
        counter = counter + 1;
        disp(counter);
        for i = 1:100
            disp(i)
            subjectresultstmp = subjectdatasummary(i,:);
            
            evalc('[resultsStruct, succeed] = bv_quickloadData(subjectdatasummary.subjectName{i}, inputStr);');
            
            if ~succeed
%                 fprintf(repmat('\b', 1, lng))
%                 startIndx = startIndx + 1;
                continue
            end
            if keepstruct
                subjectresultstmp.(inputStr) = resultsStruct;
            else
                fnames = fieldnames(resultsStruct);
                for j = 1:length(fnames)
                    switch class(resultsStruct.(fnames{j}))
                        case 'double'
                            if length(resultsStruct.(fnames{j}))==1
                                subjectresultstmp.(fnames{j})(1) = resultsStruct.(fnames{j});
                            else
                                subjectresultstmp.(fnames{j}){1} = resultsStruct.(fnames{j});
                            end
                        otherwise
                            subjectresultstmp.(fnames{j}){1} = resultsStruct.(fnames{j});
                    end
                end
            end
            
            if exist('subjectresultstmp', 'var')
                break
            end
        end
        if exist('subjectresultstmp', 'var')
            break
        end
    end    
    
    updateWaitbar = waitbarParfor(height(subjectdatasummary), 'Adding to subjectsummary ...');
    for i = 1:height(subjectdatasummary)
        newSubjectresult = add2subjectresults(subjectdatasummary(i,:), subjectresultstmp, inputStr, keepstruct);
        if ~isempty(newSubjectresult)
            subjectresults(i,:) = newSubjectresult;
        else
            new_subj_indx = height(subjectresults) + 1;
            subjectresults(new_subj_indx+1,:) = subjectresults(1,:);
            subjectresults(end,:) = [];
            subjectresults.subjectName(new_subj_indx) = subjectdatasummary(i,:).subjectName;
            T1 = subjectresults(new_subj_indx,:);
            T2 = subjectdatasummary(i,:);
            T1 = T1(:,{'subjectName', T1.Properties.VariableNames{~ismember(T1.Properties.VariableNames, T2.Properties.VariableNames)}});
            T1 = outerjoin(T1, T2, 'Keys', 'subjectName', 'MergeKeys', true);
            [~,sorted] = ismember(subjectresults.Properties.VariableNames, T1.Properties.VariableNames);
            T1 = T1(:,sorted);
            subjectresults(i,:) = T1;
            subjectresults(i,:).removed = 1;
        end
        updateWaitbar();
    end
    fprintf('done! \n')
    subjectresults(cellfun(@isempty, subjectresults.pseudo),:) =[];
else
    subjectresults = subjectdatasummary;
end

% HELPER FUNCTIONS
function subjectresults = add2subjectresults(subjectdatasummary, subjectresults, inputStr, keepstruct)
subjectresultstmp = subjectdatasummary;

if subjectdatasummary.removed
    subjectresults.pseudo = subjectdatasummary.pseudo;
    subjectresults.removed = 1;
else
    evalc('[resultsStruct, succeed] = bv_quickloadData(subjectdatasummary.subjectName, inputStr);');
    
    if ~(succeed)
        %     fprintf('\t inputStr not found, skipping \n')
        subjectresults = [];
        return
    end
    if keepstruct
        subjectresultstmp.(inputStr) = resultsStruct;
    else
        fnames = fieldnames(resultsStruct);
        for j = 1:length(fnames)
            switch class(subjectresults.(fnames{j}))
                case 'double'
                    subjectresultstmp.(fnames{j})(1) = resultsStruct.(fnames{j});
                otherwise
                    subjectresultstmp.(fnames{j}){1} = resultsStruct.(fnames{j});
            end
        end
        
        fnamesSummary = fieldnames(subjectresults);
        fnamesTmp = fieldnames(subjectresultstmp);
        extraFieldsTmp = fnamesTmp(find(not(ismember(fnamesTmp, fnamesSummary))));
        extraFieldsSummary = fnamesSummary(find(not(ismember(fnamesSummary, fnamesTmp))));
        
        for j = 1:length(extraFieldsTmp)
            if isstruct(subjectresultstmp)
                subjectresultstmp = rmfield(subjectresultstmp, extraFieldsTmp{j});
            elseif istable(subjectresultstmp)
                subjectresultstmp(:, ismember(subjectresultstmp.Properties.VariableNames, extraFieldsTmp{j})) = [];
            end
            
        end
        for j = 1:length(extraFieldsSummary)
            if isstruct(subjectresultstmp)
                subjectresultstmp = rmfield(subjectresultstmp, extraFieldsSummary{j});
            elseif istable(subjectresultstmp)
                
                switch class(subjectresults.(extraFieldsSummary{j}))
                    case 'double'
                        subjectresultstmp.(extraFieldsSummary{j})(1) = subjectresults.(extraFieldsSummary{j});
                    otherwise
                        subjectresultstmp.(extraFieldsSummary{j}){1} = subjectresults.(extraFieldsSummary{j});
                end
                
            end
            
        end
        
        n1 = subjectresults.Properties.VariableNames;
        n2 = subjectresultstmp.Properties.VariableNames;
        [~,y] = ismember(n1, n2);
        subjectresultstmp = subjectresultstmp(:,y);
        
        
    end
    subjectresults = subjectresultstmp;
end