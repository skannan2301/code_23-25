function a_importmff_and_saveset(input_file, output_file, metadata_file, params)
    % a_importmff_and_saveset - Imports an MFF file and saves it as a .set file
    %
    % Syntax: a_importmff_and_saveset(input_file, output_file, metadata_file, params)
    %
    % Inputs:
    %    input_file - String, path to the input MFF file
    %    output_file - Ex: output_file = 'C:/my_folder/my_dataset.set'; --> needs to include '.set' and the directory has to exist 
    %	 metadata_file - 
    %	 params - 
    
    % Load EEGLAB to enable importing MFF files
    tic;    
    %addpath('/gpfs/milgram/project/naples/ajn23/codeLib/eeglab1024/eeglab2024.2')
    addpath('/Users/shreya/Desktop/eeglab2024.0')
    eeglab('nogui'); % ensure EEGLAB is added to the path

    % Load the .mff file
    EEG = pop_mffimport({input_file},{'code'},0,0);

    % Save the data as a .set file
    EEG = pop_saveset(EEG, 'filename', output_file);

    % Save metadata including the parameters used
    metadata = struct();
    metadata.processing_date = datestr(now);
    %metadata.parameters = params;
    savejson('', metadata, metadata_file);

    toc;
	
    % this line will quit out of MATLAB
    %quit;
end
