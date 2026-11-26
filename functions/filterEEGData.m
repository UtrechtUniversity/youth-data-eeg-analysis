function [data] = filterEEGData(cfg, data)
% Filters EEG data (high-pass, low-pass, and/or notch) via FT_PREPROCESSING.
%
% Can be used with data passed in directly, or a raw dataset loaded from
% disk first (via cfg.dataset/cfg.hdrfile) when data is omitted.
%
% Args:
%     cfg.hpfreq (number, optional): High-pass cut-off frequency, in Hz.
%         Not applied when omitted.
%     cfg.lpfreq (number, optional): Low-pass cut-off frequency, in Hz.
%         Not applied when omitted.
%     cfg.notchfreq (number, optional): Notch filter frequency, in Hz.
%         Applied as a band-stop filter at every resonance frequency up
%         to the Nyquist frequency (``notchfreq``, ``2*notchfreq``, ...),
%         each as a +/-2 Hz band. Not applied when omitted.
%     cfg.filttype (str, optional): Filter type (``'but'`` or
%         ``'firws'``). Defaults to FieldTrip's own default (``'but'``)
%         when omitted.
%     cfg.dataset (str): Raw dataset filename. Required when no data is
%         provided.
%     cfg.hdrfile (str): Header filename. Required when no data is
%         provided.
%     data (struct, optional): FieldTrip data structure to filter. If
%         omitted, data is loaded from disk using ``cfg.dataset`` and
%         ``cfg.hdrfile``.
%
% Returns:
%     data (struct): Filtered FieldTrip data structure.
%
% Example:
%     ```matlab
%     cfg = [];
%     cfg.hpfreq    = 0.16;
%     cfg.lpfreq    = 70;
%     cfg.notchfreq = 50;
%     data = filterEEGData(cfg, data);
%     ```

dataset     = ft_getopt(cfg, 'dataset');
hdrfile     = ft_getopt(cfg, 'hdrfile');
hpfreq      = ft_getopt(cfg, 'hpfreq');
lpfreq      = ft_getopt(cfg, 'lpfreq');
notchfreq   = ft_getopt(cfg, 'notchfreq');
filttype    = ft_getopt(cfg, 'filttype');

if nargin < 2

    if isempty(dataset)
        error('No dataset given')
    end
    if isempty(hdrfile)
        error('No hdrfile given')
    end

    fprintf('no data input detected, loading raw file ... ')

    cfg.dataset = dataset;
    cfg.hdrfile = hdrfile;

    data = ft_preprocessing(cfg);
    fprintf('done! \n')
end

fprintf('\t Filtering data  ... \n')
fprintf('\t\t')
cfg = []; % create new configuration structure
if ~isempty(hpfreq) % high-pass filter configuration
    cfg.hpfilter            = 'yes';
    cfg.hpfreq              = hpfreq;
    cfg.hpfilttype          = filttype;
    cfg.hpinstabilityfix    = 'reduce'; % set to overcome problems with filter order

    fprintf('hpfilter: %1.1f ', hpfreq)

    if strcmpi(filttype, 'firws')
        cfg.hpfiltord  = floor(2048*4.8);
    end
end
if ~isempty(lpfreq) % low-pass filter configuration
    cfg.lpfilter            = 'yes';
    cfg.lpfreq              = lpfreq;
    cfg.lpfilttype          = filttype;
    cfg.lpinstabilityfix    = 'reduce';

    fprintf('lpfilter: %1.1f ', lpfreq)

    if strcmpi(filttype, 'firws')
        cfg.lpfiltord  = floor(2048*4.8);
    end
end

if ~isempty(notchfreq) % notch filter configuration
    % create a notchfilter for all the resonance frequencies of given notch
    % filter. The notch filter is created as a bandstop filter with the two
    % limits chosen as the given notchfreq +/- 2
    maxFreq         = data.fsample / 2;

    for i = 1: (maxFreq / notchfreq)
        bsFreq(i,:) = [notchfreq*i - 2, notchfreq*i + 2];
    end

    fprintf('notchfilter: %1.1f ', notchfreq)

    cfg.bsfilter            = 'yes';
    cfg.bsfreq              = bsFreq;
    cfg.bsfilttype          = 'but';
    cfg.bsinstabilityfix    = 'reduce';

    if strcmpi(filttype, 'firws')
        cfg.bsfiltord  = floor(2048*4.8);
    end

end

cfg.padding = 10; % set padding to limit edge effects of filter (not really important if you load in continuous data)

evalc('data = ft_preprocessing(cfg, data);');
fprintf('done! \n')
