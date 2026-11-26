function info = readRawFileInfo(file)
% Reads the recording information of a BDF/EDF file from its header,
% without reading the data.
%
% Only the header is read (256 fixed bytes plus the per-channel part), so
% this is fast even for large recordings. The function never errors on a
% bad file: a file that cannot be used (missing, too small to hold a
% header, not a BDF/EDF header, invalid fields, truncated) is returned
% with ``readable = false`` and the reason in ``reason``, so a caller can
% drop that file and carry on with the others.
%
% A file counts as truncated when it holds fewer data records than the
% header announces. A header that announces an unknown number of records
% (-1) is read as holding all records that fit in the file.
%
% Args:
%     file (str): Full path to the BDF/EDF file.
%
% Returns:
%     info (struct): Scalar struct with the fields:
%
%         - ``file`` (str): The path that was given.
%         - ``bytes`` (number): File size in bytes (``NaN`` if the file
%           does not exist).
%         - ``readable`` (logical): ``true`` if the header is valid and the
%           file is complete.
%         - ``reason`` (str): Why the file is not readable; ``''`` if it is.
%         - ``startTime`` (datetime): Recording start from the header
%           (1 s resolution); ``NaT`` if it could not be read.
%         - ``nRecords`` (number): Number of data records.
%         - ``recordDuration`` (number): Duration of one data record (s).
%         - ``duration`` (number): Duration of the recording (s).
%         - ``nChannels`` (number): Number of channels (including the
%           status channel).
%         - ``labels`` (cell array of str): Channel labels.
%         - ``samplesPerRecord`` (vector): Samples per data record, per
%           channel.
%         - ``fs`` (number): Sampling rate (Hz) of the channels (the most
%           common one, as the status channel can differ).
%
% Example:
%     ```matlab
%     info = readRawFileInfo('B12345_10m_facehouse.bdf');
%     % info.readable = true, info.fs = 2048, info.duration = 412
%     ```

info = struct('file', file, 'bytes', NaN, 'readable', false, 'reason', '', ...
    'startTime', NaT, 'nRecords', NaN, 'recordDuration', NaN, 'duration', NaN, ...
    'nChannels', NaN, 'labels', {{}}, 'samplesPerRecord', [], 'fs', NaN);

listing = dir(file);
if isempty(listing) || all([listing.isdir])
    info.reason = 'file not found';
    return
end
info.bytes = listing(1).bytes;

if info.bytes < 256
    info.reason = sprintf('file too small to hold a header (%d bytes)', info.bytes);
    return
end

fid = fopen(file, 'r');
if fid < 0
    info.reason = 'file could not be opened';
    return
end
closeFile = onCleanup(@() fclose(fid));

raw = fread(fid, 256, 'uint8=>uint8')';

% BDF files start with the byte 255, EDF files with the character '0'
if raw(1) == 255
    bytesPerSample = 3;
elseif raw(1) == double('0')
    bytesPerSample = 2;
else
    info.reason = 'not a BDF/EDF header';
    return
end

startDate   = sscanf(char(raw(169:176)), '%d.%d.%d');
startClock  = sscanf(char(raw(177:184)), '%d.%d.%d');
headerBytes = str2double(char(raw(185:192)));
nRecords    = str2double(char(raw(237:244)));
recDuration = str2double(char(raw(245:252)));
nChannels   = str2double(char(raw(253:256)));

if numel(startDate) ~= 3 || numel(startClock) ~= 3 || ...
        startDate(1) < 1 || startDate(1) > 31 || startDate(2) < 1 || startDate(2) > 12 || ...
        startClock(1) > 23 || startClock(2) > 59 || startClock(3) > 59
    info.reason = 'invalid start date/time in the header';
    return
end
if isnan(headerBytes) || isnan(nRecords) || isnan(recDuration) || isnan(nChannels) || ...
        nChannels < 1 || recDuration <= 0 || headerBytes < 256 * (1 + nChannels)
    info.reason = 'invalid header fields';
    return
end

% two-digit year: 85-99 is 1985-1999, 00-84 is 2000-2084 (EDF specification)
year = startDate(3);
if year >= 85
    year = 1900 + year;
else
    year = 2000 + year;
end
startTime = datetime(year, startDate(2), startDate(1), startClock(1), startClock(2), startClock(3));

% per-channel part: the labels come first, the samples per record after
% 216 bytes of other fields per channel
fseek(fid, 256, 'bof');
labelText = fread(fid, nChannels * 16, 'uint8=>char')';
fseek(fid, 256 + nChannels * 216, 'bof');
sampleText = fread(fid, nChannels * 8, 'uint8=>char')';
if numel(labelText) < nChannels * 16 || numel(sampleText) < nChannels * 8
    info.reason = 'header is incomplete';
    return
end
labels = strtrim(cellstr(reshape(labelText, 16, nChannels)'));
samplesPerRecord = str2double(cellstr(reshape(sampleText, 8, nChannels)'))';
if any(isnan(samplesPerRecord)) || any(samplesPerRecord < 1)
    info.reason = 'invalid number of samples per record in the header';
    return
end

recordBytes = sum(samplesPerRecord) * bytesPerSample;
if nRecords < 0
    nRecords = floor((info.bytes - headerBytes) / recordBytes);
end

info.startTime        = startTime;
info.nRecords         = nRecords;
info.recordDuration   = recDuration;
info.duration         = nRecords * recDuration;
info.nChannels        = nChannels;
info.labels           = labels(:)';
info.samplesPerRecord = samplesPerRecord;
info.fs               = mode(samplesPerRecord) / recDuration;

if nRecords < 1
    info.reason = 'no data records';
elseif info.bytes < headerBytes + nRecords * recordBytes
    nPresent = max(floor((info.bytes - headerBytes) / recordBytes), 0);
    info.reason = sprintf('file is truncated (%d of %d data records present)', nPresent, nRecords);
else
    info.readable = true;
end
