function chans = bv_getNEOChannels(type)

switch type
    case 'bipolar'
        chans = {'EEG Fp2-C4', 'EEG C4-O2', 'EEG Fp1-C3', 'EEG C3-O1', ...
            'EEG Fp2-T8', 'EEG T8-O2', 'EEG Fp1-T7', 'EEG T7-O1', ...
            'EEG T8-C4', 'EEG C4-Cz', 'EEG Cz-C3', 'EEG C3-T7', ...
            'EEG Fp2-Cz', 'EEG Cz-O2', 'EEG Fp1-Cz', 'EEG Cz-O1'};
    case 'regular'
        chans = {'EEG Fp1' 'EEG Fp2' 'EEG C3' 'EEG C4' 'EEG O1' 'EEG O2' 'EEG T7' 'EEG T8' 'EEG Cz', 'EEG F9', 'EEG F10'};
end
