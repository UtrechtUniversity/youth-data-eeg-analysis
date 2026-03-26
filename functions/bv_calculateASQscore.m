function scores = bv_calculateASQscore(asqTable)
% usage: scores = bv_calculateASQscore(asqTable)

switch asqTable.form{1}
    case 'ASQ5mnd'
        negatives = logical([0 0 0 1 0 0 0 0 1 0 1 1 0 1 0 1 0 1 0 0 0 0 1]);
        answers = asqTable{:,contains(asqTable.Properties.VariableNames, '_SC')};
        worries = asqTable{:,contains(asqTable.Properties.VariableNames, '_W_Y')};
        if length(negatives) ~= size(answers,2)
            error('Hardcoding does not match given asqTable')
        end

    case 'ASQ10mnd'
        negatives = logical([0 0 0 0 0 1 0 0 1 0 0 1 0 1 1 0 0 1 0 0 1 0 0 0 0 0 1]);
        answers = asqTable{:,contains(asqTable.Properties.VariableNames, '_SC')};
        worries = asqTable{:,contains(asqTable.Properties.VariableNames, '_W_X')};
        if length(negatives) ~= size(answers,2)
            error('Hardcoding does not match given asqTable')
        end
        

end

answerScores = (contains(answers, 'A') & negatives) .*10 + (contains(answers, 'B') .*5);
worriesScores = strcmpi(worries, '1') .*5;

scores = mean(answerScores + worriesScores,2);
