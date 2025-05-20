clear;
addpath('/Volumes/T7/eeglab2024.0')
eeglab;

% Define paths
saveERPPath = '/Volumes/T7/flamingo/ERPs'; % folder where your ERP files are located 
erpList = dir(fullfile(saveERPPath, "*.erp")); % list of ERP files

% Initialize an empty master table
masterTable = table();

% Process each ERP file
for k = 1:length(erpList)
    try
        fileName = erpList(k).name; % get the file name
        % Load the ERP file using the folder path
        ERP = pop_loaderp('filename', fileName, 'filepath', saveERPPath);
        
        % Define the time window in milliseconds
        timeWindow = [250 350];
        
        % Find indices in ERP.times that fall within the specified time window
        timeIndices = find(ERP.times >= timeWindow(1) & ERP.times <= timeWindow(2));
        
        % Specify the channel to process
        ch = 132;
        
        % Check if channel 132 exists in this ERP data
        if size(ERP.bindata, 1) < ch
            warning('File %s does not have channel %d. Skipping file.', fileName, ch);
            continue;
        end
        
        % Get the mean amplitude and corresponding index for channel 132 within the time window
        meanAmplitude = mean(ERP.bindata(ch, timeIndices));        
        %latencyAtMean = ERP.times(timeIndices(idx));
        
        % Get the ID from the file name (assuming ID is before an underscore)
        ID = extractBefore(fileName, '_');
        
        % Create a table for the current file (one row only)
        T = table({ID}, meanAmplitude, ...
            'VariableNames', {'subject_id_info', 'meanAmplitude'});
        
        % Append the current table to the master table
        masterTable = [masterTable; T];
        
        % Optionally display the table in the MATLAB command window
        disp(T);
        
    catch ME
        fprintf('Error processing file %s: %s\n', fileName, ME.message);
    end
end

% Write the master table to a CSV file once after processing all files
writetable(masterTable, '/Volumes/T7/flamingo/RewP_amp_output.csv');
