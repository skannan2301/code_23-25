% addpath('/Users/shreya/Desktop/eeglab2024.0')
% eeglab;
% 
% % take this file from transmit (you want a file that has been rereferenced
% % but nothing has been done with the events yet) change to match where your
% % .set and .fdt files are --> you need both in the same place 
% EEG = pop_loadset('/Users/shreya/Desktop/flamingo/test1213/jububer18_fil_cl_interp_reref.set');

addpath('/Users/shreya/Desktop/eeglab2024.0')
eeglab;

% note that these folders need to exist already for this to work 
folderPath = '/Volumes/T7/flamingo/procSteps'; % path to folder with your mffs
fileList = dir(fullfile(folderPath, '*_fil_cl_interp_reref.set')); % list of files that have been cleaned, interpolated and rereferenced in that folder ^
saveERPPath = '/Volumes/T7/flamingo/ERPsAvt'; % folder where you want to save your ERPs to 
saveStepsPath = '/Volumes/T7/flamingo/procStepsAvt'; % folder where you want to save your processing steps to
%erpList = dir(fullfile(saveERPPath, "*.erp")); not in use

% go through the files in folder 
for k = 1:length(fileList)
    fileName = fileList(k).name; % get the name of the mff file
    filePath = fullfile(folderPath, fileName); % get the path to the mff file 
    ID = extractBefore(fileName, '_'); % get just the ID

    EEG = pop_loadset('filename', fileName, 'filepath', folderPath);
    
    numEvents = length(EEG.event);
    i = 1;
    while i <= numEvents-2  % Only check if we have at least 3 events remaining
        % Safely check next events exist before comparing
        if i+2 <= numEvents && ...
           strcmpi(EEG.event(i).type, 'ix') && ...
           strcmpi(EEG.event(i+2).type, 'vt')
            % Found pattern: modify middle event type
            EEG.event(i+1).type = 'face';
            i = i + 3;  % Skip to after pattern
        else
            i = i + 1;
        end
    end
    
    % change to match where your events text file is  
    EEG  = pop_editeventlist( EEG , 'AlphanumericCleaning', 'off', 'BoundaryNumeric', { -99}, 'BoundaryString', { 'boundary' }, 'List',...
                '/Volumes/T7/flamingo/flamingEvents_010625.txt', 'SendEL2', 'EEG', 'UpdateEEG', 'code', 'Warning',...
                'off' );
    
    %for i = 1:length(EEG.event) 
    %    if isnan(EEG.event(i).type)  
    %        EEG.event(i).type = 344; 
    %    end 
    %end
    
    %EEG.event(isnan(double([EEG.event.type]))).type = 344;
    
    %[EEG.event(cellfun(@isnan,[EEG.event.type])).type] = deal(344);
    
    %EEG.event(strcmp({EEG.event.type}, 'NaN')).type = 344;
        
        % reassignment - change to match where your bins file is 
        EEG  = pop_binlister( EEG , 'BDF', '/Volumes/T7/flamingo/flamingBins_010625.txt', 'IndexEL',  1, 'SendEL2', 'EEG',... %changed file pathway
                'Voutput', 'EEG' );
        
        EEG = pop_epochbin( EEG , [-100.0  500.0],  'pre');
        
        % save after epoched
        EEG = pop_saveset(EEG, 'filename', [ID '_fil_cl_interp_reref_epoch_P300.set'], 'filepath', saveStepsPath); 
        
        EEG  = pop_artmwppth( EEG , 'Channel',  1:124, 'Flag',  1, 'LowPass',  -1, 'Threshold',  100, 'Twindow', [ -100 499], 'Windowsize',  200,...
            'Windowstep',  100 );
    
        % save after artifact detection
        EEG = pop_saveset(EEG, 'filename', [ID '_fil_cl_interp_reref_epoch_ad_P300.set'], 'filepath', saveStepsPath); 
        
        % Set the desired sampling rate
        desiredRate = 500;
        % Downsample the EEG data
        EEG = pop_resample(EEG, desiredRate);  % Downsample to 500 Hz

        % average across trials to create ERP
        ERP = pop_averager( EEG , 'Criterion', 'good', 'DQ_custom_wins', 0, 'DQ_flag', 1, 'DQ_preavg_txt', 0, 'ExcludeBoundary',...
            'on', 'SEM', 'on' );
        
        % save after averaging across trials 
        EEG = pop_saveset(EEG, 'filename', [ID '_averaged_P300.set'], 'filepath', saveStepsPath); 
    
        % adding in channels: frontal, central, frontocentral, frontoparietal
        ERP = pop_erpchanoperator( ERP, {  'ch130 = (ch4 + ch5 + ch12 + ch12 + ch19) / 5 label frontal',  'ch131 = (ch6 + ch7 + ch13 + ch106 + ch112) / 5 label frontalcentral',...
        'ch132 = (ch7 + ch31 + ch55 + ch80 + ch106) / 5 label central',  'ch133 = (ch54 + ch55 + ch61 + ch62 + ch78 + ch79) / 6 label centroparietal' , 'ch134 = (ch55 + ch72) / 2 label avatar'},...
        'ErrorMsg', 'popup', 'KeepLocations',  1, 'Warning', 'on' );
    
        ERP = pop_binoperator( ERP, {'b9 = (b1-b2) label yesMinusNo'});
        
        % save the ERP ! after adding in channels 130-134 (used to be the _chop)
        ERP = pop_savemyerp(ERP, 'erpname', 'erp', 'filename', [ID '_P300.erp'], 'filepath', saveERPPath,...
        'Warning', 'on');
    
        ERP = pop_ploterps( ERP,  8,  134 , 'AutoYlim', 'on', 'Axsize', [ 0.05 0.08], 'BinNum', 'on', 'Blc', 'pre', 'Box', [ 1 1], 'ChLabel',...
        'on', 'FontSizeChan',  10, 'FontSizeLeg',  12, 'FontSizeTicks',  10, 'LegPos', 'bottom', 'Linespec', {'k-' , 'r-' , 'b-' , 'g-' , 'c-' , 'm-' ,...
        'y-' }, 'LineWidth',  1, 'Maximize', 'on', 'Position', [ 72.375 17.5556 106.875 31.9444], 'Style', 'Classic', 'Tag', 'ERP_figure',...
        'Transparency',  0, 'xscale', [ -100.0 498.0   -100:100:400 ], 'YDir', 'normal' );

        % this doesn't save properly --> will just name the figure erp
        % without the ID
         ERP = pop_exporterplabfigure( ERP , 'filepath', saveERPPath, 'Format', 'pdf',...
    'Resolution',  300, 'SaveMode', 'auto', 'Tag', {'ERP_figure' } );
    
        % Close the figure
        close;
end