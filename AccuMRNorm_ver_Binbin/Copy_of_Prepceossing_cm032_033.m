

% Working Normalisation pipeline used by Binbin

% it requires several customised functions:

% Any questions please contact me at binbin.yan@icpbr.ac.cn




% Changes and addons to the original:
% 1. Makes the BIDSConversion directly runnable in MATLAB

% 2. Changed the BIDSConversion setOrientation to automatically calculate
% the dimension based on size indices.

% 3. Added saving modules to save built par files.

% 4. parget now can manually select the anatomical files for every run,
% such that we can change the ana accordingly.

% 5. Added QC functions to inspect scan information, and to regularlly
% check regisration at different stages of the normalisation (with parameters controlling the number and type of
% scans)

% 6. Makes the bet4animal directly runnable in MATLAB

% 7. Makes the size of manocoreg image windows larger to view the differences


% To improve:

% Add more check_reg QCs.
% Add evaluation module.



%% Pre-Module: BIDS format conversion 

% Uses BRKRAW to perform the conversion.
% BRKRAW requires linux, thus called wsl commands. Note, the conversion had
% issue with latest version of BRKRAW, so instead used a older version
% (0.3.7)

clear all


orig_dataset2convert = 'D:\CM033.za1';
[main_dir,orig_dataset_name,ext] = fileparts(orig_dataset2convert);
bids_name = [orig_dataset_name,ext,'_','bids'];

% Initialize default values
cwd = fullfile (main_dir,bids_name);

subject_name = 'sub-CM033';
subject_folder = fullfile(cwd,subject_name); 
AccuMRNorm_Dir = 'D:\AccuMRnorm_binbin\AccuMRNorm_ver_Binbin';

% remember to update the tool box folders in use in the Accu folder
folders = {'exppar','mri','plt','utils','linux','nifti_tools-master','paravision','stat'};
sub_Dirs = cellfun(@(folder) fullfile(AccuMRNorm_Dir, folder), folders, 'UniformOutput', false);
addpath(AccuMRNorm_Dir);
cellfun(@(sub_Dir) addpath(genpath(sub_Dir)),sub_Dirs);

temp_Dir = 'D:\AccuMRnorm_binbin\NMT_v2.0'; % Folder of the template
temp = 'NMT_v2.0_sym_SS'; % Default template file name
%% 
function BIDS_format_conversion_interface()
    % Create the main figure
    fig = uifigure('Name', 'BIDS Format Conversion', 'Position', [100 100 400 400]);
    
    % Create labels and input fields for each parameter
    uilabel(fig, 'Position', [20 350 120 22], 'Text', 'Original Dataset:');
    datasetField = uieditfield(fig, 'text', 'Position', [150 350 200 22]);
    
    uilabel(fig, 'Position', [20 300 120 22], 'Text', 'Subject Name:');
    subjectField = uieditfield(fig, 'text', 'Position', [150 300 200 22]);
    
    uilabel(fig, 'Position', [20 250 120 22], 'Text', 'AccuMRNorm Dir:');
    accDirField = uieditfield(fig, 'text', 'Position', [150 250 200 22]);
    
    uilabel(fig, 'Position', [20 200 120 22], 'Text', 'Template Dir:');
    tempDirField = uieditfield(fig, 'text', 'Position', [150 200 200 22]);
    
    uilabel(fig, 'Position', [20 150 120 22], 'Text', 'Template File:');
    tempFileField = uieditfield(fig, 'text', 'Position', [150 150 200 22]);
    
    % Create a button to run the conversion
    convertButton = uibutton(fig, 'Position', [150 50 100 30], 'Text', 'Convert', ...
        'ButtonPushedFcn', @(btn, event) convertToBIDS(datasetField.Value, subjectField.Value, ...
        accDirField.Value, tempDirField.Value, tempFileField.Value));
end

function convertToBIDS(orig_dataset2convert, subject_name, AccuMRNorm_Dir, temp_Dir, temp)
    % Clear all previous variables
    clear all;

    % Parse dataset path
    [main_dir, orig_dataset_name, ext] = fileparts(orig_dataset2convert);
    bids_name = [orig_dataset_name, ext, '_', 'bids'];

    % Initialize default values
    cwd = fullfile(main_dir, bids_name);
    subject_folder = fullfile(cwd, subject_name);

    % Update the toolbox folders in use in the Accu folder
    folders = {'exppar', 'mri', 'plt', 'utils', 'linux', 'nifti_tools-master', 'paravision', 'stat'};
    sub_Dirs = cellfun(@(folder) fullfile(AccuMRNorm_Dir, folder), folders, 'UniformOutput', false);
    addpath(AccuMRNorm_Dir);
    cellfun(@(sub_Dir) addpath(genpath(sub_Dir)), sub_Dirs);

    % Display confirmation message
    disp('BIDS format conversion initialized with the following parameters:');
    disp(['Original Dataset: ', orig_dataset2convert]);
    disp(['Subject Name: ', subject_name]);
    disp(['AccuMRNorm Directory: ', AccuMRNorm_Dir]);
    disp(['Template Directory: ', temp_Dir]);
    disp(['Template File: ', temp]);

    % Conversion process would be implemented here
    % For example, calling BRKRAW and other necessary functions
end

% Run the interface
BIDS_format_conversion_interface();

%%  BIDS initialisation

cd (main_dir)
bids_help_cmd = ['wsl /home/bb/miniconda3/bin/brkraw bids_helper ' ...,
    [orig_dataset_name,ext,' ',bids_name,' -f xlsx -j']];

%% IMPORTANT, we need to update information in the .xlsx table created, to
% fill in information like task type, run number, so that we can
% distinguish them after conversion.


system (bids_help_cmd)

% fill in info or copy the prepared version of the excel data sheet to the
% working folder
%% BRKRAW conversion starts, together with unzipping for the ease of SPM processing
bids_convert_cmd = ['wsl /home/bb/miniconda3/envs/unet/bin/brkraw bids_convert ',[orig_dataset_name,ext,' ',bids_name,'.xlsx -j ',orig_dataset_name,' -o ',bids_name]] ;

system (bids_convert_cmd)

% decompress the converted dataset to allow processing with SPM.
system(['wsl gunzip -r ',bids_name])


%% Pre-Module: Working Environment and variables for converted BIDS dataset


cd (cwd);

% save all the path and name information to a structure 'par'.

par = parget(subject_name,cwd,AccuMRNorm_Dir,temp_Dir,temp)

% save 'par' for ease of reloading


%% Pre-Module: Re-Orientation
cd (par.pathepi)

for i = 1:numel(par.runs)
 epi = par.runs(i).name;
 setNiiOrientation (epi);
 flip_lr(epi,epi)

end

anas=dir(fullfile(par.pathana,"*.nii"));

for i = 1:length(anas)
 ana = fullfile(anas(i).folder,anas(i).name);
 setNiiOrientation (ana);
 flip_lr(ana,ana)
%

end
cd(cwd)
%% 

% 
% files=dir('*.nii');
% for i = 1:numel(files)
%  epi = files(i).name;
%  setNiiOrientation (epi);
%  flip_lr(epi,epi)
% end
% 



%% Pre-Module: Quality Check - Dimension

% Inspection of the dimensions of the EPIs.

inspectEPIInformation (par);

%% Pre-Module: Quality Check - Display to check size, orientation and initial alignment.

% Display the selected ANAT, n*EPIs, and the chosen template.
qcDisplay(par,4);

%% Normalisation Module: Skull Stripping


% Use bet4animal (brain extraction tool of FSL) to skullstripp the anatomical image chosen
% 0.2 is the threshold to use for bet

run_bet4animal_macaque('/home/bb/fsl',par.ana,par.pathana,0.3);


% Inpect the result of skull stripping
spm_check_registration (par.ana,ss_anat,par.temp_fulldir);
spm_orthviews('Reposition', 64.5, 64.5, 20.0);
spm_orthviews('Zoom', -inf, 3);

userInput = input('Skull-stripping Alright? (Y/N): ', 's');

% Check the user's input
if strcmpi(userInput, 'Y')
    disp('skull stripped ana is now the main ana');
    % Add your code for the next steps here
    par.ana=ss_anat;
    [~,par.anaorig,~]=fileparts(ss_anat);
    par
elseif strcmpi(userInput, 'N')
    disp('redo the skull stripping');
    return;  % or add code to handle the exit
else
    disp('Invalid input. ');
    % Handle the case where the input is neither Y nor N
end



save(fullfile(par.work_dir,"par.mat"),"par")

%% Potential DEFT module
% % use deft for MREG2D_GUI
% par.pathdeft = fullfile(par.work_dir,'etc');
% cd (par.pathdeft)
% par.deft = uigetfile({ '*.nii'}, 'Select Aid_Anatomical File', par.pathdeft);
% par.deft = fullfile(par.pathdeft,par.deft)
% cd (cwd)
% 
% run_bet4animal_macaque('/home/bb/fsl',par.deft,par.pathdeft,0.2);
% 
% 
% if isfield(par, 'deft')
%     setNiiOrientation (par.deft);
% end
% 

%% Normalisation Module: Reslicing (EPI2EPI) and Realignment (ANA2EPI)



fMRI_preprocessing_par(par);




%% Normalisation Module: Quality Check of the RR process

qcDisplay(par,3,'r');


%% Normalisation Module: Manual Coregistration 

% note, do not close the panel after finishing the adjustment. As the
% followup EPI coregistration will require transformation information from
% it.

[mancoregvar] = mancoreg(par.temp_fulldir,par.ana);       
                                                                 
% realign the EPIs 
% note here par.partial_runs is used instead of par.runs, norm_epi
% automatically choose to normalise functionals with prefix r, meaning
% resliced
norm_epi(par.folder,mancoregvar,par.runs,par.norm_dir);

%% - Routine QC
qcDisplay(par,3,'r');


%% Normalisation Module: DARTEL Prep
%% - DARTEL Prep 1: get epivox, parameter adaptations
% check epi vox dimension

inspectEPIInformation (par);
epivox =[1 1 2];

USE_PARALLEL= true ; % true:  parallelization to process functional scans
                     % false: uses usual serial processing
% Settings for DARTEL transform of functional scans    
smoothing1  = [0 0 0]; % FWHM: Smoothing for 1st pass
smoothing2  = [2 2 2]; % FWHM: Smoothing for 2nd pass
bounding_box = [-50 -38.7 -5.9; 50 64.3 46.1];          

%% - DARTEL Prep 2: Tissue Probability Maps 
% 4) Generation of probability maps (through segmentation of anatomical data 
% (seg_ana)) and subsequent skull stripping (skullstrip).
%%
% probability maps for anatomy
seg_ana(par.pathana,par.anaorig,cwd,par.folder,par.temp_dir,par.norm_dir);  

% avg pob maps & skull strip
skullstrip(par.pathana,par.anaorig);                             

% re-run segmentation to get skullstripped prob maps
fnameana    = strcat('ss',par.anaorig);                                     % specify parameter

seg_ana(par.pathana,fnameana,cwd,par.folder,par.temp_dir,par.norm_dir);
%% Normalisation Module: DARTEL 

%% - DARTEL Normalisation (Anatomical): 1st Pass
% 5) Use DARTEL algorithm to normalize the anatomical data (dartel_norm_ana).
%%
warpedimg   = cellstr(strcat(par.norm_dir,'\rc2ss', par.anaorig));          % warped img. native after warping to templ
rimgana     = cellstr(strcat(par.norm_dir,'\rss', par.anaorig));            % realigned anatomicals

c3Images    = cellstr(strcat(par.pathana,'\c3ss',par.anaorig));             % c3-segmented img (WM)
c2Images    = cellstr(strcat(par.pathana,'\c2ss',par.anaorig));             % c2-segmented img (GM)
c1Images    = cellstr(strcat(par.pathana,'\c1ss',par.anaorig));             % c1-segmented img (CSF)

dartel_norm_ana(warpedimg,rimgana,c3Images, c2Images,c1Images);
%% - DARTEL Normalisation (Functional): 1st Pass
cd(par.norm_dir)
imgtemp     = dir('u_rc2ss*.nii') 	    		                   % specify deformation file 

% in the test run we only normalise 3 functional runs, so specify the
% resliced runs. Note below code we also used par.partial_runs instead of
% par.runs
% for i = 1:numel(par.partial_runs)
%     par.partial_runs(i).name = ['r',par.partial_runs(i).name];
% end

% first pass at EPI warping
% edited spm12\toolbox\DARTEL\spm_dartel_norm_fun.m's tpm t make it monkey
% specific
switch USE_PARALLEL
    case true  % If we run parallelized mode

        dartel_norm_epi_parallel(par.runs,par.pathepi,imgtemp,epivox,1, bounding_box, smoothing1); 
    case false % If we run regular mode
        dartel_norm_epi(par.runs,par.pathepi,imgtemp,epivox,1);
end     

%% DARTEL Normalisation: Manual Coregistration, Refinement of Normalization Parameters
%% part1: Quality check & manual adaptations (mreg2d_gui)

fnameana    = strcat('wrss',par.anaorig);                                   % specify parameter
% ana         = fullfile(par.norm_dir,fnameana); 
ana = "D:\test_result_anat2temp_with_deform\outputWarped.nii"
% specify parameter
%GUI for manual adaptations
mreg2d_gui(par.temp_fulldir,ana);        




%% part2: Export of the results to .nii files (tvol2nii).  

tvol2nii(par.norm_dir, par.temp_dir, par.temp); 

%%
fnameana = strcat('wrss',par.baseFileNameNoExt,'_ref(',par.temp,')_mreg2d_volume.nii'); 
seg_ana(par.norm_dir,fnameana,cwd,par.folder,par.temp_dir,par.norm_dir);

warpedimg   = cellstr(strcat(par.norm_dir,'\rc2',fnameana));
rimgana     = cellstr(strcat(par.norm_dir,'\r', fnameana));
c3Images    = cellstr(strcat(par.norm_dir,'\c3',fnameana));
c2Images    = cellstr(strcat(par.norm_dir,'\c2',fnameana));
c1Images    = cellstr(strcat(par.norm_dir,'\c1',fnameana));

dartel_norm_ana(warpedimg,rimgana,c3Images, c2Images,c1Images);
%%
cd(par.norm_dir)
imgtemp     = dir('u_rc2wrss*.nii'); 					            % specify deformation file 

% second pass at EPI warping
switch USE_PARALLEL
    case true  % If we run parallelized mode
        dartel_norm_epi_parallel(par.runs,par.pathepi,imgtemp,epivox,2, bounding_box, smoothing2); 
    case false % If we run regular mode
        dartel_norm_epi(par.partial_runs,par.pathepi,imgtemp,epivox,2);
end

par.normfile = ['wrwrss',par.baseFileNameNoExt,'_ref(NMT_v2.0_sym_SS)_mreg2d_volume.nii'];

%% QualityCheck

calculateDiceCoefficient (par)
