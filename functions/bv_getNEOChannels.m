function chans = bv_getNEOChannels(type)
% Returns a fixed list of NEO-montage channel labels for a given type.
%
% Args:
%     type (str): Channel set to return. Options: ``'bipolar'`` (16
%         bipolar pairs, e.g. ``'EEG Fp2-C4'``, matching the convention
%         expected by ``bv_createBipolarLayout``) or ``'regular'`` (11
%         single electrodes, e.g. ``'EEG Fp1'``).
%
% Returns:
%     chans (cell array of str): Channel labels for the requested type.
%
% Example:
%     ```matlab
%     chans = bv_getNEOChannels('bipolar');
%     ```

switch type
    case 'bipolar'
        chans = {'EEG Fp2-C4', 'EEG C4-O2', 'EEG Fp1-C3', 'EEG C3-O1', ...
            'EEG Fp2-T8', 'EEG T8-O2', 'EEG Fp1-T7', 'EEG T7-O1', ...
            'EEG T8-C4', 'EEG C4-Cz', 'EEG Cz-C3', 'EEG C3-T7', ...
            'EEG Fp2-Cz', 'EEG Cz-O2', 'EEG Fp1-Cz', 'EEG Cz-O1'};
    case 'regular'
        chans = {'EEG Fp1' 'EEG Fp2' 'EEG C3' 'EEG C4' 'EEG O1' 'EEG O2' 'EEG T7' 'EEG T8' 'EEG Cz', 'EEG F9', 'EEG F10'};
    otherwise
        error('bv_getNEOChannels:unknownType', ...
            'Unknown type ''%s''; expected ''bipolar'' or ''regular''.', type)
end
