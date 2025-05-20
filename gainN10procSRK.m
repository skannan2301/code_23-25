addpath('/Users/shreya/Desktop/eeglab2024.0')
eeglab;

folderPath = '/Users/shreya/Desktop/gain/testEEG';
fileList = dir(fullfile(folderPath, '*.mff')); 
saveERPPath = '/Users/shreya/Desktop/gain/ERPs';
erpList = dir(fullfile(saveERPPath, "*.erp")); 

for k = 1:length(fileList)
    fileName = fileList(k).name;
    filePath = fullfile(folderPath, fileName);
    ID = extractBefore(fileName, '_'); %extract ID

    %
    EEG = pop_mffimport({filePath},{'code'},0,0);
    
    eegOldChans = EEG;
    
    % filter
    EEG  = pop_basicfilter( EEG,  1:129 , 'Boundary', 'boundary', 'Cutoff', [ 0.01 58], 'Design', 'butter', 'Filter', 'bandpass', 'Order',  4,...
    'RemoveDC', 'on' ); % GUI: 06-Mar-2024 15:08:40
    
    EEG = eeg_checkset( EEG );
    
    % do this twice to catch those weird stragglers
    %EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion',5,'ChannelCriterion',0.8,'LineNoiseCriterion',4,'Highpass','off','BurstCriterion','off','WindowCriterion','off','BurstRejection','off','Distance','Euclidian');
    
    EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion',5,'ChannelCriterion',0.8,'LineNoiseCriterion',4,'Highpass','off','BurstCriterion','off','WindowCriterion','off','BurstRejection','off','Distance','Euclidian');
    
    EEG = pop_interp(EEG, eegOldChans.chanlocs, 'spherical'); % bring the bad ones back!

    EEG = pop_reref( EEG, [],'exclude',126:129 );
    
    EEG  = pop_editeventlist( EEG , 'AlphanumericCleaning', 'off', 'BoundaryNumeric', { -99}, 'BoundaryString', { 'boundary' }, 'List',...
            '/Users/shreya/Desktop/gain/sadEventList.txt', 'SendEL2', 'EEG', 'UpdateEEG', 'code', 'Warning',... %changed file pathway
            'off' );
    
        %EEG  = pop_overwritevent( EEG, 'codelabel'  );
        %EEG  = pop_overwritevent( EEG, 'code'  );
    
    % reassignment
    EEG  = pop_binlister( EEG , 'BDF', '/Users/shreya/Desktop/gain/aggSadface.txt', 'IndexEL',  1, 'SendEL2', 'EEG',... %changed file pathway
            'Voutput', 'EEG' );
    
    EEG = pop_epochbin( EEG , [-200.0  300.0],  'pre'); %changed this from -200, 500 to -200, 300 for N100
    EEG  = pop_artmwppth( EEG , 'Channel',  1:124, 'Flag',  1, 'LowPass',  -1, 'Threshold',  80, 'Twindow', [ -200 299], 'Windowsize',  200,... %changed this to 299 max
            'Windowstep',  100 );
    EEG  = pop_artextval( EEG , 'Channel',  1:124, 'Flag',  1, 'LowPass',  -1, 'Threshold', [ -100 100], 'Twindow',...
            [ -200 299] );
    EEG  = pop_artmwppth( EEG , 'Channel',  1:124, 'Flag',  1, 'LowPass',  -1, 'Threshold',  65, 'Twindow', [ -200 299], 'Windowsize',  100,... %changed this to 299 max
            'Windowstep',  100 );
    
    ERP = pop_averager( EEG , 'Criterion', 'good', 'DQ_custom_wins', 0, 'DQ_flag', 1, 'DQ_preavg_txt', 0, 'ExcludeBoundary',...
            'on', 'SEM', 'on' );

    ERP = pop_erpchanoperator( ERP, {  'ch130 = (ch89 + ch90 + ch91 + ch94 + ch95 + ch96)/6 label t6Avg'} , 'ErrorMsg', 'popup', 'KeepLocations',...
         1, 'Warning', 'on' );

    ERP = pop_savemyerp(ERP, 'erpname', ID, 'filename', [ID '.erp'], 'filepath', saveERPPath,...
            'Warning', 'on');
    ERP = pop_ploterps( ERP,  1:4,  130 , 'AutoYlim', 'on', 'Axsize', [ 0.05 0.08], 'BinNum', 'on', 'Blc', 'pre', 'Box', [ 1 1], 'ChLabel', 'on',...
            'FontSizeChan',  10, 'FontSizeLeg',  12, 'FontSizeTicks',  10, 'LegPos', 'bottom', 'Linespec', {'k-' , 'r-' , 'b-' , 'g-' }, 'LineWidth',...
            1, 'Maximize', 'on', 'Position', [ 72.3929 17.5556 106.857 31.9444], 'Style', 'Classic', 'Tag', 'ERP_figure', 'Transparency',  0, 'xscale',...
            [ -200.0 298.0   -200:100:200 ], 'YDir', 'normal' );

end

for j = 1:length(erpList)
    fileName = fileList(j).name;
    filePath = fullfile(saveERPPath, fileName);
    ID = extractBefore(fileName, '_'); %extract ID

    ERP = pop_loaderp( 'filename', filePath, 'filepath', saveERPPath );

    % ERP = pop_ploterps( ERP,  1:4,  130 , 'AutoYlim', 'on', 'Axsize', [ 0.05 0.08], 'BinNum', 'on', 'Blc', 'pre', 'Box', [ 1 1], 'ChLabel', 'on',...
    %     'FontSizeChan',  10, 'FontSizeLeg',  12, 'FontSizeTicks',  10, 'LegPos', 'bottom', 'Linespec', {'k-' , 'r-' , 'b-' , 'g-' }, 'LineWidth',...
    %      1, 'Maximize', 'on', 'Position', [ 72.3929 17.5556 106.857 31.9444], 'Style', 'Classic', 'Tag', 'ERP_figure', 'Transparency',  0, 'xscale',...
    %      [ -200.0 298.0   -200:100:200 ], 'YDir', 'normal' );

    %saveas(gcf, [ID '.jpg']);

end



% ERP = pop_loaderp( 'filename', 'adricya96.erp', 'filepath', '/Users/shreya/Desktop/gain/testEEG/' );

ERP = pop_ploterps( ERP,  1:4,  130 , 'AutoYlim', 'on', 'Axsize', [ 0.05 0.08], 'BinNum', 'on', 'Blc', 'pre', 'Box', [ 1 1], 'ChLabel', 'on',...
 'FontSizeChan',  10, 'FontSizeLeg',  12, 'FontSizeTicks',  10, 'LegPos', 'bottom', 'Linespec', {'k-' , 'r-' , 'b-' , 'g-' }, 'LineWidth',...
  1, 'Maximize', 'on', 'Position', [ 72.3929 17.5556 106.857 31.9444], 'Style', 'Classic', 'Tag', 'ERP_figure', 'Transparency',  0, 'xscale',...
 [ -200.0 298.0   -200:100:200 ], 'YDir', 'normal' );



%    ERP = pop_ploterps( ERP,  130,  1 , 'AutoYlim', 'on', 'Axsize', [ 0.05 0.08], 'BinNum', 'on', 'Blc', 'pre', 'Box', [ 1 1], 'ChLabel', 'on',...
% 'FontSizeChan',  10, 'FontSizeLeg',  12, 'FontSizeTicks',  10, 'LegPos', 'bottom', 'Linespec', {'k-' , 'r-' , 'b-' , 'g-' , 'c-' , 'm-' ,...
% 'y-' , 'w-' , 'k-' }, 'LineWidth',  1, 'Maximize', 'on', 'Position', [ 102.476 19.3714 106.857 31.9286], 'Style', 'Classic', 'Tag', 'ERP_figure',...
% 'Transparency',  0, 'xscale', [ -200.0 499.0   -200:100:400 ], 'YDir', 'normal' );

    % Save the figure to a PDF file
%    ERP = pop_exporterplabfigure( ERP , 'folderPath', figures_Folder, 'Format', 'pdf',...
% 'Resolution',  300, 'SaveMode', 'auto', 'Tag', {'ERP_figure' } );

% butterfly
% plot(ERP.bindata(:,:,1)')
% plot(ERP.bindata(89,:,2)')



% 
% make a new channel for the right hemi
%ERP = pop_erpchanoperator( ERP, {  'ch130 = (ch89 + ch90 + ch91 + ch94 + ch95 + ch96)/6 label t6Avg'} , 'ErrorMsg', 'popup', 'KeepLocations',...
%         1, 'Warning', 'on' );
% 
%     % save the ERP for later picking
%     ERP = pop_savemyerp(ERP, 'erpname', baseFileName, 'filename', [baseFileName '_TMS.erp'], 'filepath',...
%         '/Volumes/scratcher/dodTMS/data/sadFace/ERP');
%     catch
%         FileList2Proc(k).name
%     end
% 
% end
