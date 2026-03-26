function subjectresults = bv_addQuestionnaires2results(subjectresults, questionnaireString)

istable = contains(class(subjectresults), 'table');

eval('setPaths')
eval('setOptions')

if not(iscell(questionnaireString))
    questionnaireStringTmp{1} = questionnaireString;
    questionnaireString = questionnaireStringTmp;
    clear questionnaireStringTmp
end

csvflags = dir([PATHS.FILES filesep '*.csv']);
csvnames = {csvflags.name};
questionnaireNames = csvnames(not(contains(csvnames, 'metadata')));
questionnaireNames = questionnaireNames(contains(questionnaireNames, questionnaireString));
questionnaireMetas = csvnames(contains(csvnames, 'metadata'));
questionnaireMetas = questionnaireMetas(contains(questionnaireMetas, questionnaireString));

fieldnames = cell(1,length(questionnaireNames));
for i = 1:length(questionnaireNames)
    currQuestionnaire = questionnaireNames{i};
    currQuestionnaire = strrep(currQuestionnaire, '-', '_');
    fieldnames{i} = currQuestionnaire(1:end-4);
    
    opts = detectImportOptions(questionnaireNames{i});
    opts = setvartype(opts, 'char');
    allQuestionnaires.(fieldnames{i}) = readtable(questionnaireNames{i},opts);
    allMetas.(fieldnames{i}) = readtable(questionnaireMetas{i}, opts);
end

if isfield(allQuestionnaires, 'IBQ_2')
    allQuestionnaires.IBQ_2.IBQ4_1_SC = repmat({'X'},height(allQuestionnaires.IBQ_2),1);
end

if contains('IBQ', questionnaireString)
    ibqFields = fieldnames(find(contains(fieldnames, 'IBQ')));
    allQuestionnaires.IBQ = [];
    for i = 1:length(ibqFields)
        allQuestionnaires.IBQ = [allQuestionnaires.IBQ; allQuestionnaires.(ibqFields{i})];
    end
    allQuestionnaires = rmfield(allQuestionnaires, ibqFields);
    allQuestionnaires.IBQ = removevars(allQuestionnaires.IBQ , 'IBQ2_1_SC'); % remove double question
end

if istable
    subjectresults = table2struct(subjectresults);
end

for i = 1:length(subjectresults)
    currSubject = subjectresults(i).pseudo;
    currSession = subjectresults(i).wave;
    if strcmpi(currSession(1),'0')
        currSession(1) = [];
    end
    
    for j = 1:length(questionnaireString)
        
        switch questionnaireString{j}
            case 'ASQ'
                if any(contains(fieldnames, currSession))
                    fieldname2use = fieldnames{find(contains(fieldnames, questionnaireString) .* ...
                        contains(fieldnames, currSession))};
                    currQuestionnaire = allQuestionnaires.(fieldname2use);
                    subjIndx = find(contains(currQuestionnaire.subject, ...
                        currSubject));
                    
                    if isempty(subjIndx)
                        subjectresults(i).ASQ_version = '';
                        subjectresults(i).ASQ_score = NaN;
                        continue
                    end
                    
                    subjectresults(i).ASQ_version = currQuestionnaire.formversion(subjIndx);
                    subjectresults(i).ASQ_score = bv_calculateASQscore(currQuestionnaire(subjIndx,:));
                else
                    subjectresults(i).ASQ_version ='';
                    subjectresults(i).ASQ_score = NaN;
                end
            case 'IBQ'
                currQuestionnaire = allQuestionnaires.IBQ;
                
                switch currSession
                    case '5m'
                        subjIndx = find(contains(currQuestionnaire.subject, ...
                            currSubject) .* contains(currQuestionnaire.visit, ...
                            '4-7 maanden'));
                    case '10m'
                        subjIndx = find(contains(currQuestionnaire.subject, ...
                            currSubject) .* contains(currQuestionnaire.visit, ...
                            '9 - 12 maanden'));
                    otherwise
                        subjectresults(i).IBQ_version = '';
                        subjectresults(i).IBQ_activityLevel = NaN;
                        subjectresults(i).IBQ_approach = NaN;
                        subjectresults(i).IBQ_cuddle = NaN;
                        subjectresults(i).IBQ_distress = NaN;
                        subjectresults(i).IBQ_fallingReactivity = NaN;
                        subjectresults(i).IBQ_fear = NaN;
                        subjectresults(i).IBQ_hiPleasure = NaN;
                        subjectresults(i).IBQ_liPleasure = NaN;
                        subjectresults(i).IBQ_orientingDuration = NaN;
                        subjectresults(i).IBQ_percSensitivity = NaN;
                        subjectresults(i).IBQ_sad = NaN;
                        subjectresults(i).IBQ_smiling = NaN;
                        subjectresults(i).IBQ_sooth = NaN;
                        subjectresults(i).IBQ_vocalReactivity = NaN;
                        subjectresults(i).IBQ_sur_score = NaN;
                        subjectresults(i).IBQ_neg_score = NaN;
                        subjectresults(i).IBQ_reg_score = NaN;
                        continue
                end
                
                if isempty(subjIndx)
                    subjectresults(i).IBQ_version = '';
                    subjectresults(i).IBQ_activityLevel = NaN;
                    subjectresults(i).IBQ_approach = NaN;
                    subjectresults(i).IBQ_cuddle = NaN;
                    subjectresults(i).IBQ_distress = NaN;
                    subjectresults(i).IBQ_fallingReactivity = NaN;
                    subjectresults(i).IBQ_fear = NaN;
                    subjectresults(i).IBQ_hiPleasure = NaN;
                    subjectresults(i).IBQ_liPleasure = NaN;
                    subjectresults(i).IBQ_orientingDuration = NaN;
                    subjectresults(i).IBQ_percSensitivity = NaN;
                    subjectresults(i).IBQ_sad = NaN;
                    subjectresults(i).IBQ_smiling = NaN;
                    subjectresults(i).IBQ_sooth = NaN;
                    subjectresults(i).IBQ_vocalReactivity = NaN;
                    subjectresults(i).IBQ_sur_score = NaN;
                    subjectresults(i).IBQ_neg_score = NaN;
                    subjectresults(i).IBQ_reg_score = NaN;
                    continue
                end
                
                subjectresults(i).IBQ_version = currQuestionnaire.formversion(subjIndx);
                
                scores_ibq = bv_calculateIBQscore(currQuestionnaire(subjIndx,:));
                for k = 1:length(scores_ibq.Properties.VariableNames)
                    currFieldName = ...
                        ['IBQ_' scores_ibq.Properties.VariableNames{k}];
                    subjectresults(i).(currFieldName) = ...
                        scores_ibq.(scores_ibq.Properties.VariableNames{k});
                end
                
            otherwise
        end
    end
    
end

if istable
    subjectresults = struct2table(subjectresults);
end