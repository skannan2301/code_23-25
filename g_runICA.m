function g_runICA(original_input_file, input_file, output_file, metadata_file, params)
    % g_runICA - Imports a .set file, runs ICA from MADE BOND pipeline, and saves the result
    %
    % Syntax: g_runICA(original_input_file, input_file, output_file, metadata_file, params)
    %
    % Inputs:
    %    original_input_file - the ORIGINAL from step d (IDbadchan_remove.m)
    %    input_file - String, path to the original .set file (prior to 1Hz highpass and 1 sec epoch??)
    %    output_file - output file where data is saved
    %    metadata_file - 
    %    params - 
    
    % Load EEGLAB to enable importing set, fdt files
    tic;    
    addpath('/gpfs/milgram/project/naples/ajn23/codeLib/eeglab1024/eeglab2024.2')
    eeglab('nogui'); % ensure EEGLAB is added to the path

    % Load the saved .set file
    EEG_original=[]; % this is going to be the og EEG file from step d
    EEG_original= pop_loadset('filename', original_input_file);
    EEG_original=eeg_checkset(EEG_original);
    
    EEG = pop_loadset('filename', input_file); % this is the file that has been through: 1Hz highpass filter, 1 sec epoched 
    EEG = eeg_checkset(EEG); 
    
    EEG_copy=[]; 
    EEG_copy=EEG; % make a copy of the dataset this is the file that has been through: 1Hz highpass filter, 1 sec epoched --> doing this so every iteration of 'EEG_copy' within this section of the original pipeline doesn't need to be changed to 'EEG' 
    EEG_copy = eeg_checkset(EEG_copy);

    % % ica_prep_badChans, rejectedChannelsCount, rejectedChannelIndices, allRejectedChannels, FlatbadChans, badChannelLabels from step d, f to use here 
    % load(fullfile(outputFile, 'ica_prep_badChans.mat'), 'ica_prep_badChans');
    % load(fullfile(outputFile, 'rejectedChannelsCount.mat'), 'rejectedChannelsCount');
    % load(fullfile(outputFile, 'rejectedChannelIndices.mat'), 'rejectedChannelIndices');
    % load(fullfile(outputFile, 'allRejectedChannels.mat'), 'allRejectedChannels');
    % load(fullfile(outputFile, 'FlatbadChans.mat'), 'FlatbadChans');
    % load(fullfile(outputFile, 'badChannelLabels.mat'), 'badChannelLabels');
   
    % Keep track of rejected channels in EEG structure
    % Flat channels
    FlatbadChans = EEG_original.preproc.flat_channels.labels;
    EEG_original.preproc.flat_channels.number = length(FlatbadChans);
    
    % All rejected channels (flat + other bad channels)
    allRejectedChannels = EEG_original.preproc.rejected_channels.labels;
    EEG_original.preproc.rejected_channels.number = length(allRejectedChannels);
    rejectedChannelIndices = EEG_original.preproc.rejected_channels.indices; % Save the indices of rejected channels

    ica_prep_badChans = EEG.preproc.ica_prep_badChans.labels; 

    %% STEP 9: Run ICA on the copy file (has been through 1Hz highpass and epoched 
        ica_input_n_channels = EEG_copy.nbchan; % number of channels used for ica --> removed {subject} from after ica_input_n_channels
        length_ica_data=EEG_copy.trials; % length of data (in second) fed into ICA --> removed (subject) from after length_ica_data
        EEG_copy = eeg_checkset(EEG_copy);
        EEG_copy = pop_runica(EEG_copy, 'icatype', 'runica', 'extended', 1, 'stop', 1E-7, 'interupt','off');

        % Find the ICA weights that would be transferred to the original dataset
        ICA_WINV=EEG_copy.icawinv;
        ICA_SPHERE=EEG_copy.icasphere;
        ICA_WEIGHTS=EEG_copy.icaweights;
        ICA_CHANSIND=EEG_copy.icachansind;

        % If channels were removed from copied dataset during preparation of ica, then remove
        % those channels from original dataset as well before transferring ica weights.
        
        % keep track of additionally rejected channels --> this is happening within EEG_original, not EEG_copy
        % ica prep
        EEG_original.preproc.ica_prep_channels.number = length(ica_prep_badChans);
        EEG_original.preproc.ica_prep_channels.labels = {EEG_original.chanlocs(ica_prep_badChans).labels};
        % all 
        EEG_original.preproc.rejected_channels.number = EEG_original.preproc.rejected_channels.number + length(ica_prep_badChans);
        EEG_original.preproc.rejected_channels.labels = union(EEG_original.preproc.rejected_channels.labels, {EEG_original.chanlocs(ica_prep_badChans).labels});
        
        % for consistency (for some reason, union transposes cell if one of the inputs is empty)
        if size(EEG_original.preproc.rejected_channels.labels, 1) > size(EEG_original.preproc.rejected_channels.labels, 2)
            EEG_original.preproc.rejected_channels.labels = EEG_original.preproc.rejected_channels.labels';
        end
        
        EEG_original = eeg_checkset(EEG_original);
        EEG_original = pop_select(EEG_original,'nochannel', ica_prep_badChans);

        % Transfer the ICA weights of the copied dataset to the original dataset
        EEG_original.icawinv=ICA_WINV;
        EEG_original.icasphere=ICA_SPHERE;
        EEG_original.icaweights=ICA_WEIGHTS;
        EEG_original.icachansind=ICA_CHANSIND;
        
        EEG_original.preproc.ica.W = ICA_WEIGHTS * ICA_SPHERE;
        EEG_original.preproc.ica.A = ICA_WINV;
        EEG_original.preproc.ica.ica_channels = {EEG_copy.chanlocs(ICA_CHANSIND).labels};
        
        EEG_original = eeg_checkset(EEG_original);

        EEG_copy = pop_saveset(EEG_copy, 'filename', output_file);        % Save the dataset

    % Save metadata including the parameters used
    metadata = struct();
    metadata.processing_date = datestr(now);
    metadata.parameters = params;
    savejson('', metadata, metadata_file);
        
    toc;
    quit; 
end
