function i_removeICAs(input_file, output_file, metadata, params)
    % i_removeICAs - Imports a .set file, runs ADJUST, and saves the result
    %
    % Syntax: i_removeICAs(input_file, output_file, metadata_file, params)
    %
    % Inputs:
    %    input_file - String, path to the .set file 
    %    output_file - String, path to the output file where data is saved
    %    metadata_file - 
    %    params - 
        
    tic;    
    addpath('/gpfs/milgram/project/naples/ajn23/codeLib/eeglab1024/eeglab2024.2')
    eeglab('nogui'); % ensure EEGLAB is added to the path
        
    % Load the saved .set file
    EEG = pop_loadset('filename', input_file); 
    EEG = eeg_checkset(EEG); 

    %% STEP 11: Remove artifacted ICA components from data
    all_bad_ICs=0;
    ICs2remove=find(EEG.reject.gcompreject); % find ICs to remove

    % If all ICs and bad, save data at this stage and ignore rest of the preprocessing for this subject.
    if numel(ICs2remove)==total_ICs % removed '(subject)' after total_ICs
        all_bad_ICs=1;
        warning(['No usable data for datafile: too many artifacted ICs from ICA']); % removed '', datafile_names{subject}, '' after for
        %if output_format==1
            EEG = eeg_checkset(EEG);
            % save the data set 
            EEG = pop_saveset(EEG, 'filename', output_file);
            %EEG = pop_editset(EEG, 'setname',  strrep(datafile_names{subject}, ext, '_no_usable_data_all_bad_ICs'));
            %EEG = pop_saveset(EEG, 'filename', strrep(datafile_names{subject}, ext, '_no_usable_data_all_bad_ICs.set'),'filepath', [output_location filesep 'processed_data' filesep ]); % save .set format
            %DataFileName = strrep(datafile_names{subject}, ext, '_no_usable_data_all_bad_ICs.set');
            %DataFileLocation = [output_location filesep 'processed_data'];
        %elseif output_format==2
            %save([[output_location filesep 'processed_data' filesep ] strrep(datafile_names{subject}, ext, '_no_usable_data_all_bad_ICs.mat')], 'EEG'); % save .mat format
            %DataFileName = strrep(datafile_names{subject}, ext, '_no_usable_data_all_bad_ICs.mat');
            %DataFileLocation = [output_location filesep 'processed_data'];
        end
    else
        EEG = eeg_checkset( EEG );
        EEG = pop_subcomp( EEG, ICs2remove, 0); % remove ICs from dataset
    end

        %if all_bad_ICs==1
        %    total_epochs_before_artifact_rejection(subject)=0;
        %    total_epochs_after_artifact_rejection(subject)=0;
        %    n_total_channels_interpolated(subject)=0;
        %    total_channels_interpreted{subject} = '0';
        %    % info
        %    datafile_name_preproc_done{subject} = DataFileName;
        %    preproc_path{subject} = DataFileLocation;
        %    date_preproc{subject} = datestr(now,'dd-mm-yyyy');

    % save the data set after removed ICs 
    EEG = pop_saveset(EEG, 'filename', output_file);

    % Save metadata including the parameters used
    metadata = struct();
    metadata.processing_date = datestr(now);
    metadata.parameters = params;
    savejson('', metadata, metadata_file);
    
    quit; 
end
            
