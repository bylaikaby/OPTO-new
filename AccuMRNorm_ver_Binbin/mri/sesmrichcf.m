function sesmrichcf(SESSION,arg2)
%SESMRICHCF - Compute interelectrode coherence
% SESMRICHCF - Computes coherence for different inter-voxel
% distances. Voxels are selected only once. A good scan is taken as
% reference and its zscore-map is used to select the time series of
% all groups. To run sesmrichch you first must:
%
%	1. Load the images (sesimgload)
%	2. Run sesmoviettest(Ses) and browse for the reference
%	   This will create the ZSTS structure
%	3. Run sesmoviegettc(Ses,EXPS,RefExpNo) (last arg reference scan)
%	   This will create the REFZSTS structure
%	4. Run sesmrichcf
%	   This will create the MRICH and MRICF structures
%	5. Use grpcohere('m02lx1','movie1','mrich') to group coherence
%	6. Use grpconfunc('m02lx1','movie1','mricf') to group confunc
%	See also
%
%	SIGCOHERE EXPCOHERE

LOG=0;
if nargin == 0,
  error('usage: sesmrichcf(SESSION, ExpNo/GrpName');
end

Ses = goto(SESSION);

if exist('arg2','var'),
  if ~isa(arg2,'char'),
	error('sesmrichcf: second argument must be a group name');
  else
	Groups{1} = arg2;
  end;
else
  Groups = {};
  for N=1:length(Ses.ImgGrps),
    Groups = cat(1,Groups,Ses.ImgGrps{N}{2});
  end;
end;

if LOG,
  LogFile=strcat('CHCF_',Ses.name,'.log');		% Start log file
  diary off;									% Close previous ones...
  hbackup(LogFile);								% Make a backup for history
  diary(LogFile);								% Start the new one
end;

fprintf('sesmrichcf: coherence/confunc for session %s\n',Ses.name);

if ~isfield(Ses,'confunc'),
  fprintf('sesmrichcf: Ses.confunc is not defined\n');
  keyboard;
end;

cf = Ses.confunc;

ARGS.SESINFO = Ses;
ARGS.WINDOWSEC = 10;        % For coherence-computation

for GrpNo = 1:length(Groups),
  GrpName = Groups{GrpNo};
  grp = getgrpbyname(Ses,GrpName);

  for ExpNo = grp.exps,
    grp = getgrp(Ses,ExpNo);
    ARGS.EPOCH=0;
    if isfield(grp,'epoch'),
      ARGS.EPOCH=grp.epoch;
    end;

    if ~isrecording(Ses,grp.name),
      Sig = sesgetsig(Ses,ExpNo,'Pts');
    else
      Sig = sesgetsig(Ses,ExpNo,'xcor');
    end;
    
    NoSlice = length(Sig);
    fprintf('Computing coherence ...');
    for N=1:NoSlice,
      mrich{N} = sigcohere(Sig{N}, ARGS);
    end;
    fprintf(' and kernel covariance\n');
    for N=1:NoSlice,
      mricf{N} = sigconfunc(Sig{N}, 'kc', ARGS.EPOCH, cf);
    end;
    
    filename = catfilename(Ses,ExpNo);
    save(filename,'-append','mrich','mricf');
    fprintf('mgrpchcf: Appended mrich, mricf in %s\n', filename);
  end;
end;

if LOG,
  diary off;
end;



