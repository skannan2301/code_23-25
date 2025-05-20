function m_interp(input_file, output_file, metadata_file, params)
    % m_interp - interpolate 
    %
    % Syntax: m_interp(input_file, output_file, metadata_file, params)
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

    % interpolate
    EEG = eeg_interp(EEG, channels_analysed);
    EEG = eeg_checkset(EEG);
        
    if numel(FlatbadChans)==0 && numel(FASTbadChans)==0 && numel(ica_prep_badChans)==0
            n_total_channels_interpolated=0;
    else
            n_total_channels_interpolated=numel(FlatbadChans) + numel(FASTbadChans)+ numel(ica_prep_badChans);
    end

    % additional check
    if isequal(n_total_channels_interpolated, EEG.preproc.rejected_channels.number)
            total_channels_interpreted=EEG.preproc.rejected_channels.labels;
    else
            warning('Mismatch in number of channels rejected in EEG.preproc.rejected_channels and script')
            total_channels_interpreted = 'mismatch';
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
