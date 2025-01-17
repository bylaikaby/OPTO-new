%% *Quality control after normalization*
% 
% 
% This script can be used to objectively review the quality of the performed 
% normalization. It orients the images in the same space, removes the background 
% noise in the normalized image through binarization, and calculates the dice 
% coefficient. 
% 
% The dice coefficient is a widely used method to calculate the similarity 
% between two samples by calculating the number of the overlapping elements*2 
% divided by the total number of elements in either sample. The resulting coefficient 
% will be between 0 and 1, with 1 indicating identical samples.
% 
% _The script was written by jennifer.smuda@tuebingen.mpg.de and vinod.kumar@tuebingen.mpg.de 
% in October 2020_
% 
% In the first step the input parameters need to be defined.
% 
% Besides defining and adding the data and toolbox paths, the template (|temp|) 
% and the normalized image (|normimg|) (path & name) need to be defined as well. 
% Both files will be copied into a newly created folder called _qualitycheck_, 
% which will hold all files generated by this script.
%%
clear all                                                                   % clear workspace
% specify basic parameters needed for the analysis & copy needed files
datapath    = ('D:\NHP_fMRI\experiment');                                   % specify datapath
toolboxpath = ('D:\MatLab_Package\fMRI\AccuMRNorm');                        % add path for toolbox
addpath(toolboxpath)

expname = ('G11Gv1');     						    % specify experiment file name
temp = fullfile('D:\NHP_fMRI\templates\NMT_v2.0', 'NMT_v2.0_sym_SS.nii');   % specify template path & name

normfile = ('wrwrssG11Gv1_scan14_ref(NMT_v2.0_sym_SS)_mreg2d_volume.nii');  % specifiy normalized image name

cd(fullfile(datapath, expname, 'norm'))                                     % planned location of quality check folder
mkdir('qualitycheck')                                                       % create qualtiy check folder
%% 
% In the second step a mask of the template is created by binarizing the 
% template (using SPM).

%% place copies of norm and temp image into quality check folder
normimgOrig = fullfile(datapath, expname, 'norm', normfile);         
copyfile(normimgOrig,'qualitycheck')
copyfile(temp,'qualitycheck')
%% create mask by binarizing the template
binarize_temp(temp,'tempbi');
%% 
% After the mask was created, both images, the binarized mask of the template 
% (|tempbi|) and the normalized image (|normimg|), will be reoriented so they 
% have the same dimensions (in case they don't already). The newly created files 
% have the prefix r.

%% orient images in same dimensions
normimg = strcat(datapath,'\',expname,'\norm\qualitycheck\',normfile);            % take copied norm image file in quality check folder
rnorm = strcat(datapath,'\',expname,'\norm\qualitycheck\','r',normfile);              % set reoriented norm file to put into quality check folder

img_orient(tempbi,normimg, rnorm);                                               
%% 
% Once both images have the same orientation, the normalized image is masked 
% (|mask_norm|) and binarized (|binarize_norm|) to remove background noise, which, 
% if left in the image, would lower the dice coefficient significantly.

%% mask norm image (mask_norm) & binarize to remove background noise (binarize_norm)
mask_norm(rnorm,rtempbi,'rnormm');
binarize_norm(rnormm,'rnormmbi');
%% 
% In the final step, the dice coefficient is calculated (|dicecoef|) and 
% stored as a variable (|save|).

%% compute the dice coefficient
dicecoeff(rnormmbi,rtempbi)

filename = strcat(expname,'_dicecoeff');
save(filename, 'dicecoeff');
%% 
% The closer the resulting dice coefficient is to 1, the better the normalization 
% has worked. In case it is too low (<0.96), the manual work in the pipeline could 
% be improved.