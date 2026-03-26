function chanindx = bv_checkChannels(filename, channels)

FILENAME = filename;

% defines Seperator for Subdirectories
SLASH='/';
BSLASH=char(92);

cname=computer;
if cname(1:2)=='PC' SLASH=BSLASH; end

fid=fopen(FILENAME,'r','ieee-le');

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

H1=char(fread(EDF.FILE.FID,256,'uint8=>char')');
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
EDF.Dur  = str2num(H1(245:252));     % 8 Byte  # duration of data record in sec
EDF.NS   = str2num(H1(253:256));     % 8 Byte  # of signals

EDF.Label      = cellstr(char(fread(EDF.FILE.FID,[16,EDF.NS],'uint8=>char')'));

chanindx = find(contains(EDF.Label, channels));


