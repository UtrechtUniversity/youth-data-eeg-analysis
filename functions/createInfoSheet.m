fields2readout = {{'cleaned', 'withBadChannels', 'condition11'}, ...
    {'cleaned', 'withBadChannels', 'condition12'}, ...
    {'cleaned', 'withBadChannels', 'total'}, ...
    {'useableTrials', 'withoutBadChannels', 'condition11_cleaned'}, ...
    {'useableTrials', 'withoutBadChannels', 'condition12_cleaned'}, ...
    {'useableTrials', 'withoutBadChannels', 'total'}, ...
    'removedchannels'};

cfg = [];
cfg.startSubject = 1;
cfg.endSubject = 'end';
cfg.analysisTree = [];
cfg.structFileName = 'Subject.mat';
cfg.structVarFname = 'subjectdata';
cfg.namesOnly = 'yes';
[~, names] = readOutStructFromFile(cfg);

output = [];
hdr = {};

for iField = 1:length(fields2readout)
    
    cfg.namesOnly = 'no';
    cfg.fields = fields2readout{iField};
    currOutput = readOutStructFromFile(cfg);
    
    if isnumeric(currOutput)
        currOutput = num2cell(currOutput);
    end
    
    output = cat(2, output, currOutput);
    
    if iscell( fields2readout{iField} )
        currFields = repmat(fields2readout{iField}(end), 1, size(currOutput, 2));
    else
        currFields = repmat(fields2readout(iField), 1, size(currOutput, 2));
    end
    hdr = cat(2, hdr, currFields);
    
end

hdr = cat(2, 'names', hdr);
output = cat(2, names, output);
output = cat(1, hdr, output);

xlwrite('subjectInfoSheet3', output);
