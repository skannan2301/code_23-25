function h_ADJUST(input_file, output_file, metadata_file, params)
    % h_ADJUST - Imports a .set file, runs ADJUST, and saves the result
    %
    % Syntax: h_ADJUST(input_file, output_file, metadata_file, params)
    %
    % Inputs:
    %    input_file - String, path to the .set file 
    %    output_file - String, path to the output file where data is saved
    %    metadata_file - 
    %    params - 
    
    % Load EEGLAB to enable importing set, fdt files
    tic;    
    addpath('/gpfs/milgram/project/naples/ajn23/codeLib/eeglab1024/eeglab2024.2')
    eeglab('nogui'); % ensure EEGLAB is added to the path

    % Load the saved .set file
    EEG = pop_loadset('filename', input_file); % this is the file that has been through: 1Hz highpass filter, 1 sec epoched 
    EEG = eeg_checkset(EEG); 
    
    % took this from beginning of pipeline
    if exist('ADJUST', 'file')==0
        error(['Please make sure you download modified "ADJUST" plugin from GitHub (link is in MADE manuscript)' ...
            ' and ADJUST is in EEGLAB plugin folder and on Matlab path.']);
    end

    %% STEP 10: Run adjust to find artifacted ICA components
    badICs=[]; EEG_copy =[];
    EEG_copy = EEG;
    EEG_copy =eeg_regepochs(EEG_copy,'recurrence', 1, 'limits',[0 1], 'rmbase', [NaN], 'eventtype', '999'); % insert temporary marker 1 second apart and create epochs
    EEG_copy = eeg_checkset(EEG_copy);
        
        
        %cd([output_location filesep 'ica_data'])
        %if size(EEG_copy.icaweights,1) == size(EEG_copy.icaweights,2)
        %    if save_interim_result==1
        %        badICs = adjusted_ADJUST(EEG_copy, [[output_location filesep 'ica_data' filesep] strrep(datafile_names{subject}, ext, '_adjust_report')]);
        %    else
        %        badICs = adjusted_ADJUST(EEG_copy, [[output_location filesep 'processed_data' filesep] strrep(datafile_names{subject}, ext, '_adjust_report')]);
        %    end
        %    close all;
        %else % if rank is less than the number of electrodes, throw a warning message
        %    warning('The rank is less than the number of electrodes. ADJUST will be skipped. Artefacted ICs will have to be manually rejected for this participant');
        %end
        
    % track bad ics
    EEG.preproc.ica.bad_components = zeros(size(ICA_WEIGHTS, 1), 1);
    EEG.preproc.ica.bad_components(badICs) = 1;
    EEG.preproc.ica.bad_components = logical(EEG.preproc.ica.bad_components);

    % Mark the bad ICs found by ADJUST
    for ic=1:length(badICs)
        EEG.reject.gcompreject(1, badICs(ic))=1;
        EEG = eeg_checkset(EEG);
    end
    
    total_ICs=size(EEG.icasphere, 1); % removed '(subject)' after totalICs
    n_ICs_removed = numel(badICs); % removed '{subject}' after n_ICs_removed
    if numel(badICs)==0
        ICs_removed='0'; % removed '{subject}' after ICs_removed 
    else
        ICs_removed=num2str(double(badICs)); % removed '{subject}' after ICs_removed
    end

        %% Save dataset after ICA, if saving interim results was preferred
        %if save_interim_result==1
        %    if output_format==1
        %        EEG = eeg_checkset(EEG);
        %        EEG = pop_editset(EEG, 'setname',  strrep(datafile_names{subject}, ext, '_ica_data'));
        %        EEG = pop_saveset(EEG, 'filename', strrep(datafile_names{subject}, ext, '_ica_data.set'),'filepath', [output_location filesep 'ica_data' filesep ]); % save .set format
        %    elseif output_format==2
        %        save([[output_location filesep 'ica_data' filesep ] strrep(datafile_names{subject}, ext, '_ica_data.mat')], 'EEG'); % save .mat format
        %    end
        %end

    % save the data set 
    EEG = pop_saveset(EEG, 'filename', output_file);

    % Save metadata including the parameters used
    metadata = struct();
    metadata.processing_date = datestr(now);
    metadata.parameters = params;
    savejson('', metadata, metadata_file);

    quit; 
end
