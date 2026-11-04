function [date, time] = bv_readOutDateAndTimeBdf(bdffile)
% Reads the recording start date and time from a BDF/EDF file header.
%
% Only the fixed-size (256 byte) part of the header is read. In the
% BDF/EDF format, the start date (``dd.mm.yy``) and start time
% (``hh.mm.ss``) are stored there back to back, so they are found as a
% single ``dd.mm.yyhh.mm.ss`` match.
%
% Args:
%     bdffile (str): Full path to the BDF/EDF file.
%
% Returns:
%     date (str): Start date as ``'dd-mm-yy'`` (two-digit year, as stored
%         in the header).
%     time (str): Start time as ``'hh:mm:ss'``.
%
% Example:
%     ```matlab
%     [date, time] = bv_readOutDateAndTimeBdf('B12345_10m_facehouse.bdf');
%     % date = '06-10-23', time = '09:02:41'
%     ```

fid = fopen(bdffile, 'r');
if fid < 0
    error('bv_readOutDateAndTimeBdf:cannotOpen', 'Could not open %s', bdffile)
end
closeFile = onCleanup(@() fclose(fid));

header = fread(fid, 256, '*char')';

expr = '[0-3][0-9]\.[0-1][0-9]\.[0-9][0-9][0-2][0-9]\.[0-5][0-9]\.[0-5][0-9]';
datetimestr = regexp(header, expr, 'match', 'once');

if isempty(datetimestr)
    error('bv_readOutDateAndTimeBdf:noDateTime', ...
        'No start date/time found in the header of %s (is it a BDF/EDF file?)', bdffile)
end

splitdateandtime = strsplit(datetimestr, '.');
date = [splitdateandtime{1} '-' splitdateandtime{2} '-' splitdateandtime{3}(1:2)];
time = [splitdateandtime{3}(3:4) ':' splitdateandtime{4} ':' splitdateandtime{5}(1:2)];
