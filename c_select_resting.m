function c_select_resting(input_file, output_file, metadata_file, params)
    % c_select_resting - Imports a .set file, finds the first instance of 'rest'
    % event code and the last instance of 'rest' event code and gets their
    % latencies, then selects the data within those two boundary lantencies
    % to give us just the resting data for each kiddo 
    %
    % Syntax: c_select_resting(input_file, output_file, metadata_file, params)
    %
    % Inputs:
    %    input_file - String, path to the input .set file
    %    output_file - String, path to the output file where data is saved
    %    metadata_file - 
    %    params - 
    
    % Load EEGLAB to enable importing .set files
    tic;    
    %addpath('/gpfs/milgram/project/naples/ajn23/codeLib/eeglab1024/eeglab2024.2')
    addpath('/Users/shreya/Desktop/eeglab2024.0')
    eeglab('nogui'); % ensure EEGLAB is added to the path

    % Load the saved .set file
    EEG = pop_loadset('filename', input_file);    
    EEG = eeg_checkset(EEG); 

    event_code = 'rest';

    % Identify the latencies of the first and last occurrence of 'rest'
    first_latency = [];
    last_latency = [];

    % Loop through events to find the latencies
    for i = 1:length(EEG.event)
        if strcmp(EEG.event(i).type, event_code)
            if isempty(first_latency)
                first_latency = EEG.event(i).latency; % First 'rest'
            end
            last_latency = EEG.event(i).latency; % Continuously overwrite to get the last 'rest'
        end
    end

    % Check if 'rest' event was found --> commenting out for now, not sure if it'll throw an error since it's printing stuff 
    % if isempty(first_latency) || isempty(last_latency)
    %    error('Event code ''rest'' not found in the dataset.');
    % end

    % Use pop_select to extract data between first and last 'rest'
    EEG = pop_select(EEG, 'point', [first_latency, last_latency]);

    % Save the resulting dataset
    EEG = pop_saveset(EEG, 'filename', output_file);
    
    % Save metadata including the parameters used
    metadata = struct();
    metadata.processing_date = datestr(now);
    %metadata.parameters = params;
    savejson('', metadata, metadata_file);
    
    toc; 
    %quit; 
end

