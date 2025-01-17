function [ExpEvt, DG] = expgetevt(Ses, ExpNo)
%EXPGETEVT - Uses adf_info/dg_read to get all events of experiment ExpNo
% EXPEVT = EXPGETEVT(SES,EXPNO) gets recorded events for SES/EXPNO.
% EXPEVT = EXPGETEVT(DGZFILE)
% NKL, 4.10.02
%
% NOTES : 03.02.04  YM
%  evt.interVolumeTime is given by DGZ and it may not be corrent some cases.
%  Use GETPVPARS to get a correct value from IMND/RECO/ACQP.
%  For awake MRI, jawpo is normally collected in dgz, but if needed,
%  can be load from adfw, setting GRPP.jawpo = {'adfw',[4 5]};  % chan4/5 as jaw/pow.
%
% VERSION : 1.00 04.10.02 NKL
%           1.01 03.02.04 YM  use getpvpars() for imgtr. --> obsolete.
%           1.02 13.02.04 YM  improved speed x4 (2.5s-->0.6s for L00au2).
%           1.03 08.10.04 YM  supports "Ses" as dgzfile.
%           1.04 01.03.06 YM  warns if obsp differs between dgz/adf.
%           1.05 09.07.06 YM  adds new events.
%           1.06 06.10.06 YM  supports eye/jawpo for awake MRI.
%           1.07 13.03.07 YM  supports 'MriFixate'.
%
% See also EXPGETPAR, GOTO, GETSES, CATFILENAME, GETGRP, GETEVTCODES
%          ADF_INFO, DG_READ, SELECTEVT, SELECTPRM, GETCLN

if nargin == 0,  eval(sprintf('help %s',mfilename));  return;  end

if nargin < 2,	ExpNo = 1; end;

if ischar(Ses) && ~isempty(strfind(Ses,'.dgz')),
  % "Ses" as dgzfilename
  evtfile = Ses;
  grp.daqver = 2;
  if exist(strrep(evtfile,'.dgz','.adfw'),'file'),
    physfile = strrep(evtfile,'.dgz','.adfw');
    grp.expinfo = {'recording'};
  elseif exist(strrep(evtfile,'.dgz','.adf'),'file'),
    physfile = strrep(evtfile,'.dgz','.adf');
    grp.expinfo = {'recording'};
  else
    physfile = '';
  end
  Ses.acqp 	= getacqp;
else
  % "Ses" as a session name/structure
  Ses = goto(Ses);
  evtfile  = catfilename(Ses,ExpNo,'dgz');
  physfile = catfilename(Ses,ExpNo,'phys');
  grp = getgrp(Ses,ExpNo);
end

ec = Ses.acqp.evt;


% DGZ does't exist.
if ~exist(evtfile,'file'),  ExpEvt = {};  return;  end

if ~isempty(physfile) & ~exist(physfile,'file'), physfile = '';   end


% read dgz, event codes
DG = dg_read(evtfile);

if isrecording(grp),
  [NoChan, NoObsp, SampTime, AdfLen] = adf_info(physfile);
  AdfLen = AdfLen * SampTime;  % in msec
else
  NoChan = 0;
  NoObsp = length(DG.e_types);
  SampTime = 0;
  AdfLen = zeros(1,NoObsp);
end;


% CHECK THIS ONE.... 08.09.03 NKL !!!!!!!!!!!!!!!!
if NoObsp ~= length(DG.e_types),
  fprintf('WARNING expgetevt: NoObsp differs, dgz=%d, adf=%d\n',...
          length(DG.e_types),NoObsp);
  NoObsp = length(DG.e_types);
end

if ~any(DG.e_types{NoObsp}==46) & strfind(Ses.name,'ymfs') < 0,
  NoObsp = NoObsp - 1;
end;

% CHECK THIS ONE.... 08.09.03 NKL !!!!!!!!!!!!!!!!
% &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
if NoObsp ~= 1,
  %fprintf('WARNING expgetevt: multiple obsp detected. obsp=%d\n',NoObsp);
  %keyboard
  %NoObsp = 1;
end


% &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

tmpidx = find(DG.e_types{1} == ec.ObspType);
if isempty(tmpidx),
  mriTrigger  = 0;
else
  mriTrigger = DG.e_subtypes{1}(tmpidx(1));
end
NumTriggers = selectprm(DG, 1, ec.ObspType, 1);
if isempty(NumTriggers) | NumTriggers <= 0,
  NumTriggers = 1;  % just to prevent 'divideByZero'.
end

etime   = cell(1,NoObsp);
etimeE  = cell(1,NoObsp);
eparams = cell(1,NoObsp);
for N = NoObsp:-1:1,
  etime{N}.begin  = selectevt(DG, N, ec.BeginObsp,  ec.sub.all);
  etime{N}.end	  = selectevt(DG, N, ec.EndObsp,    ec.sub.all);
  etime{N}.isi    = selectevt(DG, N, ec.Isi,		ec.sub.all);
  etime{N}.ttype  = selectevt(DG, N, ec.TrialType,	ec.sub.all);
  etime{N}.otype  = selectevt(DG, N, ec.ObspType,	ec.sub.all);
  etime{N}.fs	  = selectevt(DG, N, ec.Fixspot,	ec.sub.all);
  if strncmpi(DG.e_pre{1}{2},'MriFixate',9) | strncmpi(DG.e_pre{1}{2},'MriPsycho',9),
    etime{N}.stm    = selectevt(DG, N, ec.Stimulus,   ec.sub.NKLStimulusOn);
  else
    etime{N}.stm    = selectevt(DG, N, ec.Stimulus,   ec.sub.all);
  end
  etime{N}.stype  = selectevt(DG, N, ec.Stimtype,   ec.sub.all);
  etime{N}.cue    = selectevt(DG, N, ec.Cue,		ec.sub.all);
  etime{N}.tar    = selectevt(DG, N, ec.Target,	    ec.sub.all);
  etime{N}.distr  = selectevt(DG, N, ec.Distractor, ec.sub.all);
  etime{N}.sound  = selectevt(DG, N, ec.Sound,		ec.sub.all);
  etime{N}.fix	  = selectevt(DG, N, ec.Fixate,	    ec.sub.all);
  etime{N}.resp	  = selectevt(DG, N, ec.Response,	ec.sub.all);
  etime{N}.eot	  = selectevt(DG, N, ec.EndTrial,	ec.sub.all);
  etime{N}.eotcor = selectevt(DG, N, ec.EndTrial,	ec.sub.EndTrialCorrect);
  etime{N}.abort  = selectevt(DG, N, ec.Abort,		ec.sub.all);
  etime{N}.rwd	  = selectevt(DG, N, ec.Reward,	    ec.sub.all);
  etime{N}.dly	  = selectevt(DG, N, ec.Delay,		ec.sub.all);
  etime{N}.pnsh	  = selectevt(DG, N, ec.Punish,	    ec.sub.all);
  etime{N}.mri    = selectevt(DG, N, ec.Mri,	    ec.sub.MriTrigger);
  etime{N}.paton  = selectevt(DG, N, ec.Pattern,    ec.sub.PatternOn);
  etime{N}.patset = selectevt(DG, N, ec.Pattern,    ec.sub.PatternSet);
  etime{N}.patoff = selectevt(DG, N, ec.Pattern,    ec.sub.PatternOff);
  % new events, Jul.06
  etime{N}.injection     = selectevt(DG, N, ec.Injection,     ec.sub.all);
  etime{N}.posture       = selectevt(DG, N, ec.Posture,       ec.sub.all);
  etime{N}.bmparams      = selectevt(DG, N, ec.BmParams,      ec.sub.all);
  etime{N}.vdaqStimReady = selectevt(DG, N, ec.VdaqStimReady, ec.sub.all);
  etime{N}.vdaqStimTrig  = selectevt(DG, N, ec.VdaqStimTrig,  ec.sub.all);
  etime{N}.vdaqGo        = selectevt(DG, N, ec.VdaqGo,        ec.sub.all);
  etime{N}.vdaqFrame     = selectevt(DG, N, ec.VdaqFrame,     ec.sub.all);
  etime{N}.revcorrInfo   = selectevt(DG, N, ec.RevcorrInfo,   ec.sub.all);
  etime{N}.revcorrUpdate = selectevt(DG, N, ec.RevcorrUpdate, ec.sub.all);
  
  % Apr/May-03, for new ess system: MriGeneric.c
  eparams{N}.prm     = selectprm(DG, N, ec.Floats_1);
  eparams{N}.stmid = [];
  eparams{N}.trialid = selectprm(DG, N, ec.TrialType, 1);
  if strncmpi(DG.e_pre{1}{2},'MriFixate',9) | strncmpi(DG.e_pre{1}{2},'MriPsycho',9),
    eparams{N}.stmid   = selectprm(DG, N, ec.Stimulus,  3, ec.sub.NKLStimulusOn);
    eparams{N}.stmdur  = selectprm(DG, N, ec.Stimulus,  1, ec.sub.NKLStimulusOn);
  else
    eparams{N}.stmid   = selectprm(DG, N, ec.Stimtype,  1);
    eparams{N}.stmdur  = selectprm(DG, N, ec.Stimulus,  1);
  end
  
  % new parameters, Jul.06
  eparams{N}.injection     = selectprm(DG, N, ec.Injection,     ec.sub.all);
  eparams{N}.posture       = selectprm(DG, N, ec.Posture,       ec.sub.all);
  eparams{N}.bmparams      = selectprm(DG, N, ec.BmParams,      ec.sub.all);
  eparams{N}.vdaqStimReady = selectprm(DG, N, ec.VdaqStimReady, ec.sub.all);
  eparams{N}.vdaqStimTrig  = selectprm(DG, N, ec.VdaqStimTrig,  ec.sub.all);
  eparams{N}.vdaqGo        = selectprm(DG, N, ec.VdaqGo,        ec.sub.all);
  eparams{N}.vdaqFrame     = selectprm(DG, N, ec.VdaqFrame,     ec.sub.all);
  eparams{N}.revcorrInfo   = selectprm(DG, N, ec.RevcorrInfo,   ec.sub.all);
  eparams{N}.revcorrUpdate = selectprm(DG, N, ec.RevcorrUpdate, ec.sub.all);
  eparams{N}.screenInfo    = selectprm(DG, N, ec.ScreenInfo,    ec.sub.all);

  % for awake MRI
  eparams{N}.emscale = selectprm(DG, N, ec.EmParams,    ec.sub.EmScale);

  % === POTENTIAL BUG FIX : begin =====================================
  % 30.05.03 YM
  % fix bugs, some float value may have a small offset like
  % 1.2e-8 maybe,due to float->double conversion.
  for k = 1:length(eparams{N}.prm),
    eparams{N}.prm{k} = round(eparams{N}.prm{k}*10000.)/10000.;
  end
  % floor() is used because in early event files,
  %stmdur(1) is added by 1 to wait dummies.
  eparams{N}.stmdur  = floor(eparams{N}.stmdur  / NumTriggers);
  % === POTENTIAL BUG FIX : end =======================================


  % 22.05.03 NOTE!!!!!!!!
  % WE MUST SUBTRACT THE FIRST MRI EVENT FROM THE REST OF THE STUFF.
  if N == 1,
    if isempty(etime{N}.mri)
      % not mri-related experiment
      t0 = 0;
    else
      % now we are analyzing mri-related experiment.
      if mriTrigger == 0,
        % no imaging, recording only.
        t0 = 0;
      else
        % imaging + recording.
        t0 = etime{N}.mri(1);
      end
    end
    fnames = fieldnames(etime{N});
    for k=1:length(fnames),
      cmdstr = sprintf('etimeE{N}.%s = subSubtractMRI1E(etime{N}.%s,t0);',...
                     fnames{k},fnames{k});
      eval(cmdstr);
    end
    etimeE{N}.mri1E = t0;
  else
    % no need to subtract mri1E for Obsp > 1.
    etimeE{N} = etime{N};
    etimeE{N}.mri1E = 0;
  end
  
  % 28.05.03
  % status of ess_endObs().
  estatus(N) = DG.e_subtypes{N}(end);
end;


% get event types, names
etypes = [];
for N = 1:NoObsp,
  etypes = [etypes, unique(DG.e_types{N}(:)')];
end
etypes = sort(unique(etypes));
enames = cellstr(DG.e_names(etypes+1,:));


% make 'evt' structure %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ExpEvt.system   = DG.e_pre{1}{2};  % name of the state system
ExpEvt.systempar = subGetSystemPar(DG);
ExpEvt.dgzfile	= evtfile;
ExpEvt.physfile	= physfile;;
ExpEvt.nch		= NoChan;
ExpEvt.nobsp	= NoObsp;
ExpEvt.dx		= SampTime/1000;
ExpEvt.trigger  = mriTrigger;
ExpEvt.dg		= DG;
% event types/names
ExpEvt.evttypes	= etypes;
ExpEvt.evtnames	= enames;

% 26-Apr-03, for the new ess system: MriGeneric.c
tmpnames     = selectprm(DG, 1, ec.Strings_1, 0);
ExpEvt.prmnames = {};
if length(tmpnames) > 0,
  % convert char-array to cell-array
  for k=1:size(tmpnames{1},1),
	ExpEvt.prmnames{k} = deblank(tmpnames{1}(k,:));
  end
end
tmpv = selectprm(DG, 1, ec.Stimulus,2, 2);

if isempty(tmpv),
  ExpEvt.interVolumeTime = 0;
  ExpEvt.numTriggersPerVolume = NumTriggers;
else
  ExpEvt.interVolumeTime = tmpv(1);  % in msec
  ExpEvt.numTriggersPerVolume = NumTriggers;
end


% get obslen from event file, if not available
if length(AdfLen) < NoObsp,
  fprintf('WARNING %s: obslen-dgz=%d, obslen-adf=%d ',mfilename,NoObsp,length(AdfLen));
  for N = length(AdfLen)+1:NoObsp,  AdfLen(N) = etimeE{N}.end;  end
end


for N = 1:NoObsp,
  % times used for analysis, backward compatibility
  ExpEvt.obs{N}.adflen		= AdfLen(N);
  ExpEvt.obs{N}.beginE		= etimeE{N}.begin;
  ExpEvt.obs{N}.endE		= etimeE{N}.end;
  ExpEvt.obs{N}.mri1E		= etimeE{N}.mri1E;
  ExpEvt.obs{N}.trialE		= etimeE{N}.ttype;
  ExpEvt.obs{N}.fixE		= etimeE{N}.fix;
  ExpEvt.obs{N}.t			= etimeE{N}.stm;
  % values used for analysis
  ExpEvt.obs{N}.v			= eparams{N}.stmid(:)';
  ExpEvt.obs{N}.trialID		= eparams{N}.trialid;
  ExpEvt.obs{N}.trialCorrect = subGetCorrectTrials(etimeE{N},eparams{N});
  
  % keep times/parameters
  ExpEvt.obs{N}.times		= etimeE{N};
  ExpEvt.obs{N}.params		= eparams{N};
  ExpEvt.obs{N}.origtimes	= etime{N};

  % Apr/May-03, for the new ess system: MriGeneric.c
  if grp.daqver > 2,
    tmpttype = [etime{N}.ttype', etime{N}.end];
    tmptstim = etime{N}.stm;
    for k=length(etime{N}.ttype):-1:1,
      tmpsel = find(tmptstim >= tmpttype(k) & tmptstim < tmpttype(k+1))
      ExpEvt.obs{N}.conditions{k} = eparams{N}.stmid(tmpsel)';
    end
  end
  
  % 06.Oct.06
  [em jawpo] = subGetEyeJawPo(Ses,ExpNo,N,etimeE{N}.mri1E,...
                                DG.ems{N},eparams{N}.emscale);
  ExpEvt.obs{N}.eye    = em;
  ExpEvt.obs{N}.jawpo = jawpo;
  clear em jawpo;
  
  
  % status of ess_endObs()
  ExpEvt.obs{N}.status = estatus(N);
  
end;


return


% subfunction %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function otimes = subSubtractMRI1E(itimes,t0)
otimes = itimes - t0;
otimes(find(otimes < 0)) = 0;

return;



% subfunction %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function trialCorrect = subGetCorrectTrials(etimes,eparams)

t_ttype  = etimes.ttype;
t_eotcor = etimes.eotcor;
t_abort  = etimes.abort;

  
trialCorrect = zeros(size(t_ttype));

% to avoid checking error
t_ttype(end+1) = etimes.end;
for N = 1:length(trialCorrect)-1,
  iscorrect = any(t_eotcor > t_ttype(N) & t_eotcor <= t_ttype(N+1));
  % double check, should not abort
  if iscorrect == 1,
    iscorrect = ~any(t_abort >= t_ttype(N) & t_abort <= t_ttype(N+1));
  end
  trialCorrect(N) = iscorrect;
end

return;





% subfunciton to get jaw-pow signals %%%%%%%%%%%%%%%%%%%%%%%
function [em jawpo] = subGetEyeJawPo(Ses,ExpNo,ObspNo,mri1E,ems,emscale)
jawpo = [];  em = [];
grp = getgrp(Ses,ExpNo);
if ~isawake(grp),  return;  end


% EYE MOVEMENT
em.dx = ems{1}(1);
em.dat(:,1) = ems{2}(:) / emscale{1}(1);  % horizontal, in deg
em.dat(:,2) = ems{3}(:) / emscale{1}(2);  % vertial, in deg
if ObspNo == 1,
  em.dat = em.dat(max([1 round(mri1E(1)/ems{1}(1))]):end,:);
end
%em.dat = int16(round(em.dat));
em.tag = {'horizontal', 'vertical'};
em.emscale = emscale{1}(:)';  % ADC/degree


% JAW-POW
if isfield(grp,'jawpo') & ~isempty(grp.jawpo),
  SRC = grp.jawpo{1};
  CHN = grp.jawpo{2};
  if strcmpi(SRC,'adfw'),
    jawpo.dx = 0.01;  % 100Hz
    jawpo.dat = [];
    adffile = catfilename(Ses,ExpNo,'adfw');
    [tmpwv npts sampt] = adf_read(adffile,ObspNo-1,CHN(1)-1);
    jawpo.dat(:,1) = tmpwv(:);
    [tmpwv npts sampt] = adf_read(adffile,ObspNo-1,CHN(2)-1);
    jawpo.dat(:,2) = tmpwv(:);
    clear tmpwv;
    if ObspNo == 1,
      jawpo.dat = jawpo.dat(max([1 round(mri1E(1)/sampt)]):end,:);
    end
    % downsample
    [p,q] = rat(sampt/1000/jawpo.dx,0.0001);  % sampt as msec
    jawpo.dat = resample(jawpo.dat,p,q);
  elseif strcmpi(SRC,'dgz'),
    jawpo.dx = ems{4}(1)/1000;  % in sec
    jawpo.dat(:,1) = ems{5}(:);
    jawpo.dat(:,2) = ems{8}(:);
    if ObspNo == 1,
      jawpo.dat = jawpo.dat(round(mri1E(1)/ems{4}(1)):end,:);
    end
  end
  jawpo.dat = int16(round(jawpo.dat));
  jawpo.tag = {'jaw','pow'};
end



return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function PAR = subGetSystemPar(DG)

PAR.esssystem = DG.e_pre{1}{2};
PAR.subject  = DG.e_pre{2}{2};

for N = 3:2:length(DG.e_pre),
  if isempty(DG.e_pre{N}{2}),  continue;  end
  switch lower(DG.e_pre{N}{2}),
   case {'# of scan volumes'}
    PAR.numScanVolumes = str2num(DG.e_pre{N+1}{2});
   case {'inter-trial time (ms)'}
    PAR.interTrialTime = str2num(DG.e_pre{N+1}{2});
   case {'mov no-motion Time'}
    PAR.noMotionTime = str2num(DG.e_pre{N+1}{2});
   case {'f delay'}
    PAR.fixDelay     = str2num(DG.e_pre{N+1}{2});
   case {'f delay max'}
    PAR.fixDelayMax  = str2num(DG.e_pre{N+1}{2});
   case {'f acquire time'}
    PAR.fixAcquireTime = str2num(DG.e_pre{N+1}{2});
   case {'s pre-stim. time'}
    PAR.preStimTime = str2num(DG.e_pre{N+1}{2});
   case {'s post-stim. time'}
    PAR.postStimTime = str2num(DG.e_pre{N+1}{2});
   case {'f fixation radius'}
    PAR.fixRadius = str2num(DG.e_pre{N+1}{2});
  end
end


return
