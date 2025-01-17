
function dirs = setup_GLM_directories(position,conditions,param_matfile)
    
    % Function to set up and return a structure with directory paths for analysis
    % parameters should include baseDir, subjectID, taskName, analysis_folder_name,regressor_rois,mask_file,position,conditions

    % first, attempt to read a mat file if existed 
    load(param_matfile);
    % Define main analysis directory
    analysis_dir = fullfile(baseDir, subjectID, analysis_folder_name);
    
    % Define function directory within analysis directory
    func_dir = fullfile(baseDir, subjectID, 'func');
    
    % Define onset times directory
    onsetTimesDir = fullfile(analysis_dir, 'onset_times');
    
    % Get the current date and time
    currentDateTime = datetime('now');
    
    % Format the date and time into a string that can be used as a folder name
    folderName = sprintf('%s_%s_%s', taskName, char(strjoin(conditions,'_')), position);
    
%     % Create the folder within the analysis directory
%     if ~exist(fullfile(analysis_dir, folderName), 'dir')
%         mkdir(analysis_dir, folderName);
%     end
%     
    % Define the output directory within the newly created folder
    output_dir = fullfile(analysis_dir,folderName);
   
    % Package all directories into a structure
    dirs = struct(...
        'baseDir', baseDir, ...
        'subjectID', subjectID, ...
        'analysis_dir', analysis_dir, ...
        'func_dir', func_dir, ...
        'onsetTimesDir', onsetTimesDir, ...
        'foldername', folderName, ...
        'output_dir', output_dir, ...
    'regressor_rois',{regressor_rois},...    
    'mask',GLM_mask_file,... 
    'parameter_file',paramfile_name,...
    'print_template',print_template);

end