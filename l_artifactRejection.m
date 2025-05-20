function l_artifactRejection(input_file, output_file, metadata_file, params)
    % l_artifactRejection - find and reject artifacts
    %
    % Syntax: l_artifactRejection(input_file, output_file, metadata_file, params)
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

    % variables needed for artifact rejection
    voltthres_rejection = 1; % 0 = NO, 1 = YES
    volt_threshold = [-100 100]; % lower and upper threshold (in uV)
    
    % artifact rejection stuff goes here 
    all_bad_epochs=0;
        if voltthres_rejection==1 % check voltage threshold rejection
            if interp_epoch==1 % check epoch level channel interpolation
                chans=[]; chansidx=[];chans_labels2=[];
                chans_labels2=cell(1,EEG.nbchan);
                for i=1:EEG.nbchan
                    chans_labels2{i}= EEG.chanlocs(i).labels;
                end
                [chans,chansidx] = ismember(frontal_channels, chans_labels2);
                frontal_channels_idx = chansidx(chansidx ~= 0);
                badChans = zeros(EEG.nbchan, EEG.trials);
                badepoch=zeros(1, EEG.trials);
                if isempty(frontal_channels_idx)==1 % check whether there is any frontal channel in dataset to check
                    warning('No frontal channels from the list present in the data. Only epoch interpolation will be performed.');
                else
                    % find artifaceted epochs by detecting outlier voltage in the specified channels list and remove epoch if artifacted in those channels
                    for ch =1:length(frontal_channels_idx)
                        EEG = pop_eegthresh(EEG,1, frontal_channels_idx(ch), volt_threshold(1), volt_threshold(2), EEG.xmin, EEG.xmax,0,0);
                        EEG = eeg_checkset( EEG );
                        EEG = eeg_rejsuperpose( EEG, 1, 1, 1, 1, 1, 1, 1, 1);
                        badChans(ch,:) = EEG.reject.rejglobal;
                    end
                    for ii=1:size(badChans, 2)
                        badepoch(ii)=sum(badChans(:,ii));
                    end
                    badepoch=logical(badepoch);
                end

                % If all epochs are artifacted, save the dataset and ignore rest of the preprocessing for this subject.
                if sum(badepoch)==EEG.trials || sum(badepoch)+1==EEG.trials
                    all_bad_epochs=1;
                    warning(['No usable data for datafile']);
                    %if output_format==1
                        EEG = eeg_checkset(EEG);
                        EEG = pop_saveset(EEG, 'filename', output_file);
                        %EEG = pop_editset(EEG, 'setname',  strrep(datafile_names{subject}, ext, '_no_usable_data_all_bad_epoch'));
                        %EEG = pop_saveset(EEG, 'filename', strrep(datafile_names{subject}, ext, '_no_usable_data_all_bad_epoch.set'),'filepath', [output_location filesep 'processed_data' filesep ]); % save .set format
                    %elseif output_format==2
                        %save([[output_location filesep 'processed_data' filesep ] strrep(datafile_names{subject}, ext, '_no_usable_data_all_bad_epochs.mat')], 'EEG'); % save .mat format
                    %end
                else
                    EEG = pop_rejepoch( EEG, badepoch, 0);
                    EEG = eeg_checkset(EEG);
                end

                if all_bad_epochs==1
                    warning(['No usable data for datafile']);
                else
                    % Interpolate artifacted data for all reaming channels
                    badChans = zeros(EEG.nbchan, EEG.trials);
                    % Find artifacted epochs by detecting outlier voltage but don't remove
                    for ch=1:EEG.nbchan
                        EEG = pop_eegthresh(EEG,1, ch, volt_threshold(1), volt_threshold(2), EEG.xmin, EEG.xmax,0,0);
                        EEG = eeg_checkset(EEG);
                        EEG = eeg_rejsuperpose(EEG, 1, 1, 1, 1, 1, 1, 1, 1);
                        badChans(ch,:) = EEG.reject.rejglobal;
                    end
                    tmpData = zeros(EEG.nbchan, EEG.pnts, EEG.trials);
                    for e = 1:EEG.trials
                        % Initialize variables EEGe and EEGe_interp;
                        EEGe = []; EEGe_interp = []; badChanNum = [];
                        % Select only this epoch (e)
                        EEGe = pop_selectevent( EEG, 'epoch', e, 'deleteevents', 'off', 'deleteepochs', 'on', 'invertepochs', 'off');
                        badChanNum = find(badChans(:,e)==1); % find which channels are bad for this epoch
                        EEGe_interp = eeg_interp(EEGe,badChanNum); %interpolate the bad channels for this epoch
                        tmpData(:,:,e) = EEGe_interp.data; % store interpolated data into matrix
                    end
                    EEG.data = tmpData; % now that all of the epochs have been interpolated, write the data back to the main file

                    % If more than 10% of channels in an epoch were interpolated, reject that epoch
                    badepoch=zeros(1, EEG.trials);
                    for ei=1:EEG.trials
                        NumbadChan = badChans(:,ei); % find how many channels are bad in an epoch
                        if sum(NumbadChan) > round((10/100)*(N_channels_analysed-1))% check if more than 10% are bad - RH; relative to the number of common channels
                            badepoch (ei)= sum(NumbadChan);
                        end
                    end
                    badepoch=logical(badepoch);
                end
                % If all epochs are artifacted, save the dataset and ignore rest of the preprocessing for this subject.
                if sum(badepoch)==EEG.trials || sum(badepoch)+1==EEG.trials
                    all_bad_epochs=1;
                    warning(['No usable data for datafile', datafile_names{subject}]);
                    if output_format==1
                        EEG = eeg_checkset(EEG);
                        EEG = pop_editset(EEG, 'setname',  strrep(datafile_names{subject}, ext, '_no_usable_data_all_bad_epochs'));
                        EEG = pop_saveset(EEG, 'filename', strrep(datafile_names{subject}, ext, '_no_usable_data_all_bad_epochs.set'),'filepath', [output_location filesep 'processed_data' filesep ]); % save .set format
                    elseif output_format==2
                        save([[output_location filesep 'processed_data' filesep ] strrep(datafile_names{subject}, ext, '_no_usable_data_all_bad_epochs.mat')], 'EEG'); % save .mat format
                    end
                else
                    EEG = pop_rejepoch(EEG, badepoch, 0);
                    EEG = eeg_checkset(EEG);
                end
            else % if no epoch level channel interpolation
                EEG = pop_eegthresh(EEG, 1, (1:EEG.nbchan), volt_threshold(1), volt_threshold(2), EEG.xmin, EEG.xmax, 0, 0);
                EEG = eeg_checkset(EEG);
                EEG = eeg_rejsuperpose( EEG, 1, 1, 1, 1, 1, 1, 1, 1);
                 
            end % end of epoch level channel interpolation if statement

            % If all epochs are artifacted, save the dataset and ignore rest of the preprocessing for this subject.
            if sum(EEG.reject.rejthresh)==EEG.trials || sum(EEG.reject.rejthresh)+1==EEG.trials
                all_bad_epochs=1;
                warning(['No usable data for datafile', datafile_names{subject}]);
                if output_format==1
                    EEG = eeg_checkset(EEG);
                    EEG = pop_editset(EEG, 'setname',  strrep(datafile_names{subject}, ext, '_no_usable_data_all_bad_epochs'));
                    EEG = pop_saveset(EEG, 'filename', strrep(datafile_names{subject}, ext, '_no_usable_data_all_bad_epochs.set'),'filepath', [output_location filesep 'processed_data' filesep ]); % save .set format
                    DataFileName = strrep(datafile_names{subject}, ext, '_no_usable_data_all_bad_epochs.set');
                    DataFileLocation = [output_location filesep 'processed_data'];
                elseif output_format==2
                    save([[output_location filesep 'processed_data' filesep ] strrep(datafile_names{subject}, ext, '_no_usable_data_all_bad_epochs.mat')], 'EEG'); % save .mat format
                    DataFileName = strrep(datafile_names{subject}, ext, '_no_usable_data_all_bad_epochs.mat');
                    DataFileLocation = [output_location filesep 'processed_data'];
                end
            else
                EEG = pop_rejepoch(EEG,(EEG.reject.rejthresh), 0);
                EEG = eeg_checkset(EEG);
            end
        end % end of voltage threshold rejection if statement

        % if all epochs are found bad during artifact rejection
        if all_bad_epochs==1
            total_epochs_after_artifact_rejection(subject)=0;
            n_total_channels_interpolated(subject)=0;
            total_channels_interpreted{subject}='0';
            % info
            datafile_name_preproc_done{subject} = DataFileName;
            preproc_path{subject} = DataFileLocation;
            date_preproc{subject} = datestr(now,'dd-mm-yyyy');
            
            
            % add to current subject to report table 
            cd('xxx')
            ID = extractBefore(datafile_names{subject},'_social');
            % report table
            if exist('BOND_preprocessing_report.mat','file')
                load BOND_preprocessing_report.mat
            end
            report_table_newrow = table({ID}, datafile_name_preproc_done(1,subject), preproc_path(1,subject), date_preproc(1,subject), ...
                {SiteCur}, {ExpComments}, {TimingChecks}, ...
                n_all_channels(1,subject), n_flat_bad_channels(1,subject), flat_bad_channels(1,subject),...
                reference_used_for_faster(1,subject), n_faster_bad_channels(1,subject), faster_bad_channels(1,subject),...
                ica_prep_input_n_channels(1,subject), ica_input_n_channels(1,subject), ...
                n_ica_preparation_bad_channels(1,subject), ica_preparation_bad_channels(1,subject), ...
                length_ica_data(subject), total_ICs(1,subject), n_ICs_removed(1,subject), ICs_removed(1,subject), ...
                total_epochs_before_artifact_rejection(subject), total_epochs_after_artifact_rejection(subject), ...
                n_total_channels_interpolated(subject), {total_channels_interpreted{subject}});
            report_table_newrow.Properties.VariableNames={'ID','datafile_names_preproc', 'path_preproc','date_preproc',...
                'site','exp_comments','flash_check',...
                'n_allChs', 'n_flatbadChs', 'label_flatbadChs', ...
                'reference_used_for_faster', 'n_FASTERbadChs','label_FASTERbadChs', ...
                'n_pre_prepica_Chs','n_post_prepica_Chs',...
                'n_prepicabadChs', 'label_prepicabadChs',...
                'length_ica_data', 'total_ICs', 'n_ICs_removed', 'label_ICs_removed',...
                'total_epochs_before_artifact_rejection', 'total_epochs_after_artifact_rejection',...
                'n_total_channels_interpolated', 'label_total_channels_interpolated'};
            BOND_report_table(subject,:) = report_table_newrow;
            save('BOND_preprocessing_report.mat','BOND_report_table');
            
            clear DataFileName DataFileLocation
            
            continue % ignore rest of the processing and go to next datafile
        else
            total_epochs_after_artifact_rejection(subject)=EEG.trials;
        end

    % save the data set after artifact rejection
    EEG = pop_saveset(EEG, 'filename', output_file);
    
    % Save metadata including the parameters used
    metadata = struct();
    metadata.processing_date = datestr(now);
    metadata.parameters = params;
    savejson('', metadata, metadata_file);

    toc;
    quit; 
end

    
