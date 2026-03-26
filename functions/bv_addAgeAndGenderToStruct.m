function dataOut = bv_addAgeAndGenderToStruct(dataIn, removeSubjects)

if nargin < 2
    removeSubjects = false;
end

if isstruct(dataIn)
    structbool = true;
    dataIn = struct2table(dataIn);
else
    structbool = false;
end

eval('setPaths')
eval('setOptions')

ageGenderPath = dir([PATHS.FILES filesep '*demo*']);
if isempty(ageGenderPath)
    error('age gender file not found')
else
    ageGenderVar = readtable([ageGenderPath.folder filesep ageGenderPath.name]);
end

ageGenderVar(:,not(contains(ageGenderVar.Properties.VariableNames, ...
    {'pseudo', 'wave', 'gender', 'age'}))) = [];

ageGenderVar.wave(contains(ageGenderVar.wave, '10')) = {'10m'};
ageGenderVar.wave(contains(ageGenderVar.wave, '5')) = {'5m'};

subjectNamesAG = strcat(ageGenderVar.pseudo, '_', ageGenderVar.wave);
subjectNamesDI = strcat(dataIn.pseudo, '_', dataIn.wave);

[~, loc] = ismember(subjectNamesDI, subjectNamesAG);
loc(loc==0) = [];

ageGenderVar2 = ageGenderVar(loc,:);
subjectNamesAG2 = strcat(ageGenderVar2.pseudo, '_', ageGenderVar2.wave);
[~, loc2] = ismember(subjectNamesAG2, subjectNamesDI);

dataIn.age(loc2) = ageGenderVar2.age;
dataIn.gender(loc2) = ageGenderVar2.gender;

if iscell(dataIn.age(1))
    dataIn.age(cellfun(@isempty, dataIn.age)) = {'0'};
    dataIn.age(contains(dataIn.age,'NA')) = {'0'};
    dataIn.age(contains(dataIn.age,'NaN')) = {'0'};
    dataIn.age = sscanf(sprintf(' %s',dataIn.age{:}),'%f',[1,Inf])';
end

if removeSubjects
    dataIn.age(dataIn.age==0 | cellfun(@isempty, dataIn.gender), : ) = [];
else
    dataIn.age(dataIn.age==0) = NaN;
    dataIn.gender(cellfun(@isempty, dataIn.gender)) = {'Unknown'};
end

if structbool
    dataOut = table2struct(dataIn);
else
    dataOut = dataIn;
end
