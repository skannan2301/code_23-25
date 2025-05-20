function e_filterTwo(input_file, output_file, metadata_file, params)
    % e_filterTwo - Imports a .set file, applies a highpass filter at 1 Hz, and saves the result
    % This is preparing for ICA 
    % 
    % Syntax: e_filterTwo(input_file, output_file, metadata_file, params)
    %
    % Inputs:
    %    inputFile - String, path to the input set file
    %    outputFile - String, path to the output file where filtered data is saved
    
    % Load EEGLAB to enable importing set, fdt files
    tic;    
    %addpath('/gpfs/milgram/project/naples/ajn23/codeLib/eeglab1024/eeglab2024.2')
    addpath('/Users/shreya/Desktop/eeglab2024.0')
    eeglab('nogui'); % ensure EEGLAB is added to the path

    % Load the saved .set file
    EEG = pop_loadset('filename', input_file);
    EEG = eeg_checkset(EEG); 

    % Prepare data for ICA
    EEG_copy=[];
    EEG_copy=EEG; % make a copy of the dataset
    EEG_copy = eeg_checkset(EEG_copy);
    
    % note down number of channels used for ica prep --> removed "{subject}" after ica_prep_input_n_channels
    ica_prep_input_n_channels = EEG_copy.nbchan;
 	
    % filter highpass 1 Hz, no lowpass
    %EEG_copy = pop_eegfiltnew(EEG_copy, params.high_cutoff, 0);     
    EEG_copy = pop_eegfiltnew(EEG_copy, 1, 0);      
    
    % Save the dataset with the new name
    EEG_copy = pop_saveset(EEG_copy, 'filename', output_file);
    
    % Save metadata including the parameters used
    metadata = struct();
    metadata.processing_date = datestr(now);
    %metadata.parameters = params;
    savejson('', metadata, metadata_file);   
    
    toc;
    %quit; 

%{ 
Commenting out this 1Hz high pass filter from MADE BOND Pipeline, replaced with eegfiltnew()
    % Perform 1Hz high pass filter on copied dataset
        transband = 1;
        fl_cutoff = transband/2;
        fl_order = 3.3 / (transband / EEG.srate);

        if mod(floor(fl_order),2) == 0
            fl_order=floor(fl_order);
        elseif mod(floor(fl_order),2) == 1
            fl_order=floor(fl_order)+1;
        end

        EEG_copy = pop_firws(EEG_copy, 'fcutoff', fl_cutoff, 'ftype', 'highpass', 'wtype', 'hamming', 'forder', fl_order, 'minphase', 0);
        EEG_copy = eeg_checkset(EEG_copy);
%}
  
end
