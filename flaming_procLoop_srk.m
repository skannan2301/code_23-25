clear;
addpath('/Volumes/T7/eeglab2024.0')
eeglab;

% note that these folders need to exist already for this to work 
folderPath = '/Volumes/T7/flamingo/testEEG'; % path to folder with your mffs
fileList = dir(fullfile(folderPath, '*.mff')); % list of files ending with .mff in that folder ^
saveERPPath = '/Volumes/T7/flamingo/ERPs'; % folder where you want to save your ERPs to 
saveStepsPath = '/Volumes/T7/flamingo/procSteps'; % folder where you want to save your processing steps to
erpList = dir(fullfile(saveERPPath, "*.erp")); % not in use

% go through the files in testEEG folder 
for k = 1:length(fileList)
    try
    fileName = fileList(k).name; % get the name of the mff file
    filePath = fullfile(folderPath, fileName); % get the path to the mff file 
    ID = extractBefore(fileName, '_'); % get just the ID

    % import mff 
    EEG = pop_mffimport({filePath},{'code'},0,0);
    
    eegOldChans = EEG;
    
    % filter (0.1, 30)
    EEG  = pop_basicfilter( EEG,  1:129 , 'Boundary', 'boundary', 'Cutoff', [ 0.1 30], 'Design', 'butter', 'Filter', 'bandpass', 'Order',  4,...
    'RemoveDC', 'on' ); 
    
    EEG = eeg_checkset( EEG );

    % save the filtered .set and .fdt to the saveStepsPath 
    EEG = pop_saveset(EEG, 'filename', [ID '_fil.set'], 'filepath', saveStepsPath);    
    
    % do this twice to catch those weird stragglers
    EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion',5,'ChannelCriterion',0.8,'LineNoiseCriterion',4,'Highpass','off','BurstCriterion','off','WindowCriterion','off','BurstRejection','off','Distance','Euclidian');
    
    % commenting 2nd one out for now to save time while testing
    % EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion',5,'ChannelCriterion',0.8,'LineNoiseCriterion',4,'Highpass','off','BurstCriterion','off','WindowCriterion','off','BurstRejection','off','Distance','Euclidian');
    
    % save again: filtered + asr raw cleaned version
    EEG = pop_saveset(EEG, 'filename', [ID '_fil_cl.set'], 'filepath', saveStepsPath); 

    % bring back bad chans
    EEG = pop_interp(EEG, eegOldChans.chanlocs, 'spherical'); 
    
    % save after interpolating 
    EEG = pop_saveset(EEG, 'filename', [ID '_fil_cl_interp.set'], 'filepath', saveStepsPath); 
    
    % remove numbers from events 
    for i=1:length(EEG.event)
        thecode = EEG.event(i).code; 
            if length(thecode) == 4
                smallCode = thecode(2:3);
                EEG.event(i).code= smallCode;
                EEG.event(i).type= smallCode;
            end
    end

    EEG = pop_reref( EEG, [],'exclude',126:129 );
    
    % save after rereferencing and after removing #s from the eventlist 
    EEG = pop_saveset(EEG, 'filename', [ID '_fil_cl_interp_reref.set'], 'filepath', saveStepsPath); 
    
    EEG  = pop_editeventlist( EEG , 'AlphanumericCleaning', 'off', 'BoundaryNumeric', { -99}, 'BoundaryString', { 'boundary' }, 'List',...
            '/Volumes/T7/flamingo/flamingEvents.txt', 'SendEL2', 'EEG', 'UpdateEEG', 'code', 'Warning',...
            'off' );
    
    % reassignment
    EEG  = pop_binlister( EEG , 'BDF', '/Volumes/T7/flamingo/flamingBins_081924.txt', 'IndexEL',  1, 'SendEL2', 'EEG',... %changed file pathway
            'Voutput', 'EEG' );
    
    EEG = pop_epochbin( EEG , [-100.0  500.0],  'pre');
    
    % save after epoched
    EEG = pop_saveset(EEG, 'filename', [ID '_fil_cl_interp_reref_epoch.set'], 'filepath', saveStepsPath); 
    
    EEG  = pop_artmwppth( EEG , 'Channel',  1:124, 'Flag',  1, 'LowPass',  -1, 'Threshold',  100, 'Twindow', [ -100 499], 'Windowsize',  200,...
        'Windowstep',  100 );

    % save after artifact detection
    EEG = pop_saveset(EEG, 'filename', [ID '_fil_cl_interp_reref_epoch_ad.set'], 'filepath', saveStepsPath); 
    
    % Set the desired sampling rate
    desiredRate = 500;
    % Downsample the EEG data
    EEG = pop_resample(EEG, desiredRate);  % Downsample to 500 Hz

    % average across trials to create ERP
    ERP = pop_averager( EEG , 'Criterion', 'good', 'DQ_custom_wins', 0, 'DQ_flag', 1, 'DQ_preavg_txt', 0, 'ExcludeBoundary',...
        'on', 'SEM', 'on' );
    
    % save after averaging across trials 
    EEG = pop_saveset(EEG, 'filename', [ID '_averaged.set'], 'filepath', saveStepsPath); 

    % adding in channels: frontal, central, frontocentral, frontoparietal
    ERP = pop_erpchanoperator( ERP, {  'ch130 = (ch4 + ch5 + ch12 + ch12 + ch19) / 5 label frontal',  'ch131 = (ch6 + ch7 + ch13 + ch106 + ch112) / 5 label frontalcentral',...
    'ch132 = (ch7 + ch31 + ch55 + ch80 + ch106) / 5 label central',  'ch133 = (ch54 + ch55 + ch61 + ch62 + ch78 + ch79) / 6 label centroparietal'} ,...
    'ErrorMsg', 'popup', 'KeepLocations',  1, 'Warning', 'on' );

    ERP = pop_binoperator( ERP, {'b8 = (b1-b2) label yesMinusNo'});
    
    % save the ERP ! after adding in channels 130-133 (used to be the _chop)
    ERP = pop_savemyerp(ERP, 'erpname', ID, 'filename', [ID '_rewP.erp'], 'filepath', saveERPPath,...
    'Warning', 'on');

    ERP = pop_ploterps( ERP,  8,  130:133 , 'AutoYlim', 'on', 'Axsize', [ 0.05 0.08], 'BinNum', 'on', 'Blc', 'pre', 'Box', [ 1 4], 'ChLabel',...
    'on', 'FontSizeChan',  10, 'FontSizeLeg',  12, 'FontSizeTicks',  10, 'LegPos', 'bottom', 'Linespec', {'k-' , 'r-' , 'b-' , 'g-' , 'c-' , 'm-' ,...
    'y-' }, 'LineWidth',  1, 'Maximize', 'on', 'Position', [ 72.375 17.5556 106.875 31.9444], 'Style', 'Classic', 'Tag', 'ERP_figure',...
    'Transparency',  0, 'xscale', [ -100.0 498.0   -100:100:400 ], 'YDir', 'normal' );

    ERP = pop_exporterplabfigure( ERP , 'filepath', saveERPPath, 'Format', 'pdf',...
    'Resolution',  300, 'SaveMode', 'auto', 'Tag', {'ERP_figure' } );
    
    % Close the figure
    close;
    catch
        a = "this crashed" + fileName; 
    end
    
end