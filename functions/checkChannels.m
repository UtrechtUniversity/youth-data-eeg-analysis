function chanindx = checkChannels(filename, channels)
% Returns channel indices from an EDF/BDF file header matching given labels.
%
% Reads only the file header — the full recording is not loaded into memory.
% Channel matching uses substring search, so a partial label will match any
% channel whose name contains it.
%
% Args:
%     filename (str): Full path to the EDF or BDF file.
%     channels (str or cell array of str): Channel label(s) to search for.
%
% Returns:
%     chanindx (numeric): Indices of the matching channels in the file's
%         channel list.
%
% Example:
%     ```matlab
%     chanindx = checkChannels('subject_01.bdf', {'EEG', 'EOG'});
%     ```

fid    = fopen(filename, 'r', 'ieee-le');
H1     = char(fread(fid, 256, 'uint8=>char')');
NS     = str2double(H1(253:256)); % EDF header: bytes 253-256 = number of signals
labels = cellstr(char(fread(fid, [16, NS], 'uint8=>char')')); % signal labels: 16 bytes each
fclose(fid);

chanindx = find(contains(labels, channels));