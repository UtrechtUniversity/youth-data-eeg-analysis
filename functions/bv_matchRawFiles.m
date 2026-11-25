function files = bv_matchRawFiles(infos, cfg)
% Decides which raw files of one session belong together, and in which
% order and with which gaps they follow each other.
%
% The files of a session (e.g. a recording that was interrupted and
% continued in a second file) are checked against a reference file and
% sorted by the start time in their header. A file is dropped, with the
% reason recorded, when it:
% - could not be read (``readable = false`` in ``bv_readRawFileInfo``);
% - has a different sampling rate or channel layout than the reference;
% - starts further after (or before) the neighbouring file than
%   ``cfg.maxGap``;
% - overlaps the neighbouring file by more than ``cfg.seamTolerance``.
%
% The reference file is the longest readable file. It is the anchor from
% which the neighbouring files are checked outwards, one after another, so
% a short stray file far away from the main recording can't cause the main
% recording to be dropped. The gap between two consecutive used files is
% the time between the end of the first (start time plus duration) and the
% start of the second. Because header start times only have a resolution
% of 1 s, a gap within ``cfg.seamTolerance`` is set to exactly 0:
% such files are treated as one continuous recording.
%
% Args:
%     infos (struct array): One element per file, from
%         ``bv_readRawFileInfo``.
%     cfg.maxGap (number, optional): Widest gap (s) allowed between two
%         consecutive files. Defaults to ``7*24*3600`` (one week).
%     cfg.seamTolerance (number, optional): Gaps and overlaps up to this
%         size (s) are treated as 0. Defaults to ``1``.
%
% Returns:
%     files (struct array): The elements of ``infos``, sorted by start
%         time (files that could not be read last), with the extra
%         fields:
%
%         - ``status`` (str): ``'used'`` or ``'dropped'``.
%         - ``reason`` (str): Why the file was dropped; ``''`` for used
%           files.
%         - ``gapToPrevious`` (number): Seconds between the end of the
%           previous used file and the start of this one (0 when
%           contiguous); ``NaN`` for the first used file and for dropped
%           files.
%
%         If no file can be used, all files are dropped.
%
% Example:
%     ```matlab
%     infos = arrayfun(@(f) bv_readRawFileInfo(fullfile(f.folder, f.name)), dir('*.bdf'));
%     cfg = [];
%     cfg.maxGap = 3600;
%     files = bv_matchRawFiles(infos, cfg);
%     used = files(strcmp({files.status}, 'used'));
%     ```

maxGap        = ft_getopt(cfg, 'maxGap', 7*24*3600);
seamTolerance = ft_getopt(cfg, 'seamTolerance', 1);

nFiles = numel(infos);
if nFiles == 0
    error('bv_matchRawFiles: no files given')
end

% sort: readable files by start time (ties by name), unreadable ones last
readableIdx   = find([infos.readable]);
unreadableIdx = find(~[infos.readable]);
if ~isempty(readableIdx)
    [~, o] = sort({infos(readableIdx).file});
    readableIdx = readableIdx(o);
    [~, o] = sort(posixtime([infos(readableIdx).startTime]));
    readableIdx = readableIdx(o);
end
[~, o] = sort({infos(unreadableIdx).file});
unreadableIdx = unreadableIdx(o);

files = infos([readableIdx(:); unreadableIdx(:)]);
nReadable = numel(readableIdx);

% unreadable files keep the reason from bv_readRawFileInfo
for i = 1:nFiles
    files(i).status        = 'dropped';
    files(i).gapToPrevious = NaN;
    if files(i).readable
        files(i).reason = '';
    end
end

if nReadable == 0
    return
end

% reference: the longest readable file
[~, p] = max([files(1:nReadable).duration]);
ref = files(p);

t0 = posixtime([files(1:nReadable).startTime]);
t1 = t0 + [files(1:nReadable).duration];

% check every file against the reference, then walk outwards from the
% reference, comparing each file to its nearest neighbour that was kept
keep = false(1, nReadable);
keep(p) = true;

nextStart = t0(p);
for i = p-1:-1:1
    [ok, why] = compareWithReference(files(i), ref);
    if ok
        gap = nextStart - t1(i);
        [ok, why] = checkGap(gap, maxGap, seamTolerance);
    end
    if ok
        keep(i) = true;
        nextStart = t0(i);
    else
        files(i).reason = why;
    end
end

prevEnd = t1(p);
for i = p+1:nReadable
    [ok, why] = compareWithReference(files(i), ref);
    if ok
        gap = t0(i) - prevEnd;
        [ok, why] = checkGap(gap, maxGap, seamTolerance);
    end
    if ok
        keep(i) = true;
        prevEnd = t1(i);
    else
        files(i).reason = why;
    end
end

% gaps between consecutive used files; 0 within the tolerance
usedIdx = find(keep);
for k = 1:numel(usedIdx)
    i = usedIdx(k);
    files(i).status = 'used';
    if k > 1
        gap = t0(i) - t1(usedIdx(k-1));
        if abs(gap) <= seamTolerance
            gap = 0;
        end
        files(i).gapToPrevious = gap;
    end
end


% =========================================================================
function [ok, why] = compareWithReference(f, ref)
% A file can be stitched to the reference if it has the same channels
% (number and labels) and the same sampling rate.

ok  = false;
why = '';
if f.nChannels ~= ref.nChannels
    why = sprintf('channel layout differs from the reference file (%d channels, reference %d)', ...
        f.nChannels, ref.nChannels);
elseif ~isequal(round(f.samplesPerRecord ./ f.recordDuration * 1e6), ...
        round(ref.samplesPerRecord ./ ref.recordDuration * 1e6))
    why = sprintf('sampling rate differs from the reference file (%g Hz, reference %g Hz)', f.fs, ref.fs);
elseif ~isequal(f.labels, ref.labels)
    why = 'channel labels differ from the reference file';
else
    ok = true;
end


% =========================================================================
function [ok, why] = checkGap(gap, maxGap, seamTolerance)
% The gap to the neighbouring used file must be at most maxGap and the
% files may only overlap within the tolerance.

ok  = true;
why = '';
if gap < -seamTolerance
    ok  = false;
    why = sprintf('overlaps the neighbouring file by %.1f s (tolerance %g s)', -gap, seamTolerance);
elseif gap > maxGap
    ok  = false;
    why = sprintf('is %.0f s away from the neighbouring file (maximum gap %g s)', gap, maxGap);
end
