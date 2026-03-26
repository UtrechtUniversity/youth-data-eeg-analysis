function scores = bv_calculateIBQscore(ibqTable)

questionLabels = {'1R','2','3','7R','9','17','18','19R','20','21','22R','23','28','30',...
    '33','34','35','36','37','40','45','47','48','49','50','53','54','56',...
    '57','60','61','63','65','69','70','71','73','77','78','79','80','81',...
    '82','83','85','88','93','94','97','98','101','102','105R','106','112',...
    '113','114','115','116','119','121R','123','124R','130R','133','136',...
    '137','138','139','141','142','144','146','147','148','150','151','153',...
    '156','159','164','168','169','172','176R','177','179R','186','188R',...
    '189','191R'};

questionLabelsExcel = ...
    ibqTable.Properties.VariableNames(contains(ibqTable.Properties.VariableNames, ...
    '_SC'));

reverses = contains(questionLabels, 'R');

activityLabels = {'1R','2','3', '33' '112','115', '116'};
activityLevelIndx = ismember(questionLabels, activityLabels);
distressLabels =  {'18','19R','20', '93','113','114', '17'};
distressIndx = ismember(questionLabels, distressLabels);
approachLabels =  {'97','98','85', '88','159','172'};
approachIndx = ismember(questionLabels, approachLabels);
fearLabels = {'94','150','151','153','156', '164'};
fearIndx = ismember(questionLabels, fearLabels);
orientingDurationLabels = {'47','48','49','50','54','101'};
orientingDurationIndx = ismember(questionLabels, orientingDurationLabels);
smilingLabels = {'53','56','57','34','36','37','40'};
smilingIndx = ismember(questionLabels, smilingLabels);
vocalReactivityLabels = {'9','102','35','146','147','148','45'};
vocalReactivityIndx = ismember(questionLabels, vocalReactivityLabels);
sadLabels = {'30','141','142','144','168','169'};
sadIndx = ismember(questionLabels, sadLabels);
percSensitivityLabels = {'83','133','136','137','138','139'};
percSensitivityIndx = ismember(questionLabels, percSensitivityLabels);
hiPleasureLabels = {'65','77','78','79','80','81','82'};
hiPleasureIndx = ismember(questionLabels, hiPleasureLabels);
liPleasureLabels = {'60','61','63','69','70','71','73'};
liPleasureIndx = ismember(questionLabels, liPleasureLabels);
cuddleLabels =  {'7R','105R','106','123','124R','130R'};
cuddleIndx = ismember(questionLabels, cuddleLabels);
soothLabels =  {'176R','177','179R','186','188R','189','191R'};
soothIndx = ismember(questionLabels, soothLabels);
fallingReactivityLabels =  {'21','22R','23','28','119','121R'};
fallingReactivityIndx = ismember(questionLabels, fallingReactivityLabels);

allIndices = who('-regexp', 'Indx');

answers = ibqTable{:,contains(ibqTable.Properties.VariableNames, '_SC')};
if length(reverses) ~= size(answers,2)
    error('Hardcoding does not match given asqTable')
end

% find not filled in answers or nvt answers and set to 0
answers(contains(answers, 'X')) = {'0'};
answers(cellfun(@isempty, answers)) = {'0'};

% efficient method to make cell with numbers strings into double
S = sprintf('%s ', answers{:});
D = sscanf(S, '%f');
answersNum = reshape(D, size(answers));

answersNum(answersNum==0) = NaN; % set zeroes to NaN

answersOut = abs(reverses*8-answersNum); % reverse score the reverse questions

% calculate the category scores
for i = 1:length(allIndices)
    indexStart = strfind(allIndices{i}, 'Indx');
    name = allIndices{i}(1:indexStart-1);
    scores.(name) = nanmean(answersOut(:,eval(allIndices{i})),2);
end

% calculate the overarching category scores
scores.sur_score = mean(cat(2, scores.approach, scores.vocalReactivity, scores.hiPleasure, ...
    scores.smiling, scores.activityLevel, scores.percSensitivity),2);
scores.neg_score = mean(cat(2, scores.sad, scores.distress, scores.fear, ...
    (8-scores.fallingReactivity)),2);
scores.reg_score = mean(cat(2, scores.liPleasure, scores.cuddle, scores.orientingDuration, ...
    scores.sooth),2);

scores = struct2table(scores);



