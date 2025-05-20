function j_segment2sec(input_file, output_file, metadata_file, params)
    % j_segment2sec - create 2 second segments 
    %
    % Syntax: j_segment2sec(input_file, output_file, metadata_file, params)
    %
    % Inputs:
    %    input_file - String, path to the input MFF file
    %    output_file - String, path to where .set file is saved
    %	 metadata_file - 
    %	 params - 

    tic;    
    addpath('/gpfs/milgram/project/naples/ajn23/codeLib/eeglab1024/eeglab2024.2')
    eeglab('nogui'); % ensure EEGLAB is added to the path
            
    % Load the saved .set file
    EEG = pop_loadset('filename', input_file); 
    EEG = eeg_checkset(EEG);  
      
    rest_epoch_length = 2; % for resting EEG continuous data will be segmented into consecutive epochs of a specified length (here 2 seconds) by adding dummy events
    dummy_events ={'910','911'}; % enter dummy events name
    
    %if epoch_data==1
            %if task_eeg==1 % task eeg
                %EEG = eeg_checkset(EEG);
                %EEG = pop_epoch(EEG, task_event_markers, task_epoch_length, 'epochinfo', 'yes');
            %elseif task_eeg==0 % resting eeg - 1 condition
    % we are overlapping right? 
    %if overlap_epoch==1
      
    % the two lines below are the only relevant ones 
    EEG=eeg_regepochs(EEG,'recurrence',(rest_epoch_length/2),'limits',[0 rest_epoch_length], 'rmbase', [NaN], 'eventtype', char(dummy_events));
    EEG = eeg_checkset(EEG);
      
    %else
        %EEG=eeg_regepochs(EEG,'recurrence',rest_epoch_length,'limits',[0 rest_epoch_length], 'rmbase', [NaN], 'eventtype', char(dummy_events));
        %EEG = eeg_checkset(EEG);
    %end
    
    % save the data set after 2 sec segments created 
    EEG = pop_saveset(EEG, 'filename', output_file);
    
    % Save metadata including the parameters used
    metadata = struct();
    metadata.processing_date = datestr(now);
    metadata.parameters = params;
    savejson('', metadata, metadata_file);

    toc; 
    quit; 
end
