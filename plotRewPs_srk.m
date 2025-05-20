clear;
addpath('/Volumes/T7/eeglab2024.0')
eeglab;

% note that these folders need to exist already for this to work 
%folderPath = '/Volumes/T7/flamingo/mffs_514'; % path to folder with your mffs
%fileList = dir(fullfile(folderPath, '*.mff')); % list of files ending with .mff in that folder ^
saveERPPath = '/Volumes/T7/flamingo/RewPs'; % folder where you want to save your ERPs to 
%saveStepsPath = '/Volumes/T7/flamingo/procSteps'; % folder where you want to save your processing steps to
erpList = dir(fullfile(saveERPPath, "*.erp")); % list of erps

for k = 1:length(erpList)
    try 
    fileName = erpList(k).name;                 % 'subj01.erp'
    fileDir  = saveERPPath;                     % '/my/folder'
    fullPath = fullfile(fileDir,fileName);      % '/my/folder/subj01.erp'

    ERP = pop_loaderp('filename', fileName, 'filepath', fileDir, 'overwrite', 'off', ...
            'warning', 'on');

    ERP = pop_ploterps( ERP,  8,  130:133 , 'AutoYlim', 'on', 'Axsize', [ 0.05 0.08], 'BinNum', 'on', 'Blc', 'pre', 'Box', [ 1 4], 'ChLabel',...
    'on', 'FontSizeChan',  10, 'FontSizeLeg',  12, 'FontSizeTicks',  10, 'LegPos', 'bottom', 'Linespec', {'k-' , 'r-' , 'b-' , 'g-' , 'c-' , 'm-' ,...
    'y-' }, 'LineWidth',  1, 'Maximize', 'on', 'Position', [ 72.375 17.5556 106.875 31.9444], 'Style', 'Classic', 'Tag', 'ERP_figure',...
    'Transparency',  0, 'xscale', [ -100.0 498.0   -100:100:400 ], 'YDir', 'normal' );

    ERP = pop_exporterplabfigure( ERP , 'filepath', saveERPPath, 'Format', 'pdf',...
    'Resolution',  300, 'SaveMode', 'auto', 'Tag', {'ERP_figure' } );
    
    % Close the figure
    close;

    catch ME
        fprintf('Failed on %s:\n%s\n', fullPath, ME.message);
    end

end
