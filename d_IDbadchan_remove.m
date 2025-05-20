function d_IDbadchan_remove(input_file, output_file, metadata_file, params)
    % d_IDbadchan_remove - Imports a .set file, finds bad channels and flat
    % channels and removes them
    %
    % Syntax: d_IDbadchan_remove(input_file, output_file, metadata_file, params)
    %
    % Inputs:
    %    input_file - String, path to the input .set file
    %    output_file - the output file where cleaned data is saved
    %	 metadata_file - 
    %	 params - 

    % Load EEGLAB to enable importing MFF files
    tic;    
    %addpath('/gpfs/milgram/project/naples/ajn23/codeLib/eeglab1024/eeglab2024.2')
    addpath('/Users/shreya/Desktop/eeglab2024.0')
    eeglab('nogui'); % ensure EEGLAB is added to the path

    % Load the saved .set file
    EEG = pop_loadset('filename', input_file);
    EEG = eeg_checkset(EEG); 
    
    % Run clean_rawdata to detect bad channels
    % Parameters:
    % - 'FlatlineCriterion': Maximum flatline duration allowed (default: 5 seconds)
    % - 'Highpass': High-pass filter cutoff frequency in Hz (default: 0.5 Hz)
    % - 'ChannelCriterion': Maximum acceptable correlation between a channel and robust estimate of others (default: 0.85)
    % - 'LineNoiseCriterion': Tolerance for line noise relative to the EEG signal (default: 4 SD)
    % - 'BurstCriterion': Maximum acceptable deviation of data in SD (default: 5 SD)
    % - 'WindowCriterion': Tolerance for bad time windows (default: 0.25)
	
    % Run clean_rawdata with your parameters
    EEG_clean = clean_rawdata(EEG, 5, -1, 0.85, 4, 'off', 'off');
    
    % Check if cleaned dataset has valid channel locations
    if isfield(EEG_clean, 'chanlocs') && ~isempty(EEG_clean.chanlocs)
        % Get original and remaining channel labels
        originalChannelLabels = {EEG.chanlocs.labels};
        remainingChannelLabels = {EEG_clean.chanlocs.labels};
        
        % Identify bad channels removed during cleaning
        badChannelLabels = setdiff(originalChannelLabels, remainingChannelLabels);
        
        % Identify flat channels using clean_channel_mask if available
        if isfield(EEG_clean.etc, 'clean_channel_mask')
            % Mask: true = retained, false = removed
            flatChannelMask = ~EEG_clean.etc.clean_channel_mask;
            FlatbadChans = originalChannelLabels(flatChannelMask); % Flat channel labels
        else
            % If clean_channel_mask is unavailable, fallback to manual detection
            flatThreshold = 1e-6; % Threshold for flat channels
            channelVariances = var(EEG.data, 0, 2); % Variance of each channel
            flatChannelIndices = find(channelVariances < flatThreshold); % Flat channels
            FlatbadChans = originalChannelLabels(flatChannelIndices);
        end
        
        % Combine bad and flat channels
        allRejectedChannels = unique([badChannelLabels, FlatbadChans]); % Combine and remove duplicates
        
        % Get indices of rejected channels in the original dataset
        rejectedChannelIndices = find(ismember(originalChannelLabels, allRejectedChannels)); 
    
        % Save bad channels and flat channels
        outputBadChans = fullfile('/Users/shreya/Desktop/daac/newEEGStuff/extras', 'badChannelLabels.mat');
        save(outputBadChans, 'badChannelLabels');
        
        outputFlatChans = fullfile('/Users/shreya/Desktop/daac/newEEGStuff/extras', 'FlatbadChans.mat');
        save(outputFlatChans, 'FlatbadChans');
        
        % Save all rejected channels and their indices
        outputRejectedChans = fullfile('/Users/shreya/Desktop/daac/newEEGStuff/extras', 'allRejectedChannels.mat');
        save(outputRejectedChans, 'allRejectedChannels');
        
        outputRejectedIndices = fullfile('/Users/shreya/Desktop/daac/newEEGStuff/extras', 'rejectedChannelIndices.mat');
        save(outputRejectedIndices, 'rejectedChannelIndices');
        
        % Save the number of rejected channels
        rejectedChannelsCount = length(allRejectedChannels);
        outputRejectedCount = fullfile('/Users/shreya/Desktop/daac/newEEGStuff/extras', 'rejectedChannelsCount.mat');
        save(outputRejectedCount, 'rejectedChannelsCount');
    else
        error('The cleaned dataset does not contain valid channel locations.');
    end

    % Keep track of rejected channels in EEG structure
    % Flat channels
    EEG.preproc.flat_channels.number = length(FlatbadChans);
    EEG.preproc.flat_channels.labels = FlatbadChans;
    
    % All rejected channels (flat + other bad channels)
    EEG.preproc.rejected_channels.number = length(allRejectedChannels);
    EEG.preproc.rejected_channels.labels = allRejectedChannels;
    EEG.preproc.rejected_channels.indices = rejectedChannelIndices; % Save the indices of rejected channels
    
    % Keep track of rejected channels in EEG structure
    % Flat channels
    EEG.preproc.flat_channels.number = length(FlatbadChans);
    EEG.preproc.flat_channels.labels = FlatbadChans;
    
    % All rejected channels (flat + other bad channels)
    EEG.preproc.rejected_channels.number = length(allRejectedChannels);
    EEG.preproc.rejected_channels.labels = allRejectedChannels;
    
    % Save the processed dataset
    EEG = pop_saveset(EEG, 'filename', output_file);
    
    % Save metadata including the parameters used
    metadata = struct();
    metadata.processing_date = datestr(now);
    %metadata.parameters = params;
    savejson('', metadata, metadata_file);
    
    toc; 
    %quit; 
end

%{
% MADE BOND Pipeline stuff below 
%% STEP 7: Find flat channels and run faster to find bad channels
        
        % First check whether reference channel (i.e. zeroed channels) is present in data
        % reference channel is needed to run faster
        %RH: in LEAP the REF channel is the same for all datasets
        ref_chan=[]; FlatbadChans=[]; all_chan_bad_Flat=0; FASTbadChans=[]; all_chan_bad_FAST=0;
        ref_chan=find(strcmp({EEG.chanlocs.labels}, 'FCz')); % find FCz channel index --> don't know if this will work for us
        n_all_channels{subject}= EEG.nbchan; 
        
        %%% Step 7.1: Find flat channels and remove from data %%%%%%%%%%%%%
        % RH; some of the datasets contained flat channels which would
        % distort the distributions of metrics in the faster algorithm
        FlatbadIdx = all(abs(EEG.data) < .0001,2);
        FlatbadChans=find(FlatbadIdx==1);
        FlatbadChans=FlatbadChans(FlatbadChans~=ref_chan);
        EEG = eeg_checkset(EEG);
        channels_analysed=EEG.chanlocs;
        N_channels_analysed = size(channels_analysed,2);
        
        % Keep track of rejected channels
        % flat
        EEG.preproc.flat_channels.number = length(FlatbadChans);
        EEG.preproc.flat_channels.labels = {EEG.chanlocs(FlatbadChans).labels};
        % all
        EEG.preproc.rejected_channels.number = length(FlatbadChans);
        EEG.preproc.rejected_channels.labels = {EEG.chanlocs(FlatbadChans).labels};
        
        % If all or more than 10% of channels are identified as flat channels, save the dataset
	% and then this file does not go any further. AJN
        % at this stage and ignore the remaining of the preprocessing.
        if numel(FlatbadChans)==EEG.nbchan || numel(FlatbadChans)+1==EEG.nbchan ...
                || numel(FlatbadChans) >= round((N_channels_analysed-1)/100*10) % RH; 10% relative to the number of common channels
            all_chan_bad_Flat=1;
            % warning(['No usable data for datafile ', datafile_names{subject}, ': too many flat channels']);
            %if output_format==1
                EEG = eeg_checkset(EEG);
                EEG = pop_editset(EEG, 'setname',  basename, ext, '_no_usable_data_flat_channels'); % changed strrep(datafile_names{subject} to basename
                EEG = pop_saveset(EEG, 'filename', [basename '.set'], 'filepath', outputFile);
                %EEG = pop_saveset(EEG, 'filename', basename, ext, '_no_usable_data_flat_channels.set'),'filepath', [output_location filesep 'processed_data' filesep ])); % save .set format
                %DataFileName = strrep(datafile_names{subject}, ext, '_no_usable_data_flat_channels.set');
                %DataFileLocation = [output_location filesep 'processed_data'];
            % elseif output_format==2
              %  save([[output_location filesep 'processed_data' filesep ] strrep(datafile_names{subject}, ext, '_no_usable_data_flat_channels.mat')], 'EEG'); % save .mat format
              %  DataFileName = strrep(datafile_names{subject}, ext, '_no_usable_data_flat_channels.mat');
              %  DataFileLocation = [output_location filesep 'processed_data'];
            % end
        else
            % Reject channels that are flat 
	    % this happens 
            EEG = pop_select( EEG,'nochannel', FlatbadChans);
            EEG = eeg_checkset(EEG);
        end

 %%% Step 7.2: Run faster and remove from data %%%%%%%%%%%%%%%%%%%%%
        ref_chan=[]; ref_chan=find(strcmp({EEG.chanlocs.labels}, 'FCz')); % find FCz channel index
        % run faster
        list_properties = channel_properties(EEG, 1:EEG.nbchan, ref_chan); % run faster
        FASTbadIdx=min_z(list_properties);
        FASTbadChans=find(FASTbadIdx==1);
        FASTbadChans=FASTbadChans(FASTbadChans~=ref_chan);
        reference_used_for_faster{subject}={EEG.chanlocs(ref_chan).labels};
        EEG = eeg_checkset(EEG);
        
        % Keep track of rejected channels
        % faster
        EEG.preproc.faster_channels.number = length(FASTbadChans);
        EEG.preproc.faster_channels.labels = {EEG.chanlocs(FASTbadChans).labels};
        % all (flat + faster)
        EEG.preproc.rejected_channels.number = EEG.preproc.flat_channels.number + length(FASTbadChans);
        EEG.preproc.rejected_channels.labels = union(EEG.preproc.rejected_channels.labels, {EEG.chanlocs(FASTbadChans).labels});
        % for consistency (for some reason, union transposes cell if one of the inputs is empty)
        if size(EEG.preproc.rejected_channels.labels, 1) > size(EEG.preproc.rejected_channels.labels, 2)
            EEG.preproc.rejected_channels.labels = EEG.preproc.rejected_channels.labels';
        end

        
        % If FASTER identifies all channels as bad channels, save the dataset
        % at this stage and ignore the remaining of the preprocessing.
        if numel(FASTbadChans)==EEG.nbchan || numel(FASTbadChans)+1==EEG.nbchan || ...
                numel(FASTbadChans)==N_channels_analysed || numel(FASTbadChans)+1==N_channels_analysed || ...
                numel(FASTbadChans) >= round((N_channels_analysed-1)/100*10) % RH; 10% relative to the number of common channels
            all_chan_bad_FAST=1;
            warning(['No usable data for datafile', datafile_names{subject}, ': too many bad FASTER channels']);
            if output_format==1
                EEG = eeg_checkset(EEG);
                EEG = pop_editset(EEG, 'setname',  strrep(datafile_names{subject}, ext, '_no_usable_data_all_faster_bad_channels'));
                EEG = pop_saveset(EEG, 'filename', strrep(datafile_names{subject}, ext, '_no_usable_data_all_faster_bad_channels.set'),'filepath', [output_location filesep 'processed_data' filesep ]); % save .set format
                DataFileName = strrep(datafile_names{subject}, ext, '_no_usable_data_all_faster_bad_channels.set');
                DataFileLocation = [output_location filesep 'processed_data'];
            elseif output_format==2
                save([[output_location filesep 'processed_data' filesep ] strrep(datafile_names{subject}, ext, '_no_usable_data_all_faster_bad_channels.mat')], 'EEG'); % save .mat format
                DataFileName = strrep(datafile_names{subject}, ext, '_no_usable_data_all_faster_bad_channels.set');
                DataFileLocation = [output_location filesep 'processed_data'];
            end
        else
            % Reject channels that are bad as identified by Faster
            EEG = pop_select( EEG,'nochannel', FASTbadChans);
            EEG = eeg_checkset(EEG);
%             if numel(ref_chan)==1
%                 ref_chan=find(any(EEG.data, 2)==0);
                ref_chan=[]; ref_chan=find(strcmp({EEG.chanlocs.labels}, 'FCz'));   
                EEG = pop_select( EEG,'nochannel', ref_chan); % remove reference channel
%             end
        end 
%}
