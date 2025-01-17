function varargout = mroi(varargin)
%MROI - Utility to define Regions of Interests (ROIs)
% MROI(SESSION,GRPANME) permits the definition of multiple ROIs in arbitrarily
% selected slices. Full documentation of the program and description
% of the procedures to generate and use ROIs can be obtained by
% typing HROI.
%  
% TODO's
% ===============
% ** GETELEDIST get interelectrode distance from "ROI" file
%
%
% NOTES :
%   settings can be set by ANAP in the description file like
%     ANAP.colors = 'crgbkmy';
%     ANAP.gamma  = 1.8;
%
% NOTES :
%  ROI structure will be like .... (updated 05.08.2005 YM)
%  RoiDef = 
%      session: 'm02lx1'
%      grpname: 'movie1'
%         exps: [1 16]
%      anainfo: {4x1 cell}
%     roinames: {7x1 cell}
%          dir: [1x1 struct]
%          dsp: [1x1 struct]
%          grp: [1x1 struct]
%          ana: [136x88x2 double]
%          img: [34x22x2 double]
%           ds: [0.7500 0.7500 2]
%           dx: 0.2500
%          roi: {1x14 cell}
%          ele: {[1x1 struct]  [1x1 struct]}
%
%  RoiDef.roi{1} = 
%         name: 'V1'
%        slice: 1
%           px: [7x1 double]
%           py: [7x1 double]
%         mask: [34x22 logical]
%
%  RoiDef.ele{1} = 
%          ele: 1
%        slice: 1
%         anax: 87.5456
%         anay: 73.5622
%            x: 22
%            y: 18
%
%  
%  VERSION
%    0.90 05.03.04 YM  pre-release, modified from Nikos's mroi.m.
%    1.00 09.03.04 NKL ROI & DEBUG
%    1.01 11.04.04 NKL
%    1.02 16.04.04 NKL Display Ana and tcImg
%    1.03 06.09.04 YM  bug fix on 'grproi-select' and Roi saving.
%    1.04 12.10.04 YM  supports zoom-in, bug fix on 'grp-select'.
%    1.05 23.11.04 YM  supports gamma setting, bug fix.
%    1.10 30.11.04 YM  supports corr.map if available.
%    1.11 29.05.05 YM  bug fix of 'sticky' mode.
%    1.12 30.05.05 YM  supports 'cursor' shape for roipoly.
%    1.13 06.06.05 YM  set .mask/.anamask as logical.
%    1.14 09.06.05 YM  supports 'AnaScale', bug fix on saving roi.anamask.
%    1.15 20.07.05 YM  supports 'DrawROI', bug fix.
%    1.20 05.08.05 YM  changed "Roi.roi" format, px/py is for funtional, not anatomy.
%    1.21 07.10.06 YM  does a simple motion correction if 'ImgDistort'.
%    1.22 15.11.06 YM  suppoprts the sama gamma value for all slices.
%    1.23 19.02.07 YM  suppoprts 'midline' and 'ant.commisure'
%    1.24 01.03.07 YM  now 'stat.map' as old 'corr.map'.
%    1.25 20.03.07 YM  fix upper/lower case between ses.roi.names and Roi.roi{X}.name.
%    1.26 02.04.07 YM  fix problem on group selection, colored stat.map.
%    1.27 10.12.07 YM  bug fix for MatLab 7.5, crash of roipoly().
%    1.28 07.03.08 YM  use roipoly of Matlab 7.1
%    1.29 30.05.08 YM  avoid crash on huge tcImg like i008c1
%
%  See also HROI, MROISCT, MROIDSP, MROI_CURSOR, HIMGPRO, HHELP

persistent H_MROI;	% keep the figure handle.

if ~nargin,
  help mroi;
  return;
else
  if isfield(varargin{1},'name'),
    SESSION = varargin{1}.name;
  else
    SESSION = varargin{1};
  end
  if nargin > 1,  GrpName = varargin{2};  end
end

% execute callback function then return;
if isstr(SESSION) & ~isempty(findstr(SESSION,'Callback')),
  if nargout
    [varargout{1:nargout}] = feval(varargin{:});
  else
    feval(varargin{:});
  end
  return;
end

% prevent double execution
if ishandle(H_MROI),
  close(H_MROI);
end

% ====================================================================
% DISPLAY PARAMETERS FOR THE PLACEMENT OF AXIS ETC.
% ====================================================================
[scrW scrH] = getScreenSize('char');
figW        = 180.0;
figH        =  46.0;
figX        =   1.0;
figY        = scrH-figH-4;   % MUST BE "-4" for menu/title, need to avoid y-offset of roipoly()
IMGXOFS     = 3;
IMGYOFS     = figH * 0.11;
IMGYLEN     = figH * 0.68;
IMGXLEN     = figW * 0.47;
IMG2XOFS	= 2 * IMGXOFS + IMGXLEN;
TCPY        = 18;
TCPOFS      = 29;
FRPOFS      = 6;
XPLOT       = 97;
XPLOTLEN    = 75;

% ====================================================================
% CREATE THE MAIN WINDOW
% Reminder: get(0,'DefaultUicontrolBackgroundColor')
%    'Color', get(0,'DefaultUicontrolBackgroundColor'),...
% ====================================================================
hMain = figure(...
'Name',...
'MROI: Graphics Interface for Region-of-Interest (ROI) selection (v1.15.20050720)',...
	'NumberTitle','off', ...
    'Tag','main', 'MenuBar', 'none', ...
    'HandleVisibility','on','Resize','on',...
    'DoubleBuffer','on', 'BackingStore','on','Visible','off',...
    'Units','char','Position',[figX figY figW figH],...
    'UserData',[figW figH],...
    'Color',[.85 .98 1],'DefaultAxesfontsize',10,...
    'DefaultAxesFontName', 'Comic Sans MS',...
    'DefaultAxesfontweight','bold');
H_MROI = hMain;
%[figX figY figW figH]
%set(hMain,'visible','on');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PULL-DOWN MENU [File Edit View Help]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- FILE
hMenuFile = uimenu(hMain,'Label','File');
uimenu(hMenuFile,'Label','Export as TIFF','Separator','off',...
       'Callback','mroi(''Print_Callback'',gcbo,''tiff'',[])');
uimenu(hMenuFile,'Label','Export as JPEG','Separator','off',...
       'Callback','mroi(''Print_Callback'',gcbo,''jpeg'',[])');
uimenu(hMenuFile,'Label','Export as Windows Metafile','Separator','off',...
       'Callback','mroi(''Print_Callback'',gcbo,''meta'',[])');
uimenu(hMenuFile,'Label','Page Setup...','Separator','on',...
       'Callback','mroi(''Print_Callback'',gcbo,''pagesetupdlg'',[])');
uimenu(hMenuFile,'Label','Print Setup...','Separator','off',...
       'Callback','mroi(''Print_Callback'',gcbo,''printdlg'',[])');
uimenu(hMenuFile,'Label','Print','Separator','off',...
       'Callback','mroi(''Print_Callback'',gcbo,''print'',[])');
uimenu(hMenuFile,'Label','Exit','Separator','on',...
       'Callback','mroi(''Main_Callback'',gcbo,''exit'',[])');
% --- EDIT
hMenuEdit = uimenu(hMain,'Label','Edit');
uimenu(hMenuEdit,'Label','mroi',...
       'Callback','edit ''mroi'';');
hCB = uimenu(hMenuEdit,'Label','mroi : Callbacks');
uimenu(hCB,'Label','Main_Callback',...
       'Callback','mroi(''Main_Callback'',gcbo,''edit-cb'',[])');
uimenu(hCB,'Label','Roi_Callback',...
       'Callback','mroi(''Main_Callback'',gcbo,''edit-cb'',[])');
uimenu(hCB,'Label','Print_Callback',...
       'Callback','mroi(''Main_Callback'',gcbo,''edit-cb'',[])');
uimenu(hMenuEdit,'Label','sescheck  : session checker',...
       'Callback','edit ''sescheck'';');
uimenu(hMenuEdit,'Label','Copy Figure','Separator','on',...
       'Callback','mroi(''Print_Callback'',gcbo,''copy-figure'',[])');
% --- FILE
hMenuView = uimenu(hMain,'Label','View');
uimenu(hMenuView,'Label','Figure Toolbar','Separator','off','Tag','MenuFigToolbar',...
       'Callback','mroi(''Main_Callback'',gcbo,''fig-toolbar'',[])');
% --- HELP
hMenuHelp = uimenu(hMain,'Label','Help');
uimenu(hMenuHelp,'Label','ROI','Separator','off',...
       'Callback','hroi');
uimenu(hMenuHelp,'Label','ROI Structure','Separator','off',...
       'Callback','hroistructure');
uimenu(hMenuHelp,'Label','roiTS Structure','Separator','off',...
       'Callback','hroitsstructure');

% ====================================================================
% DISPLAY NAMES OF SESSION/GROUP
% ====================================================================
H = figH - 2;
BKGCOL = get(hMain,'Color');
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS H-0.15 12 1.5],...
    'String','Session: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
uicontrol(...
    'Parent',hMain,'Style','pushbutton',...
    'Units','char','Position',[IMGXOFS+14 H-0.05 22 1.5],...
    'String',SESSION,'FontWeight','bold','fontsize',9,...
    'HorizontalAlignment','left',...
    'Callback','mroi(''Main_Callback'',gcbo,''edit-session'',[])',...
    'ForegroundColor',[1 1 0.1],'BackgroundColor',[0 0.5 0]);
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS H-2 12 1.5],...
    'String','Group: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
GrpNameBut = uicontrol(...
    'Parent',hMain,'Style','pushbutton',...
    'Units','char','Position',[IMGXOFS+14 H-2 22 1.5],...
    'String','Edit','FontWeight','bold','fontsize',9,...
    'HorizontalAlignment','left','Tag','GrpNameBut',...
    'Callback','mroi(''Main_Callback'',gcbo,''edit-group'',[])',...
    'TooltipString','Edit the group',...
    'ForegroundColor',[1 1 0.1],'BackgroundColor',[0.6 0.2 0]);
GrpSelCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[IMGXOFS+38 H-2 31 1.5],...
    'String',{'Grp 1','Grp 2'},...
    'Callback','mroi(''Main_Callback'',gcbo,''grp-select'',[])',...
    'TooltipString','Group Selection',...
    'Tag','GrpSelCmb','FontWeight','Bold');
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS H-4 12 1.5],...
    'String','ROI Set: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
GrpRoiSelCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[IMGXOFS+14 H-3.8 22 1.25],...
    'String',{'Roi 1','Roi 2'},...
    'Callback','mroi(''Main_Callback'',gcbo,''grproi-select'',[])',...
    'TooltipString','GrpRoi Selection',...
    'Tag','GrpRoiSelCmb','FontWeight','Bold');


% ====================================================================
% ROI CONTROL
% ====================================================================
XDSP = IMGXOFS;
H = IMGYOFS + IMGYLEN + 0.6;
% COMBO : ROI selecton
RoiSelCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[XDSP H 19 1.5],...
    'String',{'Roi1','Roi2'},...
    'Callback','mroi(''Main_Callback'',gcbo,''roi-select-redraw'',[])',...
    'TooltipString','ROI selection',...
    'Tag','RoiSelCmb','FontWeight','Bold');
% COMBO : ROI action
ActCmd = {'No Action','Append','Replace','Electrodes',...
          'Midline','Ant.Commisure',...
          'Reset CURSOR',...
          'Clear','Clear All Slices','Clear electrodes',...
          'Clear midline','Clear ant.commisure','COMPLETE CLEAR'};
RoiActCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[XDSP+21 H 25 1.5],...
    'String',ActCmd,...
    'Callback','mroi(''Roi_Callback'',gcbo,''roi-action'',[])',...
    'TooltipString','ROI action',...
    'Tag','RoiActCmb','FontWeight','Bold');
% COMBO : ROI draw
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+47.5 H+2 12 1.25],...
    'String','DrawROI: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
RoiDrawCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[XDSP+60 H+2 25 1.5],...
    'Callback','mroi(''Main_Callback'',gcbo,''roidraw'',[])',...
    'Tag','RoiDrawCmb','Value',1,...
    'String',{'all','current','none'},'FontWeight','bold',...
    'TooltipString','Draw ROI-polygon');
% STICKY BUTTON - IF SET APPEND IS STICKY AND SLICE ADVANCES
StickyCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+47.5 H 12 1.5],...
    'Tag','Sticky','Value',0,...
    'String','Sticky','FontWeight','bold',...
    'TooltipString','Append-Advance-Slice','BackgroundColor',get(hMain,'Color'));
% LOAD BUTTON - LOADS ROIs
RoiLoadBtn = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[XDSP+60 H 12 1.5],...
    'Callback','mroi(''Main_Callback'',gcbo,''load-redraw'',guidata(gcbo))',...
    'Tag','RoiLoadBtn','String','LOAD',...
    'TooltipString','Load ROIs','FontWeight','bold',...
    'ForegroundColor',[0.9 0.9 0],'BackgroundColor',[0 0 0.5]);
% SAVE BUTTON - Saves ROIs
RoiSaveBtn = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',[XDSP+73 H 12 1.5],...
    'Callback','mroi(''Main_Callback'',gcbo,''save'',guidata(gcbo))',...
    'Tag','RoiSaveBtn','String','SAVE',...
    'TooltipString','Save ROIs','FontWeight','bold',...
    'ForegroundColor',[0.9 0.9 0],'BackgroundColor',[0 0 0.5]);

% ====================================================================
% AXES for plots, image and ROIs
% ====================================================================
% ANATOMY-IMAGE-ROI AXIS
AxsFrame = axes(...
    'Parent',hMain,'Units','char','color',get(hMain,'color'),'xtick',[],...
    'ytick',[],'Position',[IMGXOFS IMGYOFS IMGXLEN+1 IMGYLEN],...
    'Box','on','linewidth',3,'xcolor','r','ycolor','r',...
	'ButtonDownFcn','mroi(''Main_Callback'',gcbo,''zoomin-ana'',[])',...
    'color',[0 0 .2]);
ImageAxs = axes(...
    'Parent',hMain,'Tag','ImageAxs',...
    'Units','char','Color','k','layer','top',...
    'Position',[IMGXOFS+2 IMGYOFS+1 IMGXLEN*.95 IMGYLEN*.85],...
    'xticklabel','','yticklabel','','xtick',[],'ytick',[]);
% EPI-IMAGE-ROI AXIS
Axs2Frame = axes(...
    'Parent',hMain,'Units','char','color',get(hMain,'color'),'xtick',[],...
    'ytick',[],'Position',[IMG2XOFS IMGYOFS IMGXLEN+1 IMGYLEN],...
    'Box','on','linewidth',3,'xcolor','r','ycolor','r',...
	'ButtonDownFcn','mroi(''Main_Callback'',gcbo,''zoomin-func'',[])',...
    'color',[0 0 .2]);
% W/out BAR 'Position',[IMG2XOFS+2 IMGYOFS+1 IMGXLEN*.95 IMGYLEN*.85],...
Image2Axs = axes(...
    'Parent',hMain,'Tag','Image2Axs',...
    'Units','char','Color','k','layer','top',...
    'Position',[IMG2XOFS+2 IMGYOFS+1 IMGXLEN*.9 IMGYLEN*.85],...
    'xticklabel','','yticklabel','','xtick',[],'ytick',[]);



% ====================================================================
% Statistical.Map (Optional)
% ====================================================================
XDSP = IMG2XOFS + 3;  HY = figH - 2;
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP HY 12 1.25],...
    'String','Stat Map: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
StatMapCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[XDSP+14 HY 25 1.5],...
    'String',{'none'},...
    'Callback','mroi(''Main_Callback'',gcbo,''imgdraw'',[])',...
    'TooltipString','Stat Map Selection',...
    'Tag','StatMapCmb','FontWeight','Bold');
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+42 HY 12 1.25],...
    'String','V-Thr: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
StatVThrEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+50 HY 10 1.5],...
    'Callback','mroi(''Main_Callback'',gcbo,''imgdraw'',guidata(gcbo))',...
    'String','10','Tag','StatVThrEdt',...
    'HorizontalAlignment','left',...
    'TooltipString','set threshold for stat.map',...
    'FontWeight','bold','BackgroundColor','white');
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+62 HY 12 1.25],...
    'String','P-Thr: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
StatPThrEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+70 HY 12 1.5],...
    'Callback','mroi(''Main_Callback'',gcbo,''imgdraw'',guidata(gcbo))',...
    'String','0.1','Tag','StatPThrEdt',...
    'HorizontalAlignment','left',...
    'TooltipString','set threshold for stat.map',...
    'FontWeight','bold','BackgroundColor','white');
BonferroniCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+67 HY-2 30 1.5],...
    'Callback','mroi(''Main_Callback'',gcbo,''imgdraw'',guidata(gcbo))',...
    'Tag','BonferroniCheck','Value',0,...
    'String','Bonferroni','FontWeight','bold',...
    'TooltipString','Bonferroni correction','BackgroundColor',get(hMain,'Color'));



% ====================================================================
% Anatomy/Display settings, gamma etc.
% ====================================================================
XDSP = IMG2XOFS + 3;  HY = figH - 6;
% Gamma setting to displaying anatomy
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP, HY 30 1.25],...
    'String','AnaGamma: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
GammaEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+17, HY 7 1.5],...
    'Callback','mroi(''Main_Callback'',gcbo,''set-gamma'',guidata(gcbo))',...
    'String','Gamma','Tag','GammaEdt',...
    'HorizontalAlignment','left',...
    'TooltipString','set a gamma value for image',...
    'FontWeight','bold','BackgroundColor','white');
GammaHoldCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+24 HY 25 1.5],...
    'Tag','GammaHoldCheck','Value',1,...
    'Callback','mroi(''Main_Callback'',gcbo,''imgdraw'',[])',...
    'String','Hold','FontWeight','bold',...
    'TooltipString','hold gamma for all slices','BackgroundColor',get(hMain,'Color'));

% CLim setting for display
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP+37, HY 30 1.25],...
    'String','AnaScale: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
AnaScaleEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[XDSP+50, HY 22 1.5],...
    'Callback','mroi(''Main_Callback'',gcbo,''imgdraw'',[])',...
    'String','firsttime','Tag','AnaScaleEdt',...
    'HorizontalAlignment','left',...
    'TooltipString','set scaling for anatomy',...
    'FontWeight','bold','BackgroundColor','white');
% AutoScale button - If checked "clim" became "auto"
AutoAnaScaleCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[XDSP+72 HY 25 1.5],...
    'Tag','AutoAnaScale','Value',0,...
    'Callback','mroi(''Main_Callback'',gcbo,''imgdraw'',[])',...
    'String','Auto','FontWeight','bold',...
    'TooltipString','Automatic scaling','BackgroundColor',get(hMain,'Color'));




% ====================================================================
% Cursor setting for ROIPOLY
% ====================================================================
XDSP = IMG2XOFS + 1;
HY = IMGYOFS + IMGYLEN + 0.6;
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP HY 12 1.25],...
    'String','Pointer: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
RoiCursorCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[XDSP+12 HY 25 1.5],...
    'String',{'crosshair','black dot','white dot','circle','cross','fluer','fullcross','ibeam','arrow'},...
    'TooltipString','ROIPOLY pointer',...
    'Tag','RoiCursorCmb','Value',3,'FontWeight','Bold');


% ====================================================================
% FUNCTION BUTTONS FOR IMAGE AND TIME-SERIES PROCESSING
% ====================================================================
XDSP = IMG2XOFS + 41;
HY = IMGYOFS + IMGYLEN + 0.6;
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[XDSP HY 18 1.25],...
    'String','Image Process: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
imgpro = {'Mean-Img','Median-Img','Max-Img','Min-Img','Std-Img','StmStd-Img','Cv-Img'};
ImgProcCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[XDSP+20 HY 25 1.5],...
    'String',imgpro,...
    'Callback','mroi(''Main_Callback'',gcbo,''imgproc-select'',[])',...
    'TooltipString','GrpRoi Selection',...
    'Tag','ImgProcCmb','FontWeight','Bold');




% ====================================================================
% SLICE SELECTION SLIDER
% ====================================================================
% LABEL : Slice X
SliceBarTxt = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS 2.5 15 1.5],...
    'String','Slice : 1','FontWeight','bold','FontSize',10,...
    'HorizontalAlignment','left','Tag','SliceBarTxt',...
    'BackgroundColor',get(hMain,'Color'));
SliceBarSldr = uicontrol(...
    'Parent',hMain,'Style','slider',...
    'Units','char','Position',[IMGXOFS+16 2.6 158 1.5],...
    'Callback','mroi(''Main_Callback'',gcbo,''slice-slider'',[])',...
    'Tag','SliceBarSldr','SliderStep',[1 4],...
    'TooltipString','Set current slice');

% ====================================================================
% STATUS LINE: 
% ====================================================================
StatusCol = [.92 .96 .94];
StatusFrame = axes(...
    'Parent',hMain,'Units','char','color',get(hMain,'color'),'xtick',[],...
    'ytick',[],'Position',[IMGXOFS 0.35 174 1.8],...
    'Box','on','linewidth',1,'xcolor','k','ycolor','k',...
    'color',StatusCol);
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS+2 0.45 11 1.5],...
    'String','Status :','FontWeight','bold','fontsize',10,...
    'HorizontalAlignment','left','ForegroundColor','r',...
    'BackgroundColor',StatusCol);
StatusField = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS+16 0.55 145 1.2],...
    'String','Normal','FontWeight','bold','fontsize',9,...
    'HorizontalAlignment','left','Tag','StatusField',...
    'ForegroundColor','k','BackgroundColor',StatusCol);

% ====================================================================
% INITIALIZE THE APPLICATION.
% ====================================================================
MAPCOLORS = 'cywgmrbkcywgmrbk';
COLORS = 'crgbkmy';
GAMMA = 1.8;
ses = goto(SESSION);
grps = getgroups(ses);
anap = getanap(ses);
if isfield(anap,'mroi'),
  if isfield(anap.mroi,'colors'),
    COLORS = anap.mroi.colors;
    MAPCOLORS = anap.mroi.mapcolors;
  end
  if isfield(anap.mroi,'gamma'),
    GAMMA = anap.mroi.gamma;
  end
end


% SELECT GROUPS HAVING DIFFERENT ROI-DEFINITION-REQUIREMENTS
DoneGroups = {};
ToDoGroups = {};
K=0;
for GrpNo = 1:length(grps),
  if ~isfield(grps{GrpNo},'grproi') | isempty(grps{GrpNo}.grproi),
	grps{GrpNo}.grproi = 'RoiDef';
  end;
  ToDoGroups{end+1} = grps{GrpNo}.name;
%   if isempty(DoneGroups) | ...
%  		~any(strcmp(DoneGroups,grps{GrpNo}.grproi)),
%  	K=K+1;
%  	DoneGroups{K} = grps{GrpNo}.grproi;
%  	ToDoGroups{K} = grps{GrpNo}.name;
%   end;
end;
GrpNames = getgrpnames(ses);
GrpNames = ToDoGroups;

% NOW WE HAVE THE GROUPS REQURING DIFFERENT ROI-DEFINITIONS
% THIS MAY HAPPEN WHEN THE ANIMAL'S POSITION IS CHANGED DURING THE
% EXPERIMENT.
% WE SAVE THE NAMES OF THE ROIS OF EACH SUCH GROUP IN GRPROINAMES
for N=1:length(GrpNames),
  grp = getgrpbyname(ses,GrpNames{N});
  GrpRoiNames{N} = grp.grproi;
end;

% GET DEFAULT GROUP NAME IF NONE IS DEFINED
if ~exist('GrpName'),
  GrpName = GrpNames{1};
end;

% AND ALSO THE ROI NAME FOR THIS GROUP
grp = getgrpbyname(ses,GrpName);
wgts = guihandles(hMain);
idx = find(strcmp(GrpNames,grp.name));
if isempty(idx),  idx = 1;  end
set(wgts.GrpSelCmb,'String',GrpNames,'Value',idx);
set(wgts.GrpRoiSelCmb,'String',GrpRoiNames,'Value',1);
clear idx;


setappdata(hMain,'Ses',ses);
setappdata(hMain,'Grp',grp);
setappdata(hMain,'COLOR',COLORS);
setappdata(hMain,'MAPCOLOR',MAPCOLORS);
setappdata(hMain,'GAMMA',GAMMA);
setappdata(hMain,'StatMap',[]);
setappdata(hMain,'CurOp', 'Mean-Img');

mroi('Main_Callback',hMain,'init');
set(hMain,'Visible','on');

if nargout, varargout{1} = hMain;  end
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAIN CALLBACK
function Main_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
funcname = mfilename('fullpath');
[ST, I] = dbstack;
n = findstr(ST(I).name,'(');
cbname = ST(I).name(n+1:end-1);

wgts = guihandles(hObject);
ses = getappdata(wgts.main,'Ses');
grp = getappdata(wgts.main,'Grp');
curImg = getappdata(wgts.main,'curImg');
curanaImg = getappdata(wgts.main,'curanaImg');
COLORS = getappdata(wgts.main,'COLOR');
MAPCOLORS = getappdata(wgts.main,'MAPCOLOR');
GAMMA = getappdata(wgts.main,'GAMMA');

%fprintf('%s: eventdata=''%s''\n',gettimestring,eventdata);

switch lower(eventdata),
 case {'init'}
  % CHANGE 'UNITS' OF ALL WIDGETS FOR SUCCESSFUL PRINT
  % the following is as dirty as it can be... but it allows
  % rescaling and also correct printing... leave it so, until you
  % find a better solution!
  handles = findobj(wgts.main);
  for N=1:length(handles),
    try,
      set(handles(N),'units','normalized');
    catch
    end
  end
  % DUE TO BUG OF MATLAB 7.5, 'units' for figure must be 'pixels'
  % otherwise roipoly() will crash.
  set(wgts.main,'units','pixels');
  
  % re-evaluate session/group info.
  ses = getses(ses.name);
  grp = getgrp(ses,grp.name);
  anap = getanap(ses,grp);
  setappdata(wgts.main,'Ses',ses);
  setappdata(wgts.main,'Grp',grp);
  
  % INITIALIZE WIDGETS
  set(wgts.GrpNameBut,'String',grp.name);
  set(wgts.RoiSelCmb,'String',ses.roi.names,'Value',1);
  
  % ---------------------------------------------------------------------
  % LOAD FUNCTIONAL SCAN (average or single-experiment)
  % ---------------------------------------------------------------------
%  if exist('tcImg.mat','file') & ~isempty(who('-file','tcImg.mat',grp.name)),
%    fname = 'tcImg.mat';
%    tcAvgImg = load(fname,grp.name);
%    tcAvgImg = tcAvgImg.(grp.name);
%    StatusPrint(hObject,cbname,'tcAvgImg is group %s of "tcImg.mat"',grp.name);
%  else
    ExpNo = grp.exps(1);
    if isfield(anap,'mareats') && isfield(anap.mareats,'USE_REALIGNED') && ~any(anap.mareats.USE_REALIGNED),
      fname = catfilename(ses,ExpNo,'tcImg.bak');
      if exist(fname,'file'),
        tcAvgImg = sigload(ses,ExpNo,'tcImg.bak');
      else
        fname = catfilename(ses,ExpNo,'tcImg');
        tcAvgImg = sigload(ses,ExpNo,'tcImg');
      end
    else
      fname = catfilename(ses,ExpNo,'tcImg');
      tcAvgImg = sigload(ses,ExpNo,'tcImg');
    end
    if isstruct(tcAvgImg) & ~isfield(tcAvgImg,'stm'),
      fprintf('MROI: No stm-field was found! Check dgz/session files\n');
      keyboard;
    end;
    if iscell(tcAvgImg) & ~isfield(tcAvgImg{1},'stm'),
      fprintf('MROI: No stm-field was found! Check dgz/session files\n');
      keyboard;
    end;
    
    StatusPrint(hObject,cbname,'tcAvgImg loaded from "%s"',fname);
%  end
  % adds Z resolution, if needed.
  if length(tcAvgImg.ds) < 3,
    tmppar = expgetpar(ses,grp.name);
    tcAvgImg.ds(3) = tmppar.pvpar.slithk;
    clear tmppar;
  end
  
  curImg = tcAvgImg;
  if size(curImg.dat,4) > 1,
    % checks centroid and average only stable images
    curImg = subDoCentroidAverage(curImg);
  end
  setappdata(wgts.main,'tcAvgImg',tcAvgImg);
  setappdata(wgts.main,'curImg',curImg);

  % ---------------------------------------------------------------------
  % LOAD ANATOMY
  % ---------------------------------------------------------------------
  if isfield(anap,'ImgDistort') & anap.ImgDistort,
    anaImg = tcAvgImg;
    anaImg.EpiAnatomy = 1;
    if size(anaImg.dat,4) > 1,
      % checks centroid and average only stable images
      anaImg = subDoCentroidAverage(anaImg);
    end
  elseif ~isfield(grp,'ana') | isempty(grp.ana),
    anaImg = tcAvgImg;
    anaImg.EpiAnatomy = 1;
    if size(anaImg.dat,4) > 1,
      % checks centroid and average only stable images
      anaImg = subDoCentroidAverage(anaImg);
    end
  else
    AnaFile = sprintf('%s.mat',grp.ana{1});
    if exist(AnaFile,'file') & ~isempty(who('-file',AnaFile,grp.ana{1})),
      tmp = load(AnaFile,grp.ana{1});
      eval(sprintf('anaImg = tmp.%s;',grp.ana{1}));
      anaImg = anaImg{grp.ana{2}};
    else
      StatusPrint(hObject,cbname,'"%s" not found, run "sesascan"',AnaFile);
      return;
    end
    % We use to keep all slices and select the appropriate ones in
    % the 'imgdraw' case, but the line:
    % mroidsp(curanaImg.dat(:,:,grp.ana{3}(SLICE)));
    % Now this step is eliminated. We choose the appropriate
    % slices right here.
    if ~isempty(grp.ana{3}),
      anaImg.dat = anaImg.dat(:,:,grp.ana{3});
    end
    anaImg.EpiAnatomy = 0;
  end
  
  curanaImg = anaImg;
  setappdata(wgts.main,'anaImg',anaImg);
  setappdata(wgts.main,'curanaImg',curanaImg);
  % set color scaling for anatomy
  %%% AnaScale = [min(curanaImg.dat(:)) max(curanaImg.dat(:))*0.8]; -- NKL 27.09.06
  AnaScale = [min(curanaImg.dat(:)) max(curanaImg.dat(:))];
  set(wgts.AnaScaleEdt,'String',sprintf('%.1f  %.1f',AnaScale(1),AnaScale(2)));
  setappdata(wgts.main,'AnaScale',AnaScale);

  % set dimensional info.
  IMGDIMS.ana     = [size(curanaImg.dat,1), size(curanaImg.dat,2)];
  if ~isfield(anap,'ImgDistort'),
    anap.ImgDistort = 0;
  end
  if anap.ImgDistort == 0 & isfield(grp,'ana') & ~isempty(grp.ana),
    IMGDIMS.anaorig = ses.ascan.(grp.ana{1}){grp.ana{2}}.imgcrop(3:4);
  else
    IMGDIMS.anaorig = ones(size(IMGDIMS.ana));
  end
  IMGDIMS.epi     = [size(tcAvgImg.dat,1), size(tcAvgImg.dat,2)];
  IMGDIMS.pxscale = size(tcAvgImg.dat,1)/size(curanaImg.dat,1);
  IMGDIMS.pyscale = size(tcAvgImg.dat,2)/size(curanaImg.dat,2);
  IMGDIMS.EpiAnatomy = anaImg.EpiAnatomy;
  setappdata(wgts.main,'IMGDIMS',IMGDIMS);


  % ---------------------------------------------------------------------
  % LOAD STAT.MAP if available.
  % ---------------------------------------------------------------------
  roiTs = {};  StatMap = [];
  if exist('mroistat.mat','file') & ~isempty(who('-file','mroistat.mat',grp.name)),,
    roiTs = load('mroistat.mat',grp.name);
    roiTs = roiTs.(grp.name);
  elseif exist('allcorr.mat','file') & ~isempty(who('-file','allcorr.mat',grp.name)),,
    % for compatibility for manganese stuff
    roiTs = load('allcorr.mat',grp.name);
    roiTs = roiTs.(grp.name);
    for N = 1:length(roiTs),
    end
    for N = 1:length(roiTs),
      for K = 1:length(roiTs{N}.modelname),
        roiTs{N}.modelname{K} = sprintf('corr %s',roiTs{N}.modelname{K});
      end
      if ~isfield(roiTs{N},'statv'),
        roiTs{N}.statv = roiTs{N}.r;
        roiTs{N} = rmfield(roiTs{N},'r');
      end
    end
  end
  if ~isempty(roiTs),
    modelname = {'none','all'};
    modelname(3:length(roiTs{1}.modelname)+2) = roiTs{1}.modelname;
    set(wgts.StatMapCmb,'String',modelname);
    set(wgts.StatMapCmb,'Value',1);
    set(wgts.StatMapCmb,'Tag','StatMapCmb');

    % prepare stat. maps.
    StatMap.modelname = roiTs{1}.modelname;
    xyz = double(roiTs{1}.coords);  % make sure to be double, to avoid troubles on sub2ind().
    %sz = [size(curImg.dat,1),size(curImg.dat,2),size(curImg.dat,3)];
    sz  = [size(roiTs{1}.ana,1),size(roiTs{1}.ana,2),size(roiTs{1}.ana,3)];
    StatMap.vmap = zeros([sz length(roiTs{1}.p)]);
    StatMap.pmap = ones([sz length(roiTs{1}.p)]);
    StatMap.vmax = zeros(1,length(roiTs{1}.p));
    ind = sub2ind(sz,xyz(:,1),xyz(:,2),xyz(:,3));
    for iModel = 1:length(roiTs{1}.p),
      tmpvmap = zeros(sz);
      tmppmap = ones(sz);
      tmpvmap(ind) = roiTs{1}.statv{iModel}(:);
      tmppmap(ind) = roiTs{1}.p{iModel}(:);
      StatMap.vmap(:,:,:,iModel) = tmpvmap;
      StatMap.pmap(:,:,:,iModel) = tmppmap;
      if ~isempty(strfind(roiTs{1}.modelname{iModel},'corr')),
        Statmap.vmax(iModel) = 1;
      else
        Statmap.vmax(iModel) = max(roiTs{1}.statv{iModel}(:));
      end
    end
  else
    modelname = {'none'};
    set(wgts.StatMapCmb,'String',modelname);
    set(wgts.StatMapCmb,'Value',1);
    set(wgts.StatMapCmb,'Tag','StatMapCmb');
  end
  setappdata(wgts.main,'roiTs',roiTs);
  setappdata(wgts.main,'StatMap',StatMap);

  % SET SLIDER PROPERTIES: +0.01 TO PREVENT ERROR
  nslices = size(curImg.dat,3);
  set(wgts.SliceBarSldr,'Min',1,'Max',nslices+0.01,'Value',1);
  % NOTE THAT SLIDER STEP IS NORMALIZED FROM 0 to 1, NOT MIN/MAX
  if nslices > 1,
    sstep = [1/(nslices-1), 2/(nslices-1)];
  else
    sstep = [1 2];
  end
  set(wgts.SliceBarSldr,'SliderStep',sstep);

  
  % ---------------------------------------------------------------------
  % SET GRPROI/ROI
  % ---------------------------------------------------------------------
  selgrproi = find(strcmp(get(wgts.GrpRoiSelCmb,'String'),grp.grproi));
  if isempty(selgrproi),  selgrproi = 1;  end
  set(wgts.GrpRoiSelCmb,'Value',selgrproi(1));
  Main_Callback(wgts.GrpRoiSelCmb,'load',[]);
  Main_Callback(wgts.RoiSelCmb,'roi-select',[]);

  % INVOKE THIS TO DRAW IMAGES
  Main_Callback(wgts.SliceBarSldr,'slice-slider',[]);
 
 
 case {'edit-session'}
  mguiEdit(which(ses.name));
  
 case {'edit-group'}
  grpname = get(wgts.GrpNameBut,'String');
  mguiEdit(which(ses.name),strcat('GRP.',grpname));
  
 case {'slice-slider'}		% HERE WE DISPLAY THE IMAGES
  if ~isfield(wgts,'ImageAxs') | ~isfield(wgts,'main'),  return;  end    % why this happens?
  SLICE = round(get(wgts.SliceBarSldr,'Value'));
  set(wgts.SliceBarTxt,'String',sprintf('Slice: %d',SLICE));
  GAMMA = getappdata(wgts.main,'GAMMA');
  if get(wgts.GammaHoldCheck,'Value') == 0,
    set(wgts.GammaEdt,'String',num2str(GAMMA(SLICE)));
  end
  
  mroi('Main_Callback',wgts.main,'imgdraw');
  if isfield(curanaImg,'dat') & ~isempty(curanaImg.dat),
    set(wgts.ImageAxs,'xlim',[1,size(curanaImg.dat,1)],'ylim',[1,size(curanaImg.dat,2)]);
  end
  curImg = getappdata(wgts.main,'curImg');
  if isfield(curImg,'dat') & ~isempty(curImg.dat),
    set(wgts.Image2Axs,'xlim',[1,size(curImg.dat,1)],'ylim',[1,size(curImg.dat,2)]);
  end

 case {'imgdraw'}
  if ~isfield(wgts,'ImageAxs') | ~isfield(wgts,'main'),  return;  end    % why this happens?
  % ************* DRAWING OF THE ANATOMY IMAGE
  SLICE = round(get(wgts.SliceBarSldr,'Value'));
  RoiRoi = getappdata(wgts.main,'RoiRoi');
  RoiEle = getappdata(wgts.main,'RoiEle');
  RoiML  = getappdata(wgts.main,'RoiML');
  RoiAC  = getappdata(wgts.main,'RoiAC');
  figure(wgts.main);
  
  % ************* DRAWING OF THE ANATOMY IMAGE ****************************************
  GAMMA = str2num(get(wgts.GammaEdt,'String'));
  tmpanaimg = subScaleAnaImage(hObject,wgts,curanaImg.dat(:,:,SLICE));
  axes(wgts.ImageAxs); cla;
  mroidsp(tmpanaimg,0,GAMMA);
  
  daspect(wgts.ImageAxs,[2 2*curanaImg.ds(1)/curanaImg.ds(2) 1]);

  mdl = get(wgts.StatMapCmb,'String');
  mdl = mdl{get(wgts.StatMapCmb,'Value')};
  
  if ~strcmpi(mdl,'none'),
    StatMap  = getappdata(wgts.main,'StatMap');
    vthr     = str2num(get(wgts.StatVThrEdt,'String'));
    pthr     = str2num(get(wgts.StatPThrEdt,'String'));
    roinames = get(wgts.RoiSelCmb,'String');
    midx = find(strcmpi(StatMap.modelname,mdl));
    
    tmpscaleX = size(curanaImg.dat,1) / size(StatMap.vmap,1);
    tmpscaleY = size(curanaImg.dat,2) / size(StatMap.vmap,2);
    
    L=length(StatMap.modelname);
    for N = 1:length(StatMap.modelname),
      ofs = -L/2 + N;
      if ~strcmpi(mdl,'all') & N ~= midx,  continue;  end
      vmap = squeeze(StatMap.vmap(:,:,SLICE,N));
      pmap = squeeze(StatMap.pmap(:,:,SLICE,N));
      if pthr < 1,
        % Bonferroni
        if get(wgts.BonferroniCheck,'value') > 0,
          pthr = pthr / prod(size(vmap));
        end
        idx = find(pmap(:) > pthr);
        if ~isempty(idx),  vmap(idx) = 0;  end
      end
      
      cidx = find(strcmpi(roinames,StatMap.modelname{N}));
      if ~isempty(cidx),
        cidx = mod(cidx(1),length(MAPCOLORS)) + 1;
      else
        cidx = mod(N,length(MAPCOLORS)) + 1;
      end
      tmpcol = MAPCOLORS(cidx);
      [tmpx tmpy] = find(pmap < pthr);
      hold on;
      tmpx = tmpx * tmpscaleX;
      tmpy = tmpy * tmpscaleY;

      MODEL_MARKER_SIZE = 5;
      plot(tmpx+ofs,tmpy+ofs,'marker','.','markersize',MODEL_MARKER_SIZE,...
           'markerfacecolor',tmpcol,'markeredgecolor',tmpcol,...
           'linestyle','none');
    end
  end

  tmptxt = sprintf('Vox=[%g %g %g]mm',curanaImg.ds);
  text(0.01,-0.01,tmptxt,'units','normalized','color','y','VerticalAlignment','top');
  
  % DRAW ROIS
  axes(wgts.ImageAxs); 
  subDrawAnaROIs(wgts,RoiRoi,RoiEle,ses,SLICE,COLORS,RoiML,RoiAC);
  % some plotting function clears 'tag' of the axes !!!!!
  set(wgts.ImageAxs,'Tag','ImageAxs');  

  % ************* DRAWING OF THE EPI IMAGE *******************************************
  curImg = getappdata(wgts.main,'curImg');
  IMGDIMS = getappdata(wgts.main,'IMGDIMS');
  figure(wgts.main);
  axes(wgts.Image2Axs); cla;
  mroidsp(curImg.dat(:,:,SLICE,:),1,0,getappdata(wgts.main,'CurOp'));
  set(wgts.Image2Axs,'xlim',[1,size(curImg.dat,1)],'ylim',[1,size(curImg.dat,2)]);
  daspect(wgts.Image2Axs,[2 2*curImg.ds(1)/curImg.ds(2) 1]);
  % DRAW ROIs
  subDrawEpiROIs(wgts,RoiRoi,RoiEle,ses,SLICE,COLORS,IMGDIMS,RoiML,RoiAC);
  set(wgts.Image2Axs,'Tag','Image2Axs');
  tmptxt = sprintf('Vox=[%g %g %g]mm',curImg.ds);
  text(0.01,-0.01,tmptxt,'units','normalized','color','y','VerticalAlignment','top');

  
 case {'roidraw'}
  SLICE = round(get(wgts.SliceBarSldr,'Value'));
  RoiRoi = getappdata(wgts.main,'RoiRoi');
  RoiEle = getappdata(wgts.main,'RoiEle');
  RoiML  = getappdata(wgts.main,'RoiML');
  RoiAC  = getappdata(wgts.main,'RoiAC');
  delete(findobj(wgts.ImageAxs,'tag','roi'))
  subDrawAnaROIs(wgts,RoiRoi,RoiEle,ses,SLICE,COLORS,RoiML,RoiAC);


 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 case {'load'}
  % ---------------------------------------------------------------------
  % LOAD ROI IF EXISTS.
  % ---------------------------------------------------------------------
  GAMMA = 1.8;
  RoiFile = fullfile('.','Roi.mat');
  grproiname = get(wgts.GrpRoiSelCmb,'String');
  RoiVar = grproiname{get(wgts.GrpRoiSelCmb,'Value')};
  if exist(RoiFile,'file') & ~isempty(who('-file',RoiFile,RoiVar)),
    StatusPrint(hObject,cbname,'Loading "%s" from Roi.mat, please wait...',RoiVar);
    Roi = matsigload('Roi.mat',RoiVar);
    Roi = subValidateRoi(wgts,Roi,ses);
	if isfield(Roi,'roi'), RoiRoi = Roi.roi; else RoiRoi = {}; end;
	if isfield(Roi,'ele'), RoiEle = Roi.ele; else RoiEle = {}; end;
	if isfield(Roi,'midline'),  RoiML = Roi.midline; else RoiML = {}; end;
	if isfield(Roi,'acommisure'),  RoiAC = Roi.acommisure; else RoiAC = {}; end;
	StatusPrint(hObject,cbname,'Loaded Roi "%s" from Roi.mat',RoiVar);
    if isfield(Roi,'gamma'),  GAMMA = Roi.gamma;  end
  else
    RoiRoi = {};
    RoiEle = {};
    RoiML  = {};
    RoiAC  = {};
    StatusPrint(hObject,cbname,'"%s" not found in Roi.mat',RoiVar);
  end
  % set gamma values for each slices
  nslices = size(curImg.dat,3);
  if length(GAMMA) ~= nslices,
    GAMMA = ones(1,nslices)*GAMMA(1);
  end
  SLICE = round(get(wgts.SliceBarSldr,'Value'));
  set(wgts.GammaEdt,'String',num2str(GAMMA(SLICE)));
  
  setappdata(wgts.main,'RoiRoi',RoiRoi);
  setappdata(wgts.main,'RoiEle',RoiEle);
  setappdata(wgts.main,'RoiML',RoiML);
  setappdata(wgts.main,'RoiAC',RoiAC);
  setappdata(wgts.main,'GAMMA',GAMMA);
  
  % no 'redraw' to avoid Matlab warning, 
  % if redraw needed, use 'load-redraw' below.
  %Main_Callback(wgts.GrpRoiSelCmb,'redraw',[]);
  
  
 case {'load-redraw'}
  Main_Callback(wgts.GrpRoiSelCmb,'load',[]);
  Main_Callback(wgts.GrpRoiSelCmb,'redraw',[]);
  %mroi('Main_Callback',wgts.main,'redraw');
  

 case {'save'}
  tcAvgImg  = getappdata(wgts.main,'tcAvgImg');
  anaImg    = getappdata(wgts.main,'anaImg');
  GAMMA     = getappdata(wgts.main,'GAMMA');
  Roi = mroisct(ses,grp,tcAvgImg,anaImg,GAMMA);
  Roi.roi = getappdata(wgts.main,'RoiRoi');
  Roi.ele = getappdata(wgts.main,'RoiEle');
  Roi.midline    = getappdata(wgts.main,'RoiML');
  Roi.acommisure = getappdata(wgts.main,'RoiAC');
  if isempty(Roi.roi),
    StatusPrint(hObject,cbname,'no ROI to save');
    return;
  end
  % mroisct(ses,grp,tcAvgImg,anaImg) returns the following Roi-fields
  % ====================================================
  % Roi.session Roi.grpname Roi.exps Roi.anainfo  Roi.roi.names
  % Roi.dir  Roi.dsp  Roi.grp  Roi.usr
  % Roi.ana  Roi.img  Roi.ds   Roi.dx		
  % Roi.roi  Roi.ele	
  % Roi.roi.coords --- ARE ADDED BY THE FOLLOWING LINES
  % [x,y] = find(Roi.roi{RoiNo}.mask);
  % Roi.roi{RoiNo}.coords = [x y ones(length(x),1)*Roi.roi{RoiNo}.slice];
  % 26.04.04 -- The cooordinates will be added by the mareats
  % function which selects the time series of interest. In all
  % other positions, the .coords will be eliminated. It's
  % maintenance along the process is only nuisance, as the
  % information is used after mareats anyway...
  % ====================================================
  IMGDIMS = getappdata(wgts.main,'IMGDIMS');
  % Check whether tracer experiment or not, if it is, then use Roi.ana (int16)
  % as Roi.img, to save the size of Roi.mat:  120M-->12M for m02th1.
  if isfield(tcAvgImg,'dir') & isfield(tcAvgImg.dir,'scantype'),
    if strcmpi(tcAvgImg.dir.scantype,'mdeft') & ndims(tcAvgImg.dat) == 3,
      szana = size(Roi.ana);  szimg = size(Roi.img);
      if length(szana) == length(szana) & all(szana == szimg),
        % it is likely that this is a tracer experiment.
        Roi.img = Roi.ana;  % ana supposed to be int16.
      end
    end
  end
  

  goto(ses); % MAKE SURE WE ARE IN THE SESSION DIRECTORY
  RoiFile = fullfile('.','Roi.mat');
  % grproiname = grp.grproi;
  grproiname = get(wgts.GrpRoiSelCmb,'String');
  grproiname = grproiname{get(wgts.GrpRoiSelCmb,'Value')};
  eval(sprintf('%s = Roi;',grproiname));
  StatusPrint(hObject,cbname,'Saving "%s" to "%s", please wait...',grproiname,RoiFile);
  if exist(RoiFile,'file'),
    copyfile(RoiFile,sprintf('%s.bak',RoiFile),'f');
    if all(strcmp(who('-file',RoiFile),grproiname)),
      % only "grproiname" in RoiFile
      save(RoiFile,grproiname);
    else
      % need to 'append' since RoiFile has other stuffs.
      save(RoiFile,grproiname,'-append');
    end
  else
    save(RoiFile,grproiname);
  end
  StatusPrint(hObject,cbname,'"%s" saved to "%s"',grproiname,RoiFile);

 case {'roi-select'}
  roiname = get(wgts.RoiSelCmb,'String');
  roiname = roiname{get(wgts.RoiSelCmb,'Value')};
  % set 'RoiAction' to 'no action'
  actions = get(wgts.RoiActCmb,'String');
  idx = find(strcmpi(actions,'no action'));
  set(wgts.RoiActCmb,'Value',idx);
  
 case {'roi-select-redraw'}
  % redraw rois
  Main_Callback(wgts.SliceBarSldr,'roi-select',[]);
  Main_Callback(wgts.SliceBarSldr,'roidraw',[]);
  

  % MENU HANDLING
 case {'edit-cb'}
  % edit callback functions
  token = get(hObject,'Label');
  if ~isempty(token),
    mguiEdit(which('mroi'),sprintf('function %s(hObject',token));
  end
 case {'exit'}
  if ishandle(wgts.main), close(wgts.main);  end
  return;

 case {'grp-select', 'group-select'}
  grpname = get(wgts.GrpSelCmb,'String');
  grpname = grpname{get(wgts.GrpSelCmb,'Value')};
  grp = getgrp(ses,grpname);
  setappdata(wgts.main,'Grp',grp);
  mroi('Main_Callback',wgts.main,'init');
  mroi('Main_Callback',wgts.main,'redraw');
 
 case {'grproi-select'}
  roiset  = get(wgts.GrpRoiSelCmb,'String');
  roiset  = roiset{get(wgts.GrpRoiSelCmb,'Value')};
  grpname = get(wgts.GrpSelCmb,'String');
  for N = 1:length(grpname),
    grp = getgrp(ses,grpname{N});
    if strcmpi(grp.grproi,roiset),
      set(wgts.GrpSelCmb,'value',N);
      mroi('Main_Callback',wgts.main,'grp-select');
      break;
    end
  end
  
 case {'set-gamma'}
  SLICE = round(get(wgts.SliceBarSldr,'Value'));
  value = str2num(get(wgts.GammaEdt,'String'));
  GAMMA = getappdata(wgts.main,'GAMMA');
  GAMMA(SLICE) = value;
  setappdata(wgts.main,'GAMMA',GAMMA);
  mroi('Main_Callback',wgts.main,'redraw');


 % =============================================================
 % EXECUTION OF CALLBACKS OF THE FUNCTION-BUTTONS (bNames)
 % PROCESSING AND DISPLAY OF IMAGES AND TIME SERIES
 % =============================================================
 case {'redraw'}
  Main_Callback(wgts.RoiSelCmb,'roi-select',[]);
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);

 case {'imgproc-select'}
  curImg = getappdata(wgts.main,'tcAvgImg');
  anaImg = getappdata(wgts.main,'anaImg');
  curanaImg = anaImg;
  imgpro = get(wgts.ImgProcCmb,'String');
  imgpro = imgpro{get(wgts.ImgProcCmb,'Value')};
  if ~isa(curImg.dat,'double'), curImg.dat = double(curImg.dat);  end

  switch lower(imgpro)
   case {'mean','mean-img'}
    curImg.dat = mean(curImg.dat,4);
   case {'median','median-img'}
    curImg.dat = median(curImg.dat,4);
   case {'max','max-img'}
    curImg.dat = max(curImg.dat,4);
   case {'std','std-img'}
    curImg.dat = std(curImg.dat,1,4);
   case {'stmstd-img'}
    curImg = tosdu(curImg);
    tmp = getbaseline(curImg,'dat','notblank');
    curImg.dat = mean(curImg.dat(:,:,:,tmp.ix),4);
    mask = curImg.dat;
    mask(find(mask<3)) = 1;
    mask(find(mask>=3)) = 1.5;
    for N=1:size(curImg.dat,3),
      curanaImg.dat(:,:,N) = anaImg.dat(:,:,N) .* ...
          imresize(mask(:,:,N),size(anaImg.dat(:,:,N)));
    end;
    setappdata(wgts.main,'curanaImg',curanaImg);
   case {'cv','cv-img'}
    m = mean(double(curImg.dat),4);
    curImg.dat = std(double(curImg.dat),1,4)./m;
  end
  
  setappdata(wgts.main,'curImg',curImg);
  setappdata(wgts.main,'curanaImg',curanaImg);
  setappdata(wgts.main, 'CurOp', imgpro);
  mroi('Main_Callback',wgts.main,'redraw');

 case {'zoomin-ana'}
  click = get(wgts.main,'SelectionType');
  if strcmp(click,'open'),
    %fprintf('zoomin-ana\n');
    hfig = wgts.main+1001;
    figure(hfig); clf;
    haxs = copyobj(wgts.ImageAxs,hfig);
    set(haxs,'Position',[ 0.1300 0.1100 0.7750 0.8150]);
    set(hfig,'Colormap',get(wgts.main,'Colormap'));
    title(haxs,sprintf('%s: GRP=%s ROI=%s (ana)',ses.name,grp.name,grp.grproi));
  end
  
 case {'zoomin-func'}
  click = get(wgts.main,'SelectionType');
  if strcmp(click,'open'),
    %fprintf('zoomin-func\n');
    hfig = wgts.main+1002;
    figure(hfig); clf;
    haxs = copyobj(wgts.Image2Axs,hfig);
    set(haxs,'Position',[ 0.1300 0.1100 0.7750 0.8150]);
    set(hfig,'Colormap',get(wgts.main,'Colormap'));
    title(haxs,sprintf('%s: GRP=%s ROI=%s (func)',ses.name,grp.name,grp.grproi));
  end
  
 case {'fig-toolbar'}
  %HandleVisibility = get(wgts.main,'HandleVisibility');
  %set(wgts.main,'HandleVisibility','on');
  if strcmpi(get(wgts.MenuFigToolbar,'checked'),'off'),
    set(wgts.main,'toolbar','figure');
    set(wgts.MenuFigToolbar,'checked','on');
  else
    set(wgts.main,'toolbar','none');
    set(wgts.MenuFigToolbar,'checked','off');
  end
  %set(wgts.main,'HandleVisibility',HandleVisibility);
 
 
 otherwise
  %fprintf('unknown\n');
  
end
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CALLBACK for ROI-ACTION
function Roi_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~strcmpi(eventdata,'roi-action'), return;  end
  
funcname = mfilename('fullpath');
[ST, I] = dbstack;
n = findstr(ST(I).name,'(');
cbname = ST(I).name(n+1:end-1);

wgts = guihandles(hObject);
actions = get(wgts.RoiActCmb,'String');
ROI_COMMAND = actions{get(wgts.RoiActCmb,'Value')};

% do the current action
% 30.05.05 YM:  I have to use "subRoiCommand" to support "replace" in "sticky" mode,
% otherwise, "replace" become "append" when move to the next slice in the old code.
switch lower(ROI_COMMAND),
 case {'append','replace'}
  % if command == 'replace', then clear the current ROIs.
  if strcmpi(ROI_COMMAND,'replace'),
    subRoiCommand('clear',wgts);
  end
  % adds ROIs
  subRoiCommand('append',wgts);
  % call recursively, if 'sticky' mode
  if get(wgts.Sticky,'Value'),
    curImg = getappdata(wgts.main,'curImg');
    nslices = size(curImg.dat,3);
    SLICE = round(get(wgts.SliceBarSldr,'Value')) + 1;
    if get(wgts.Sticky,'Value') & SLICE <= nslices,
      set(wgts.SliceBarTxt,'String',sprintf('Slice: %d',SLICE));
      set(wgts.SliceBarSldr,'Value',SLICE);
      mroi('Main_Callback',wgts.main,'redraw');
      idx = find(strcmpi(actions,ROI_COMMAND));
      set(wgts.RoiActCmb,'Value',idx);
      %mroi('Roi_Callback',wgts.RoiActCmb,'roi-action',[]);
      Roi_Callback(wgts.RoiActCmb,'roi-action',[]);
    end
  end
 
 otherwise
  subRoiCommand(ROI_COMMAND,wgts);
end

% set to 'no action'
idx = find(strcmpi(actions,'no action'));
set(wgts.RoiActCmb,'Value',idx);
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sub function of CALLBACK for ROI-ACTION
function subRoiCommand(COMMANDSTR,wgts)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ses = getappdata(wgts.main,'Ses');
grp = getappdata(wgts.main,'Grp');
COLORS = getappdata(wgts.main,'COLOR');

RoiRoi  = getappdata(wgts.main,'RoiRoi');
RoiEle  = getappdata(wgts.main,'RoiEle');
RoiML   = getappdata(wgts.main,'RoiML');
RoiAC   = getappdata(wgts.main,'RoiAC');
SLICE   = round(get(wgts.SliceBarSldr,'Value'));
roiname = get(wgts.RoiSelCmb,'String');
roiname = roiname{get(wgts.RoiSelCmb,'Value')};
actions = get(wgts.RoiActCmb,'String');

% reset the mouse event to avoid matlab returns
% a funny state of it...
set(wgts.main,'SelectionType','normal');

axes(wgts.ImageAxs);

switch lower(COMMANDSTR),
 case {'append'}
  % disable widgets
  set(wgts.RoiSelCmb,'Enable','off');
  set(wgts.RoiActCmb,'Enable','off');
  set(wgts.RoiLoadBtn,'Enable','off');
  set(wgts.RoiSaveBtn,'Enable','off');

  IMGDIMS = getappdata(wgts.main,'IMGDIMS');
  
  if all(IMGDIMS.ana == IMGDIMS.epi),
    SAME_DIMS = 1;
  else
    SAME_DIMS = 0;
  end

  cidx = find(strcmpi(ses.roi.names,roiname));
  cidx = mod(cidx(1),length(COLORS)) + 1;
  while 1,
    % use 'timer' function to modify the cusor
    tmpcursor = get(wgts.RoiCursorCmb,'String');
    tmpcursor = tmpcursor{get(wgts.RoiCursorCmb,'Value')};
    tobj = timer('TimerFcn',sprintf('mroi_cursor(''%s'');',tmpcursor),...
                'StartDelay',0.2);
    start(tobj);
    % get roi
    try,
      %[anamask,anapx,anapy] = roipoly;
      [anamask,anapx,anapy] = roipoly_71;
    catch
      % Note that Matlab 7.5 roipoly() will crash by right-click.
      % check user interaction
      click = get(wgts.main,'SelectionType');
      if strcmpi(click,'alt'),
        wait(tobj);  delete(tobj);
        break;
      else
        lasterr
      end
    end
    % delete the timer object and restore the cursor
    wait(tobj);  delete(tobj);
    
    % check user interaction
    click = get(wgts.main,'SelectionType');

    if strcmpi(click,'extend'),
      set(wgts.Sticky,'Value',0);
      %fprintf('click-extend');
      break;
    elseif strcmpi(click,'alt'),
      %fprintf('click-alt');
      break;
    else
      %fprintf('click-%s',click);
    end;

    % check size of poly, if very small ignore it.
    %length(anapx), length(anapy)
    if length(anapx)*length(anapy) < 1,  break;  end
    anamask = logical(anamask'); % transpose "mask"
    % now register the new roi
    N = length(RoiRoi) + 1;
    RoiRoi{N}.name  = roiname;
    RoiRoi{N}.slice = SLICE;
    %RoiRoi{N}.anamask  = anamask;
    %RoiRoi{N}.anapx    = anapx;
    %RoiRoi{N}.anapy    = anapy;
    RoiRoi{N}.px    = anapx * IMGDIMS.pxscale; 
    RoiRoi{N}.py    = anapy * IMGDIMS.pyscale; 
    if SAME_DIMS,
      RoiRoi{N}.mask     = anamask;
    else
      RoiRoi{N}.mask     = logical(round(imresize(double(anamask),IMGDIMS.epi)));
      %RoiRoi{N}.mask = poly2mask(RoiRoi{N}.px,RoiRoi{N}.py,IMGDIMS.epi(2),IMGDIMS.epi(1))';
    end

    % draw the polygon
    axes(wgts.ImageAxs); hold on;
    plot(anapx,anapy,'color',COLORS(cidx));
    x = min(anapx) - 4;  y = min(anapy) - 2; if x<0, x=1; end;
    %x = px(1) - 2;  y = py(1) - 2;
    text(x,y,roiname,'color',COLORS(cidx),'fontsize',8);
  end
  setappdata(wgts.main,'RoiRoi',RoiRoi);

  % enable widgets
  set(wgts.RoiSelCmb,'Enable','on');
  set(wgts.RoiActCmb,'Enable','on');
  set(wgts.RoiLoadBtn,'Enable','on');
  set(wgts.RoiSaveBtn,'Enable','on');
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);
  mroi_cursor('arrow');
  
 case {'replace'}
  subRoiCommand('clear',wgts);
  subRoiCommand('append',wgts);
  
 case {'clear'}
  % clear the current ROI in this slice
  IDX = [];
  for N = 1:length(RoiRoi),
    if ~strcmpi(RoiRoi{N}.name,roiname) | RoiRoi{N}.slice ~= SLICE,
      IDX(end+1) = N;
    end
  end
  setappdata(wgts.main,'RoiRoi',RoiRoi(IDX));
  % redraw image/ROIs
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);
  
 case {'clear all slices'}
  % clear the current ROI throughout slices
  IDX = [];
  for N = 1:length(RoiRoi),
    if ~strcmpi(RoiRoi{N}.name,roiname),
      IDX(end+1) = N;
    end
  end
  if isempty(IDX),
    RoiRoi = {};
  else
    RoiRoi = RoiRoi(IDX);
  end
  setappdata(wgts.main,'RoiRoi',RoiRoi);
  % redraw image/ROIs
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);

 case {'clear ac','clear anterior commisure','clear ant.commisure'}
  % look for corresonding indices for electrodes in this slice
  IDX = [];
  for N = 1:length(RoiAC),
    if RoiAC{N}.slice ~= SLICE,
      IDX(end+1) = N;
    end
  end
  if isempty(IDX),
    RoiAC = {};
  else
    RoiAC = RoiAC(IDX);
  end
  setappdata(wgts.main,'RoiAC',RoiAC);
  % redraw image/ROIs
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);

 case {'clear midline'}
  RoiML = getappdata(wgts.main,'RoiML');
  % look for corresonding indices for electrodes in this slice
  IDX = [];
  for N = 1:length(RoiML),
    if RoiML{N}.slice ~= SLICE,
      IDX(end+1) = N;
    end
  end
  if isempty(IDX),
    RoiML = {};
  else
    RoiML = RoiML(IDX);
  end
  setappdata(wgts.main,'RoiML',RoiML);
  % redraw image/ROIs
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);
 
 case {'clear electrodes'}
  % look for corresonding indices for electrodes in this slice
  IDX = [];
  for N = 1:length(RoiEle),
    if RoiEle{N}.slice ~= SLICE,
      IDX(end+1) = N;
    end
  end
  if isempty(IDX),
    RoiEle = {};
  else
    RoiEle = RoiEle(IDX);
  end
  setappdata(wgts.main,'RoiEle',RoiEle);
  % redraw image/ROIs
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);
 
 case {'midline'}
  % disable widgets
  set(wgts.RoiSelCmb,'Enable','off');
  set(wgts.RoiActCmb,'Enable','off');
  set(wgts.RoiLoadBtn,'Enable','off');
  set(wgts.RoiSaveBtn,'Enable','off');
  % clear the points first
  % look for corresonding indices for electrodes in this slice
  IDX = [];
  for N = 1:length(RoiML),
    if RoiML{N}.slice ~= SLICE,
      IDX(end+1) = N;
    end
  end
  if isempty(IDX),
    RoiML = {};
  else
    RoiML = RoiML(IDX);
  end
  setappdata(wgts.main,'RoiML',RoiML);
  % redraw image/ROIs
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);
  IMGDIMS = getappdata(wgts.main,'IMGDIMS');
  
  % This works too, but [y, x] = myginput(1,'fleur');
  % impixel is better for pixel coordinates
  for N = 1:1,
    % use 'timer' function to modify the cusor
    tmpcursor = get(wgts.RoiCursorCmb,'String');
    tmpcursor = tmpcursor{get(wgts.RoiCursorCmb,'Value')};
    tobj= timer('TimerFcn',sprintf('mroi_cursor(''%s'');',tmpcursor),...
                'StartDelay',0.1);
    start(tobj);
    % get the electrode position
    [x, y] = ginput(1);
    % delete the timer object and restore the cursor
    delete(tobj);  mroi_cursor('arrow');
    
    % check user interaction
    click = get(wgts.main,'SelectionType');
    if strcmp(click,'alt'),  continue;  end
    % check the size
    if isempty(x),  continue;  end
    K = length(RoiML) + 1;
    RoiML{K}.ele   = N;
    RoiML{K}.slice = SLICE;
    RoiML{K}.anax  = x;
    RoiML{K}.anay  = y;
    RoiML{K}.x  = round(RoiML{K}.anax * IMGDIMS.pxscale);
    RoiML{K}.y  = round(RoiML{K}.anay * IMGDIMS.pyscale);
    % plot the position
    axes(wgts.ImageAxs); hold on;
    plot(x,y,'yx','markersize',12);
    text(x-5,y-5,'ML','color','y','fontsize',8);
  end
  set(wgts.ImageAxs,'tag','ImageAxs');
  setappdata(wgts.main,'RoiML',RoiML);
  % enable widgets
  set(wgts.RoiSelCmb,'Enable','on');
  set(wgts.RoiActCmb,'Enable','on');
  set(wgts.RoiLoadBtn,'Enable','on');
  set(wgts.RoiSaveBtn,'Enable','on');
 

 case {'ant.commisure'}
  % disable widgets
  set(wgts.RoiSelCmb,'Enable','off');
  set(wgts.RoiActCmb,'Enable','off');
  set(wgts.RoiLoadBtn,'Enable','off');
  set(wgts.RoiSaveBtn,'Enable','off');
  % clear the points first
  % look for corresonding indices for electrodes in this slice
  IDX = [];
  for N = 1:length(RoiAC),
    if RoiAC{N}.slice ~= SLICE,
      IDX(end+1) = N;
    end
  end
  if isempty(IDX),
    RoiAC = {};
  else
    RoiAC = RoiAC(IDX);
  end
  setappdata(wgts.main,'RoiAC',RoiAC);
  % redraw image/ROIs
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);
  IMGDIMS = getappdata(wgts.main,'IMGDIMS');
  
  % This works too, but [y, x] = myginput(1,'fleur');
  % impixel is better for pixel coordinates
  for N = 1:1,
    % use 'timer' function to modify the cusor
    tmpcursor = get(wgts.RoiCursorCmb,'String');
    tmpcursor = tmpcursor{get(wgts.RoiCursorCmb,'Value')};
    tobj= timer('TimerFcn',sprintf('mroi_cursor(''%s'');',tmpcursor),...
                'StartDelay',0.1);
    start(tobj);
    % get the electrode position
    [x, y] = ginput(1);
    % delete the timer object and restore the cursor
    delete(tobj);  mroi_cursor('arrow');
    
    % check user interaction
    click = get(wgts.main,'SelectionType');
    if strcmp(click,'alt'),  continue;  end
    % check the size
    if isempty(x),  continue;  end
    K = length(RoiAC) + 1;
    RoiAC{K}.ele   = N;
    RoiAC{K}.slice = SLICE;
    RoiAC{K}.anax  = x;
    RoiAC{K}.anay  = y;
    RoiAC{K}.x  = round(RoiAC{K}.anax * IMGDIMS.pxscale);
    RoiAC{K}.y  = round(RoiAC{K}.anay * IMGDIMS.pyscale);
    % plot the position
    axes(wgts.ImageAxs); hold on;
    plot(x,y,'yx','markersize',12);
    text(x-5,y-5,'AC','color','y','fontsize',8);
  end
  set(wgts.ImageAxs,'tag','ImageAxs');
  setappdata(wgts.main,'RoiAC',RoiAC);
  % enable widgets
  set(wgts.RoiSelCmb,'Enable','on');
  set(wgts.RoiActCmb,'Enable','on');
  set(wgts.RoiLoadBtn,'Enable','on');
  set(wgts.RoiSaveBtn,'Enable','on');
  
 case {'electrodes'}
  if ~isfield(grp,'hardch') || isempty(grp.hardch),
    % set to 'no action'
    idx = find(strcmpi(actions,'no action'));
    set(wgts.RoiActCmb,'Value',idx);
    return;
  end
  
  % disable widgets
  set(wgts.RoiSelCmb,'Enable','off');
  set(wgts.RoiActCmb,'Enable','off');
  set(wgts.RoiLoadBtn,'Enable','off');
  set(wgts.RoiSaveBtn,'Enable','off');
  % clear the points first
  % look for corresonding indices for electrodes in this slice
  IDX = [];
  for N = 1:length(RoiEle),
    if RoiEle{N}.slice ~= SLICE,
      IDX(end+1) = N;
    end
  end  
  if isempty(IDX),
    RoiEle = {};
  else
    RoiEle = RoiEle(IDX);
  end
  setappdata(wgts.main,'RoiEle',RoiEle);
  % redraw image/ROIs
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);
  IMGDIMS = getappdata(wgts.main,'IMGDIMS');
  
  % This works too, but [y, x] = myginput(1,'fleur');
  % impixel is better for pixel coordinates
  for N = 1:length(grp.hardch),
    % use 'timer' function to modify the cusor
    tmpcursor = get(wgts.RoiCursorCmb,'String');
    tmpcursor = tmpcursor{get(wgts.RoiCursorCmb,'Value')};
    tobj= timer('TimerFcn',sprintf('mroi_cursor(''%s'');',tmpcursor),...
                'StartDelay',0.1);
    start(tobj);
    % get the electrode position
    [x, y] = ginput(1);
    % delete the timer object and restore the cursor
    delete(tobj);  mroi_cursor('arrow');
    
    % check user interaction
    click = get(wgts.main,'SelectionType');
    if strcmp(click,'alt'),  continue;  end
    % check the size
    if isempty(x),  continue;  end
    K = length(RoiEle) + 1;
    RoiEle{K}.ele   = N;
    RoiEle{K}.slice = SLICE;
    RoiEle{K}.anax  = x;
    RoiEle{K}.anay  = y;
    RoiEle{K}.x  = round(RoiEle{K}.anax * IMGDIMS.pxscale);
    RoiEle{K}.y  = round(RoiEle{K}.anay * IMGDIMS.pyscale);
    % plot the position
    axes(wgts.ImageAxs); hold on;
    plot(x,y,'y+','markersize',12);
    VALS = sprintf('e%d[%4.1f,%4.1f]', N, x, y);
    text(x-5,y-5,VALS,'color','y','fontsize',8);
  end
  set(wgts.ImageAxs,'tag','ImageAxs');
  setappdata(wgts.main,'RoiEle',RoiEle);
  % enable widgets
  set(wgts.RoiSelCmb,'Enable','on');
  set(wgts.RoiActCmb,'Enable','on');
  set(wgts.RoiLoadBtn,'Enable','on');
  set(wgts.RoiSaveBtn,'Enable','on');
 
 case {'complete clear'}
  % clear ROIs completely
  setappdata(wgts.main,'RoiRoi',{});
  setappdata(wgts.main,'RoiEle',{});
  setappdata(wgts.main,'RoiML',{});
  setappdata(wgts.main,'RoiAC',{});
  % redraw image/ROIs
  Main_Callback(wgts.SliceBarSldr,'imgdraw',[]);

 case {'reset cursor'}
  set(wgts.main,'Pointer','arrow');
  
end  
  
return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function StatusPrint(hObject,fname,varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tmp = sprintf(varargin{:});
tmp = sprintf('(%s): %s',fname,tmp);
wgts = guihandles(hObject);
set(wgts.StatusField,'String',tmp);
drawnow;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Print_Callback(hObject,eventdata,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
funcname = mfilename('fullpath');
[ST, I] = dbstack;
n = findstr(ST(I).name,'(');
cbname = ST(I).name(n+1:end-1);

wgts = guihandles(hObject);

ses = getappdata(wgts.main,'Ses');
grp = getappdata(wgts.main,'Grp');
goto(ses);
tmp = gettimestring;
tmp(findstr(tmp,':')) = '_';
OutFile = sprintf('%s_%s_%s',ses.name,grp.name,tmp);
StatusPrint(hObject,cbname,OutFile);

orient landscape;
set(gcf,'PaperPositionMode',	'auto');
set(gcf,'PaperType',			'A4');
set(gcf,'InvertHardCopy',		'off');

if 0,
papersize = get(gcf, 'PaperSize');
width = papersize(1) * 0.8;
height = papersize(2) * 0.8;
left = (papersize(1)- width)/2;
bottom = (papersize(2)- height)/2;
myfiguresize = [left, bottom, width, height]
set(gcf, 'PaperPosition', myfiguresize);
end;

switch lower(eventdata),
 case {'print'},
  % print the figure
  print;
 case {'printdlg'},
  % show a printer-setup dialog
  printdlg;
 case {'pagesetupdlg'},
  % show a page-setup dialog
  pagesetupdlg;
 case {'meta'}
  % export as meta
  print('-dmeta',OutFile);
 case {'tiff'}
  % export as tiff
  print('-dtiff',OutFile);
 case {'jpeg'}
  % export as jpeg
  print('-djpeg',OutFile);
 case {'copy-figure'}
  % copy the figure to the clipboard
  print('-dmeta');
  
 otherwise
  StatusPrint(hObject,cbname,'Wrong Printer Parameters');
end;
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SetFunBtn(hMain,HX,HY,TagName,Label)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cb = sprintf('mroi(''Main_Callback'',gcbo,''%s'',guidata(gcbo))',...
            Label);
POS = [HX HY 16 1.55];
COL = [1 .9 .6];
H = uicontrol(...
    'Parent',hMain,'Style','PushButton',...
    'Units','char','Position',POS,'Callback',cb,...
    'Tag',TagName,'String',Label,...
    'TooltipString','Process Data (Filter Operations)','FontWeight','bold',...
    'ForegroundColor',[0 0 .1],'BackgroundColor',COL);
evalin('caller',sprintf('%s=H;',TagName));

return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SetRadioBtn(hMain,HX,HY,TagName,Label)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cb = sprintf('mroi(''RadioButton_Callback'',gcbo,''%s'',guidata(gcbo))',...
            TagName);
POS = [HX HY 18 1.52];
FCOL = [1 0 0];
BCOL = [1 1 .8];
H = uicontrol(...
'Parent',hMain,...
'Style','radiobutton',...
'Units','characters',...
'String',Label,...
'Position',POS,...
'BackgroundColor',BCOL,...
'ForegroundColor',FCOL,...
'Callback',cb,...
'ListboxTop',0,...
'TooltipString','',...
'Tag',TagName);
evalin('caller',sprintf('%s=H;',TagName));


return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to validate ROI structure to most updated format.
function Roi = subValidateRoi(wgts,Roi,ses);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(Roi.roi),  return;  end

IMGDIMS = getappdata(wgts.main,'IMGDIMS');
% remove non-sense ROIs
selidx = [1:length(Roi.roi)];
for N = 1:length(Roi.roi),
  if ~isfield(Roi.roi{N},'mask') | isempty(find(Roi.roi{N}.mask(:) > 0)),
    selidx(N) = NaN;
  end
end
selidx = find(~isnan(selidx));
if length(selidx) ~= length(Roi.roi),
  Roi.roi = Roi.roi(selidx);
end

% 1. fix upper/lower case of ROI names
% 2. scale px/py if needed, now .px/py is for functional image, no longer for anatomy.
for N = 1:length(Roi.roi),
  % FIX ROINAME'S UPPER/LOWER CASE, sometime lgn renamed as LGN and so on...
  idx = find(strcmpi(ses.roi.names,Roi.roi{N}.name));
  if ~isempty(idx),
    Roi.roi{N}.name = ses.roi.names{idx(1)};
  end
  % SCALE PX/PY
  [px,py] = find(Roi.roi{N}.mask);
  % +1 may need due to imresize() operated mask.
  if floor(max(Roi.roi{N}.px)) > max(px)+1 & floor(max(Roi.roi{N}.py)) > max(py)+1,
    % likely px/py is for anatomy and not for functional image.
    % first convert for the current anatomy
    Roi.roi{N}.px      = Roi.roi{N}.px * IMGDIMS.ana(1) / IMGDIMS.anaorig(1);
    Roi.roi{N}.py      = Roi.roi{N}.py * IMGDIMS.ana(2) / IMGDIMS.anaorig(2);
    % not convert anatomy to functional
    Roi.roi{N}.px      = Roi.roi{N}.px * IMGDIMS.pxscale;
    Roi.roi{N}.py      = Roi.roi{N}.py * IMGDIMS.pyscale;
  end
  if isfield(Roi.roi{N},'anamask'),
    Roi.roi{N} = rmfield(Roi.roi{N},'anamask');
  end
  Roi.roi{N}.mask = logical(Roi.roi{N}.mask);
end

% scale anax/anay, if needed
if isfield(Roi,'ele'),
  for N = 1:length(Roi.ele),
    tmpx = round(Roi.ele{N}.anax * IMGDIMS.pxscale);
    if tmpx ~= Roi.ele{N}.anax,
      Roi.ele{N}.anax = Roi.ele{N}.x / IMGDIMS.pxscale;
      Roi.ele{N}.anay = Roi.ele{N}.y / IMGDIMS.pyscale;
    end
  end
end
  
  
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to draw anatomical image
function anaimg = subScaleAnaImage(hObject,wgts,anaimg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
anasclstr = get(wgts.AnaScaleEdt,'String');
anaimg = double(anaimg);
if get(wgts.AutoAnaScale,'Value'),
  AnaScale = [min(anaimg(:)) max(anaimg(:))*0.8];
  set(wgts.AnaScaleEdt,'String',sprintf('%.1f  %.1f',AnaScale(1),AnaScale(2)));
  setappdata(wgts.main,'AnaScale',AnaScale);
else
  anasclstr = strrep(anasclstr,'[','');
  anasclstr = strrep(anasclstr,'[','');
  if length(str2num(anasclstr)) == 2,
    AnaScale = str2num(anasclstr);
    setappdata(wgts.main,'AnaScale',AnaScale);
  else
    [ST, I] = dbstack;
    n = findstr(ST(I).name,'(');
    cbname = ST(I).name(n+1:end-1);
    StatusPrint(hObject,cbname,'WARNING: Invalid AnaScale');
    AnaScale = getappdata(wgts.main,'AnaScale');
  end
end
 
if isempty(AnaScale),
  minv = min(anaimg(:));  maxv = max(anaimg(:));
else
  minv = AnaScale(1);     maxv = AnaScale(2);
end

% scale image 0 to 1
anaimg = double(anaimg);
anaimg = (anaimg - minv) ./ (maxv - minv);
anaimg(find(anaimg(:) < 0)) = 0;
anaimg(find(anaimg(:) > 1)) = 1;

return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to draw ROIs for anatomy
function subDrawAnaROIs(wgts,RoiRoi,RoiEle,ses,SLICE,COLORS,RoiML,RoiAC)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
RoiDraw = get(wgts.RoiDrawCmb,'Value');
if RoiDraw == 3, return;  end
if ~ishandle(wgts.ImageAxs),  return;  end
IMGDIMS = getappdata(wgts.main,'IMGDIMS');
CurRoiName = get(wgts.RoiSelCmb,'String');
CurRoiName = CurRoiName{get(wgts.RoiSelCmb,'Value')};
for N = 1:length(RoiRoi),
  if RoiRoi{N}.slice ~= SLICE, continue;  end
  if RoiDraw == 2 & ~strcmpi(RoiRoi{N}.name,CurRoiName),  continue;  end
  roiname = RoiRoi{N}.name;
  px      = RoiRoi{N}.px / IMGDIMS.pxscale;
  py      = RoiRoi{N}.py / IMGDIMS.pyscale;
  % draw the polygon
  axes(wgts.ImageAxs); hold on;
  cidx = find(strcmpi(ses.roi.names,roiname));
  if isempty(cidx),  cidx = 1;  end
  cidx = mod(cidx(1),length(COLORS)) + 1;
  if isempty(px) | isempty(py),
    [px,py] = find(imresize(double(RoiRoi{N}.mask),IMGDIMS.ana));
    plot(px,py,'color',COLORS(cidx),'linestyle','none',...
         'marker','s','markersize',1.5,'tag','roi',...
         'markeredgecolor','none','markerfacecolor',COLORS(cidx));
  else
    ROI_LINE_WIDTH = 3;
    %plot(px,py,'color','w','tag','roi','linewidth',ROI_LINE_WIDTH); hold on;
    %plot(px,py,'color',COLORS(cidx),'tag','roi','linewidth',1.5);
    plot(px,py,'color',COLORS(cidx),'tag','roi');
    hold off;
  end;
  x = min(px) - 4;  y = min(py) - 2; if x<0, x=1; end;
  % x = px(1) - 2;  y = py(1) - 2;
  text(x,y,roiname,'color',COLORS(cidx),'fontsize',10,'tag','roi','fontweight','bold');
end
% draw electrodes
for N = 1:length(RoiEle)
  if RoiEle{N}.slice ~= SLICE, continue;  end
  ele = RoiEle{N}.ele;
  x   = RoiEle{N}.anax;
  y   = RoiEle{N}.anay;
  % plot the position
  axes(wgts.ImageAxs); hold on;
  plot(x,y,'y+','markersize',12);
  VALS = sprintf('e%d[%4.1f,%4.1f]', ele, x, y);
  text(x-5,y-5,VALS,'color','y','fontsize',8,'tag','roi');
end  

% draw midline
for N = 1:length(RoiML)
  if RoiML{N}.slice ~= SLICE, continue;  end
  ele = RoiML{N}.ele;
  x   = RoiML{N}.anax;
  y   = RoiML{N}.anay;
  % plot the position
  axes(wgts.ImageAxs); hold on;
  plot(x,y,'yx','markersize',12);
  text(x-5,y-5,'ML','color','y','fontsize',8,'tag','roi');
end  
% draw ant.commisure
for N = 1:length(RoiAC)
  if RoiAC{N}.slice ~= SLICE, continue;  end
  ele = RoiAC{N}.ele;
  x   = RoiAC{N}.anax;
  y   = RoiAC{N}.anay;
  % plot the position
  axes(wgts.ImageAxs); hold on;
  plot(x,y,'yx','markersize',12);
  text(x-5,y-5,'AC','color','y','fontsize',8,'tag','roi');
end  


set(wgts.ImageAxs,'YDir','reverse');

return;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to draw ROIs for functional image
function subDrawEpiROIs(wgts,RoiRoi,RoiEle,ses,SLICE,COLORS,IMGDIMS,RoiML,RoiAC)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%RoiDraw = get(wgts.RoiDrawCmb,'Value');
for N = 1:length(RoiRoi),
  if RoiRoi{N}.slice ~= SLICE, continue;  end
  roiname = RoiRoi{N}.name;

  % 01.06.04 TO SEE THE RoiDef_Act !!!
  if ~ishandle(wgts.Image2Axs),  continue;  end
  axes(wgts.Image2Axs); hold on;
    
  SEE_USERROI_AND_XCOR_RESULT = 0;    %Debugging
  if SEE_USERROI_AND_XCOR_RESULT,
    DIMS = [size(tcAvgImg.dat,1) size(tcAvgImg.dat,2)];
    [maskx,masky] = find(RoiRoi{N}.mask);
    if all(size(Roi.roi{N}.mask)==DIMS),
      if ~isfield(anaImg,'EpiAnatomy') | ~anaImg.EpiAnatomy,
        % 06.06.05 YM: WHY SAVING ANATOMY IMAGES NOT MASK HERE?????
        if 0,          
          Roi.roi{N}.anamask = curanaImg.dat(:,:,SLICE);
        end
        continue;
      end;
    end;

    cidx = find(strcmpi(ses.roi.names,roiname));
    cidx = mod(cidx(1),length(COLORS)) + 1;
    plot(maskx,masky,'linestyle','none','marker','s',...
           'markersize',2,'markerfacecolor',COLORS(cidx),...
         'markeredgecolor',COLORS(cidx));
  end;
    
  if isempty(RoiRoi{N}.px) | isempty(RoiRoi{N}.py),
    [px,py] = find(RoiRoi{N}.mask);
  else
    px = RoiRoi{N}.px;
    py = RoiRoi{N}.py;
  end;
  % draw the polygon
  cidx = find(strcmpi(ses.roi.names,roiname));
  if isempty(cidx),  cidx = 1;  end
  cidx = mod(cidx(1),length(COLORS)) + 1;
  if isempty(RoiRoi{N}.px) | isempty(RoiRoi{N}.py),
    plot(px,py,'color',COLORS(cidx),'linestyle','none',...
         'marker','s','markersize',3,'markerfacecolor',COLORS(cidx));
  else
    plot(px,py,'color',COLORS(cidx));
  end;
  x = min(px) - 4;  y = min(py) - 2; if x<0, x=1; end;
  %x = px(1) - 2;  y = py(1) - 2;
  % text(x,y,roiname,'color',COLORS(cidx),'fontsize',8);
end
% draw electrodes
for N = 1:length(RoiEle)
  if RoiEle{N}.slice ~= SLICE, continue;  end
  ele = RoiEle{N}.ele;
  x   = RoiEle{N}.x;
  y   = RoiEle{N}.y;
  axes(wgts.Image2Axs); hold on;
  plot(x,y,'y+','markersize',12);
  VALS = sprintf('e%d[%4.1f,%4.1f]', ele, x, y);
  text(x-5,y-5,VALS,'color','y','fontsize',8);
end

% draw midline
for N = 1:length(RoiML)
  if RoiML{N}.slice ~= SLICE, continue;  end
  ele = RoiML{N}.ele;
  x   = RoiML{N}.x;
  y   = RoiML{N}.y;
  axes(wgts.Image2Axs); hold on;
  plot(x,y,'yx','markersize',12);
  text(x-5,y-5,'ML','color','y','fontsize',8);
end
% draw ant.commisure
for N = 1:length(RoiAC)
  if RoiAC{N}.slice ~= SLICE, continue;  end
  ele = RoiAC{N}.ele;
  x   = RoiAC{N}.x;
  y   = RoiAC{N}.y;
  axes(wgts.Image2Axs); hold on;
  plot(x,y,'yx','markersize',12);
  text(x-5,y-5,'AC','color','y','fontsize',8);
end

set(wgts.Image2Axs,'YDir','reverse');


return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION to average only stable images
function tcImg = subDoCentroidAverage(tcImg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

TCENT = mcentroid(tcImg.dat);
TCENT = TCENT';  % (xyz,t) --> (t,xyz)
  
m = mean(TCENT);
s = std(TCENT);

% to avoid "divide by zero"
idx = find(s == 0);
TCENT(idx,:) = 0;
s(idx) = 1;

for N = 1:3,
  TCENT(:,N) = (TCENT(:,N) - m(N)) / s(N);
end
TCENT = abs(TCENT);

if numel(tcImg.dat)*8 > 400e+6,
  idx = find(TCENT(:,1) < 2.0 & TCENT(:,2) < 2.0 & TCENT(:,3) < 2.0);
  imgsz = size(tcImg.dat);
  mdat = zeros(imgsz(1:3));
  Nlen = length(idx);
  for N = 1:length(idx),
    mdat = mdat + tcImg.dat(:,:,:,idx(N))/Nlen;
  end
  tcImg.dat = mdat;
else
  idx = find(TCENT(:,1) > 2.0 | TCENT(:,2) > 2.0 | TCENT(:,3) > 2.0);
  %fprintf('(%d/%d)',length(idx),size(tcImg.dat,4));
  if ~isempty(idx),
    tcImg.dat(:,:,:,idx) = [];
  end
  tcImg.dat = mean(tcImg.dat,4);
end
  
return;
