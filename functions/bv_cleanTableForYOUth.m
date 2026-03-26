function T = bv_cleanTableForYOUth(T)
addpath('~/MatlabToolboxes/EditDistance/')

% cleanup temp log variable
T.Temp = cellfun(@(x) strrep(x, ',', '.'), T.Temp, 'Un', 0);
T.Temp(cellfun(@isempty, T.Temp)) = {'NaN'};
T.Temp(not(cellfun(@(x) all(ismember(x, '0123456789+-.eEdD')), T.Temp))) = {'NaN'};
T.Temp = cellfun(@str2num, T.Temp);
T.Temp(T.Temp>30) = NaN;
T.Temp(T.Temp<15) = NaN;

% cleanup illumination log variable
T.Illumination = cellfun(@(x) strrep(x, ',', '.'), T.Illumination, 'Un', 0);
T.Illumination(cellfun(@isempty, T.Illumination)) = {'NaN'};
T.Illumination(not(cellfun(@(x) all(ismember(x, '0123456789.eEdD')), T.Illumination))) = {'NaN'};
T.Illumination = cellfun(@str2num, T.Illumination);
T.Illumination(T.Illumination>350) = NaN;
T.Illumination(T.Illumination<5) = NaN;

% cleanup illumination log variable
T.HeadCircum = cellfun(@(x) strrep(x, ',', '.'), T.HeadCircum, 'Un', 0);
T.HeadCircum(cellfun(@isempty, T.HeadCircum)) = {'NaN'};
T.HeadCircum(not(cellfun(@(x) all(ismember(x, '0123456789+-.eEdD')), T.HeadCircum))) = {'NaN'};
T.HeadCircum = cellfun(@str2num, T.HeadCircum);
T.HeadCircum(T.HeadCircum>70) = NaN;
T.HeadCircum(T.HeadCircum<30) = NaN;

T.Headshape(cellfun(@isempty, T.Headshape)) = {''};

% cleanup electrodecode variable
T.ElectrodeCode(contains(T.ElectrodeCode, 'Other')) = T.ElectrodeCodeOther(contains(T.ElectrodeCode, 'Other'));
realElectrodeCodes = ...
    {'FR17-007146';
    'FR17-007361';
    'FR16-006987';
    'FR16-006986';
    'FR16-006573';
    'FR13-003901';
    'FR16-006325';
    'FR13-004413';
    'FR13-004429';
    'FR13-004412';
    'FR10-001605';
    'FR13-004427'};
T.ElectrodeCode = upper(T.ElectrodeCode);
for j = 1:height(T)
    for i = 1:length(realElectrodeCodes)
        distance(i) = EditDistance(T.ElectrodeCode{j}, realElectrodeCodes{i});
    end
    if any(distance<3)
        [~,indx] = min(distance);
        T.ElectrodeCode{j} = realElectrodeCodes{indx};
    else
        T.ElectrodeCode{j} = 'Unknown';
    end
end

T.roomNumber = strrep(T.roomNumber, ',', '');
T.roomNumber = strrep(T.roomNumber, '.', '');
T.roomNumber(find(cellfun(@length, T.roomNumber) ~= 3)) = {''};

% cleanup assistant names
T = bv_cleanAssistantNames(T);

    