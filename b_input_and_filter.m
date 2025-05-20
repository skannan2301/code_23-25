function b_input_and_filter(input_file, output_file, metadata_file, params)
    % b_input_and_filter - Imports a .set file, applies a bandpass filter [1, 32], and saves the result
    %
    % Syntax: b_input_and_filter(input_file, output_file, metadata_file, params)
    %
    % Inputs:
    %    input_file - String, path to the input set file
    %    output_file - String, path to the output file where filtered data is saved
    %    metadata_file - 
    %    params - need a high cutoff and low cutoff for the bandpass filter, order for the filter, and the filter type
    
    % Load EEGLAB to enable importing set, fdt files
    tic;    
    %addpath('/gpfs/milgram/project/naples/ajn23/codeLib/eeglab1024/eeglab2024.2')
    addpath('/Users/shreya/Desktop/eeglab2024.0')
    eeglab('nogui'); % ensure EEGLAB is added to the path

    % Load the EEG dataset using EEGLAB
    EEG = pop_loadset('filename', input_file);
    EEG = eeg_checkset(EEG); 
    
    % Use the parameters from the config file --> don't know if filter type will work 
    %EEG = pop_eegfiltnew(EEG, params.low_cutoff, params.high_cutoff, [], params.order, 0, params.filter_type);
    EEG = pop_eegfiltnew(EEG, 1, 32);

    % Save the processed dataset
    EEG = pop_saveset(EEG, 'filename', output_file);
    
    % Save metadata including the parameters used
    metadata = struct();
    metadata.processing_date = datestr(now);
    %metadata.parameters = params;
    savejson('', metadata, metadata_file);
    
    toc;
    %quit; 

    %{
    %% Filter data from MADE Pipeline
        % Calculate filter order using the formula: m = dF / (df / fs), where m = filter order,
        % df = transition band width, dF = normalized transition width, fs = sampling rate
        % dF is specific for the window type. Hamming window dF = 3.3

        high_transband = highpass; % high pass transition band
        low_transband = 10; % low pass transition band

        hp_fl_order = 3.3 / (high_transband / EEG.srate);
        lp_fl_order = 3.3 / (low_transband / EEG.srate);

        % Round filter order to next higher even integer. Filter order is always even integer.
        if mod(floor(hp_fl_order),2) == 0
            hp_fl_order=floor(hp_fl_order);
        elseif mod(floor(hp_fl_order),2) == 1
            hp_fl_order=floor(hp_fl_order)+1;
        end

        if mod(floor(lp_fl_order),2) == 0
            lp_fl_order=floor(lp_fl_order)+2;
        elseif mod(floor(lp_fl_order),2) == 1
            lp_fl_order=floor(lp_fl_order)+1;
        end

        % Calculate cutoff frequency
        high_cutoff = highpass/2;
        low_cutoff = lowpass + (low_transband/2);

        % Performing high pass filtering
        EEG = eeg_checkset( EEG );
        EEG = pop_firws(EEG, 'fcutoff', high_cutoff, 'ftype', 'highpass', 'wtype', 'hamming', 'forder', hp_fl_order, 'minphase', 0);
        EEG = eeg_checkset( EEG );

        % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

        % pop_firws() - filter window type hamming ('wtype', 'hamming')
        % pop_firws() - applying zero-phase (non-causal) filter ('minphase', 0)

        % Performing low pass filtering
        EEG = eeg_checkset( EEG );
        EEG = pop_firws(EEG, 'fcutoff', low_cutoff, 'ftype', 'lowpass', 'wtype', 'hamming', 'forder', lp_fl_order, 'minphase', 0);
        EEG = eeg_checkset( EEG );

        % pop_firws() - transition band width: 10 Hz
        % pop_firws() - filter window type hamming ('wtype', 'hamming')
        % pop_firws() - applying zero-phase (non-causal) filter ('minphase', 0) 
    
    %}

end
