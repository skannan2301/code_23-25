clear;
addpath('/Volumes/T7/eeglab2024.0')
eeglab;

% note that these folders need to exist already for this to work 
saveStepsPath = '/Volumes/T7/flamingo/procSteps'; % folder where you want to save your processing steps to
fileList = dir(fullfile(saveStepsPath, '*_fil_cl_interp_reref_epoch_ad.set')); % list of files that have gone through artifact rejection in that folder ^
saveADTablePath = '/Volumes/T7/flamingo/ad'; % path to folder to save artifact detection tables

for k = 1:length(fileList)
    
    try
    fileName = fileList(k).name; % get the name of the mff file
    filePath = fullfile(saveStepsPath, fileName); % get the path to the mff file 
    ID = extractBefore(fileName, '_'); % get just the ID
    
    % load your already–artifact-rejected dataset
    EEG = pop_loadset('filename', fileName, 'filepath', saveStepsPath);

    % run the summary artifact-rejection routine
    % —– NOTE: pop_summary_AR_eeg_detection returns a MATLAB table
    summaryTable = pop_summary_AR_eeg_detection(EEG);

    % save the table as a .mat
    outName = fullfile(saveADTablePath, [subjID '_ADtable.mat']);
    save(outName, 'summaryTable');

    catch
        a = "this crashed" + fileName; 
    end
end



