function Tout = bv_addGestationalAgeToTable(Tin)

gestPath = ...
    '/Volumes/youth.data.uu.nl/research-grp-ydi-1904-02/20191101_GestationalAge.xlsx';
gestPresent = ...
    exist(gestPath, 'file');
if not(gestPresent)
    error('Demo2.xlsx not found')
else
    evalc('T_gest = readtable(gestPath);');
end

T_gest.daysOld = T_gest.YBECHCHLABJGENEQ001_Weeks_ * 7 + ...
    T_gest.YBECHCHLABJGENEQ001_Days_;
T_gest.conceptionDate = datetime(T_gest.date, 'format', 'yyyy-MM-dd') - T_gest.daysOld;

Tout = Tin;
for i = 1:height(Tout)
    subjIndx = ismember(T_gest.pseudoKind, Tout.pseudo(i));
    subjIndx = max(find(subjIndx));
    
    if ~isempty(subjIndx)
        Tout.gestationalAge(i) = ...
            days(datetime(Tout.testdate(i), 'Input', 'dd-MM-yy') - ...
            T_gest.conceptionDate(subjIndx));
    else
        Tout.gestationalAge(i) = NaN;
    end
end
