function T = bv_cleanAssistantNames(T)

T.PrimaryAssistant = cellfun(@(x) strrep(x, '(', ''), T.PrimaryAssistant, 'Un', 0);
T.PrimaryAssistant = cellfun(@(x) strrep(x, ')', ''), T.PrimaryAssistant, 'Un', 0);

% find older faulty labelling for more than 1 assistant
plusIndx = find(contains(T.PrimaryAssistant, '+'));
for i = 1:length(plusIndx)
    splitAssistants = strsplit(T.PrimaryAssistant{plusIndx(i)}, '+');
    splitAssistants = cellfun(@(x) strrep(x, ' ', ''), splitAssistants, 'Un', 0);
    T.PrimaryAssistant{plusIndx(i)} = splitAssistants{1};
    T.SecondaryAssistant{plusIndx(i)} = splitAssistants{2};
end

enIndx = find(contains(T.PrimaryAssistant, 'EN'));
for i = 1:length(enIndx)
    splitAssistants = strsplit(T.PrimaryAssistant{enIndx(i)}, 'EN');
    splitAssistants = cellfun(@(x) strrep(x, ' ', ''), splitAssistants, 'Un', 0);
    T.PrimaryAssistant{enIndx(i)} = splitAssistants{1};
    T.SecondaryAssistant{enIndx(i)} = splitAssistants{2};
end

ampIndx = find(contains(T.PrimaryAssistant, '&'));
for i = 1:length(ampIndx)
    splitAssistants = strsplit(T.PrimaryAssistant{ampIndx(i)}, '&');
    splitAssistants = cellfun(@(x) strrep(x, ' ', ''), splitAssistants, 'Un', 0);
    T.PrimaryAssistant{ampIndx(i)} = splitAssistants{1};
    T.SecondaryAssistant{ampIndx(i)} = splitAssistants{2};
end

commaIndx = find(contains(T.PrimaryAssistant, ','));
for i = 1:length(commaIndx)
    splitAssistants = strsplit(T.PrimaryAssistant{commaIndx(i)}, ',');
    splitAssistants = cellfun(@(x) strrep(x, ' ', ''), splitAssistants, 'Un', 0);
    T.PrimaryAssistant{commaIndx(i)} = splitAssistants{1};
    T.SecondaryAssistant{commaIndx(i)} = splitAssistants{2};
end

spaceIndx = find(contains(T.PrimaryAssistant, ' '));
for i = 1:length(spaceIndx)
    splitAssistants = strsplit(T.PrimaryAssistant{spaceIndx(i)}, ' ');
    splitAssistants = cellfun(@(x) strrep(x, ' ', ''), splitAssistants, 'Un', 0);
    T.PrimaryAssistant{spaceIndx(i)} = splitAssistants{1};
    T.SecondaryAssistant{spaceIndx(i)} = splitAssistants{2};
end

T.PrimaryAssistant = upper(T.PrimaryAssistant);
T.SecondaryAssistant(cellfun(@isempty, T.SecondaryAssistant)) = {''};
T.SecondaryAssistant = upper(T.SecondaryAssistant);
% T.PrimaryAssistant{contains(T.PrimaryAssistant,'0376623311.2')} = '03766233';

solistable = readtable(['/Volumes/youth.data.uu.nl/b.vandervelde@uu.nl/QC' filesep 'Admin' filesep 'SolisYOUth.xlsx']);
T.PrimaryAssistantName = T.PrimaryAssistant;
for i = 2:width(solistable)
    solistable(:,i) = upper(solistable{:,i});
    for j = 1:length(solistable{:,i})
        if ~isempty(solistable{j,i}{1})
            assistentIndx = find(contains(T.PrimaryAssistant, solistable{j,i}{1}));
            if ~isempty(assistentIndx)
                T.PrimaryAssistantName(assistentIndx) = solistable{j,1};
            end
        end
    end
end
