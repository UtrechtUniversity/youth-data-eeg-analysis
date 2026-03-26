bdfs = dir('*.bdf');
coherenceTriggers = [129 139];
houseTriggers = 133:10:243;
faceTriggers = sort([131:10:181 132:10:182]);
for i = 1:length(bdfs)
    
    FILENAME = bdfs(i).name;
    disp(FILENAME)
    
    % defines Seperator for Subdirectories
    SLASH='/';
    BSLASH=char(92);
    
    cname=computer;
    if cname(1:2)=='PC' SLASH=BSLASH; end
    
    try
        fid=fopen(FILENAME,'r','ieee-le');
    catch err
        fprintf(2,['Error LOADEDF: File ' FILENAME ' not found\n']);
        return;
    end
    
    EDF.FILE.FID=fid;
    EDF.FILE.OPEN = 1;
    EDF.FileName = FILENAME;
    
    PPos=min([max(find(FILENAME=='.')) length(FILENAME)+1]);
    SPos=max([0 find((FILENAME=='/') | (FILENAME==BSLASH))]);
    EDF.FILE.Ext = FILENAME(PPos+1:length(FILENAME));
    EDF.FILE.Name = FILENAME(SPos+1:PPos-1);
    if SPos==0
        EDF.FILE.Path = pwd;
    else
        EDF.FILE.Path = FILENAME(1:SPos-1);
    end
    EDF.FileName = [EDF.FILE.Path SLASH EDF.FILE.Name '.' EDF.FILE.Ext];
    
    H1=char(fread(EDF.FILE.FID,256,'char')');     %
    EDF.VERSION=H1(1:8);                          % 8 Byte  Versionsnummer
    %if 0 fprintf(2,'LOADEDF: WARNING  Version EDF Format %i',ver); end
    EDF.PID = deblank(H1(9:88));                  % 80 Byte local patient identification
    EDF.RID = deblank(H1(89:168));                % 80 Byte local recording identification
    %EDF.H.StartDate = H1(169:176);               % 8 Byte
    %EDF.H.StartTime = H1(177:184);               % 8 Byte
    EDF.T0=[str2num(H1(168+[7 8])) str2num(H1(168+[4 5])) str2num(H1(168+[1 2])) str2num(H1(168+[9 10])) str2num(H1(168+[12 13])) str2num(H1(168+[15 16])) ];
    
    % Y2K compatibility until year 2090
    if EDF.VERSION(1)=='0'
        if EDF.T0(1) < 91
            EDF.T0(1)=2000+EDF.T0(1);
        else
            EDF.T0(1)=1900+EDF.T0(1);
        end
    else
        % in a future version, this is hopefully not needed
    end
    
    EDF.HeadLen = str2num(H1(185:192));  % 8 Byte  Length of Header
    % reserved = H1(193:236);            % 44 Byte
    EDF.NRec = str2num(H1(237:244));     % 8 Byte  # of data records
    EDF.Dur = str2num(H1(245:252));      % 8 Byte  # duration of data record in sec
    EDF.NS = str2num(H1(253:256));       % 8 Byte  # of signals
    
    EDF.Label = char(fread(EDF.FILE.FID,[16,EDF.NS],'char')');
    EDF.Transducer = char(fread(EDF.FILE.FID,[80,EDF.NS],'char')');
    EDF.PhysDim = char(fread(EDF.FILE.FID,[8,EDF.NS],'char')');
    
    EDF.PhysMin= str2num(char(fread(EDF.FILE.FID,[8,EDF.NS],'char')'));
    EDF.PhysMax= str2num(char(fread(EDF.FILE.FID,[8,EDF.NS],'char')'));
    EDF.DigMin = str2num(char(fread(EDF.FILE.FID,[8,EDF.NS],'char')'));
    EDF.DigMax = str2num(char(fread(EDF.FILE.FID,[8,EDF.NS],'char')'));
    
    % check validity of DigMin and DigMax
    if (length(EDF.DigMin) ~= EDF.NS)
        fprintf(2,'Warning OPENEDF: Failing Digital Minimum\n');
        EDF.DigMin = -(2^15)*ones(EDF.NS,1);
    end
    if (length(EDF.DigMax) ~= EDF.NS)
        fprintf(2,'Warning OPENEDF: Failing Digital Maximum\n');
        EDF.DigMax = (2^15-1)*ones(EDF.NS,1);
    end
    if (any(EDF.DigMin >= EDF.DigMax))
        fprintf(2,'Warning OPENEDF: Digital Minimum larger than Maximum\n');
    end
    % check validity of PhysMin and PhysMax
    if (length(EDF.PhysMin) ~= EDF.NS)
        fprintf(2,'Warning OPENEDF: Failing Physical Minimum\n');
        EDF.PhysMin = EDF.DigMin;
    end
    if (length(EDF.PhysMax) ~= EDF.NS)
        fprintf(2,'Warning OPENEDF: Failing Physical Maximum\n');
        EDF.PhysMax = EDF.DigMax;
    end
    if (any(EDF.PhysMin >= EDF.PhysMax))
        fprintf(2,'Warning OPENEDF: Physical Minimum larger than Maximum\n');
        EDF.PhysMin = EDF.DigMin;
        EDF.PhysMax = EDF.DigMax;
    end
    EDF.PreFilt= char(fread(EDF.FILE.FID,[80,EDF.NS],'char')');   %
    tmp = fread(EDF.FILE.FID,[8,EDF.NS],'char')'; %   samples per data record
    EDF.SPR = str2num(char(tmp));               % samples per data record
    
    fseek(EDF.FILE.FID,32*EDF.NS,0);
    
    EDF.Cal = (EDF.PhysMax-EDF.PhysMin)./(EDF.DigMax-EDF.DigMin);
    EDF.Off = EDF.PhysMin - EDF.Cal .* EDF.DigMin;
    tmp = find(EDF.Cal < 0);
    EDF.Cal(tmp) = ones(size(tmp));
    EDF.Off(tmp) = zeros(size(tmp));
    
    % the following adresses https://github.com/fieldtrip/fieldtrip/pull/395
    tmp = find(strcmpi(cellstr(EDF.Label), 'STATUS'));
    if EDF.Cal(tmp)~=1
        timeout = 60*15; % do not show it for the next 15 minutes
        ft_warning('FieldTrip:BDFCalibration', 'calibration for status channel appears incorrect, setting it to 1', timeout);
        EDF.Cal(tmp) = 1;
    end
    if EDF.Off(tmp)~=0
        timeout = 60*15; % do not show it for the next 15 minutes
        ft_warning('FieldTrip:BDFOffset', 'offset for status channel appears incorrect, setting it to 0', timeout);
        EDF.Off(tmp) = 0;
    end
    
    EDF.Calib=[EDF.Off';(diag(EDF.Cal))];
    
    EDF.SampleRate = EDF.SPR / EDF.Dur;
    
    EDF.FILE.POS = ftell(EDF.FILE.FID);
    if EDF.NRec == -1                            % unknown record size, determine correct NRec
        fseek(EDF.FILE.FID, 0, 'eof');
        endpos = ftell(EDF.FILE.FID);
        EDF.NRec = floor((endpos - EDF.FILE.POS) / (sum(EDF.SPR) * 3)); % Bug found by Bauke van der Velde (changed from * 2 to * 3)
        fseek(EDF.FILE.FID, EDF.FILE.POS, 'bof');
        H1(237:244)=sprintf('%-8i',EDF.NRec);      % write number of records
    end
    
    EDF.Chan_Select=(EDF.SPR==max(EDF.SPR));
    for k=1:EDF.NS
        if EDF.Chan_Select(k)
            EDF.ChanTyp(k)='N';
        else
            EDF.ChanTyp(k)=' ';
        end
        if contains(upper(EDF.Label(k,:)),'ECG')
            EDF.ChanTyp(k)='C';
        elseif contains(upper(EDF.Label(k,:)),'EKG')
            EDF.ChanTyp(k)='C';
        elseif contains(upper(EDF.Label(k,:)),'EEG')
            EDF.ChanTyp(k)='E';
        elseif contains(upper(EDF.Label(k,:)),'EOG')
            EDF.ChanTyp(k)='O';
        elseif contains(upper(EDF.Label(k,:)),'EMG')
            EDF.ChanTyp(k)='M';
        end
    end
    
    EDF.AS.spb = sum(EDF.SPR);    % Samples per Block
    
    % close the file
    fclose(EDF.FILE.FID);
    
    if any(EDF.SampleRate~=EDF.SampleRate(1))
        ft_error('channels with different sampling rate not supported');
    end
    hdr.Fs          = EDF.SampleRate(1);
    hdr.nChans      = EDF.NS;
    hdr.label       = cellstr(EDF.Label);
    % it is continuous data, therefore append all records in one trial
    hdr.nTrials     = 1;
    hdr.nSamples    = EDF.NRec * EDF.Dur * EDF.SampleRate(1);
    hdr.nSamplesPre = 0;
    hdr.orig        = EDF;
    
    begsample = 1;
    endsample = hdr.nSamples*hdr.nTrials;
    
    % determine the trial containing the begin and end sample
    epochlength = EDF.Dur * EDF.SampleRate(1);
    begepoch    = floor((begsample-1)/epochlength) + 1;
    endepoch    = floor((endsample-1)/epochlength) + 1;
    nepochs     = endepoch - begepoch + 1;
    nchans      = EDF.NS;
    
    chanindx = find(strcmpi(hdr.label,'STATUS'));
    
    % allocate memory to hold the data
    dat = zeros(length(chanindx),nepochs*epochlength);
    
    % read and concatenate all required data epochs
    for j=begepoch:endepoch
        offset = EDF.HeadLen + (j-1)*epochlength*nchans*3;
        % this is more efficient if only one channel has to be read, e.g. the status channel
        offset = offset + (chanindx-1)*epochlength*3;
        
        fp = fopen(FILENAME,'r','ieee-le');
        status = fseek(fp, offset, 'bof');
        [buf,num] = fread(fp,epochlength,'bit24=>double');
        fclose(fp);
        dat(:,((j-begepoch)*epochlength+1):((j-begepoch+1)*epochlength)) = buf;
        
    end
    
    % select the desired samples
    begsample = begsample - (begepoch-1)*epochlength;  % correct for the number of bytes that were skipped
    endsample = endsample - (begepoch-1)*epochlength;  % correct for the number of bytes that were skipped
    dat = dat(:, begsample:endsample);
    
    % convert from digital to physical values and apply the offset
    calib  = EDF.Cal(chanindx);
    offset = EDF.Off(chanindx);
    for i=1:numel(calib)
        dat(i,:) = calib(i)*dat(i,:) + offset(i);
    end
    
    sdata = dat;
    sdata = bitand(int32(sdata), 2^24-1);
    
    byte1 = 2^8  - 1;
    byte2 = 2^16 - 1 - byte1;
    byte3 = 2^24 - 1 - byte1 - byte2;
    
    % get the respective status and trigger bits
    trigger = bitand(sdata, bitor(byte1, byte2)); % this is contained in the lower two bytes
    epoch   = int8(bitget(sdata, 16+1));
    cmrange = int8(bitget(sdata, 20+1));
    battery = int8(bitget(sdata, 22+1));
    
    % determine when the respective status bits go up or down
    flank_trigger = diff([0 trigger]);
    flank_epoch   = diff([0 epoch ]);
    flank_cmrange = diff([0 cmrange]);
    flank_battery = diff([0 battery]);
    
    %%%%%%%%%% HACK ADDED BY BAUKE VAN DER VELDE 20160218 %%%%%%%%%%
    
    trigger = bitand( sdata, byte1 );           % convert to 8bit numbers
    flank_trigger = abs( flank_trigger );       % take the absolute value of flank_trigger to also register down-flanks
    flank_trigger( trigger==0 ) = 0;            % ignore 0 trigger resets in trigger data
    
    %%%%%%%%%% HACK ADDED BY BAUKE VAN DER VELDE 20160218 %%%%%%%%%%
    event = [];
    
    for i=find(flank_trigger>0)
        event(end+1).type   = 'STATUS';
        event(end  ).sample = i + begsample - 1;
        event(end  ).value  = double(trigger(i));
    end
    
    for i=find(flank_epoch==1)
        event(end+1).type   = 'Epoch';
        event(end  ).sample = i;
    end
    
    for i=find(flank_cmrange==1)
        event(end+1).type   = 'CM_in_range';
        event(end  ).sample = i;
    end
    
    for i=find(flank_cmrange==-1)
        event(end+1).type   = 'CM_out_of_range';
        event(end  ).sample = i;
    end
    
    for i=find(flank_battery==1)
        event(end+1).type   = 'Battery_low';
        event(end  ).sample = i;
    end
    
    for i=find(flank_battery==-1)
        event(end+1).type   = 'Battery_ok';
        event(end  ).sample = i;
    end
    
    fprintf('\t %1.0f coherence trials \n', sum(ismember([event.value], coherenceTriggers)))
    fprintf('\t %1.0f house trials \n', sum(ismember([event.value], [faceTriggers houseTriggers])))
    
end
