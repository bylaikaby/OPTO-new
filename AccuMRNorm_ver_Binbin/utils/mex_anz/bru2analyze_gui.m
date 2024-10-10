function varargout = bru2analyze_gui(varargin)
%BRU2ANALYZE_GUI - GUI for converting Bruker 2dseq as ANALYZE-7.5 format.
%  BRU2ANALYZE_GUI run a GUI for converting Bruker 2dseq as ANALYZE-7.5 format.
%
%  EXAMPLE :
%    bru2analyze_gui
%
%  VERSION :
%    0.90 17.02.14 YM  pre-release
%    0.91 18.02.14 YM  supports showing Bruker parameters.
%    0.92 26.05.15 YM  supports .nii (NIfTI-1) format.
%    0.93 28.05.15 YM  GUI update.
%    0.94 17.04.18 YM  Update of the default data directory.
%
%  See also bru2analyze anz_view pvread_acqp pvread_method pvread_imnd pvread_reco

persistent H_BRU2ANALYZE;  % keep the figure handle
  

% execute callback function then return -----------------------------------
if nargin > 0 && ischar(varargin{1}) && ~isempty(findstr(varargin{1},'Callback')),
  if nargout
    [varargout{1:nargout}] = feval(varargin{:});
  else
    feval(varargin{:});
  end
  return;
end


% prevent double execution -----------------------------------------------
if ishandle(H_BRU2ANALYZE),
  close(H_BRU2ANALYZE);
  %fprintf('\n ''mgui'' already opened.\n');
  %return;
end


% DEFAULT CONTROL SETTINGS ===============================================
DEF.datadir  = '//wks8/mridata_wks6';
DEF.study    = 'J10.mo1';
DEF.scan     = '9';
DEF.reco     = '1';
DEF.savedir  = 'D:/Temp';
DEF.imgcrop  = '';
DEF.slicrop  = '';
DEF.permute  = '';
DEF.flipdim  = '';
DEF.export2d = 0;
DEF.taverage = 0;
DEF.tsplit   = 0;
DEF.nifti1   = 0;


% GET SCREEN SIZE ========================================================
[scrW scrH] = subGetScreenSize('char');

%figW = 60.5; figH = 19;
figW = 72.5; figH = 19;
figX = 1;  figY = scrH-figH-6;

%[figX figY figW figH]
% CREATE A MAIN FIGURE ===================================================
hMain = figure(...
    'Name',mfilename,...
    'NumberTitle','off', 'toolbar','none','MenuBar','none',...
    'Tag','main', 'units','char', 'pos',[figX figY figW figH],...
    'HandleVisibility','on', 'Resize','on',...
    'DoubleBuffer','on', 'BackingStore','on', 'Visible','on',...
    'DefaultAxesFontSize',10,...
    'DefaultAxesfontweight','bold',...
    'PaperPositionMode','auto', 'PaperType','A4', 'PaperOrientation', 'landscape');


% WIDGETS ================================================================
XDSP = 1.5; H = figH - 2.5;
% Data Dir
uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[XDSP H 12.5 1.5],...
    'Callback','bru2analyze_gui(''Main_Callback'',gcbo,''browse-datadir'',guidata(gcbo))',...
    'String','Data :','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','DataDirBtn',...
    'TooltipString','Browse Bruker Data Directory',...
    'BackgroundColor',[0.5 0.8 0.8],'ForegroundColor',[0 0 0]);
uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+14 H 55 1.5],...
    'String',DEF.datadir,'Tag','DataDirEdt',...
    'HorizontalAlignment','left',...
    'TooltipString','Set Data Directory',...
    'FontWeight','Bold','FontName','FixedWidth');

XDSP = 1.5; H = figH - 4.5;
% Study
uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[XDSP H 12.5 1.5],...
    'Callback','bru2analyze_gui(''Main_Callback'',gcbo,''browse-study'',guidata(gcbo))',...
    'String','Study :','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','StudyBtn',...
    'TooltipString','Browse Bruker Study',...
    'BackgroundColor',[0.5 0.8 0.8],'ForegroundColor',[0 0 0]);
uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+14 H 55 1.5],...
    'String',DEF.study,'Tag','StudyEdt',...
    'HorizontalAlignment','left',...
    'TooltipString','Set Study',...
    'FontWeight','Bold','FontName','FixedWidth');

XDSP = 1.5;  H = figH - 6.5;
% Scan/Reco number
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+2 H-0.2 30 1.5],...
    'String','Scan # :','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','ScanNumTxt',...
    'BackgroundColor',get(hMain,'Color'));
uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+14 H 12 1.5],...
    'String',DEF.scan,'Tag','ScanNumEdt',...
    'HorizontalAlignment','left',...
    'TooltipString','Set scan number',...
    'FontWeight','Bold','FontName','FixedWidth');
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+30 H-0.2 30 1.5],...
    'String','Reco # :','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','RecoNumTxt',...
    'BackgroundColor',get(hMain,'Color'));
uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+40 H 12 1.5],...
    'String',DEF.reco,'Tag','RecoNumEdt',...
    'HorizontalAlignment','left',...
    'TooltipString','Set reco number',...
    'FontWeight','Bold','FontName','FixedWidth');
% PvPar button
uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[XDSP+57 H 12 1.5],...
    'Callback','bru2analyze_gui(''Main_Callback'',gcbo,''pvpar'',guidata(gcbo))',...
    'Tag','PvParBtn','String','PvPar',...
    'TooltipString','Read/Show ParaVision Parameters','FontWeight','bold',...
    'BackgroundColor',[0.5 0.8 0.5],'ForegroundColor',[0 0 0]);


XDSP = 1.5;  H = figH - 8.5;
% Save directory
uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[XDSP H 12.5 1.5],...
    'Callback','bru2analyze_gui(''Main_Callback'',gcbo,''browse-savedir'',guidata(gcbo))',...
    'String','Save :','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','SaveDirBtn',...
    'TooltipString','Browse Directory to Save',...
    'BackgroundColor',[0.5 0.8 0.8],'ForegroundColor',[0 0 0]);
uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+14 H 55 1.5],...
    'String',DEF.savedir,'Tag','SaveDirEdt',...
    'HorizontalAlignment','left',...
    'TooltipString','Set directory to save',...
    'FontWeight','Bold','FontName','FixedWidth');


XDSP = 1.5;  H = figH - 10.5;
% permute
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+6 H-0.3 30 1.5],...
    'String','permute :','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','PermuteTxt',...
    'TooltipString','Order to Permute Dimensions',...
    'BackgroundColor',get(hMain,'Color'));
uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+18 H 18 1.5],...
    'String',DEF.permute,'Tag','PermuteEdt',...
    'HorizontalAlignment','left',...
    'TooltipString','Order to Permute Dimensions',...
    'FontWeight','Bold','FontName','FixedWidth');
% flipdim
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+41 H-0.3 30 1.5],...
    'String','flipdim :','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','FlipdimTxt',...
    'TooltipString','Dimension to Flip',...
    'BackgroundColor',get(hMain,'Color'));
uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+51 H 18 1.5],...
    'String',DEF.flipdim,'Tag','FlipdimEdt',...
    'HorizontalAlignment','left',...
    'TooltipString','Dimension to Flip',...
    'FontWeight','Bold','FontName','FixedWidth');


XDSP = 1.5;  H = figH - 12.5;
% t-average
uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+6 H 30 1.5],...
    'Tag','TimeAverageCheck','Value',DEF.taverage,...
    'String','Time Average','FontWeight','bold',...
    'TooltipString','TimeAverage on/off, only for EPI','BackgroundColor',get(hMain,'Color'));
% t-split
uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+30 H 30 1.5],...
    'Tag','TimeSplitCheck','Value',DEF.tsplit,...
    'String','4D to multi-3Ds','FontWeight','bold',...
    'TooltipString','TimeSplit on/off, only for EPI','BackgroundColor',get(hMain,'Color'));


XDSP = 1.5;  H = figH - 14.5;
% export as 2D
uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+6 H 30 1.5],...
    'Tag','ExportAs2DCheck','Value',DEF.export2d,...
    'String','Export As 2D','FontWeight','bold',...
    'TooltipString','ExportAs2D on/off','BackgroundColor',get(hMain,'Color'));

FormatCmb = uicontrol(...
    'Parent',hMain,'Style','Popupmenu',...
    'Units','char','Position',[XDSP+30 H 32 1.5],...
    'String',{'ANALYZE-7.5','NIfTI-1.nii: qform=2,d=1','NIfTI-1.nii: spm', 'NIfTI-1.nii: No XFORM'},...
    'Value',1,...
    'Tag','FormatCmb',...
    'HorizontalAlignment','left',...
    'TooltipString','Select the exporting format.',...
    'FontWeight','Bold');




XDSP = 1.5;  H = 0.5;
% RUN button
uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[XDSP H 69 1.5],...
    'Callback','bru2analyze_gui(''Main_Callback'',gcbo,''run'',guidata(gcbo))',...
    'Tag','RunBtn','String','Convert 2dseq',...
    'TooltipString','Convert to ANALYZE-7.5 or NIfTI-1','FontWeight','bold',...
    'BackgroundColor',[0.8 0.8 0],'ForegroundColor',[0 0 1.0]);



% get widgets handles at this moment
HANDLES = findobj(hMain);
Main_Callback(hMain,'init',[]);


% NOW SET "UNITS" OF ALL WIDGETS AS "NORMALIZED".
HANDLES = HANDLES(HANDLES ~= hMain);
set(HANDLES,'units','normalized');

H_BRU2ANALYZE = hMain;

if nargout,
  varargout{1} = hMain;
end
  




return


% ========================================================================
function Main_Callback(hObject,eventdata,handles)
% ========================================================================
wgts = guihandles(hObject);
APPDATA = getappdata(wgts.main,'APPDATA');

%eventdata

switch lower(eventdata),
 case {'init'}
  
 case {'browse-datadir'}
  curdir = get(wgts.DataDirEdt,'String');
  if ~exist(curdir,'dir'),
    curdir = pwd;
  end
  folder_name = uigetdir(curdir,'Select Bruker Data Directory');
  if isequal(folder_name,0)
    % cancel
  else
    set(wgts.DataDirEdt,'String',folder_name);
  end
  
  
 case {'browse-study'}
  datadir = get(wgts.DataDirEdt,'String');
  study   = get(wgts.StudyEdt,'String');
  curdir  = fullfile(datadir,study);
  if ~exist(curdir,'dir'),
    if exist(datadir,'dir')
      curdir = datadir;
    else
      curdir = pwd;
    end
  end
  folder_name = uigetdir(curdir,'Select Bruker Study');
  if isequal(folder_name,0)
    % cancel
  else
    [fp,fr,fe] = fileparts(folder_name);
    set(wgts.DataDirEdt,'String',fp);
    set(wgts.StudyEdt,'String',sprintf('%s%s',fr,fe));
  end

 case {'browse-savedir'}
  curdir = get(wgts.SaveDirEdt,'String');
  if ~exist(curdir,'dir')
    curdir = pwd;
  end
  folder_name = uigetdir(curdir,'Select Directory to Save');
  if isequal(folder_name,0)
    % cancel
  else
    set(wgts.SaveDirEdt,'String',folder_name);
  end
 
 case {'run'}
  datadir = get(wgts.DataDirEdt,'String');
  study   = get(wgts.StudyEdt,'String');
  scan    = get(wgts.ScanNumEdt,'String');
  reco    = get(wgts.RecoNumEdt,'String');
  imgfile = fullfile(datadir,study,scan,'pdata',reco,'2dseq');

  if ~exist(imgfile,'file')
    if ~exist(datadir,'dir')
      fprintf(' ERROR %s: DATA-directory not found/accessible, ''%s''.\n',mfilename,datadir);
      return;
    end
    if ~exist(fullfile(datadir,study),'dir'),
      fprintf(' ERROR %s: STUDY(%s) not found in DATA-dir ''%s''.\n',mfilename,study,datadir);
      return;
    end
    if ~exist(fullfile(datadir,study,scan),'dir'),
      fprintf(' ERROR %s: SCAN(%s) not found in STUDY(%s).\n',mfilename,scan,study);
      return;
    end
    if ~exist(fullfile(datadir,study,scan,'pdata',reco),'dir'),
      fprintf(' ERROR %s: RECO(%s) not found in ''%s''.\n',mfilename,reco,fullfile(study,scan,'pdata'));
      return;
    end
  
    fprintf(' ERROR %s: 2dseq not found, ''%s''.\n',mfilename,imgfile);
    return;
  end
  
  savedir = get(wgts.SaveDirEdt,'String');
  if ~exist(savedir,'dir'),
    fprintf(' ERROR %s: SAVE-directory not found, ''%s''.\n',mfilename,savedir);
    return;
  end
  
  % everything fine, let's run
  perm_v  = get(wgts.PermuteEdt,'String');
  flip_v  = get(wgts.FlipdimEdt,'String');
  taverage = get(wgts.TimeAverageCheck,'Value');
  tsplit   = get(wgts.TimeSplitCheck,'Value');
  export2d = get(wgts.ExportAs2DCheck,'Value');
      
  fformat  = get(wgts.FormatCmb,'String');
  fformat  = fformat{get(wgts.FormatCmb,'Value')};

  if strncmpi(fformat,'nifti',5)
    nifti1  = 1;
    if any(strfind(fformat,'qform=2,d=1'))
      niicomp = 'qform=2,d=1';
    elseif any(strfind(fformat,'spm'))
      niicomp = 'spm';
    elseif any(strfind(fformat,'amira'))
      niicomp = 'amira';
    elseif any(strfind(fformat,'slicer'))
      niicomp = 'slicer';
    else
      niicomp = 'no xform';
    end
  else
    nifti1  = 0;
    niicomp = 'none';
  end

  cmdstr = [ 'bru2analyze(''' imgfile '''' ...
             ', ''SaveDir'',' '''' savedir '''' ...
             ',''Permute'',' '['   perm_v ']' ...
             ',''FlipDim'',' '['   flip_v ']' ...
             ',''Average'','       num2str(taverage) ...
             ',''SplitInTime'','   num2str(tsplit) ...
             ',''ExportAs2D'','    num2str(export2d) ...
             ',''NII'','           num2str(nifti1) ...
             ',''NIIcompatible'',' '''' niicomp '''' ...
             ');' ];
  
  
  fprintf('%s running: %s\n',datestr(now),cmdstr);
  eval(cmdstr);
  %bru2analyze(imgfile,);


 case {'pvpar'}
  datadir = get(wgts.DataDirEdt,'String');
  study   = get(wgts.StudyEdt,'String');
  scan    = get(wgts.ScanNumEdt,'String');
  reco    = get(wgts.RecoNumEdt,'String');
  imgfile = fullfile(datadir,study,scan,'pdata',reco,'2dseq');
  
  if exist(imgfile,'file')
    sub_show_pvpar(imgfile,fullfile(datadir,study),[str2double(scan) str2double(reco)]);
  else
    fprintf(' ERROR %s: 2dseq not found, ''%s''.\n',mfilename,imgfile);
  end
  

 otherwise
  fprintf('WARNING %s: Main_Callback() ''%s'' not supported yet.\n',mfilename,eventdata);
end
  
return;



% ========================================================================
% FUNCTION to get screen size
function [scrW, scrH] = subGetScreenSize(Units)
% ========================================================================
oldUnits = get(0,'Units');
set(0,'Units',Units);
sz = get(0,'ScreenSize');
set(0,'Units',oldUnits);

scrW = sz(3);  scrH = sz(4);

return;




% ========================================================================
function varargout = sub_show_pvpar(IMGFILE,SESDIR,SCANRECO)
% ========================================================================

fprintf(' %s.sub_show_pvpar:  reading parameters...',mfilename);
PVPAR.acqp   = pvread_acqp(IMGFILE);
fprintf(' acqp.');
PVPAR.method = pvread_method(IMGFILE,'verbose',0);
if ~isempty(PVPAR.method),  fprintf(' method.');  end
PVPAR.imnd   = pvread_imnd(IMGFILE,'verbose',0);
if ~isempty(PVPAR.imnd),  fprintf(' imnd.');  end
PVPAR.reco   = pvread_reco(IMGFILE);
fprintf(' reco.');
fprintf(' done.\n');


[scrW scrH] = subGetScreenSize('char');
% keep the figure size smaller than XGA (1024x768) for notebook PC.
% figWH: [185 57]chars = [925 741]pixels
figW = 162; figH = 35;
figX = max(min(63,scrW-figW),10);
%figY = scrH-figH-9.7;
figY = scrH-figH-10;


% SET WINDOW TITLE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tmptitle = sprintf('%s.PvPar:  %s  %d/%d',...
                   mfilename,SESDIR,SCANRECO(1),SCANRECO(2));

FontSize = 9;


hMain = figure;

set(hMain,...
    'Name',tmptitle,...
    'NumberTitle','off', 'toolbar','none','MenuBar','none',...
    'Tag','PvPar', 'units','char', 'pos',[figX figY figW figH],...
    'HandleVisibility','on', 'Resize','on',...
    'DoubleBuffer','on', 'BackingStore','on', 'Visible','on',...
    'DefaultAxesFontSize',FontSize,...
    'DefaultAxesfontweight','bold',...
    'PaperPositionMode','auto', 'PaperType','A4', 'PaperOrientation', 'landscape');

tmptxt = sprintf('%s  %d/%d  ''%s''',...
                 SESDIR,SCANRECO(1),SCANRECO(2),IMGFILE);
InfoTxt =  uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[3 figH-2 150 1.5],...
    'String',tmptxt,'FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','InfoTxt',...
    'BackgroundColor',get(hMain,'Color'));


AcqpTxt =  uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[3 figH-3.5 30 1.5],...
    'String','ACQP :','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','AcqpTxt',...
    'BackgroundColor',get(hMain,'Color'));
AcqpList = uicontrol(...
    'Parent',hMain,'Style','Listbox',...
    'Units','char','Position',[3 1 50 figH-4.2],...
    'String',subGetPvString(PVPAR.acqp),...
    'HorizontalAlignment','left',...
    'FontSize',FontSize,...
    'Tag','AcqpList','Background','white');

if isfield(PVPAR,'method') & ~isempty(PVPAR.method),
  MethodTxt =  uicontrol(...
      'Parent',hMain,'Style','Text',...
      'Units','char','Position',[56 figH-3.5 30 1.5],...
      'String','METHOD :','FontWeight','bold',...
      'HorizontalAlignment','left',...
      'Tag','MethodTxt',...
      'BackgroundColor',get(hMain,'Color'));
  MethodList = uicontrol(...
      'Parent',hMain,'Style','Listbox',...
      'Units','char','Position',[56 1 50 figH-4.2],...
      'String',subGetPvString(PVPAR.method),...
      'HorizontalAlignment','left',...
      'FontSize',FontSize,...
      'Tag','MethodList','Background','white');
else
  ImndTxt =  uicontrol(...
      'Parent',hMain,'Style','Text',...
      'Units','char','Position',[56 figH-3.5 30 1.5],...
      'String','IMND :','FontWeight','bold',...
      'HorizontalAlignment','left',...
      'Tag','ImndTxt',...
      'BackgroundColor',get(hMain,'Color'));
  ImndList = uicontrol(...
      'Parent',hMain,'Style','Listbox',...
      'Units','char','Position',[56 1 50 figH-4.2],...
      'String',subGetPvString(PVPAR.imnd),...
      'HorizontalAlignment','left',...
      'FontSize',FontSize,...
      'Tag','ImndList','Background','white');
end



RecoTxt =  uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[109 figH-3.5 30 1.5],...
    'String','RECO :','FontWeight','bold',...
    'HorizontalAlignment','left',...
    'Tag','RecoTxt',...
    'BackgroundColor',get(hMain,'Color'));
RecoList = uicontrol(...
    'Parent',hMain,'Style','Listbox',...
    'Units','char','Position',[109 1 50 figH-4.2],...
    'String',subGetPvString(PVPAR.reco),...
    'HorizontalAlignment','left',...
    'FontSize',FontSize,...
    'Tag','RecoList','Background','white');



% get widgets handles at this moment
HANDLES = findobj(hMain);
% NOW SET "UNITS" OF ALL WIDGETS AS "NORMALIZED".
HANDLES = HANDLES(find(HANDLES ~= hMain));
set(HANDLES,'units','normalized');


% RETURNS THE WINDOW HANDLE IF REQUIRED.
if nargout,
  varargout{1} = hMain;
end

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION to convert numbers to strings
function STR = subGetPvString(par)

STR = {};
fnames = fieldnames(par);
for N = 1:length(fnames),
  STR{end+1} = sprintf('%s: %s',fnames{N},sub2string(par.(fnames{N})));
end

return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTION to convert data into a string
function STR = sub2string(val)

STR = '';
if isempty(val),  return;  end
if ischar(val),
  STR = val;
elseif isnumeric(val),
  if isvector(val) & length(val) > 1,
    STR = sprintf('[%s]',deblank(sprintf('%g ',val)));
  else
    try,
      STR = num2str(val);
    catch
      STR = 'ERROR: old matlab';
    end
  end
elseif iscell(val),
  STR = sprintf('{%s}',sub2string(val{1}));
  for N = 1:length(val),
    STR = strcat(STR,sprintf(' {%s}',sub2string(val{N})));
  end
end

STR = deblank(STR);

return
