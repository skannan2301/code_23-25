function n_reref(input_file, output_file, metadata_file, params)
    % n_reref - interpolate 
    %
    % Syntax: n_reref(input_file, output_file, metadata_file, params)
    %
    % Inputs:
    %    input_file - String, path to the input file
    %    output_file - .set file to be saved
    %    metadata_file - 
    %    params - 
    
    tic;    
    addpath('/gpfs/milgram/project/naples/ajn23/codeLib/eeglab1024/eeglab2024.2')
    eeglab('nogui'); % ensure EEGLAB is added to the path
        
    % Load the saved .set file
    EEG = pop_loadset('filename', input_file); 
    EEG = eeg_checkset(EEG);  

    reref=[]; % Enter electrode name/s or number/s to be used for rereferencing
    % For channel name/s enter, reref = {'channel_name', 'channel_name'};
    % For channel number/s enter, reref = [channel_number, channel_number];
    % For average rereference enter, reref = []; default is average rereference

    if iscell(reref)==1 % this will be false for average rereference b/c cell array is empty above ^ 
            reref_idx=zeros(1, length(reref));
            for rr=1:length(reref)
                    reref_idx(rr)=find(strcmp({EEG.chanlocs.labels}, reref{rr}));
            end
            EEG = eeg_checkset(EEG);
            EEG = pop_reref( EEG, reref_idx);
    % this is what will run for average rereference 
    else
            EEG = eeg_checkset(EEG);
            EEG = pop_reref(EEG, reref);
    end

    % save data set 
    EEG = pop_saveset(EEG, 'filename', output_file); 

    % Save metadata including the parameters used
    metadata = struct();
    metadata.processing_date = datestr(now);
    metadata.parameters = params;
    savejson('', metadata, metadata_file);
    
    toc;
    quit;
end
    

