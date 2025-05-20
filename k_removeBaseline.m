function k_removeBaseline(input_file, output_file, metadata_file, params)
    % k_removeBaseline - remove baseline
    %
    % Syntax: k_removeBaseline(input_file, output_file, metadata_file, params)
    %
    % Inputs:
    %    input_file - String, path to the input MFF file
    %    output_file - String, path to where .set file is saved
    %    metadata_file - 
    %    params - need the baseline window, this is MADE BOND's: baseline_window = []; % baseline period in milliseconds (MS) [] = entire epoch

    tic;    
    addpath('/gpfs/milgram/project/naples/ajn23/codeLib/eeglab1024/eeglab2024.2')
    eeglab('nogui'); % ensure EEGLAB is added to the path
        
    % Load the saved .set file
    EEG = pop_loadset('filename', input_file); 
    EEG = eeg_checkset(EEG);  

    % baseline window from BOND pipeline
    baseline_window = []; % baseline period in milliseconds (MS) [] = entire epoch

    % remove baseline
    % EEG = pop_rmbase( EEG, params.baseline_window); once I understand the params thing 
    EEG = pop_rmbase( EEG, baseline_window);

    % save the data set after removing baseline
    EEG = pop_saveset(EEG, 'filename', output_file);
    
    % Save metadata including the parameters used
    metadata = struct();
    metadata.processing_date = datestr(now);
    metadata.parameters = params;
    savejson('', metadata, metadata_file);

    toc;
    quit; 
end
