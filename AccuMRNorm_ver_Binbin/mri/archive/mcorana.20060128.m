function roiTs = mcorana(SesName, GrpExp)
%MCORANA - Correlation Analysis for functional MRI
% roiTs = MCORANA(SesName, GrpExp) loads the roiTs structure of an experiment or group file
% and runs cross-correlation analysis between each voxel's time series and one or more
% models defined by the user.
%
% The regressors (or models) used for correlation analysis can be diverse depending on
% whether or not fMRI was combined with physiology. In the latter case, regressors can be
% the usual models created on the basis of stimulus timing information, or alternatively can
% be any of the neural signals (in the blp structure), which are first convolved with a real
% (estimated from the data) or with a theoretically computed HRF.
%  
%  
%  
%  Models are created by calling the EXPGETSTM function (see
% arguments and coventions in expgetstm.m). In addition models can be defined by averaging
% the neural activity in different frequency bands (LFP, MUA etc.).
%
% MCORANA assumes that MAREATS is already invoked.
% Note (NKL 5.1.2006) that as of this date the DETREND function in mareats, does NOT remove
% the mean of the time courses, but only the linear trends. This is important for
% experiments, such as those of the Hypercapnia project, in which the absolute value of
% activation is used to compare different runs.
% Default values for the preprocessing done during the selection of time series of
% individual ROI by means of MAREATS are:
%
% ANAP.mareats.IEXCLUDE   = {'brain'};  % Exclude in MAREATS
% ANAP.mareats.ICONCAT    = 1;          % 1= concatanate ROIs before creating roiTs
% ANAP.mareats.IFFTFLT    = 0;          % Respiratory artifact removal I
% ANAP.mareats.IARTHURFLT = 1;          % Respiratory artifact removal II (Default)
% ANAP.mareats.IMIMGPRO   = 0;          % No imageprocessing for high temp/spat fMRI
% ANAP.mareats.ICUTOFF    = 1;          % 1Hz low pass cutoff
% ANAP.mareats.ICUTOFFHIGH= 0;          % No highpass
% ANAP.mareats.ITOSDU     = 0;          % No transformation to SD-units (Default)
%
% MCORANA will apply the correlation analysis to either observation-period or trial based
% experiments. The selection of roiTs type is defined in the description file. For example,
% for an experiment, in which positive and negative BOLD is studied, the defaults can be:
% 
% GRPP.corana{1}.mdlsct = 'hemo';
% GRPP.corana{2}.mdlsct = 'invhemo';
%
% At this point, it's a good idea to also define the signals to be grouped by
% SESGRPMAKE. For the observation-based experiments this can be:
% GRPP.grpsigs = {'blp';'roiTs'};
% For the trial-based experiments:
% GRPP.grpsigs = {'tblp';'troiTs'};
%
% The following parameters must be defined appropriately in the description file to ensure
% proper function of MCORANA:
%  
% ANAP.aval               = 0.05;         % p-value for selecting time series
% ANAP.rval               = 0.15;         % r (Pearson) coeff. for selecting time series
% ANAP.shift              = 0;            % nlags for xcor in seconds
% ANAP.clustering         = 1;            % apply clustering after voxel-selection
% ANAP.bonferroni         = 0;            % Correction for multiple comparisons
%  
% Note: The selection of method was done by comparing results from different
% analyses-types. According to NKL & YM (04.01.06) for the hypercapnia data (e.g. J04yz1,
% but it can be generalized for any trial-based session):
%
% 1.    Selecting voxels by MCORANA for each trial does not give good results.
% 2.    We'll adapt the method of selecting voxels on the basis of the strongest stimulus,
%       which is indicated by the reftrial field.
% 3.1   We tried to run sescorana "indiscriminably" for all groups with stimulus.
% 3.2   We then averaged by "or"ing p/r
% 3.3   The normo works very well. All hypercapnia groups show a drop after the largest
%       contrast and a further drop for the lowest contrast. Intermediate contrast effects
%       are not well discriminable.
% 3.4   The MION shows lack of sensitivity to contrast-changes, in general. With HYPERC the
%       situation is obviously worse, because the signal is dominated by volume changes and
%       reduced sensitivity to CMRO2 changes.
% 4.    To ensure that the analysis of individual experiments selects voxels that were
%       positively correlated with the stimulus, we analyzed the control group, we determine
%       a mask with voxels above certain threshold, and we apply this mask to individual
%       experiments. In this way, each experiment can only be a "subset" of the control
%       group. In other words, if we expect an inversion of BOLD, as is the case in the
%       hypercapnia project, then we know that the negative BOLD is coming from voxels that
%       were POSITIVELY correlated with the stimulus during the control experiment.
%
% MCORANA will analyze session with diverse groups (trial-based, obsp-based, w/ stimulus,
% and w/out stimulus). For proper function, make sure the following fields are defined in
% your description file:
%  
% GRP.normobase.stminfo           = 'none | polar | pinwheel w/ Var-Contrast';  etc...
% GRP.normobase.condition         = {'normal | hypercapnia | injection'}; 
%
% If the session contains groups with stimulus and trial-format, then:
%  
% Defaults:
% GRPP.anap.gettrial.status       = 0;        % IsTrial
% GRPP.anap.gettrial.Xmethod      = 'tosdu';  % Argument (Method)to xfrom in gettrial
% GRPP.anap.gettrial.Xepoch       = 'prestim';% Argument (Epoch) to xfrom in gettrial
% GRPP.anap.gettrial.Average      = 1;        % Do not average tblp, but concat
% GRPP.anap.gettrial.Convolve     = 1;        % If =1, then use HRF; otherwise resample only
% GRPP.anap.gettrial.RefChan      = 2;        % Reference channel (for DIFF)
% GRPP.anap.gettrial.newFs        = 10;       % Filter envelop down to 4Hz (1/TR); if 0 no-resamp
% GRPP.anap.gettrial.sort         = 'trial';  % sorting with SIGSORT, can be 'none|stimulus|trial
% GRPP.anap.gettrial.reftrial     = 5;        % Use the .reftrial for analysis
%  
% Group-Specific:
% GRP.normostim.anap.gettrial.status        = 0;
% GRP.normostim.anap.gettrial.Xmethod       = 'none';
% GRP.normostim.anap.gettrial.reftrial      = 1;        % Use the .reftrial for analysis
% GRP.normostim.grpsigs                     = {'tblp';'troiTs'};
%  
% For the cross-correlation analysis the procedue we finally selected is:
% (1) Run MCORANA for each experiment
% (2) Group experiments according to the grp.exps. During this procedure the best voxels of
%     any experiment (logical OR) are selected.
% (3) Use the control-groups to generate a mask from voxels always correlated with the
%     stimulus (quasi logical AND, in the sense that we can select 80-100% of the experiments as
%     criterion).
% (4) When you need to obtain the best-correlated voxels of any experiment, which are within
%     the control-group defined mask, use roiTs = MAPPLYMASK(roiTs);
%
% ======================================================================================
% In summary, typical preprocessing steps to run SESCORANA are:
% ======================================================================================
% sesdumppars('j04yz1');        % Extract parameters, generate SesPar.mat file
% sesimgload('j04yz1');         % Load all 2dseq files, generate tcImg structure
% sesroi('j04yz1');             % Define ROIs
% sesareats('j04yz1');          % Extract their time series
% sesgettrial('j04yz1');        % Sort by trial, if trial-based groups exist
% sescorana('j04yz1');          % Run correlation analysis for obsp/trial-based exps
% sesgrpmake('j04yz1');         % Group them
% sesgetmask('j04yz1');         % Get the masks generated in control experiments (e.g. normo)
%
% See also SESCORANA, EXPMKMODEL, MATSCOR, MCOR, SHOWMODEL
%
% NKL, 01.13.00, 07.10.01, 02.09.02, 23.10.02 17.04.04
% NKL, 27.12.05, 05.01.06
  
if nargin < 2,
  help mcorana;
  return;
end;

Ses = goto(SesName);
grp = getgrp(Ses,GrpExp);

roiTs = subRunMATSCOR(Ses,GrpExp);    

if ~nargout,
  mfigure([1 100 800 800]);
  dsproits(roiTs);
  mfigure([801 100 580 800]);
  dsprpvals(roiTs);
end;
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNTION to run correlation analysis
function roiTs = subRunMATSCOR(SesName,GrpExp)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SesName);
grp = getgrp(Ses,GrpExp);

% ==========================================================================================
% The following fields *must* be defined before the MCORANA is invoked
% ==========================================================================================
% GRPP.anap.gettrial.status    = 0;        % IsTrial
% GRPP.anap.gettrial.Xmethod   = 'tosdu';  % Argument (Method)to xfrom in gettrial
% GRPP.anap.gettrial.Xepoch    = 'prestim';% Argument (Epoch) to xfrom in gettrial
% GRPP.anap.gettrial.Average   = 1;        % Do not average tblp, but concat
% GRPP.anap.gettrial.RefChan   = 2;        % Reference channel (for DIFF)
% GRPP.anap.gettrial.sort      = 'trial';  % sorting with SIGSORT, can be 'none|stimulus|trial

% GRPP.refgrp.grpexp          = 'normo';      % Default reference group
% GRPP.refgrp.reftrial        = 5;            % Use the .reftrial for analysis
% GRPP.refgrp.WhichContrast   = 1;            % Contrast type (for GLM)


if isnumeric(GrpExp),
  ExpNo = GrpExp;
else
  ExpNo = grp.exps(1);
end

if ~isfield(grp,'corana'),
  fprintf('MCORANA: Please update your description file\n');
  fprintf('MCORANA: You must defined GRP.corana().mdlsct (check J04yz1)'\n);
  keyboard;
end;

anap = getanap(Ses,ExpNo);
if ~isfield(anap,'shift'),  anap.shift = 0;  end


fprintf(' %s:',mfilename);


if isfield(anap,'gettrial') & anap.gettrial.status > 0,

  % TRIAL BASED
  troiTs = sigload(Ses,GrpExp,'troiTs');
  if isempty(troiTs),
    error('\nERROR %s: no troiTs, run sesgettrial() first.',mfilename);
  end
  
  if isfield(anap.gettrial,'trial2obsp') & anap.gettrial.trial2obsp > 0,
    % METHOD: using troiTs WITH trial2obsp=1
    fprintf(' TRIAL-model=');
    for M = 1:length(grp.corana),
      fprintf('%s.',grp.corana{M}.mdlsct);
      mdlsct{M} = expmkmodel(Ses,ExpNo,grp.corana{M}.mdlsct);
    end;

    fprintf(' matscor.');
    troiTs = matscor(troiTs,mdlsct,anap.shift);
    fprintf(' done.\n');
    sigsave(Ses,GrpExp,'troiTs',troiTs);

    refTs = {};
    for R = length(troiTs):-1:1,
      refTs{R} = troiTs{R};
      refTs{R}.dat = [];
    end
    clear troiTs;
  else
    % METHOD: using troiTs WITH trial2obsp=0,  grp.refgrp.reftrial
    if ~isfield(grp,'refgrp') | ~isfield(grp.refgrp,'reftrial'),
      TrialIndex = 0;
    else
      TrialIndex = grp.refgrp.reftrial;
    end
 
    if isfield(troiTs{1}{1},'sigsort'),
      PreT = troiTs{1}{1}.sigsort.PreT;  PostT = troiTs{1}{1}.sigsort.PostT;
    else
      PreT = 0;  PostT = 0;
    end
 
    fprintf(' TRIAL-model=');
    for M = 1:length(grp.corana),
      fprintf('%s.',grp.corana{M}.mdlsct);
      tmp = expmkmodel(Ses,ExpNo,grp.corana{M}.mdlsct,'PreT',PreT,'PostT',PostT);
      for T = length(tmp):-1:1,
        mdlsct{T}{M} = tmp{T};
      end
    end;
 
    fprintf(' matscor');
    if TrialIndex > 0,
      % run mcorana only for TrialIndex
      for R = 1:length(troiTs),
        fprintf('.');
        T = TrialIndex;
        tmpTs = troiTs{R}(T);
        if size(tmpTs{1}.dat,3) > 1,
          tmpTs{1}.dat = squeeze(mean(tmpTs{1}.dat,3));
        end
        tmpTs{1}.dat(find(isnan(tmpTs{1}.dat(:)))) = 0;
        tmpTs = matscor(tmpTs,mdlsct{T},anap.shift);
        troiTs{R}{T}.r   = tmpTs{1}.r;
        troiTs{R}{T}.p   = tmpTs{1}.p;
        if isfield(tmpTs{1},'mdl'),
          troiTs{R}{T}.mdl = tmpTs{1}.mdl;
        end
      end
      % SUBSTITUTE .r/.p with that of TrialIndex
      fprintf(' substitute .r/.p (reftrial=%d)...',TrialIndex);
      for R = 1:length(troiTs),
        for T = 1:length(troiTs{R}),
          if T == TrialIndex, continue;  end
          troiTs{R}{T}.r   = troiTs{R}{TrialIndex}.r;
          troiTs{R}{T}.p   = troiTs{R}{TrialIndex}.p;
          if isfield(troiTs{R}{TrialIndex},'mdl'),
            troiTs{R}{T}.mdl = troiTs{R}{TrialIndex}.mdl;
          end
        end
      end
      
    else
      % run mcorana for all trials
      for R = 1:length(troiTs),
        fprintf('.');
        for T = 1:length(troiTs{R}),
          tmpTs = troiTs{R}(T);
          if size(tmpTs{1}.dat,3) > 1,
            tmpTs{1}.dat = squeeze(mean(tmpTs{1}.dat,3));
          end
          tmpTs = matscor(tmpTs,mdlsct{T},anap.shift);
          troiTs{R}{T}.r   = tmpTs{1}.r;
          troiTs{R}{T}.p   = tmpTs{1}.p;
          if isfield(tmpTs{1},'mdl'),
            troiTs{R}{T}.mdl = tmpTs{1}.mdl;
          end
        end
      end
    end
 
    fprintf(' done.\n');

    sigsave(Ses,GrpExp,'troiTs',troiTs);
    
    if TrialIndex == 0,
      TrialIndex = 1;
      if length(troiTs{R}) > 1,
        fprintf(' TrialIndex=%d for roiTs',TrialIndex);
      end
    end
    refTs = {};
    for R = length(troiTs):-1:1,
      refTs{R} = troiTs{R}{TrialIndex};
      refTs{R}.dat = [];
    end
    clear troiTs;
  end
 
  % update roiTs
  roiTs = sigload(Ses,GrpExp,'roiTs');
  for N=1:length(roiTs),
    if isfield(roiTs{N},'mdl'),
      roiTs{N} = rmfield(roiTs{N},'mdl');
    end
    roiTs{N}.r = refTs{N}.r;
    roiTs{N}.p = refTs{N}.p;
  end;

else
  fprintf(' OBSP-model=');

  neumdl = [];
  for M=1:length(grp.corana)
    fprintf('%s.',grp.corana{M}.mdlsct);
    mdlsct{M} = expmkmodel(Ses,ExpNo,grp.corana{M}.mdlsct);
    neumdl(M) = ~any(strcmpi({'hemo','boxcar','fhemo','ir'},grp.corana{M}.mdlsct));
  end;

  roiTs = sigload(Ses,GrpExp,'roiTs');
  if isstim(Ses,grp.name) | any(neumdl),
    fprintf(' matscor...');
    roiTs = matscor(roiTs,mdlsct);
  else
    fprintf(' cleaning ./.p...');
    for R = 1:length(roiTs),
      roiTs{R}.r = {};  roiTs{R}.p = {};
      roiTs{R}.r{1} = zeros(size(roiTs{R}.dat,2),1);
      roiTs{R}.p{1} = ones(size(roiTs{R}.dat,2),1);
    end
  end
  fprintf(' done.\n');
end;
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OLD CODE
% The following code was trying to check whether we want to apply correlation analysis or
% simply copy the selected voxel numbers of a reference group into the current roiTs.
% Please do not delete. We'll keep all options open, until we definitely decide what the
% best process is for the kind of analysis we do on the data.
% The same is true for the subCopyStat function below!!
% We may turn this to an independent code for usage in the future (if experiments really
% require copying the reference map).
% NKL 08.01.06
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% RUN_matscor = 1;
% if isfield(grp,'refgrp') & ~isempty(grp.refgrp),
%   grpexp = grp.refgrp.grpexp;
%   if ischar(grpexp)
%     % grpexp IS THE GROUP NAME OF THE GROUP ITSELF (grp.name)
%     if ~strcmpi(grpexp,grp.name),
%       RUN_matscor = 0;
%     end
%   else
%     % grpexp IS AN EXPERIMENT NUMBER BELONGING TO THE GROUP ITSELF (grp.name)
%     grp2 = getgrp(Ses,grpexp),
%     if ~strcmpi(grp.name,grp2.name),
%       RUN_matscor = 0;
%     end
%     clear grp2;
%   end
% end
%
% if RUN_matscor > 0,
%   roiTs = subRunMATSCOR(Ses,GrpExp);    
% else
%   roiTs = subRunMATSCOR(Ses,GrpExp);
% end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNTION to copy results of other ExpNo/Grp correlation analysis
function roiTs = subCopyStat(SesName,GrpExp)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Ses = goto(SesName);
grp = getgrp(Ses,GrpExp);


% LOAD REFERENCE .r/.p DATA
grp2 = getgrp(Ses,grp.refgrp.grpexp);
anap = getanap(Ses,grp2);
if anap.gettrial.status,
  % TRIAL BASED
  refTs = sigload(Ses, grp.refgrp.grpexp, 'troiTs');
  TrialIndex = anap.gettrial.reftrial;
  for N = 1:length(refTs),
    refTs{N} = refTs{N}{TrialIndex};
  end
else
  refTs = sigload(Ses, grp.refgrp.grpexp, 'roiTs');
end
% don't need .dat, free large data.
for N = 1:length(refTs),  refTs{N}.dat = [];  end

%% NOW UPDATE troiTs AND roiTS 
anap = getanap(Ses,GrpExp);

% update troiTs, if needed
if anap.gettrial.status,
  troiTs = sigload(Ses,GrpExp,'troiTs');
  for N = 1:length(troiTs),
    for T = 1:length(troiTs{N}),
      troiTs{N}{T}.r = refTs{N}.r;
      troiTs{N}{T}.p = refTs{N}.p;
    end
  end
  sigsave(Ses,GrpExp,'troiTs',troiTs);
  clear troiTs;
end

% update roiTs
roiTs = sigload(Ses, GrpExp, 'roiTs');
for N=1:length(roiTs),
  roiTs{N}.r = refTs{N}.r;
  roiTs{N}.p = refTs{N}.p;
end;
return;
