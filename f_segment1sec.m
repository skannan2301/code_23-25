function f_segment1sec(input_file, output_file, metadata_file, params)
    % f_segment1sec - Imports a .set file, creates 1 second epochs, and saves the result
    % the inputFile should be the COPY version from filter 2!!!
    % 
    % Syntax: f_segment1sec(input_file, output_file, metadata_file, params)
    %
    % Inputs:
    %    input_file - String, path to the input set file
    %    output_file - output file where epoched data is saved
    %    metadata_file - 
    %    params - 
    
    % Load EEGLAB to enable importing set, fdt files
    tic;    
    %addpath('/gpfs/milgram/project/naples/ajn23/codeLib/eeglab1024/eeglab2024.2')
    addpath('/Users/shreya/Desktop/eeglab2024.0')
    eeglab('nogui'); % ensure EEGLAB is added to the path

    % Load the saved .set file --> THE COPY 
    EEG = pop_loadset('filename', input_file); 
    EEG = eeg_checkset(EEG); 
    
    EEG_copy=[];
    EEG_copy=EEG; % make a copy of the dataset again 
    EEG_copy = eeg_checkset(EEG_copy);

    % this is from when they ran faster --> need these for checking if all
    % channels marked bad line 86
    channels_analysed=EEG.chanlocs;
    N_channels_analysed = size(channels_analysed,2);

    % Create 1 second epoch in our copy file 
    % params from made bond pipeline: recurrence 1, limits [0 1], rmbase [NaN], eventype '999'
    EEG_copy=eeg_regepochs(EEG_copy,'recurrence', 1, 'limits',[0 1], 'rmbase', [NaN], 'eventtype', '999'); % insert temporary marker 1 second apart and create epochs
    % with the params input? --> don't know if this works
    %EEG_copy=eeg_regepochs(EEG_copy,'recurrence', params.recurrence, 'limits',params.limit, 'rmbase', params.rmbase, 'eventtype', params.eventtype); % insert temporary marker 1 second apart and create epochs
    EEG_copy = eeg_checkset(EEG_copy);

    % Find bad epochs and delete them from dataset
    vol_thrs = [-1000 1000]; % [lower upper] threshold limit(s) in uV.
    emg_thrs = [-100 30]; % [lower upper] threshold limit(s) in dB.
    emg_freqs_limit = [20 40]; % [lower upper] frequency limit(s) in Hz.

    % Find channel/s with xx% of artifacted 1-second epochs and delete them
    chanCounter = 1; ica_prep_badChans = [];
    numEpochs =EEG_copy.trials; % find the number of epochs
    all_bad_channels_ica=0;

    for ch=1:EEG_copy.nbchan
        % Find artifacted epochs by detecting outlier voltage
        EEG_copy = pop_eegthresh(EEG_copy,1, ch, vol_thrs(1), vol_thrs(2), EEG_copy.xmin, EEG_copy.xmax, 0, 0);
        EEG_copy = eeg_checkset( EEG_copy );
    
        % 1         : data type (1: electrode, 0: component)
        % 0         : display with previously marked rejections? (0: no, 1: yes)
        % 0         : reject marked trials? (0: no (but store the  marks), 1:yes)
    
        % Find artifaceted epochs by using thresholding of frequencies in the data.
        % this method mainly rejects muscle movement (EMG) artifacts
        EEG_copy = pop_rejspec( EEG_copy, 1,'elecrange',ch ,'method','fft','threshold', emg_thrs, 'freqlimits', emg_freqs_limit, 'eegplotplotallrej', 0, 'eegplotreject', 0);
    
        % method                : method to compute spectrum (fft)
        % threshold             : [lower upper] threshold limit(s) in dB.
        % freqlimits            : [lower upper] frequency limit(s) in Hz.
        % eegplotplotallrej     : 0 = Do not superpose rejection marks on previous marks stored in the dataset.
        % eegplotreject         : 0 = Do not reject marked trials (but store the  marks).
    
        % Find number of artifacted epochs
        EEG_copy = eeg_checkset( EEG_copy );
        EEG_copy = eeg_rejsuperpose( EEG_copy, 1, 1, 1, 1, 1, 1, 1, 1);
        artifacted_epochs=EEG_copy.reject.rejglobal;

        % Find bad channel / channel with more than 20% artifacted epochs
        if sum(artifacted_epochs) > (numEpochs*20/100)
            ica_prep_badChans(chanCounter) = ch;
            chanCounter=chanCounter+1;
        end
    end

    % If all channels are bad, save the dataset at this stage and ignore the remaining of the preprocessing. --> they're comparing the number of bad chans in the COPY (EEG_copy) to the original EEG (which is just EEG)
    if numel(ica_prep_badChans)==EEG.nbchan || numel(ica_prep_badChans)+1==EEG.nbchan || numel(ica_prep_badChans)==N_channels_analysed || numel(ica_prep_badChans)+1==N_channels_analysed || ...
    numel(ica_prep_badChans) >= round((N_channels_analysed-1)/100*10) % RH; 10% relative to the number of common channels
        all_bad_channels_ica=1; % note for future use: this variable can be used to see if the file had too many bad chans for ICA 
        EEG = eeg_checkset(EEG); % save the original before artifact detection and removal 
        new_basename1 = [basename '_no_usable_data_all_bad_channels_ica_prep'];        % Append '_no_usable_data_all_bad_channels_ica_prep' to the base name
        EEG = pop_saveset(EEG, 'filename', [new_basename1 '.set'], 'filepath', outputFile);         % Save the dataset that has too many bad chans with the new name
    else % continuing on with the COPY 
        % Reject bad channel - channel with more than xx% artifacted epochs
        EEG_copy = pop_select( EEG_copy,'nochannel', ica_prep_badChans);
        EEG_copy = eeg_checkset(EEG_copy);
    end
    
    % Find the artifacted epochs across all channels and reject them before doing ICA.
    EEG_copy = pop_eegthresh(EEG_copy,1, 1:EEG_copy.nbchan, vol_thrs(1), vol_thrs(2), EEG_copy.xmin, EEG_copy.xmax,0,0);
    EEG_copy = eeg_checkset(EEG_copy);

    % 1         : data type (1: electrode, 0: component)
    % 0         : display with previously marked rejections? (0: no, 1: yes)
    % 0         : reject marked trials? (0: no (but store the  marks), 1:yes)

    % Find artifaceted epochs by using power threshold in 20-40Hz frequency band.
    % This method mainly rejects muscle movement (EMG) artifacts.
    EEG_copy = pop_rejspec(EEG_copy, 1,'elecrange', 1:EEG_copy.nbchan, 'method', 'fft', 'threshold', emg_thrs ,'freqlimits', emg_freqs_limit, 'eegplotplotallrej', 0, 'eegplotreject', 0);

    % method                : method to compute spectrum (fft)
    % threshold             : [lower upper] threshold limit(s) in dB.
    % freqlimits            : [lower upper] frequency limit(s) in Hz.
    % eegplotplotallrej     : 0 = Do not superpose rejection marks on previous marks stored in the dataset.
    % eegplotreject         : 0 = Do not reject marked trials (but store the  marks).

    % Find the number of artifacted epochs and reject them
    EEG_copy = eeg_checkset(EEG_copy);
    EEG_copy = eeg_rejsuperpose(EEG_copy, 1, 1, 1, 1, 1, 1, 1, 1);
    reject_artifacted_epochs=EEG_copy.reject.rejglobal;
    EEG_copy = pop_rejepoch(EEG_copy, reject_artifacted_epochs, 0);

    % save the epoched .set file 
    EEG_copy = eeg_checkset(EEG_copy);
    EEG_copy = pop_saveset(EEG_copy, 'filename', output_file);         % Save the dataset
    
    %save ica_prep_badChans since it's used to run ICA
    EEG.preproc.ica_prep_badChans.labels = ica_prep_badChans;
    %save(fullfile(outputFile, 'ica_prep_badChans.mat'), 'ica_prep_badChans');

    % Save metadata including the parameters used
    metadata = struct();
    metadata.processing_date = datestr(now);
    %metadata.parameters = params;
    savejson('', metadata, metadata_file);

    toc;
    %quit;
end
