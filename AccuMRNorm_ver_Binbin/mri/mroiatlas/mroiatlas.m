function varargout = mroiatlas(varargin)
%MROIATLAS - GUI to generate transformed atlas matching with anatomical images.
%  MROIATLAS(Session,GrpName) generates transformed atlas which matches with
%  anatomical images. The program works like following.
%    1)  Define fiducial points with GUI.
%    2)  "TRANSFORM" button does following things.
%       mytform  = cp2tform(atlas_points,anatomy_points,METHOD)
%       newatlas = imtransform(atlas_rgb, mytform,...)
%    1) and 2) should be done for all slices.
%    3)  "SAVE" button saves transformed atlas as "(grproi)_atlasimg" in "mroiatlas_tform.mat".
%
%  EXAMPLE :
%    mroiatlas('i07541')
%
%  NOTE :
%    Note that imtransform() function requires coordinates in pixels
%    (not physical 'mm').
%
%  VERSION :
%    0.90 22.11.10 YM  pre-release
%    0.91 24.11.10 YM  improved UI, bug fix.
%    0.92 27.11.10 YM  supports displaying the result.
%    0.93 28.11.10 YM  improved UI, bug fix.
%    0.94 29.11.10 YM  supports EPI, marker etc.  bug fix.
%    0.95 11.04.11 YM  supports rat atlas.
%    0.96 12.04.11 YM  followup case of str2double('5.8') != 58*0.1
%    0.97 13.04.11 YM  exports ROI by rat atlas.
%    0.98 17.05.11 YM  atlas-labeling (rat) by button.
%    0.99 16.11.11 YM  supports grouped rois, can call paxrenamerois.m.
%    1.00 09.01.12 YM  udpated for new monkey atlas.
%    1.01 21.01.12 YM  makes backup like Roi.yyyymmdd_HHMM.mat.
%    1.02 03.03.12 YM  use mroiatlas_tform.mat instead of atlas_tform.mat.
%    1.03 17.12.12 YM  adapted for sesversion()>=2.
%    1.04 22.08.13 YM  supports "rat2013" atlas.
%
%  See also cp2tform imtransform mroi mroi_cursor

if ~nargin,  eval(sprintf('help %s',mfilename)); return;  end


% execute callback function then return;
if ischar(varargin{1}) && ~isempty(findstr(varargin{1},'Callback')),
  if nargout
    [varargout{1:nargout}] = feval(varargin{:});
  else
    feval(varargin{:});
  end
  return;
end


if isfield(varargin{1},'name'),
  SESSION = varargin{1}.name;
else
  SESSION = varargin{1};
end
if nargin > 1,  GrpExp = varargin{2};  end






% ====================================================================
% DISPLAY PARAMETERS FOR THE PLACEMENT OF AXIS ETC.
% ====================================================================
[scrW scrH] = getScreenSize('char');
figW = 250.0;   % 288x60.3 char. for 1440x900 pixels.
figH =  50.0;
figX =   1.0;
figY = scrH-figH-6;


hMain = figure(...
'Name','MROIATLAS: Graphical User Interface for ATLAS registration',...
    'NumberTitle','off', 'toolbar','figure',...
    'Tag','main', 'units','char', 'pos',[figX figY figW figH],...
    'HandleVisibility','on', 'Resize','on',...
    'DoubleBuffer','on', 'BackingStore','on', 'Visible','on',...
    'DefaultAxesFontSize',10,...
    'PaperPositionMode','auto', 'PaperType','A4', 'PaperOrientation', 'landscape');


% ====================================================================
% DISPLAY NAMES OF SESSION/GROUP
% ====================================================================
H = figH - 2;
IMGXOFS     = 3;
BKGCOL = get(hMain,'Color');

uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS H 20 1.5],...
    'String','Session: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
uicontrol(...
    'Parent',hMain,'Style','pushbutton',...
    'Units','char','Position',[IMGXOFS+12 H 25 1.5],...
    'String',SESSION,'FontWeight','bold','fontsize',9,...
    'HorizontalAlignment','left',...
    'Callback','mroiatlas(''Main_Callback'',gcbo,''edit-group'',[])',...
    'ForegroundColor',[1 1 0.1],'BackgroundColor',[0 0.5 0]);
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS+40 H 20 1.5],...
    'String','Group: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);

GrpSelCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[IMGXOFS+50 H 36 1.5],...
    'String',{'Group 1','Group 2'},...
    'Callback','mroiatlas(''Main_Callback'',gcbo,''grp-select'',[])',...
    'TooltipString','Group Selection',...
    'Tag','GrpSelCmb','FontWeight','Bold');
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS H-2 12 1.5],...
    'String','ROI Set: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
GrpRoiSelCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[IMGXOFS+12 H-1.75 25 1.25],...
    'String',{'RoiSet 1','RoiSet 2'},...
    'Callback','mroiatlas(''Main_Callback'',gcbo,''grproi-select'',[])',...
    'TooltipString','GrpRoi Selection',...
    'Tag','GrpRoiSelCmb','FontWeight','Bold');
clear GrpNames tmpvalue tmpgrp RoiSet GrpRoi;



uicontrol(...
    'Parent',hMain,'Style','pushbutton',...
    'Units','char','Position',[IMGXOFS+108 H 25 1.5],...
    'String','LOAD','FontWeight','bold','fontsize',9,...
    'HorizontalAlignment','left',...
    'Callback','mroiatlas(''Main_Callback'',gcbo,''load-redraw'',[])');
uicontrol(...
    'Parent',hMain,'Style','pushbutton',...
    'Units','char','Position',[IMGXOFS+135 H 25 1.5],...
    'String','SAVE','FontWeight','bold','fontsize',9,...
    'HorizontalAlignment','left',...
    'Callback','mroiatlas(''Main_Callback'',gcbo,''save-atlas'',[])');
ForceTransformCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[IMGXOFS+122 H-2 40 1.5],...
    'Tag','ForceTransformCheck','Value',0,...
    'String','Force Transformation on SAVE','FontWeight','bold',...
    'TooltipString','Foce transformation before saving','BackgroundColor',get(hMain,'Color'));
CallPaxrenameCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[IMGXOFS+90 H-3.5 40 1.5],...
    'Tag','CallPaxrenameCheck','Value',1,...
    'String','Call paxrenameroi()','FontWeight','bold',...
    'TooltipString','Call paxrenameroi() on saving.','BackgroundColor',get(hMain,'Color'));
CreateROICheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[IMGXOFS+122 H-3.5 40 1.5],...
    'Tag','CreateROICheck','Value',1,...
    'String','Create ROI on SAVE','FontWeight','bold',...
    'TooltipString','Create ROI on saving','BackgroundColor',get(hMain,'Color'));



H = H - 6;
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS H-0.3 20 1.5],...
    'String','Fiducial Point: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
PointActionCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[IMGXOFS+18 H 32 1.5],...
    'String',{'No Action' 'Append' 'Replace' 'Remove END' 'Remove X' 'Remove ALL' 'CLEAR ALL SLICES'},...
    'Value',1,...
    'Callback','mroiatlas(''Main_Callback'',gcbo,''point-action'',[])',...
    'TooltipString','Select action',...
    'Tag','PointActionCmb','FontWeight','Bold');
PointCursorCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[IMGXOFS+52 H 25 1.5],...
    'String',{'crosshair','black dot','white dot','circle','cross','fluer','fullcross','ibeam','arrow'},...
    'TooltipString','pointer',...
    'Tag','PointCursorCmb','Value',4,'FontWeight','Bold');
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS+6.5 H-2.3 20 1.5],...
    'String','marker: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
MarkerCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[IMGXOFS+18 H-2 13 1.5],...
    'String',{'+','o','*' '.' 'x' 'square' 'diamond' '^' 'v' '>' '<' 'pentagram' 'hexagram'},...
    'Callback','mroiatlas(''Main_Callback'',gcbo,''marker-type'',[])',...
    'TooltipString','maker type',...
    'Tag','MarkerCmb','Value',1,'FontWeight','Bold');
MarkerColorEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[IMGXOFS+32 H-2 18 1.5],...
    'Callback','mroiatlas(''Main_Callback'',gcbo,''marker-color'',guidata(gcbo))',...
    'String','1.0  1.0  0.0','Tag','MarkerColorEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','set marker color',...
    'FontWeight','bold');
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS+52 H-2.3 20 1.5],...
    'String','label: ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
TextColorEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[IMGXOFS+59 H-2 18 1.5],...
    'Callback','mroiatlas(''Main_Callback'',gcbo,''text-color'',guidata(gcbo))',...
    'String','0.3  0.3  1.0','Tag','TextColorEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','set text color',...
    'FontWeight','bold');



uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS+90 H-0.3 20 1.5],...
    'String','Trans. Type : ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
TransformCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[IMGXOFS+108 H 25 1.5],...
    'String',{'linear conformal','affine','projective','polynomial','piecewise linear','lwm'},...
    'Value',6,...
    'TooltipString','Transformation Type, see/help cp2tform.m',...
    'Tag','TransformCmb','FontWeight','Bold');
uicontrol(...
    'Parent',hMain,'Style','pushbutton',...
    'Units','char','Position',[IMGXOFS+135 H 25 1.5],...
    'String','TRANSFORM','FontWeight','bold','fontsize',9,...
    'HorizontalAlignment','left',...
    'Callback','mroiatlas(''Main_Callback'',gcbo,''transform'',[])');




% ====================================================================
% AXES
% ====================================================================
IMGYOFS = figH * 0.15;
IMGW = figW/3;
IMGH = 30;

H = IMGYOFS + IMGH + 0.2;
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS H-0.1 20 1.5],...
    'String','Anatomy : ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
UseEpiCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[IMGXOFS+15 H 25 1.5],...
    'Tag','UseEpiCheck','Value',0,...
    'Callback','mroiatlas(''Main_Callback'',gcbo,''redraw-ana'',guidata(gcbo))',...
    'String','Use EPI','FontWeight','bold',...
    'TooltipString','Use EPI as anatomy','BackgroundColor',get(hMain,'Color'));
AnaSliceEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[IMGXOFS+37, H 7 1.5],...
    'Callback','mroiatlas(''Main_Callback'',gcbo,''ana-slice'',guidata(gcbo))',...
    'String','1','Tag','AnaSliceEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','anatomy slice',...
    'FontWeight','bold');
AnaSldr = uicontrol(...
    'Parent',hMain,'Style','slider',...
    'Units','char','Position',[IMGXOFS+45 H IMGW*0.38 1.2],...
    'Callback','mroiatlas(''Main_Callback'',gcbo,''ana-slider'',guidata(gcbo))',...
    'Tag','AnaSldr','SliderStep',[1 4],'Value',1,'Min',1,'Max',2,...
    'TooltipString','anatomy slice');
AnaAxs = axes(...
    'Parent',hMain,'Tag','AnaAxs',...
    'Units','char','Color','k','layer','top',...
    'Position',[IMGXOFS IMGYOFS IMGW*0.92 IMGH],...
    'xticklabel','','yticklabel','','xtick',[],'ytick',[]);
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS IMGYOFS-2.7 35 1.5],...
    'String','Scale [min max] :','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
AnaScaleEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[IMGXOFS+22, IMGYOFS-2.5 25 1.5],...
    'Callback','mroiatlas(''Main_Callback'',gcbo,''redraw-ana'',guidata(gcbo))',...
    'String','','Tag','AnaScaleEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','anatomy scale [min max]',...
    'FontWeight','bold');
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS+55 IMGYOFS-2.7 35 1.5],...
    'String','Gamma :','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
AnaGammaEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[IMGXOFS+67, IMGYOFS-2.5 10 1.5],...
    'Callback','mroiatlas(''Main_Callback'',gcbo,''redraw-ana'',guidata(gcbo))',...
    'String','1.5','Tag','AnaGammaEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','anatomy gamma',...
    'FontWeight','bold');


uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS+IMGW H-0.1 20 1.5],...
    'String','Atlas : ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
AtlasAxs = axes(...
    'Parent',hMain,'Tag','AtlasAxs',...
    'Units','char','Color','k','layer','top',...
    'Position',[IMGXOFS+IMGW IMGYOFS IMGW*0.92 IMGH],...
    'xticklabel','','yticklabel','','xtick',[],'ytick',[]);

AtlasSetCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[IMGXOFS+IMGW H+2 33 1.5],...
    'String',{'Rat : Paxinos' 'Rat : Rat2013' 'Rhesus : Saleem' 'Rhesus : CoCoMac/mod'},...
    'Value',1,...
    'Callback','mroiatlas(''Main_Callback'',gcbo,''load-atlas-redraw'',[])',...
    'TooltipString','Atlas Selection',...
    'Tag','AtlasSetCmb','FontWeight','Bold');
GroupRoisCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[IMGXOFS+IMGW+34 H+2 17 1.5],...
    'Tag','GroupRoisCheck','Value',0,...
    'Callback','mroiatlas(''Main_Callback'',gcbo,''redraw'',[])',...
    'String','Group ROIs','FontWeight','bold',...
    'TooltipString','Group ROIs','BackgroundColor',get(hMain,'Color'));
AtlasViewCmb = uicontrol(...
    'Parent',hMain,'Style','popupmenu',...
    'Units','char','Position',[IMGXOFS+IMGW+9 H 24 1.5],...
    'String',{'Horizontal DV','Horizontal VD','Coronal AP','Coronal PA'},...
    'Value',2,...
    'Callback','mroiatlas(''Main_Callback'',gcbo,''load-atlas-redraw'',[])',...
    'TooltipString','Atlas Selection',...
    'Tag','AtlasViewCmb','FontWeight','Bold');
AtlasSliceEdt = uicontrol(...
    'Parent',hMain,'Style','Edit',...
    'Units','char','Position',[IMGXOFS+IMGW+34 H 10 1.5],...
    'Callback','mroiatlas(''Main_Callback'',gcbo,''atlas-slice'',guidata(gcbo))',...
    'String','1','Tag','AtlasSliceEdt',...
    'HorizontalAlignment','center',...
    'TooltipString','atlas slice',...
    'FontWeight','bold');
AtlasSldr = uicontrol(...
    'Parent',hMain,'Style','slider',...
    'Units','char','Position',[IMGXOFS+IMGW+45 H IMGW*0.38 1.2],...
    'Callback','mroiatlas(''Main_Callback'',gcbo,''atlas-slider'',guidata(gcbo))',...
    'Tag','AtlasSldr','SliderStep',[1 4],'Value',1,'Min',1,'Max',2,...
    'TooltipString','atlas slice');
ImageOffCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[IMGXOFS+IMGW IMGYOFS-2.7 25 1.5],...
    'Tag','ImageOffCheck','Value',0,...
    'Callback','mroiatlas(''Main_Callback'',gcbo,''image-off'',[])',...
    'String','Image Off','FontWeight','bold',...
    'TooltipString','hide image','BackgroundColor',get(hMain,'Color'));
% FlipLRCheck = uicontrol(...
%     'Parent',hMain,'Style','Checkbox',...
%     'Units','char','Position',[IMGXOFS+IMGW+30 IMGYOFS-2.7 25 1.5],...
%     'Tag','FlipLRCheck','Value',0,...
%     'Callback','mroiatlas(''Main_Callback'',gcbo,''redraw-atlas'',[])',...
%     'String','Flip L/R','FontWeight','bold',...
%     'TooltipString','hide image','BackgroundColor',get(hMain,'Color'));
GridOnCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[IMGXOFS+IMGW+20 IMGYOFS-2.7 25 1.5],...
    'Tag','GridOnCheck','Value',0,...
    'Callback','mroiatlas(''Main_Callback'',gcbo,''grid-onoff'',[])',...
    'String','Grid On','FontWeight','bold',...
    'TooltipString','Grid On','BackgroundColor',get(hMain,'Color'));
uicontrol(...
    'Parent',hMain,'Style','pushbutton',...
    'Units','char','Position',[IMGXOFS+IMGW+35 IMGYOFS-2.7 15 1.5],...
    'String','Label','FontWeight','bold','fontsize',9,...
    'HorizontalAlignment','center',...
    'TooltipString','Get the ROI label',...
    'Callback','mroiatlas(''Main_Callback'',gcbo,''label-atlas'',[])');
ReverseBWCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[IMGXOFS+IMGW+53 IMGYOFS-2.7 25 1.5],...
    'Tag','ReverseBWCheck','Value',0,...
    'Callback','mroiatlas(''Main_Callback'',gcbo,''redraw-atlas'',[])',...
    'String','Reverse B/W','FontWeight','bold',...
    'TooltipString','','BackgroundColor',get(hMain,'Color'));



uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS+IMGW+IMGW H-0.1 20 1.5],...
    'String','Anatomy+Atlas : ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
OverlayUpdateCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[IMGXOFS+IMGW+IMGW+57 H 25 1.5],...
    'Tag','OverlayUpdateCheck','Value',1,...
    'String','AutoUpdate','FontWeight','bold',...
    'TooltipString','Update by Anatomy/Atlas','BackgroundColor',get(hMain,'Color'));
OverlayAxs = axes(...
    'Parent',hMain,'Tag','OverlayAxs',...
    'Units','char','Color','k','layer','top',...
    'Position',[IMGXOFS+IMGW+IMGW IMGYOFS IMGW*0.92 IMGH],...
    'xticklabel','','yticklabel','','xtick',[],'ytick',[]);
OverlayCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[IMGXOFS+IMGW+IMGW IMGYOFS-2.7 25 1.5],...
    'Tag','OverlayCheck','Value',1,...
    'Callback','mroiatlas(''Main_Callback'',gcbo,''redraw-overlay'',[])',...
    'String','Overlay Atlas','FontWeight','bold',...
    'TooltipString','Overlay the atlas','BackgroundColor',get(hMain,'Color'));
OverlayReverseBWCheck = uicontrol(...
    'Parent',hMain,'Style','Checkbox',...
    'Units','char','Position',[IMGXOFS+IMGW+IMGW+53 IMGYOFS-2.7 25 1.5],...
    'Tag','OverlayReverseBWCheck','Value',1,...
    'Callback','mroiatlas(''Main_Callback'',gcbo,''redraw-overlay'',[])',...
    'String','Reverse B/W','FontWeight','bold',...
    'TooltipString','','BackgroundColor',get(hMain,'Color'));

InfoTxt = uicontrol(...
    'Parent',hMain,'Style','Listbox',...
    'Units','char','Position',[IMGXOFS+IMGW+IMGW IMGYOFS+IMGH+3 IMGW*0.92 9],...
    'String',{'session','group','datsize','resolution'},...
    'HorizontalAlignment','left',...
    'FontName','Comic Sans MS','FontSize',9,...
    'Tag','InfoTxt','Background','white');



StatusFrame = axes(...
    'Parent',hMain,'Units','char','color',get(hMain,'color'),'xtick',[],...
    'ytick',[],'Position',[IMGXOFS 0.35 IMGW+IMGW-7 1.8],...
    'Box','on','linewidth',1,'xcolor',[0.5 0 0.5],'ycolor',[0.5 0 0.5],...
    'color',BKGCOL);
uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS+1.5 0.35 11 1.5],...
    'String','Status : ','FontWeight','bold',...
    'HorizontalAlignment','left','fontsize',9,...
    'BackgroundColor',BKGCOL);
StatusField = uicontrol(...
    'Parent',hMain,'Style','Text',...
    'Units','char','Position',[IMGXOFS+12 0.65 145 1.2],...
    'String','ready','FontWeight','bold','fontsize',9,...
    'HorizontalAlignment','left','Tag','StatusField','BackgroundColor',BKGCOL);





wgts = guihandles(hMain);


GrpNames = getgrpnames(SESSION);
if ~exist('GrpExp','var'),  GrpExp = GrpNames{1};  end
if isnumeric(GrpExp),  GrpExp = getgrpname(GrpExp);  end
idx = find(strcmpi(GrpNames,GrpExp));
if isempty(idx),  idx = 1;  end
GrpRoiSet = {};
for N = 1:length(GrpNames),
  tmpgrp = getgrp(SESSION,GrpNames{N});
  if isfield(tmpgrp,'grproi') && ~isempty(tmpgrp.grproi),
    GrpRoiSet{end+1} = tmpgrp.grproi;
  end
end
GrpRoiSet = unique(GrpRoiSet);
set(wgts.GrpSelCmb,'String',GrpNames,'Value',idx);
set(wgts.GrpRoiSelCmb,'String',GrpRoiSet,'Value',1);



setappdata(hMain,'Ses',SESSION);
setappdata(hMain,'Grp',GrpExp);

mroiatlas('Main_Callback',hMain,'init');
set(hMain,'visible','on');

if nargout,  varargout{1} = hMain;  end


return



% ====================================================================
% MAIN CALLBACK
function Main_Callback(hObject,eventdata,handles)
% ====================================================================

wgts = guihandles(hObject);
ses = getappdata(wgts.main,'Ses');
grp = getappdata(wgts.main,'Grp');

switch lower(eventdata),
 case {'init'}
  % CHANGE 'UNITS' OF ALL WIDGETS FOR SUCCESSFUL PRINT
  % the following is as dirty as it can be... but it allows
  % rescaling and also correct printing... leave it so, until you
  % find a better solution!
  handles = findobj(wgts.main);
  for N=1:length(handles),
    try
      set(handles(N),'units','normalized');
    catch
    end
  end
  % DUE TO BUG OF MATLAB 7.5, 'units' for figure must be 'pixels'
  % otherwise roipoly() will crash.
  set(wgts.main,'units','pixels');
  
  % re-evaluate session/group info.

  % Code change Bernd Schaffeld 16.08.10
  %ses = getses(ses.name);

  ses = goto(ses);
  grp = getgrp(ses,grp);
  anap = getanap(ses,grp);
  setappdata(wgts.main,'Ses',ses);
  setappdata(wgts.main,'Grp',grp);

  if strncmpi(ses.name,'rat',3),
    set(wgts.AtlasSetCmb,'Value',1);
  else
    set(wgts.AtlasSetCmb,'Value',3);
  end
  
  
  idx = find(strcmpi(get(wgts.GrpRoiSelCmb,'String'),grp.grproi));
  if isempty(idx),  idx = 1;  end
  set(wgts.GrpRoiSelCmb,'Value',idx);
  
  Main_Callback(wgts.main,'load-redraw');


 case {'load-redraw'}
  Main_Callback(wgts.main,'load-ana');
  Main_Callback(wgts.main,'load-atlas');
  Main_Callback(wgts.main,'redraw');

 case {'load-ana'}
  % loading ana/epi
  StatusTxt = 'Loading anatomy...';
  set(wgts.StatusField,'String',StatusTxt);  drawnow;
  ANA = anaload(ses,grp,0);
  StatusTxt = sprintf('%s epi...',StatusTxt);
  set(wgts.StatusField,'String',StatusTxt);  drawnow;
  EPI = sigload(ses,grp.exps(1),'tcImg');
  EPI.dat = nanmean(EPI.dat,4);
  setappdata(wgts.main,'ANA',ANA);
  setappdata(wgts.main,'EPI',EPI);
  
  % set slider edit value
  N = size(ANA.dat,3);
  set(wgts.AnaSliceEdt,   'String', sprintf('%d',1));
  set(wgts.AtlasSliceEdt, 'String', sprintf('%g',1));
  % set slider, add +0.01 to prevent error.
  set(wgts.AnaSldr,     'Min',1,'Max',N+0.01,'Value',1);
  set(wgts.AtlasSldr,   'Min',1,'Max',N+0.01,'Value',1);
  % set slider step, it is normalized from 0 to 1, not min/max
  set(wgts.AnaSldr,     'SliderStep',[1, 2]/max(1,N-1));
  set(wgts.AtlasSldr,   'SliderStep',[1, 2]/max(1,N-1));
  
  tmptxt = {};
  tmptxt{end+1} = sprintf('ANA.size: [%s]',deblank(sprintf('%g ',size(ANA.dat))));
  tmptxt{end+1} = sprintf('ANA.ds:   [%s] mm',deblank(sprintf('%g ',ANA.ds)));
  tmptxt{end+1} = sprintf('EPI.size: [%s]',deblank(sprintf('%g ',size(EPI.dat))));
  tmptxt{end+1} = sprintf('EPI.ds:   [%s] mm',deblank(sprintf('%g ',EPI.ds)));
  tmptxt{end+1} = sprintf('EPI.dx:   %g sec',   EPI.dx(1));
  set(wgts.InfoTxt,'String',tmptxt);
  
  % ana scale
  minv = 0;
  maxv = round(max(ANA.dat(:))*0.8/100)*100;
  set(wgts.AnaScaleEdt, 'String', sprintf('%g  %g',minv,maxv));

  % backward compatibility...
  if exist('./atlas_tform.mat','file'),
    srcfile = fullfile(pwd,'atlas_tform.mat');
    dstfile = fullfile(pwd,'mroiatlas_tform.mat');
    movefile(srcfile,dstfile,'f');
    clear srcfile dstfile;
  end
  
  % load transformed atlas
  if sesversion(ses) >= 2
    tfile = fullfile(pwd,'roi','mroiatlas_tform.mat');
  else
    tfile = fullfile(pwd,'mroiatlas_tform.mat');
  end
  T_ATLAS = [];
  if exist(tfile,'file'),
    StatusTxt = sprintf('%s mroiatlas_tform...',StatusTxt);
    set(wgts.StatusField,'String',StatusTxt');  drawnow;
    if strcmpi(grp.grproi,'RoiGrp')
      % guessing the original grproi as 'RoiDef'...
      vname = sprintf('%s_atlasimg','RoiDef');
    else
      vname = sprintf('%s_atlasimg',strrep(grp.grproi,'_atlas',''));
    end
    if any(strcmpi(who('-file',tfile),vname)),
      T_ATLAS = load(tfile,vname);
      T_ATLAS = T_ATLAS.(vname);
    else
      StatusTxt = sprintf('%s %s not found...',StatusTxt,vname);
      set(wgts.StatusField,'String',StatusTxt');  drawnow;
      T_ATLAS = [];
    end
    StatusTxt = sprintf('%s done.',StatusTxt);
    set(wgts.StatusField,'String',StatusTxt');  drawnow;
    if isfield(T_ATLAS,'points') && ~isempty(T_ATLAS.points) && isfield(T_ATLAS.points,'atlas_name'),
      if strncmpi(ses.name,'rat',3),
        aset = 'Rat : Paxinos';
      else
        aset = 'Rhesus : Saleem';
      end
      for K = 1:length(T_ATLAS.points)
        T_ATLAS.points(N).atlas_type = aset;
        T_ATLAS.points(N).atlas_view = T_ATLAS.points(N).atlas_name;
      end
      T_ATLAS.points = rmfield(T_ATLAS.points,'atlas_name');
    end
  end
  if isempty(T_ATLAS),
    T_ATLAS.session   = ses.name;
    T_ATLAS.grproi    = grp.grproi;
    T_ATLAS.date      = datestr(now);
    T_ATLAS.points    = [];
    T_ATLAS.atlas     = [];
  end

  for K = 1:length(T_ATLAS.points)
    if any(T_ATLAS.points(K).atlas_view),
      tmpidx = find(strcmpi(get(wgts.AtlasViewCmb,'String'),T_ATLAS.points(K).atlas_view));
      if any(tmpidx),
        set(wgts.AtlasViewCmb,'Value',tmpidx(1));
        tmpidx = find(strcmpi(get(wgts.AtlasSetCmb,'String'),T_ATLAS.points(K).atlas_type));
        if any(tmpidx),
          set(wgts.AtlasSetCmb, 'Value',tmpidx(1));
          break;
        end
      end
    end
  end
  setappdata(wgts.main,'T_ATLAS',T_ATLAS);
  
 case {'load-atlas-redraw'}
  Main_Callback(wgts.main,'load-atlas');
  Main_Callback(wgts.main,'redraw-atlas');
 
  
 case {'load-atlas'}
  % loading atlas
  aset  = get(wgts.AtlasSetCmb,'String');
  aset  = aset{get(wgts.AtlasSetCmb,'Value')};
  aview = get(wgts.AtlasViewCmb,'String');
  aview = aview{get(wgts.AtlasViewCmb,'Value')};
  ATLAS = [];  ATLAS_COORDS = [];  ROI_TABLE = {};  GROI = {};
  setappdata(wgts.main,'ROI_TABLE',ROI_TABLE);  % reset

  switch lower(aset),
   case {'rat : paxinos'}
    setappdata(wgts.main,'ATLAS_AS_IMAGE',0);
    [ATLAS ATLAS_COORDS ROI_TABLE] = sub_load_atlas_rat(wgts,aview);
    GROI = sub_roi_group_list_rat();
   case {'rat : rat2013'}
    setappdata(wgts.main,'ATLAS_AS_IMAGE',0);
    [ATLAS ATLAS_COORDS ROI_TABLE] = sub_load_atlas_rat2013(wgts,aview);
    GROI = sub_roi_group_list_rat();
    
   case {'rhesus : saleem'}
    % monkey atlas
    setappdata(wgts.main,'ATLAS_AS_IMAGE',1);
    [ATLAS ATLAS_COORDS ROI_TABLE] = sub_load_atlas_saleem(wgts,aview);
   case {'rhesus : cocomac/mod' 'rhesus : bezgin/mod'}
    % monkey atlas
    setappdata(wgts.main,'ATLAS_AS_IMAGE',0);
    [ATLAS ATLAS_COORDS ROI_TABLE] = sub_load_atlas_cocomac(wgts,aview);
    GROI = sub_roi_group_list_macaque();
  end 
  
  setappdata(wgts.main,'ATLAS',ATLAS);
  setappdata(wgts.main,'ATLAS_COORDS',ATLAS_COORDS);
  setappdata(wgts.main,'ROI_TABLE',ROI_TABLE);
  setappdata(wgts.main,'GROI',GROI);

  T_ATLAS = getappdata(wgts.main,'T_ATLAS');
  if ~isempty(T_ATLAS) && ~isempty(ATLAS),
    iSlice = round(str2double(get(wgts.AnaSliceEdt,'String')));
    if isfield(T_ATLAS,'points') && length(T_ATLAS.points) >= iSlice
      tmpcoords = T_ATLAS.points(iSlice).coords;
      if any(tmpcoords),
        % use x1000 to avoid str2double() problem...
        tmpidx = find(round(ATLAS_COORDS*1000)/1000 == round(tmpcoords(1)*1000)/1000);
        if any(tmpidx),
          set(wgts.AtlasSliceEdt, 'String', sprintf('%+g',tmpcoords(1)));
          set(wgts.AtlasSldr,      'Value', tmpidx(1));
        end
      end
    end
  end
  
 
 case {'save-atlas'}
  ATLAS = getappdata(wgts.main,'ATLAS');
  T_ATLAS = getappdata(wgts.main,'T_ATLAS');
  ROI_TABLE = getappdata(wgts.main,'ROI_TABLE');
  if isempty(T_ATLAS),  return;  end
  T_ATLAS.session = ses.name;
  T_ATLAS.grproi  = grp.grproi;
  T_ATLAS.date = datestr(now);
  T_ATLAS.roitable = ROI_TABLE;
  if get(wgts.ForceTransformCheck,'Value') > 0,
    ANA = getappdata(wgts.main,'ANA');
    for N = 1:size(ANA.dat,3),
      if length(T_ATLAS.points) < N || isempty(T_ATLAS.points(N).anax),
        tmptxt = sprintf('SLICE(%d) ERROR : CANT''T TRANSFORM, NO FIDUCIAL POINTS.',N);
        set(wgts.StatusField,'String',tmptxt);
        return
      end
      tmpatlas = sub_transform(wgts,ATLAS,T_ATLAS,N,'verbose',1);
      if isempty(tmpatlas.img),  return;  end
      if isempty(T_ATLAS.atlas)
        T_ATLAS = rmfield(T_ATLAS,'atlas');  % avoid error...
      end
      T_ATLAS.atlas(N) = tmpatlas;
    end
  else
    % apply "transform" if needed.
    for N = 1:length(T_ATLAS.points),
      PINFO = T_ATLAS.points(N);
      if isempty(PINFO.anax),  continue;  end
      DO_TRANSFORM = 1;
      if length(T_ATLAS.atlas) >= N,
        tmpatlas = T_ATLAS.atlas(N);
        if isfield(tmpatlas,'tform') && isfield(tmpatlas.tform,'input_points'),
          input_points = [PINFO.atlasx(:) PINFO.atlasy(:)];
          if isequal(input_points,tmpatlas.tform.input_points),
            continue;
          end
        end
      end
      if DO_TRANSFORM == 0,  continue;  end
      tmpatlas = sub_transform(wgts,ATLAS,T_ATLAS,N,'verbose',1);
      if isempty(tmpatlas.img),  continue;  end
      if isempty(T_ATLAS.atlas)
        T_ATLAS = rmfield(T_ATLAS,'atlas');  % avoid error...
      end
      T_ATLAS.atlas(N) = tmpatlas;
    end
  end

  setappdata(wgts.main,'T_ATLAS',T_ATLAS);
  if sesversion(ses) >= 2,
    tfile = fullfile(pwd,'roi','mroiatlas_tform.mat');
  else
    tfile = fullfile(pwd,'mroiatlas_tform.mat');
  end
  if strcmpi(grp.grproi,'RoiGrp')
    % guessing the original grproi as 'RoiDef'...
    vname = sprintf('%s_atlasimg','RoiDef');
  else
    vname = sprintf('%s_atlasimg',strrep(grp.grproi,'_atlas',''));
  end
  eval(sprintf('%s = T_ATLAS;',vname));
  set(wgts.StatusField,'String',sprintf(' Saving ''%s'' to ''%s''...',vname,tfile));
  drawnow;
  if exist(tfile,'file'),
    [fp fr fe] = fileparts(tfile);
    x = dir(tfile);
    bakfile = sprintf('%s.%s%s',fr,datestr(datenum(x.date),'yyyymmdd_HHMM'),fe);
    bakfile = fullfile(fp,bakfile);
    copyfile(tfile,bakfile,'f');
    %copyfile(tfile,sprintf('%s.bak',tfile),'f');
    save(tfile,vname,'-append');
  else
    mmkdir(fileparts(tfile));
    save(tfile,vname);
  end
  set(wgts.StatusField,'String',sprintf('%s done.',get(wgts.StatusField,'String')));

  if get(wgts.CreateROICheck,'Value') > 0 && getappdata(wgts.main,'ATLAS_AS_IMAGE') == 0,
    sub_create_roi(wgts,T_ATLAS);
  end
  
  
 case {'ana-slice', 'ana-slider'}
  ANA = getappdata(wgts.main,'ANA');
  if strcmpi(eventdata,'ana-slice')
    iSlice = round(str2double(get(wgts.AnaSliceEdt,'String')));
    if isempty(iSlice),  return;  end
    if iSlice < 1,  iSlice = 1;  end
    if iSlice > size(ANA.dat,3),  iSlice = size(ANA.dat,3);  end
    set(wgts.AnaSldr,'Value',iSlice);
  else
    %get(wgts.AnaSldr,'Value')
    %get(wgts.AnaSldr,'SliderStep')
    iSlice = round(get(wgts.AnaSldr,'Value'));
    if iSlice < 1,  iSlice = 1;  end
    if iSlice > size(ANA.dat,3),  iSlice = size(ANA.dat,3);  end
    set(wgts.AnaSliceEdt,'String',sprintf('%d',iSlice));
  end
  Main_Callback(wgts.main,'redraw-ana');
  delete(findobj(wgts.AtlasAxs,'tag','fpoint'));
  delete(findobj(wgts.AtlasAxs,'tag','fpoint-text'));
  T_ATLAS = getappdata(wgts.main,'T_ATLAS');
  if length(T_ATLAS.points) >= iSlice
    tmpcoords = T_ATLAS.points(iSlice).coords;
    if any(tmpcoords),
      ATLAS_COORDS = getappdata(wgts.main,'ATLAS_COORDS');
      % use x1000 to avoid str2double() problem...
      tmpidx = find(round(ATLAS_COORDS*1000)/1000 == round(tmpcoords(1)*1000)/1000);
      if any(tmpidx),
        set(wgts.AtlasSliceEdt,'String',sprintf('%+g',tmpcoords(1)));
        set(wgts.AtlasSldr,    'Value',tmpidx);
        Main_Callback(wgts.main,'redraw-atlas');  drawnow;
      end
    end
  end
  Main_Callback(wgts.main,'redraw-overlay');
  
 case {'atlas-slice','atlas-slider'}
  ANA = getappdata(wgts.main,'ANA');
  ATLAS = getappdata(wgts.main,'ATLAS');
  if isempty(ATLAS),  return;  end
  if strcmpi(eventdata,'atlas-slice')
    iCoords = str2double(get(wgts.AtlasSliceEdt,'String'));
    if isempty(iCoords),  return;  end
    ATLAS_COORDS = getappdata(wgts.main,'ATLAS_COORDS');
    [minv mini] = min(abs(ATLAS_COORDS-iCoords));
    iSlice = mini(1);
    if minv ~= 0,
      set(wgts.AtlasSliceEdt,'String',sprintf('%+g',ATLAS_COORDS(iSlice)));
    end
    set(wgts.AtlasSldr,'Value',iSlice);
  else
    iSlice = round(get(wgts.AtlasSldr,'Value'));
    if iSlice < 1,  iSlice = 1;  end
    if iSlice > length(ATLAS),  iSlice = length(ATLAS);  end
    ATLAS_COORDS = getappdata(wgts.main,'ATLAS_COORDS');
    set(wgts.AtlasSliceEdt,'String',sprintf('%+g',ATLAS_COORDS(iSlice)));
  end
  Main_Callback(wgts.main,'redraw-atlas');
  Main_Callback(wgts.main,'redraw-overlay');
 
 case {'redraw'}
  Main_Callback(wgts.main,'redraw-ana');
  Main_Callback(wgts.main,'redraw-atlas');
  Main_Callback(wgts.main,'redraw-overlay');
  
 case {'redraw-ana'}
  sub_DrawANA(wgts);
  iSlice = round(get(wgts.AnaSldr,'Value'));
  T_ATLAS = getappdata(wgts.main,'T_ATLAS');
  npts = 0;  tmptxt = 'NaN';
  if length(T_ATLAS.points) >= iSlice
    tmpcoords = T_ATLAS.points(iSlice).coords;
    if any(tmpcoords),
      ATLAS_COORDS = getappdata(wgts.main,'ATLAS_COORDS');
      % use x1000 to avoid str2double() problem...
      tmpidx = find(round(ATLAS_COORDS*1000)/1000 == round(tmpcoords(1)*1000)/1000);
      if any(tmpidx),
        npts = length(T_ATLAS.points(iSlice).anax);
        tmptxt = sprintf('%s(%+g)',T_ATLAS.points(iSlice).atlas_view,tmpcoords(1));
      end
    end
  end
  set(wgts.StatusField,'String',sprintf('SLICE(%d) : npoints=%d atlas=%s',iSlice,npts,tmptxt));
  
 case {'redraw-atlas'}
  sub_DrawATLAS(wgts);
  
 case {'redraw-overlay'}
  sub_DrawOverlay(wgts);
  
 case {'image-off'}
  h = findobj(wgts.AnaAxs,'tag','image-ana');
  if ishandle(h),
    set(wgts.AnaAxs,'color','k');
    if get(wgts.ImageOffCheck,'value')
      set(h,'visible','off');
    else
      set(h,'visible','on');
    end
  else
    Main_Callback(wgts.main,'redraw-ana');
  end
  h = findobj(wgts.AtlasAxs,'tag','image-atlas');
  if ishandle(h),
    if get(wgts.ReverseBWCheck,'Value')
      set(wgts.AtlasAxs,'color','k');
    else
      set(wgts.AtlasAxs,'color','w');
    end
    if get(wgts.ImageOffCheck,'value')
      set(h,'visible','off');
    else
      set(h,'visible','on');
    end
  else
    Main_Callback(wgts.main,'redraw-atlas');
  end
  drawnow;
  
 case {'transform'}
  iSlice = round(str2double(get(wgts.AnaSliceEdt,'String')));
  if isempty(iSlice) || isnan(iSlice),  return;  end
  ATLAS = getappdata(wgts.main,'ATLAS');
  T_ATLAS = getappdata(wgts.main,'T_ATLAS');
  if isempty(T_ATLAS),  return;  end
  if isfield(T_ATLAS,'atlas') && isempty(T_ATLAS.atlas),
    T_ATLAS = rmfield(T_ATLAS,'atlas');
  end
  T_ATLAS.atlas(iSlice) = sub_transform(wgts,ATLAS,T_ATLAS,iSlice,'verbose',1);
  setappdata(wgts.main,'T_ATLAS',T_ATLAS);

  ATLAS_COORDS = getappdata(wgts.main,'ATLAS_COORDS');
  tmpcoords = ATLAS_COORDS(round(get(wgts.AtlasSldr,'Value')));
  if ~isempty(T_ATLAS.atlas(iSlice).img) && ~any(T_ATLAS.atlas(iSlice).coords == tmpcoords),
    % move the atlas to the correct one
    tmpcoords = T_ATLAS.atlas(iSlice).coords(1);
    % use x1000 to avoid str2double() problem...
    tmpidx = find(round(ATLAS_COORDS*1000)/1000 == round(tmpcoords(1)*1000)/1000);
    if any(tmpidx),
      set(wgts.AtlasSliceEdt,'String',sprintf('%+g',tmpcoords));
      set(wgts.AtlasSldr,    'Value', tmpidx);
      Main_Callback(wgts.main,'redraw-atlas');
    end
  end
  Main_Callback(wgts.main,'redraw-overlay');

  
 case {'grid-onoff'}
  if get(wgts.GridOnCheck,'Value') > 0,
    set(wgts.AnaAxs,    'XGrid','on', 'YGrid','on');
    set(wgts.AtlasAxs,  'XGrid','on', 'YGrid','on');
    set(wgts.OverlayAxs,'XGrid','on', 'YGrid','on');
  else
    set(wgts.AnaAxs,    'XGrid','off','YGrid','off');
    set(wgts.AtlasAxs,  'XGrid','off','YGrid','off');
    set(wgts.OverlayAxs,'XGrid','off','YGrid','off');
  end

 case {'marker-type'}
  tmpmarker = get(wgts.MarkerCmb,'String');
  tmpmarker = tmpmarker{get(wgts.MarkerCmb,'Value')};
  set(findobj(wgts.AnaAxs,    'tag','fpoint'),'marker',tmpmarker);
  set(findobj(wgts.AtlasAxs,  'tag','fpoint'),'marker',tmpmarker);
  set(findobj(wgts.OverlayAxs,'tag','fpoint'),'marker',tmpmarker);
 case {'marker-color'}
  tmpcolor = sub_get_color(wgts.MarkerColorEdt,[1.0 1.0 0.0]);
  set(findobj(wgts.AnaAxs,    'tag','fpoint'),'color',tmpcolor);
  set(findobj(wgts.AtlasAxs,  'tag','fpoint'),'color',tmpcolor*0.7);
  set(findobj(wgts.OverlayAxs,'tag','fpoint'),'color',tmpcolor);
 case {'text-color'}
  tmpcolor = sub_get_color(wgts.TextColorEdt,[0.3 0.3 1.0]);
  set(findobj(wgts.AnaAxs,    'tag','fpoint-text'),'color',tmpcolor);
  set(findobj(wgts.AtlasAxs,  'tag','fpoint-text'),'color',tmpcolor);
  set(findobj(wgts.OverlayAxs,'tag','fpoint-text'),'color',tmpcolor);
  
 case {'point-action'}
  cmdstr = get(wgts.PointActionCmb,'String');
  cmdstr = cmdstr{get(wgts.PointActionCmb,'Value')};
  if strcmpi(cmdstr,'no action'),  return;  end
  % disable widgets
  set(wgts.PointActionCmb,'Enable','off');
  set(wgts.AnaSliceEdt,   'Enable','off');
  set(wgts.AnaSldr,       'Enable','off');
  set(wgts.AtlasSliceEdt, 'Enable','off');
  set(wgts.AtlasSldr,     'Enable','off');
  set(wgts.AtlasSetCmb,   'Enable','off');
  set(wgts.AtlasViewCmb,  'Enable','off');
  try
    Point_Function(wgts,cmdstr);
  catch
  end
  set(wgts.PointActionCmb,'Enable','on');
  set(wgts.AnaSliceEdt,   'Enable','on');
  set(wgts.AnaSldr,       'Enable','on');
  set(wgts.AtlasSliceEdt, 'Enable','on');
  set(wgts.AtlasSldr,     'Enable','on');
  set(wgts.AtlasSetCmb,   'Enable','on');
  set(wgts.AtlasViewCmb,  'Enable','on');
  
  set(wgts.PointActionCmb,'Value',1);
  
 case {'label-atlas'}
  set(wgts.main,'CurrentAxes',wgts.AtlasAxs);
  [x y] = ginput(1);
  click = get(wgts.main,'SelectionType');
  if ~strcmp(click,'alt'),
    sub_TextATLAS(wgts,[x y]);
  end
  
 case {'atlas-button-down'}
  click = get(wgts.main,'SelectionType');
  if strcmp(click,'open'),
    sub_TextATLAS(wgts,[]);
    %fprintf('double-click\n');
  end
  
 otherwise
end
  

return




% ====================================================================
% MAIN CALLBACK
function Point_Function(wgts,cmdstr)
% ====================================================================

%ses = getappdata(wgts.main,'Ses');
%grp = getappdata(wgts.main,'Grp');

T_ATLAS = getappdata(wgts.main,'T_ATLAS');
iSlice = round(str2double(get(wgts.AnaSliceEdt,'String')));
if isempty(iSlice) || isnan(iSlice),  return;  end

if length(T_ATLAS.points) < iSlice,
  T_ATLAS.points(iSlice).atlas_type  = '';
  T_ATLAS.points(iSlice).atlas_view = '';
  T_ATLAS.points(iSlice).anax = [];
  T_ATLAS.points(iSlice).anay = [];
  T_ATLAS.points(iSlice).atlasx = [];
  T_ATLAS.points(iSlice).atlasy = [];
  T_ATLAS.points(iSlice).coords = [];
end


switch lower(cmdstr),
 case {'append'}
  ANA   = getappdata(wgts.main,'ANA');
  ATLAS = getappdata(wgts.main,'ATLAS');
  
  NEW_POINTS = T_ATLAS.points(iSlice);
  OLD_POINTS = T_ATLAS.points(iSlice);

  set(wgts.StatusField,'String','Left-Click to set a point,  Right-Click to quit.');

  marker = get(wgts.MarkerCmb,'String');
  marker = marker{get(wgts.MarkerCmb,'Value')};
  mkrcol = sub_get_color(wgts.MarkerColorEdt,[1.0 1.0 0.0]);
  txtcol = sub_get_color(wgts.TextColorEdt,  [0.3 0.3 1.0]);
  
  % temporally disable the callback..
  %himg = findobj(wgts.AtlasAxs,'image-atlas');
  %if ishandle(himg),  set(himg,'ButtonDownFcn','');  end

  while 1,
    tmpcursor = get(wgts.PointCursorCmb,'String');
    tmpcursor = tmpcursor{get(wgts.PointCursorCmb,'Value')};
    tobj = timer('TimerFcn',sprintf('mroi_cursor(''%s'');',tmpcursor),...
                 'StartDelay',0.1);
    start(tobj);
    try
      [x y] = ginput(1);
    catch
      click = get(wgts.main,'SelectionType');
      if strcmpi(click,'alt'),
        wait(tobj);  delete(tobj);
        break;
      else
        lasterr;
      end
    end
    % delete the timer object and restore the cursor
    wait(tobj);  delete(tobj);
    set(wgts.main,'Pointer','arrow');

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
    end
    
    % note that ginput() will select the current axes
    if wgts.AnaAxs == gca,
      xlm = get(gca,'xlim');
      if x < xlm(1) || x > xlm(2)*1.2,  continue;  end
      ylm = get(gca,'ylim');
      if y < ylm(1) || y > ylm(2)*1.2,  continue;  end
      
      NEW_POINTS.anax(end+1) = x;
      NEW_POINTS.anay(end+1) = y;
      N = length(NEW_POINTS.anax);
      
      tmpcolor = mkrcol;
      txtoffs = ceil(0.4/ANA.ds(1));
    elseif wgts.AtlasAxs == gca,
      xlm = get(gca,'xlim');
      if x < xlm(1) || x > xlm(2)*1.2,  continue;  end
      ylm = get(gca,'ylim');
      if y < ylm(1) || y > ylm(2)*1.2,  continue;  end

      NEW_POINTS.atlasx(end+1) = x;
      NEW_POINTS.atlasy(end+1) = y; 
      N = length(NEW_POINTS.atlasx);
      
      tmpcolor = mkrcol*0.7;
      txtoffs = ceil(0.4/ATLAS(1).res(1));
    else
      continue;
    end
    hold on;
    plot(x,y,'marker',marker,'color',tmpcolor,'markersize',10,'tag','fpoint');
    text(x+txtoffs,y-txtoffs,sprintf('%d',N),'color',txtcol,'fontsize',8,...
         'tag','fpoint-text');
    hold off;
  end
  % enable the disabled callback
  %himg = findobj(wgts.AtlasAxs,'tag','image-atlas');
  %if ishandle(himg),
  %  set(himg,'ButtonDownFcn',...
  %           'ButtonDownFcn','mroiatlas(''Main_Callback'',gcbo,''atlas-button-down'',[])');
  %end
  
  if length(NEW_POINTS.anax) ~= length(NEW_POINTS.atlasx),
    n = min(length(NEW_POINTS.anax), length(NEW_POINTS.atlasx));
    NEW_POINTS.anax = NEW_POINTS.anax(1:n);
    NEW_POINTS.anay = NEW_POINTS.anay(1:n);
    NEW_POINTS.atlasx = NEW_POINTS.atlasx(1:n);
    NEW_POINTS.atlasy = NEW_POINTS.atlasy(1:n);
    DO_REDRAW = 1;
  else
    DO_REDRAW = 0;
  end
  
  NEW_POINTS.coords = str2double(get(wgts.AtlasSliceEdt,'String'));
  if ~isequal(OLD_POINTS,NEW_POINTS),
    if isfield(T_ATLAS,'atlas') && length(T_ATLAS.atlas) >= iSlice,
      T_ATLAS.atlas(iSlice).img    = [];
      T_ATLAS.atlas(iSlice).map    = [];
      T_ATLAS.atlas(iSlice).res    = [];
      T_ATLAS.atlas(iSlice).coords = [];
      T_ATLAS.atlas(iSlice).tform  = [];
    end
  end
  atlas_type = get(wgts.AtlasSetCmb,'String');
  atlas_type = atlas_type{get(wgts.AtlasSetCmb,'Value')};
  atlas_view = get(wgts.AtlasViewCmb,'String');
  atlas_view = atlas_view{get(wgts.AtlasViewCmb,'Value')};
  NEW_POINTS.atlas_type = atlas_type;
  NEW_POINTS.atlas_view = atlas_view;

  T_ATLAS.points(iSlice) = NEW_POINTS;
  setappdata(wgts.main,'T_ATLAS',T_ATLAS);
  if DO_REDRAW,
    Main_Callback(wgts.main,'redraw-ana');
    Main_Callback(wgts.main,'redraw-atlas');
  end

  n = length(T_ATLAS.points(iSlice).anax);
  set(wgts.StatusField,'String',sprintf('SLICE(%d) : npoints=%d',iSlice,n));
  
 case {'replace'}
  Point_Function(wgts,'Remove ALL');
  Point_Function(wgts,'Append');
  
 case {'remove end'}
  T_ATLAS.points(iSlice).anax(end) = [];
  T_ATLAS.points(iSlice).anay(end) = [];
  T_ATLAS.points(iSlice).atlasx(end) = [];
  T_ATLAS.points(iSlice).atlasy(end) = [];
  if isfield(T_ATLAS,'atlas') && length(T_ATLAS.atlas) >= iSlice,
    T_ATLAS.atlas(iSlice).img    = [];
    T_ATLAS.atlas(iSlice).map    = [];
    T_ATLAS.atlas(iSlice).res    = [];
    T_ATLAS.atlas(iSlice).coords = [];
    T_ATLAS.atlas(iSlice).tform  = [];
  end
  setappdata(wgts.main,'T_ATLAS',T_ATLAS);
  Main_Callback(wgts.main,'redraw-ana');
  Main_Callback(wgts.main,'redraw-atlas');
  Main_Callback(wgts.main,'redraw-atlas');
  drawnow;
  
 case {'remove x'}
  npoints  = length(T_ATLAS.points(iSlice).anax);
  tmptitle = sprintf('%s: remove points',mfilename);
  tmptxt   = sprintf('Enter point indices (1-%d) for the current slice.',npoints);
  answer = inputdlg({ tmptxt },tmptitle,1,{''});
  if ~isempty(answer),
    tmpidx = str2num(answer{1});
    tmpidx = tmpidx(tmpidx > 0 & tmpidx <= npoints);
    if any(tmpidx),
      T_ATLAS.points(iSlice).anax(tmpidx)   = [];
      T_ATLAS.points(iSlice).anay(tmpidx)   = [];
      T_ATLAS.points(iSlice).atlasx(tmpidx) = [];
      T_ATLAS.points(iSlice).atlasy(tmpidx) = [];
      if isfield(T_ATLAS,'atlas') && length(T_ATLAS.atlas) >= iSlice,
        T_ATLAS.atlas(iSlice).img    = [];
        T_ATLAS.atlas(iSlice).map    = [];
        T_ATLAS.atlas(iSlice).res    = [];
        T_ATLAS.atlas(iSlice).coords = [];
        T_ATLAS.atlas(iSlice).tform  = [];
      end
      setappdata(wgts.main,'T_ATLAS',T_ATLAS);
      Main_Callback(wgts.main,'redraw-ana');
      Main_Callback(wgts.main,'redraw-atlas');
      drawnow;
    end
  end
  
 case {'remove all'}
  T_ATLAS.points(iSlice).anax = [];
  T_ATLAS.points(iSlice).anay = [];
  T_ATLAS.points(iSlice).atlasx = [];
  T_ATLAS.points(iSlice).atlasy = [];
  if isfield(T_ATLAS,'atlas') && length(T_ATLAS.atlas) >= iSlice,
    T_ATLAS.atlas(iSlice).img    = [];
    T_ATLAS.atlas(iSlice).map    = [];
    T_ATLAS.atlas(iSlice).res    = [];
    T_ATLAS.atlas(iSlice).coords = [];
    T_ATLAS.atlas(iSlice).tform  = [];
  end
  setappdata(wgts.main,'T_ATLAS',T_ATLAS);
  delete(findobj(wgts.AnaAxs,    'tag','fpoint'));
  delete(findobj(wgts.AnaAxs,    'tag','fpoint-text'));
  delete(findobj(wgts.AtlasAxs,  'tag','fpoint'));
  delete(findobj(wgts.AtlasAxs,  'tag','fpoint-text'));
  delete(findobj(wgts.OverlayAxs,'tag','fpoint'));
  delete(findobj(wgts.OverlayAxs,'tag','fpoint-text'));
  n = length(T_ATLAS.points(iSlice).anax);
  set(wgts.StatusField,'String',sprintf('SLICE(%d) : npoints=%d',iSlice,n));
  drawnow;
 
 case {'clear all slices'}
  T_ATLAS.points = [];
  T_ATLAS.atlas  = [];
  setappdata(wgts.main,'T_ATLAS',T_ATLAS);
  delete(findobj(wgts.AnaAxs,    'tag','fpoint'));
  delete(findobj(wgts.AnaAxs,    'tag','fpoint-text'));
  delete(findobj(wgts.AtlasAxs,  'tag','fpoint'));
  delete(findobj(wgts.AtlasAxs,  'tag','fpoint-text'));
  delete(findobj(wgts.OverlayAxs,'tag','fpoint'));
  delete(findobj(wgts.OverlayAxs,'tag','fpoint-text'));
  n = length(T_ATLAS.points(iSlice).anax);
  set(wgts.StatusField,'String',sprintf('SLICE(%d) : npoints=%d',iSlice,n));
  drawnow;
  
 otherwise
  
end


return



% ========================================================================
function [ATLAS ATLAS_COORDS ROI_TABLE] = sub_load_atlas_rat(wgts,aview)
% ========================================================================

ATLAS = [];  ATLAS_COORDS = [];  ROI_TABLE = {};

USE_ORIGINAL = 0;

if USE_ORIGINAL,
  afile = fullfile(fileparts(which(mfilename,'fullpath')),'atlas_data/atlas_structImage.mat');
  DV0   = 187;
else
  afile = fullfile(fileparts(which(mfilename,'fullpath')),'atlas_data/rathead16T_AtlasROIs.mat');
  DV0   = 29;  % 29 is the cortical surface
end
if exist(afile,'file'),
  set(wgts.StatusField,'String','Loading atlas...');  drawnow;
  tmpatlas = load(afile,'ATLAS');
  tmpatlas = tmpatlas.ATLAS;
  tmpatlas.ds  = double(tmpatlas.ds)/10;  % rat-atlas has the x10 factor
  tmpatlas.dat = abs(tmpatlas.dat);
  %tmpatlas.dat = tmpatlas.dat + 1;  % +1 for matlab indexing
  tmpatlas.dat = flipdim(tmpatlas.dat,2);
  tmpatlas.dat = flipdim(tmpatlas.dat,3);
  %nrois = length(unique(abs(tmpatlas.dat(:))));
  %cmap = cat(1,[1 1 1],lines(nrois-1));  % 0 as white
  maxv = max(abs(tmpatlas.dat(:)));
  cmap = cat(1,[1 1 1],lines(maxv));  % 0 as white
  switch lower(aview)
   case {'coronal ap' 'coronal pa'}
    for N = 1:size(tmpatlas.dat,3),
      ATLAS(N).img = squeeze(tmpatlas.dat(:,:,N))';
      ATLAS(N).map = cmap;
      ATLAS(N).res = tmpatlas.ds([2 1]);  % as [dy dx]
      ATLAS(N).coords = (N-1)*tmpatlas.ds(3);  % str2double() returns incorrect value...
      % ATLAS(N).coords = N;
    end
    if strcmpi(aview,'coronal pa'),  ATLAS = ATLAS(end:-1:1);  end
   case {'horizontal dv' 'horizontal vd'}
    for N = 1:size(tmpatlas.dat,2),
      ATLAS(N).img = squeeze(tmpatlas.dat(:,N,:))';
      ATLAS(N).map = cmap;
      ATLAS(N).res = tmpatlas.ds([3 1]);  % as [dy dx]
      ATLAS(N).coords = (N-DV0)*tmpatlas.ds(2);  % str2double() returns incorrect value...,
      % ATLAS(N).coords = N;
    end
    if strcmpi(aview,'horizontal vd'),  ATLAS = ATLAS(end:-1:1);  end
  end
  set(wgts.StatusField,'String','Loading atlas... done.');  drawnow;
  N = length(ATLAS);
  set(wgts.AtlasSliceEdt, 'String', sprintf('%+g',ATLAS(1).coords));
  ATLAS_COORDS = NaN(1,N);
  for N = 1:length(ATLAS),
    ATLAS_COORDS(N) = ATLAS(N).coords;
  end
  % set slider, add +0.01 to prevent error.
  set(wgts.AtlasSldr,   'Min',1,'Max',N+0.01,'Value',1);
  % set slider step, it is normalized from 0 to 1, not min/max
  set(wgts.AtlasSldr,   'SliderStep',[1, 2]/max(1,N-1));
  delete(findobj(wgts.AtlasAxs,'tag','image-atlas'));
end

txtfile = fullfile(fileparts(which(mfilename,'fullpath')),'atlas_data/atlas_structDefs');
ROI_TABLE = mratatlas_roitable(txtfile);

%ATLAS(1)

return


% ========================================================================
function [ATLAS ATLAS_COORDS ROI_TABLE] = sub_load_atlas_rat2013(wgts,aview)
% ========================================================================

ATLAS = [];  ATLAS_COORDS = [];  ROI_TABLE = {};

afile = fullfile(fileparts(which(mfilename,'fullpath')),'atlas_data/rathead16T_atlas.img');
DV0   = 29;  % 29 is the cortical surface
DV0   = 26;  % 26 is the cortical surface

if exist(afile,'file'),
  set(wgts.StatusField,'String','Loading atlas...');  drawnow;
  [img hdr] = anz_read(afile);
  tmpatlas.ds  = double(hdr.dime.pixdim(2:4))/10;    % rat-atlas has the x10 factor
  tmpatlas.dat = abs(img);
  tmpatlas.dat = flipdim(tmpatlas.dat,2);
  tmpatlas.dat = flipdim(tmpatlas.dat,3);
  maxv = max(abs(tmpatlas.dat(:)));
  cmap = cat(1,[1 1 1],lines(maxv));  % 0 as white
  
  switch lower(aview)
   case {'coronal ap' 'coronal pa'}
    for N = 1:size(tmpatlas.dat,3),
      ATLAS(N).img = squeeze(tmpatlas.dat(:,:,N))';
      ATLAS(N).map = cmap;
      ATLAS(N).res = tmpatlas.ds([2 1]);  % as [dy dx]
      ATLAS(N).coords = (N-1)*tmpatlas.ds(3);  % str2double() returns incorrect value...
      % ATLAS(N).coords = N;
    end
    if strcmpi(aview,'coronal pa'),  ATLAS = ATLAS(end:-1:1);  end
   case {'horizontal dv' 'horizontal vd'}
    for N = 1:size(tmpatlas.dat,2),
      ATLAS(N).img = squeeze(tmpatlas.dat(:,N,:))';
      ATLAS(N).map = cmap;
      ATLAS(N).res = tmpatlas.ds([3 1]);  % as [dy dx]
      ATLAS(N).coords = (N-DV0)*tmpatlas.ds(2);  % str2double() returns incorrect value...,
      % ATLAS(N).coords = N;
    end
    if strcmpi(aview,'horizontal vd'),  ATLAS = ATLAS(end:-1:1);  end
  end
  set(wgts.StatusField,'String','Loading atlas... done.');  drawnow;
  N = length(ATLAS);
  set(wgts.AtlasSliceEdt, 'String', sprintf('%+g',ATLAS(1).coords));
  ATLAS_COORDS = NaN(1,N);
  for N = 1:length(ATLAS),
    ATLAS_COORDS(N) = ATLAS(N).coords;
  end
  % set slider, add +0.01 to prevent error.
  set(wgts.AtlasSldr,   'Min',1,'Max',N+0.01,'Value',1);
  % set slider step, it is normalized from 0 to 1, not min/max
  set(wgts.AtlasSldr,   'SliderStep',[1, 2]/max(1,N-1));
  delete(findobj(wgts.AtlasAxs,'tag','image-atlas'));
end

%ATLAS(1)

txtfile = fullfile(fileparts(which(mfilename,'fullpath')),'atlas_data/rathead16T_atlas.txt');
ROI_TABLE = mratatlas_roitable(txtfile);


return



% ========================================================================
function [ATLAS ATLAS_COORDS ROI_TABLE] = sub_load_atlas_saleem(wgts,aview)
% ========================================================================

ATLAS = [];  ATLAS_COORDS = [];  ROI_TABLE = {};

afile = fullfile(fileparts(which(mfilename,'fullpath')),'atlas_data/atlas_saleem.mat');
if exist(afile,'file'),
  set(wgts.StatusField,'String','Loading atlas...');  drawnow;
  switch lower(aview)
   case {'coronal ap'}
    ATLAS = load(afile,'cor');
    ATLAS = ATLAS.cor;
   case {'coronal pa'}
    ATLAS = load(afile,'cor');
    ATLAS = ATLAS.cor;
    ATLAS = ATLAS(end:-1:1);
   case {'horizontal dv'}
    ATLAS = load(afile,'hor');
    ATLAS = ATLAS.hor;
    ATLAS = ATLAS(end:-1:1);
   case {'horizontal vd'}
    ATLAS = load(afile,'hor');
    ATLAS = ATLAS.hor;
  end
  set(wgts.StatusField,'String','Loading atlas... done.');  drawnow;
  N = length(ATLAS);
  set(wgts.AtlasSliceEdt, 'String', sprintf('%+g',ATLAS(1).coords));
  ATLAS_COORDS = NaN(1,N);
  for N = 1:length(ATLAS),
    ATLAS_COORDS(N) = ATLAS(N).coords;
  end
  % set slider, add +0.01 to prevent error.
  set(wgts.AtlasSldr,   'Min',1,'Max',N+0.01,'Value',1);
  % set slider step, it is normalized from 0 to 1, not min/max
  set(wgts.AtlasSldr,   'SliderStep',[1, 2]/max(1,N-1));
  delete(findobj(wgts.AtlasAxs,'tag','image-atlas'));
end


return



% ========================================================================
function [ATLAS ATLAS_COORDS ROI_TABLE] = sub_load_atlas_cocomac(wgts,aview)
% ========================================================================

ATLAS = [];  ATLAS_COORDS = [];  ROI_TABLE = {};

afile = fullfile(fileparts(which(mfilename,'fullpath')),'atlas_data/rhesus_7_model-MNI_Xflipped_1mm_cocomac.mat');
if exist(afile,'file'),
  set(wgts.StatusField,'String','Loading atlas...');  drawnow;
  tmpatlas = load(afile,'ATLAS');
  tmpatlas = tmpatlas.ATLAS;
  ROI_TABLE = tmpatlas.roitable;
  % convert RGB to unique numbers
  tmpatlas.dat = int32(tmpatlas.dat);
  tmpatlas.dat = tmpatlas.dat(:,:,:,1)*256*256 + tmpatlas.dat(:,:,:,2)*256 + tmpatlas.dat(:,:,:,3);
  NEWDAT = zeros(size(tmpatlas.dat));
  cmap = zeros(length(ROI_TABLE)+1,3);
  cmap(1,:) = [1 1 1];  % 0 as white
  for N = 1:length(ROI_TABLE),
    tmprgb = ROI_TABLE{N}{1};
    cmap(N+1,:) = tmprgb/255;
    tmpidx = tmpatlas.dat(:) == tmprgb(1)*256*256 + tmprgb(2)*256 + tmprgb(3);
    NEWDAT(tmpidx)  = N+1;
    ROI_TABLE{N}{1} = N+1;
  end
  tmpatlas.dat = NEWDAT;
  tmpatlas.dat = flipdim(tmpatlas.dat,2);
  tmpatlas.dat = flipdim(tmpatlas.dat,3);
  
  switch lower(aview)
   case {'coronal ap' 'coronal pa'}
    for N = 1:size(tmpatlas.dat,2),
      ATLAS(N).img = squeeze(tmpatlas.dat(:,N,:))';
      ATLAS(N).map = cmap;
      ATLAS(N).res = tmpatlas.ds([3 1]);  % as [dy dx]
      ATLAS(N).coords = (N-1)*tmpatlas.ds(2);  % str2double() returns incorrect value...
      % ATLAS(N).coords = N;
    end
    if strcmpi(aview,'coronal pa'),  ATLAS = ATLAS(end:-1:1);  end
   case {'horizontal dv' 'horizontal vd'}
    for N = 1:size(tmpatlas.dat,3),
      ATLAS(N).img = squeeze(tmpatlas.dat(:,:,N))';
      ATLAS(N).map = cmap;
      ATLAS(N).res = tmpatlas.ds([2 1]);  % as [dy dx]
      ATLAS(N).coords = (N-1)*tmpatlas.ds(3);  % str2double() returns incorrect value...
      % ATLAS(N).coords = N;
    end
    if strcmpi(aview,'horizontal vd'),  ATLAS = ATLAS(end:-1:1);  end
  end
  set(wgts.StatusField,'String','Loading atlas... done.');  drawnow;
  N = length(ATLAS);
  set(wgts.AtlasSliceEdt, 'String', sprintf('%+g',ATLAS(1).coords));
  ATLAS_COORDS = NaN(1,N);
  for N = 1:length(ATLAS),
    ATLAS_COORDS(N) = ATLAS(N).coords;
  end
  % set slider, add +0.01 to prevent error.
  set(wgts.AtlasSldr,   'Min',1,'Max',N+0.01,'Value',1);
  % set slider step, it is normalized from 0 to 1, not min/max
  set(wgts.AtlasSldr,   'SliderStep',[1, 2]/max(1,N-1));
  delete(findobj(wgts.AtlasAxs,'tag','image-atlas'));
end


return



% ========================================================================
function NEW_DATA = sub_transform(wgts,ATLAS,T_ATLAS,iAnaSlice,varargin)
% ========================================================================


VERBOSE = 0;
for N = 1:2:length(varargin)
  switch lower(varargin{N}),
   case {'verbose'}
    VERBOSE = varargin{N+1};
  end
end


NEW_DATA.img     = [];
NEW_DATA.map     = [];
NEW_DATA.res     = [];
NEW_DATA.coords  = [];
NEW_DATA.tform.func         = '';
NEW_DATA.tform.method       = '';
NEW_DATA.tform.ana_resize   = [];
NEW_DATA.tform.base_points  = [];
NEW_DATA.tform.input_points = [];
NEW_DATA.tform.tform        = [];
NEW_DATA.tform.xdata        = [];
NEW_DATA.tform.ydata        = [];

if length(T_ATLAS.points) < iAnaSlice || isempty(T_ATLAS.points(iAnaSlice).anax),
  if VERBOSE,
    keyboard
    set(wgts.StatusField,'String','WARNING: no fiducial points for transform.');
  end  
  return
end

  
ANA    = getappdata(wgts.main,'ANA');
PINFO  = T_ATLAS.points(iAnaSlice);
ATLAS_COORDS = getappdata(wgts.main,'ATLAS_COORDS');

% use x1000 to avoid str2double() problem...
tmpidx = find(round(ATLAS_COORDS*1000)/1000 == round(PINFO.coords*1000)/1000);
if isempty(tmpidx),
  tmptxt = sprintf('WARNING: ATLAS().coords(%+g) not found.',PINFO.coords);
  set(wgts.StatusField,'String',tmptxt);
  return
end

METHOD = get(wgts.TransformCmb,'String');
METHOD = METHOD{get(wgts.TransformCmb,'Value')};
% check # of points
n = length(PINFO.anax);
minn = 0;
switch lower(METHOD),
 case {'lwm'}
  if n < 12,  minn = 12;  end
 case {'linear conformal'}
  if n <  2,  minn =  2;  end
 case {'affine'}
  if n <  3,  minn =  3;  end
 case {'projective','piecewise linear'}
  if n <  4,  minn =  4;  end
 case {'polynomial'}
  if n < 10,  minn = 10;  end
end
if minn > 0,
  StatusTxt = sprintf('SLICE(%d) ERROR : Min.Control Points=%d for ''%s'', see/help cp2tform.m.',...
                      iAnaSlice,minn,METHOD);
  set(wgts.StatusField,'String',StatusTxt);  drawnow;
  return;
end



tmpimg = ATLAS(tmpidx).img;
% if get(wgts.FlipLRCheck,'Value'),
%   % note that tmpimg as (y,x)
%   tmpimg = flipdim(tmpimg,2);
% end
tmpmap = ATLAS(tmpidx).map;
if getappdata(wgts.main,'ATLAS_AS_IMAGE') > 0,
  tmpimg = ind2rgb(double(tmpimg),tmpmap);   % ind2rgb() has bugs when tmpimg as int16...
else
  % no RGB conversion...
end

input_points = [PINFO.atlasx(:) PINFO.atlasy(:)];
base_points  = [PINFO.anax(:)   PINFO.anay(:)];

if VERBOSE,
  StatusTxt = sprintf('SLICE(%d) : npoints=%d atlas=%s/%s(%+g).',...
                      iAnaSlice,size(input_points,1),...
                      PINFO.atlas_type,PINFO.atlas_view,PINFO.coords(1));
  set(wgts.StatusField,'String',StatusTxt);  drawnow;
end


if 1,
  nx = size(ANA.dat,1);
  ny = size(ANA.dat,2);
  %xdata = 1:nx;
  %ydata = 1:ny;
  % make larger to keep atlas detail
  sx = floor(ANA.ds(1)/ATLAS(tmpidx).res(2));
  sy = floor(ANA.ds(2)/ATLAS(tmpidx).res(1));

  if sx > 1,
    nx = nx * sx;
    base_points(:,1) = base_points(:,1) * sx;
  end
  if sy > 1,
    ny = ny * sy;
    base_points(:,2) = base_points(:,2) * sy;
  end
  xdata = [1 nx];
  ydata = [1 ny];

  if VERBOSE,
    StatusTxt = sprintf('%s size[%dx%d].',StatusTxt,nx,ny);
    set(wgts.StatusField,'String',StatusTxt);  drawnow;
  end 
  
  NEW_DATA.res     = [ANA.ds(1)*size(ANA.dat,1)/nx ANA.ds(2)*size(ANA.dat,2)/ny];
else
  % imtransform() doesn't accept floating values as coordinates...
  fov = [ANA.ds(1)*size(ANA.dat,1)  ANA.ds(2)*size(ANA.dat,2)];
  dx = ATLAS(1).res(2);
  dy = ATLAS(1).res(1);
  nx = round(fov(1)/dx);
  ny = round(fov(2)/dy);
  xdata = [1 nx]*dx - dx/2;
  ydata = [1 ny]*dy - dy/2;
end


tic;

if VERBOSE,
  StatusTxt = sprintf('%s cp2tform(''%s'').',StatusTxt,METHOD);
  set(wgts.StatusField,'String',StatusTxt);  drawnow;
end 
mytform = cp2tform(input_points,base_points,METHOD);
if VERBOSE,
  StatusTxt = sprintf('%s imtransform()...',StatusTxt);
  set(wgts.StatusField,'String',StatusTxt);  drawnow;
end 

if size(tmpimg,3) > 2,
  % note that tmpimg as (y,x,color)
  regimg  = imtransform(tmpimg, mytform,...
                        'xdata',xdata,'ydata',ydata,'size',[ydata(2) xdata(2)],...
                        'FillValues',[255;255;255]);
  % convert RGB to indexed
  regimg  = rgb2ind(regimg,tmpmap);
else
  % note that tmpimg as (y,x) of indexed color or atlas IDs
  regimg  = imtransform(tmpimg, mytform,'nearest',...
                        'xdata',xdata,'ydata',ydata,'size',[ydata(2) xdata(2)],...
                        'FillValues',0);
end

NEW_DATA.img    = regimg;
NEW_DATA.map    = tmpmap;
NEW_DATA.coords = PINFO.coords(1);


NEW_DATA.tform.func         = 'imtransform';
NEW_DATA.tform.method       = METHOD;
NEW_DATA.tform.ana_resize   = [nx ny];
NEW_DATA.tform.base_points  = base_points;
NEW_DATA.tform.input_points = input_points;
NEW_DATA.tform.tform        = mytform;
NEW_DATA.tform.xdata        = xdata;
NEW_DATA.tform.ydata        = ydata;

T1 = toc;

if VERBOSE,
  StatusTxt = sprintf('%s done (%gs).',StatusTxt,T1);
  set(wgts.StatusField,'String',StatusTxt);  drawnow;
end 

return



% ========================================================================
function sub_DrawANA(wgts,haxs,cmap)
% ========================================================================

if nargin < 2,
  haxs = wgts.AnaAxs;
end
if nargin < 3,
  cmap = gray(256);
end
  

iSlice = round(str2double(get(wgts.AnaSliceEdt,'String')));
if isempty(iSlice) || isnan(iSlice),  return;  end

ANA = getappdata(wgts.main,'ANA');
if isempty(ANA),  return;  end

AnaScale = str2num(get(wgts.AnaScaleEdt,'String'));
if length(AnaScale) < 2,  return;  end
AnaGamma = str2double(get(wgts.AnaGammaEdt,'String'));
if isempty(AnaGamma),  return;  end

cmap = cmap.^(1/AnaGamma);

if get(wgts.UseEpiCheck,'Value'),
  EPI = getappdata(wgts.main,'EPI');
  tmpana = squeeze(EPI.dat(:,:,iSlice));
  tmpana = imresize(tmpana,[size(ANA.dat,1) size(ANA.dat,2)]);
else
  tmpana = squeeze(ANA.dat(:,:,iSlice));
end


if get(wgts.ImageOffCheck,'Value')
  tmpana(:) = 1;
else
  tmpana = (tmpana - AnaScale(1)) / (AnaScale(2) - AnaScale(1));
  tmpana = round(tmpana*256);
  tmpana(tmpana(:) > 256) = 256;
  tmpana(tmpana(:) <   1) =   1;
end
tmpana = ind2rgb(tmpana',cmap);

if 1
  tmpX = 1:size(tmpana,2);
  tmpY = 1:size(tmpana,1);
else
  % imtransform() doesn't accept floating values as coordinates...
  tmpX = (1:size(tmpana,2)) * ANA.ds(1) - ANA.ds(1)/2;
  tmpY = (1:size(tmpana,1)) * ANA.ds(2) - ANA.ds(2)/2;
end
  
set(wgts.main,'CurrentAxes',haxs);
TagAxs = get(haxs,'tag');
h = findobj(haxs,'tag','image-ana');
if any(h),
  xlm = get(haxs,'xlim');  ylm = get(wgts.AnaAxs,'ylim');
else
  xlm = [];  ylm = [];
end

h = findobj(haxs,'tag','image-ana');
if ishandle(h),
  delete(findobj(haxs,'tag','fpoint'));
  delete(findobj(haxs,'tag','fpoint-text'));
  set(h,'cdata',tmpana,'xdata',tmpX,'ydata',tmpY,'tag','image-ana');
else
  h = image(tmpX,tmpY,tmpana,'tag','image-ana');
end
%image(tmpX,tmpY,tmpana,'tag','image-ana');
set(gca,'fontsize',5);
set(gca,'xcolor',[0.8 0 0.8],'ycolor',[0.8 0 0.8]);
set(gca,'tag',TagAxs);
if get(wgts.GridOnCheck,'Value') > 0,
  grid on;
end


if ~isempty(xlm),
  set(gca,'xlim',xlm);  set(gca,'ylim',ylm);
else
  %daspect([1 1 1]);
end


T_ATLAS = getappdata(wgts.main,'T_ATLAS');
if ~isfield(T_ATLAS,'points'),  return;  end
if length(T_ATLAS.points) < iSlice,  return;  end
points = T_ATLAS.points(iSlice);

txtoffs = ceil(0.4/ANA.ds(1));


marker = get(wgts.MarkerCmb,'String');
marker = marker{get(wgts.MarkerCmb,'Value')};
mkrcol = sub_get_color(wgts.MarkerColorEdt,[1.0 1.0 0.0]);
txtcol = sub_get_color(wgts.TextColorEdt,  [0.3 0.3 1.0]);


hold on;
for N = 1:length(points.anax),
  tmpx = points.anax(N);
  tmpy = points.anay(N);
  plot(tmpx,tmpy,'marker',marker,'color',mkrcol,'markersize',10,'tag','fpoint');
  text(tmpx+txtoffs,tmpy-txtoffs,sprintf('%d',N),'color',txtcol,'fontsize',8,...
       'tag','fpoint-text');
end
hold off;


return



% ========================================================================
function sub_DrawATLAS(wgts)
% ========================================================================

iSlice = round(get(wgts.AtlasSldr,'Value'));
if isempty(iSlice) || isnan(iSlice),  return;  end

ATLAS = getappdata(wgts.main,'ATLAS');
if isempty(ATLAS),  return;  end
if iSlice < 1,  iSlice = 1;  end
if iSlice > length(ATLAS),  iSlice = length(ATLAS);  end


cmap = ATLAS(iSlice).map;
if get(wgts.ReverseBWCheck,'Value')
  % reverse black/white,  B<-->W
  if getappdata(wgts.main,'ATLAS_AS_IMAGE') == 0,
    tmpw = cmap(:,1) == 1.0 & cmap(:,2) == 1.0 & cmap(:,3) == 1.0;
    %tmpb = cmap(:,1) == 0.0 & cmap(:,2) == 0.0 & cmap(:,3) == 0.0;
    tmpb = [];
  else
    tmpw = cmap(:,1) > 0.8 & cmap(:,2) > 0.8 & cmap(:,3) > 0.8;
    tmpb = cmap(:,1) < 0.2 & cmap(:,2) < 0.2 & cmap(:,3) < 0.2;
  end
  cmap(tmpw,:) = 0;
  cmap(tmpb,:) = 1;
end

tmpimg = ATLAS(iSlice).img;
% if get(wgts.FlipLRCheck,'Value'),
%   % note that tmpimg as (y,x)
%   tmpimg = flipdim(tmpimg,2);
% end

if getappdata(wgts.main,'ATLAS_AS_IMAGE') == 0 && get(wgts.GroupRoisCheck,'value') > 0,
  cmap = sub_group_rois(wgts,tmpimg,cmap);
end
tmpimg = ind2rgb(double(tmpimg),cmap);   % ind2rgb() has bugs when tmpimg as int16...

if get(wgts.ImageOffCheck,'Value')
  if get(wgts.ReverseBWCheck,'Value')
    tmpimg(:) = 0;
  else
    tmpimg(:) = 1;
  end
end



dx = ATLAS(1).res(2);
dy = ATLAS(1).res(1);

if 1
  tmpX = 1:size(tmpimg,2);
  tmpY = 1:size(tmpimg,1);
else
  % imtransform() doesn't accept floating values as coordinates...
  tmpX = (1:size(tmpimg,2)) * dx - dy/2;
  tmpY = (1:size(tmpimg,1)) * dy - dy/2;
end
  
set(wgts.main,'CurrentAxes',wgts.AtlasAxs);
h = findobj(wgts.AtlasAxs,'tag','image-atlas');
if any(h),
  xlm = get(wgts.AtlasAxs,'xlim');  ylm = get(wgts.AtlasAxs,'ylim');
else
  xlm = [];  ylm = [];
end

%tmpimg = imresize(tmpimg,round([size(tmpimg,1) size(tmpimg,2)]/3));
%tmpimg(tmpimg(:) < 0) = 0;
%tmpimg(tmpimg(:) > 1) = 1;
%tmpX = 1:size(tmpimg,2);
%tmpY = 1:size(tmpimg,1);

% delete labels
delete(findobj(wgts.AtlasAxs,'tag','label-atlas'));

% draw, update
h = findobj(wgts.AtlasAxs,'tag','image-atlas');
if ishandle(h),
  delete(findobj(wgts.AtlasAxs,'tag','fpoint'));
  delete(findobj(wgts.AtlasAxs,'tag','fpoint-text'));
  set(h,'cdata',tmpimg,'xdata',tmpX,'ydata',tmpY,'tag','image-atlas');
else
  h = image(tmpX,tmpY,tmpimg,'tag','image-atlas');
end



%image(tmpX,tmpY,tmpimg,'tag','image-atlas');
%h = imshow(tmpimg,'xdata',tmpX,'ydata',tmpY);
%set(h,'tag','image-atlas');
set(gca,'fontsize',5);
set(gca,'xcolor',[0.8 0 0.8],'ycolor',[0.8 0 0.8]);
set(gca,'tag','AtlasAxs');
if get(wgts.GridOnCheck,'Value') > 0,
  grid on;
end

if ~isempty(xlm),
  set(gca,'xlim',xlm);  set(gca,'ylim',ylm);
else
  %daspect([1 1 1]);
end


% set the callback,  NOTE that this will interfere with fiducial point functions...
%set(h,...
%	'ButtonDownFcn','mroiatlas(''Main_Callback'',gcbo,''atlas-button-down'',[])');




iAnaSlice = round(str2double(get(wgts.AnaSliceEdt,'String')));
if isempty(iAnaSlice) || isnan(iAnaSlice),  return;  end

T_ATLAS = getappdata(wgts.main,'T_ATLAS');
if ~isfield(T_ATLAS,'points'),  return;  end
if length(T_ATLAS.points) < iAnaSlice,  return;  end
points = T_ATLAS.points(iAnaSlice);

% use x1000 to avoid str2double() problem...
if round(ATLAS(iSlice).coords*1000)/1000 ~= round(points.coords*1000)/1000,
  fprintf('atlas=%g,  points=%g\n',ATLAS(iSlice).coords,points.coords);
  return;
end


marker = get(wgts.MarkerCmb,'String');
marker = marker{get(wgts.MarkerCmb,'Value')};
mkrcol = sub_get_color(wgts.MarkerColorEdt,[1.0 1.0 0.0]);
txtcol = sub_get_color(wgts.TextColorEdt,  [0.3 0.3 1.0]);

txtoffs = ceil(0.4/ATLAS(iSlice).res(1));

hold on;
for N = 1:length(points.atlasx),
  tmpx = points.atlasx(N);
  tmpy = points.atlasy(N);
  plot(tmpx,tmpy,'marker',marker,'color',mkrcol*0.7,'markersize',10,'tag','fpoint');
  text(tmpx+txtoffs,tmpy-txtoffs,sprintf('%d',N),'color',txtcol,'fontsize',8,...
       'tag','fpoint-text');
end
hold off;



return




% ========================================================================
function sub_DrawOverlay(wgts)
% ========================================================================

if get(wgts.OverlayUpdateCheck,'Value') == 0,  return;  end

iSlice = round(str2double(get(wgts.AnaSliceEdt,'String')));
if isempty(iSlice) || isnan(iSlice),  return;  end

ANA = getappdata(wgts.main,'ANA');
if isempty(ANA),  return;  end

AnaScale = str2num(get(wgts.AnaScaleEdt,'String'));
if length(AnaScale) < 2,  return;  end
AnaGamma = str2double(get(wgts.AnaGammaEdt,'String'));
if isempty(AnaGamma),  return;  end

cmap = gray(256);
cmap = cmap.^(1/AnaGamma);


NEW_ATLAS.img    = [];
NEW_ATLAS.map    = [];
NEW_ATLAS.res    = [];
NEW_ATLAS.coords = [];
NEW_ATLAS.tform.ana_resize = [];


% get the current Atlas coords.
ATLAS = getappdata(wgts.main,'ATLAS');
tmpcoords = str2double(get(wgts.AtlasSliceEdt,'String'));
if isempty(tmpcoords) || isnan(tmpcoords),
  tmpidx = round(get(wgts.AtlasSldr,'Value'));
  tmpcoords = ATLAS(tmpidx).coords;
end

% check the existing transformation
T_ATLAS = getappdata(wgts.main,'T_ATLAS');
if isfield(T_ATLAS,'atlas') && length(T_ATLAS.atlas) >= iSlice,
  NEW_ATLAS = T_ATLAS.atlas(iSlice);
end


% use x1000 to avoid str2double() problem...
if isempty(NEW_ATLAS.img) || ~isequal(round(NEW_ATLAS.coords*1000)/1000,round(tmpcoords*1000)/1000),
  % use the current
  tmpslice = round(get(wgts.AtlasSldr,'Value'));
  NEW_ATLAS.img = ATLAS(tmpslice).img;
  % if get(wgts.FlipLRCheck,'Value'),
  %   % note that img as (y,x)
  %   NEW_ATLAS.img = flipdim( NEW_ATLAS.img,2);
  % end
  NEW_ATLAS.map = ATLAS(tmpslice).map;
  xlm = round(get(wgts.AtlasAxs,'xlim'));
  ylm = round(get(wgts.AtlasAxs,'ylim'));
  x1 = max([xlm(1) 1]);
  x2 = min([xlm(2) size(NEW_ATLAS.img,2)]);
  y1 = max([ylm(1) 1]);
  y2 = min([ylm(2) size(NEW_ATLAS.img,1)]);
  NEW_ATLAS.img = NEW_ATLAS.img(y1:y2,x1:x2);
  NEW_ATLAS.tform = [];
  NEW_ATLAS.tform.ana_resize = [size(NEW_ATLAS.img,2), size(NEW_ATLAS.img,1)];
end

if get(wgts.UseEpiCheck,'Value'),
  EPI = getappdata(wgts.main,'EPI');
  tmpana = squeeze(EPI.dat(:,:,iSlice));
  tmpana = imresize(tmpana,[size(ANA.dat,1) size(ANA.dat,2)]);
else
  tmpana = squeeze(ANA.dat(:,:,iSlice));
end

tmpana = (tmpana - AnaScale(1)) / (AnaScale(2) - AnaScale(1));

if isfield(NEW_ATLAS,'tform') && ~isempty(NEW_ATLAS.tform.ana_resize),
  SX = NEW_ATLAS.tform.ana_resize(1) / size(tmpana,1);
  SY = NEW_ATLAS.tform.ana_resize(2) / size(tmpana,2);
  if SX ~= 1 || SY ~= 1,
    tmpana = imresize(tmpana,NEW_ATLAS.tform.ana_resize);
  end
end


tmpana = round(tmpana*256);
tmpana(tmpana(:) > 256) = 256;
tmpana(tmpana(:) <   1) =   1;
tmpana = ind2rgb(tmpana',cmap);


if get(wgts.OverlayCheck,'Value') > 0 && ~isempty(NEW_ATLAS.img),
  cmap = NEW_ATLAS.map;
  if get(wgts.OverlayReverseBWCheck,'Value')
    % reverse black/white,  B<-->W
    if getappdata(wgts.main,'ATLAS_AS_IMAGE') == 0,
      tmpw = cmap(:,1) == 1.0 & cmap(:,2) == 1.0 & cmap(:,3) == 1.0;
      %tmpb = cmap(:,1) == 0.0 & cmap(:,2) == 0.0 & cmap(:,3) == 0.0;
      tmpb = [];
    else
      tmpw = cmap(:,1) > 0.8 & cmap(:,2) > 0.8 & cmap(:,3) > 0.8;
      tmpb = cmap(:,1) < 0.2 & cmap(:,2) < 0.2 & cmap(:,3) < 0.2;
    end
    cmap(tmpw,:) = 0;
    cmap(tmpb,:) = 1;
  end
  tmpimg = NEW_ATLAS.img;
  if getappdata(wgts.main,'ATLAS_AS_IMAGE') == 0 && get(wgts.GroupRoisCheck,'value') > 0,
    cmap = sub_group_rois(wgts,tmpimg,cmap);
  end
  tmpimg = ind2rgb(double(tmpimg),cmap);   % ind2rgb() has bugs when tmpimg as int16...

  % now fuse images
  sz_ana = size(tmpana);
  tmpana = reshape(tmpana,[sz_ana(1)*sz_ana(2) sz_ana(3)]);
  sz_img = size(tmpimg);
  tmpimg = reshape(tmpimg,[sz_img(1)*sz_img(2) sz_img(3)]);

  if getappdata(wgts.main,'ATLAS_AS_IMAGE') == 0,
    if get(wgts.OverlayReverseBWCheck,'Value')
      tmpidx = find(tmpimg(:,1) > 0.0 | tmpimg(:,2) > 0.0 | tmpimg(:,3) > 0.0);
    else
      tmpidx = find(tmpimg(:,1) < 1.0 | tmpimg(:,2) < 1.0 | tmpimg(:,3) < 1.0);
    end
  else  
    if get(wgts.OverlayReverseBWCheck,'Value')
      tmpidx = find(tmpimg(:,1) > 0 & tmpimg(:,2) > 0 & tmpimg(:,3) > 0);
    else
      tmpidx = find(tmpimg(:,1) < 0.9 & tmpimg(:,2) < 0.9 & tmpimg(:,3) < 0.9);
    end
  end
  tmpana(tmpidx,:) = tmpimg(tmpidx,:);

  tmpana = reshape(tmpana,sz_ana);
  tmpimg = reshape(tmpimg,sz_img);
end

tmpX = 1:size(tmpana,2);
tmpY = 1:size(tmpana,1);
set(wgts.main,'CurrentAxes',wgts.OverlayAxs);

h = findobj(wgts.AtlasAxs,'tag','image-tform');
if ishandle(h),
 delete(findobj(wgts.AtlasAxs,'tag','fpoint'));
 delete(findobj(wgts.AtlasAxs,'tag','fpoint-text'));
 set(h,'cdata',tmpana,'xdata',tmpX,'ydata',tmpY,'tag','image-tform');
else
 h = image(tmpX,tmpY,tmpana,'tag','image-tform');
end
%h = image(tmpX,tmpY,tmpana,'tag','image-tform');

if get(wgts.GridOnCheck,'Value') > 0,
  grid on;
end

if isfield(NEW_ATLAS,'tform') && isfield(NEW_ATLAS.tform,'base_points'),
  base_points = NEW_ATLAS.tform.base_points;
  txtoffs = ceil(0.4/NEW_ATLAS.res(2));
  marker = get(wgts.MarkerCmb,'String');
  marker = marker{get(wgts.MarkerCmb,'Value')};
  mkrcol = sub_get_color(wgts.MarkerColorEdt,[1.0 1.0 0.0]);
  txtcol = sub_get_color(wgts.TextColorEdt,  [0.3 0.3 1.0]);
  hold on;
  for N = 1:length(base_points),
    x = base_points(N,1);
    y = base_points(N,2);
    plot(x,y,'marker',marker,'color',mkrcol,'markersize',10,'tag','fpoint');
    text(x+txtoffs,y-txtoffs,sprintf('%d',N),'color',txtcol,'fontsize',8,...
         'tag','fpoint-text');
  end
  tmptxt = sprintf('Transformed : Ana(%d)-Atlas(%+g)',iSlice,NEW_ATLAS.coords(1));
  text(0.01,0.99,tmptxt,'color','y','units','normalized',...
       'VerticalAlignment','top');
  hold off;
else
  text(0.01,0.99,'No Transformation','color','y','units','normalized',...
       'VerticalAlignment','top');
end

set(gca,'fontsize',5);
set(gca,'xcolor',[0.8 0 0.8],'ycolor',[0.8 0 0.8]);
set(wgts.OverlayAxs,'Tag','OverlayAxs');

return


% ========================================================================
function NEW_CMAP = sub_group_rois(wgts,IMG,CMAP)

ROI_TABLE = getappdata(wgts.main,'ROI_TABLE');
if isempty(ROI_TABLE),  return;  end

GROI = getappdata(wgts.main,'GROI');
if isempty(GROI),  return;  end

aset  = get(wgts.AtlasSetCmb,'String');
aset  = aset{get(wgts.AtlasSetCmb,'Value')};
switch lower(aset),
 case {'rat : rat2013'}
  NEW_CMAP = CMAP;
  return;
end


% Get ROI names
vals  = sort(unique(IMG(:)));
vals  = vals(vals > 0);
names = {};
for N = 1:length(vals),
  for K = 1:length(ROI_TABLE),
    if ROI_TABLE{K}{1} == vals(N),
      %names{N} = ROI_TABLE{K}{2};  full name
      names{N} = ROI_TABLE{K}{3};
      break;
    end
  end
end

% Update the color for grouped ROIs.
NEW_CMAP = repmat(CMAP(1,:),[size(CMAP,1),1]);
%NEW_CMAP = CMAP;
for N = 1:length(names),
  if isempty(names{N}),  continue;  end
  for K = 1:length(GROI),
    if any(strcmpi(GROI{K}{4},names{N})),
      NEW_CMAP(vals(N),:) = GROI{K}{3};
      %NEW_CMAP(vals(N),:) = [1 0 0];  % testing...
      break;
    end
  end
end


return


function GROI = sub_roi_group_list_rat()
%HENRY 2013-01-09: I replaced this list with the list I modified in
%paxroigroups. I will keep updating this list in parallel with my work in
%paxroigroups. I'll change the date above accordingly. 
GROI = {};
% METENCEPHALON (PONS + CEREBELLUM)++++++++++++++++++++++++++++++++++++++++
% Cerebellum (dorsal met.)-------------------------------------------------
% proximal muscles - trunk/posture - spinocerebellum proximal  
GROI{end+1} =  {'Vermis','Vermis', [0.57 0.06 0.20], {'vermis'}};                    
% distal muscles - limbs - spinocerebellum distal
GROI{end+1} =  {'IntHemCb','Intermediate cerebellar hemisphere', [0.59 0.06 0.39],...
                {'inthemCb'}};                                            
% proximal muscles - trunk/posture - spinocerebellum proximal
GROI{end+1} =  {'alCb','Anterior cerebellar lobe', [0.63 0.06 0.78], {'alCb'}};
% receive cortical afferent from the pontine nucleus - cerebrocerebellum
GROI{end+1} =  {'LatHemCb','Lateral cerebellar hemisphere', [0.61 0.06 0.59],...
                {'lathemCb'}};                                           
% receive vestibular afferent - vestibullo/oculocerebellum 
GROI{end+1} =  {'pflCb','Parafloculonodular', [0.90 0.22 0.78],...
                {'pflCb'}};                                               
% output of the cerebellum - massive projections to thalamus (+few others)
GROI{end+1} =  {'DCbN', 'Deep cerebellar nuclei', [.2 .2 1],...
                {'DCbN'}};

% Pons (ventral met.)------------------------------------------------------
GROI{end+1} =  {'PontReg','Pontine Region',[.7 .7 .7],... %HENRY: renamed as in mky
                {'lfp','Pn','PnO','RtTg','RtTgP','tfp'}};
GROI{end+1} =  {'Raphe', 'Raphe', [.2 .2 1],... %Already as in mky
                {'CLi','DR','DRC','DRV','DRVL','PMnR','RLi','MnR'}};          
       
% MESENCEPHALON++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GROI{end+1} =  {'MesE','MesE',[.2 .2 .2],... %not mapped in mky
                {'DpMe','APT','IMLF','IMLFG','PaR','REth','RMC','RPC'}};

%Tectum--------------------------------------------------------------------
GROI{end+1} =  {'SC', 'Superior Colliculus',      [.4 .3 .1],...
                {'DpG','DpGWh','DpWh','InG','InWh','Op','SuG','SC'}};
GROI{end+1} =  {'InfCol',  'Inferior Colliculus', [0.08 0.22 0.39],...  %added
                {'BIC','CIC','cic','ECIC','IC','DCIC','bic'...
                 'PBG'}};

% Tegmentum-----------(many small areas omitted)---------------------------
GROI{end+1} =  {'PAG', 'Periaqueductal Gray', [.5 .5 .5],... %renamed
                {'DLPAG','DMPAG','LPAG','PAG','Su3','Su3C','VLPAG'}};
     
           
% DIENCEPHALON+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%Basal Forebrain-----------------------------------------------------------             
GROI{end+1} =  {'DB+MS', 'Diagonal Band + Septum', [.3 .5 .7],... %IMO, too small to be drawn spearately, like in monkeys
                {'HDB','VDB', 'df','f','Ld','LSD','LSI','LSV','MS',...
                 'PLd','SFi','SHi','SL','TS'}};                          
%GROI{end+1} =  {'DB', 'DiagonalBand', [.3 .5 .7], {'HDB','VDB'}};
%GROI{end+1} =  {'Septum', 'Septum', [.2 1 .2],...
%               {'df','f','Ld','LSD','LSI','LSV','MS','PLd','SFi','SHi','SL','TS'}};
GROI{end+1} =  {'BNST', 'StriaTerm', [.5 0 0],... %not yet mapped in mky
                {'BSTL',',BSTLD','BSTLI','BSTLJ','BSTLP','BSTLV','BSTMA',...
                 'BSTMPI','BSTMPL','BSTMPM','BSTMV','BSTS'}};
             
%Basal Ganglia-------------------------------------------------------------
GROI{end+1} =  {'Striatum',  'Striatum', [.5 .8 1],... %inserted Accumbens
                {'CPu','AcbC','AcbSh', 'LAcbSh', 'aca_intraAcb'}};                      
GROI{end+1} =  {'GP',  'Globus Pallidus', [.5 .8 1],... %separated from striatum
                {'LGP','MGP','VP'}}; %added MGP
%GROI{end+1} =  {'Acc', 'Accumbens', [1 0 0],...  %now in Striatum
               % {'AcbC', 'AcbSh', 'LAcbSh', 'aca_intraAcb'}};          
GROI{end+1} =  {'SN','SubNigra',[.3 .1 .6],...
                {'PBP','PN','SN','SNCD','SNL','SNM','SNR','SNRDM','SNRVL'}};
GROI{end+1} =  {'VTA','Ventral Tegmental Area', [.4 .6 1], {'VTA'}}; 

%Smaller and 'hard to map' regions-----------------------------------------
%GROI{end+1} =  {'IPAC', 'Interpeduncular-Interestitial',[.3 .5 .7],...
                %{'IPAC','IPACL','IPACM','IP','IPA','IPD','IPL','IPR','IPRL'}};
                % HENRY: WAY TO SMALL AND POSSIBLY TOO VENTRAL

%Hypothalamus------------------------------------------------------------
GROI{end+1} =  {'HTh', 'Hypothalamus', [0 .5 0]...
                {'HTv','HTd','AHA','AHC','AHP','ArcD','ArcL','ArcLP','ArcM',...
                 'ArcMP','Cir','DA','DMC','DMD','DMV','DTM','Gem','LA','LH','LM','LPO',...
                 'MCLH','MEE','MEI','ML','MM','MMn','mp','MPA','MPO','MPOL','MPOM','MRe','MTu',...
                 'PaAM','PaAP','PaDC','PaLM','PaMP','PaPo','PaPo','PaV','Pe','PeF','PH','pm',...
                 'PMD','PMV','Rch','SMT','SuM','SuML','SuMM','TC','Te','VLH','VMHA','VMHC',...
                 'VMHDM','VMHVL','VTM'}};
             
GROI{end+1} =  {'Amy', 'Amygdala', [.8 0 0],...
                {'amyg','AA','AAD','AAV','Aco','AHiAL','AHiPM','APir',...
                 'AStr','BLA','BLP','BLV','BMA','BMP','BSTIA','CeC','CeL','CeM','CxA',...
                 'I','IM','IMG','LaVL','LaVM','MeAD','MePD','MePV','PLCo','PMCo'}};
          
GROI{end+1} =  {'HP', 'Hippocampus', [1 0 0],...
                {'CA3d','DGd','hc_fd','hc_d','DS','hc_v','CA3v','VS','DGv','PoDG','STr', ...
                 'PAs','Post','PrS'}};
             
GROI{end+1} =  {'Tha', 'Thalamus',                [1 .8 .5],...
                {'CL','CM','fr','IAD','IMD','iml','imvc','LHb','LHbL','LHbM','MD',...
                 'MDC','MDL','MDM','MDPL','OPC','PC','PF','PoMn','PT','pv','PV','PVA', ...
                 'PVP','SM','sm','SPF','SPFPC','AD','AM','Ang','AV', ...
                 'AVDM','AVVL','DLG','Eth','IMA','LDDM','LDVL','LPL','LPLC','LPLR',...
                 'LPMC','LPMR','PIL','Po','PoT','Rt','Sc','SG','VA','VL','VLG',...
                 'VLGMC','VLGPC','VM','VPL','VPM','VPPC','AMV','IAM','mt','Re',...
                 'Rh','Sub','SubD','SubV','VRe','MGD','MGV'}};
             
%GROI{end+1} =  {'MGN','MGN',[.4 .4 .4], {'MGD','MGV'}}; %moved to thalamus
%GROI{end+1} =  {'SubInn','SubInn',[.4 1 .4], {'SI','SIB','SID','SIV'}};
%GROI{end+1} =  {'ZoIns','Zona Inserta', [.7 .5 .3], {'ZI','ZID','ZIV'}};

%TELENCEPHALON - CORTICAL++++++++++++++++++16 GROI's+++++++++++++++++++++++
GROI{end+1} =  {'Olf','Olfactory',[ .3 .3 .3],...
                {'AOD','AOE','AOL','AOM','AOP','aci','Tu1','Tu2','Tu3','Tu'}};
GROI{end+1} =  {'Ent', 'Entorhinal Cortex',      [0 1 0],...
                {'DEn','Ect','LEnt','PRh','VEn','MEnt'}};         
GROI{end+1} =  {'PirFo','Piriform Cortex',[.1 .5 .1], {'Pir/ext','Pir/int','Pir','PirCtx'}}; 

%Sensorimotor Areas--------------------------------------------------------
GROI{end+1} =  {'Motor','Motor Cortex', [.3 .4 .9], {'M1','M2'}};
GROI{end+1} =  {'Som', 'Somatosensory Cortex',    [1 0 1],...
                {'S1','S1BF','S1DZ','S1FL','S1HL','S1J','S1JO','S1Tr','S1ULp','S2'}};

%Insular Areas-------------------------------------------------------------
GROI{end+1} =  {'Ins', 'Insular Cortex', [.7 1 .5], {'AI','AID','AIP','AIV','DI','GI'}};

%Cingulate Areas-----------------------------------------------------------
GROI{end+1} =  {'Cing','Cingulate', [1 0 0], {'Cg1','Cg2'}};
GROI{end+1} =  {'RetSplen', 'Retrosplenial Cortex', [1 0 0], {'RSA','RSGa','RSGb'}};  %part of the cingulate... Important for antergrade amnesia, connections with HP and Anterior Thalamus

%Prefrontal Areas----------------------------------------------------------
GROI{end+1} =  {'OrbFro','Orbitofronal Cortex', [.5 .5 0], {'DLO','LO','MO','VO'}};
GROI{end+1} =  {'PFC','Prefrontal Cortex', [1 .4 .4], {'FrA','DP','IL','PrL'}};

%Visual Areas--------------------------------------------------------------
GROI{end+1} =  {'V1','Primary Visual Cortex', [0 1 0], {'V1B','V1M'}};
GROI{end+1} =  {'V2','Area V2', [0 .7 0], {'V2L','V2ML','V2MM'}};

%Auditory Areas------------------------------------------------------------
GROI{end+1} =  {'A1','Primary Auditory Cortex', [0 0 1], {'Au1'}};
GROI{end+1} =  {'A2','Secondary Auditory Cortex', [0 0 .7], {'AuD','AuV'}};

%Temporal Associative------------------------------------------------------
GROI{end+1} =  {'Temp','Temporal Association Cortex', [0 .5 0],{'TeA'}}; %replaced PtA with TeA

%Parietal Associative------------------------------------------------------
GROI{end+1} =  {'Par','Parietal Association Cortex', [.5 0 0], {'PtA'}};
return

function GROI = sub_roi_group_list_macaque()
%HENRY 2013-01-04: I guess this list is obsolete and will never be used
%again. Right?
GROI = {};
GROI{end+1} =  {'HP', 'Hippocampus',              [1 0 0],...
                {'DG' 'HipF' 'CA1' 'CA1''' 'CA2' 'CA3' 'CA4' 'IG' ...
                 'S' 'PaS' 'ProS' 'PrS' 'SS' 'Shi'} };

GROI{end+1} =  {'Ent', 'Enthorhinal Cortex',      [0 1 0],...
                {'EC' 'ECL' 'EI' 'EL' 'ELC' 'ELR' 'EOI' 'ER'} };

GROI{end+1} =  {'Vis', 'Visual Cortex',           [0 0 1],...
                {'V1' 'V2' 'V3' 'V3D' 'V3V' 'V3A' ...
                 'V4' 'V4A' 'V4D' 'V4V' 'V4T' 'MT'} };

GROI{end+1} =  {'Aud', 'Auditory Cortex',         [1 1 0],...
                {'AKL' 'AKM'} };

GROI{end+1} =  {'Som', 'Somatosensory Cortex',    [1 0 1],...
                {'S1' '1' '2' '2Ve' '2/1' '3a' '3b' 'S2' 'S2E' 'S2I'} };

GROI{end+1} =  {'Mot', 'Motor Cortex',            [0 1 1],...
                {'4(F1)'} };

GROI{end+1} =  {'Ass', 'Association Cortex',      [.8 .5 1],...
                {'INS' 'AI' 'DI' 'GI' 'Ipro'} };

GROI{end+1} =  {'SC', 'Superior Colliculus',      [.4 .3 .1],...
                {'bsc' 'csc' 'DpG' 'DpWh' 'InG' 'InWh' 'Op' 'SuG' 'Zo'} };

GROI{end+1} =  {'Tha', 'Thalamus',                [1 .8 .5],...
                {'AThal' 'AD' 'AM' 'AV' 'IAM' 'CMn' 'CMnL' 'CMnM' 'ithp' 'LThal' ...
                 'CL' 'LDt' 'LDSF' 'VA' 'VAL' 'VAL(pal)' 'VAL(VO)' 'VAL(VO)+pal' ...
                 'VAM' 'VAMC' 'VL' 'VLL' 'VLM' 'VPThal' 'VPL' 'VPM' 'MedLam' ...
                 'eml' 'iml' 'MG' 'MGD' 'MGM' 'MGV' 'mt' 'MThal' 'CM' 'IMD' 'MD' ...
                 'MDC' 'MDD' 'MDL' 'MDM' 'PC' 'PF' 'PT' 'Pul' 'Apul' 'Ipul' 'Lpul' 'MPul' ...
                 'PV' 'PVA' 'PVP' 'Re' 'Rt' 'SG' 'SPF' 'SPFPC' 'Xi'} };

GROI{end+1} =  {'BG',  'Basal Ganglia',           [.5 .8 1],...
                {'Acb' 'AcbC' 'AcbSh' 'ICj' 'ICjM' 'Cd' 'Cl' 'Pall' 'EGP' 'IGP' 'VP' ...
                 'Pu' 'SN' 'SNV' 'SNVL' 'SNC' 'SNCV' 'SND' 'SNL' 'VTA'} };

GROI{end+1} =  {'Lmb', 'Limbic System',           [.6 .6 0],...
                {'Amyg' 'AA' 'BL' 'BLD' 'BLDL' 'BLI' 'BLV' 'BLVL' 'BLVM' ...
                 'BM' 'BMMC' 'BMPC' 'BMPCD' 'BMPCV' 'BMPCVM' 'Ce' 'CeL' 'CeM' 'I' 'IMG' ...
                 'La' 'Me' 'CeMV' 'PaL' 'PaLGl' 'VACo' 'VCo' 'VColn' 'VColnf' 'VCoSu' ...
                 'Pir' 'DEn' 'VEn' 'CG' 'ACG' 'Cg1' 'Cg2' 'PECg' 'cgs' 'Spt' 'LS' 'LSD' 'LSV' ...
                 'MS' 'TS' 'HDB' 'VDB' 'BST' 'BSTL' 'BSTLD' 'BSTLI' 'BSTLJ' 'BSTM' 'BSTMA' ...
                 'BSTMP' 'BSTMPL' 'BSTMPM' 'BSTMV' 'SFi' 'SHi' 'SHy' 'f' 'OlfSys' ...
                 'AO' 'AOL' 'AOM' 'Olb' 'OlfTract' 'lo' 'Tu' } };

  
GROI{end+1} =  {'ME',  'Mesencephalic System',    [0.1 0.1 0.1],...
                {'PAG' 'LPAG' 'DLPAG' 'DMPAG' 'Su3' 'Su3C' 'CGPn' 'Pn' 'DPPN' 'VPPn' 'DMPn' ...
                 'PnR' 'PnC' 'PnO' 'gamma' 'PPTg' 'RtTg' 'RtTgP' 'mcp' 'scp' 'ptpn' 'LC' ...
                 'DLL' 'VLL' 'SOI' 'LSO' 'MSO' 'tz' 'DR' 'DRC' 'DRD' 'DRI' 'DRV' 'DRVL' ...
                 'MnR' 'PMnR' 'RIP' 'RMg' 'ROb' 'RPa' 'CLi' 'RLi' 'DpMe' 'APT' 'IMLF' ...
                 'RI' 'ml' 'R' 'RMC' 'RPC' 'RRF' } };
return



% ========================================================================
function sub_TextATLAS(wgts,XY)

ROI_TABLE = getappdata(wgts.main,'ROI_TABLE');
if isempty(ROI_TABLE),  return;  end

if isempty(XY),
  pt = get(wgts.AtlasAxs,'CurrentPoint');
  XY = [pt(1,1) pt(1,2)];
end
tmpx = XY(1);  tmpy = XY(2);


iSlice = round(get(wgts.AtlasSldr,'Value'));
if isempty(iSlice) || isnan(iSlice),  return;  end

ATLAS = getappdata(wgts.main,'ATLAS');
if isempty(ATLAS),  return;  end
if iSlice < 1,  iSlice = 1;  end
if iSlice > length(ATLAS),  iSlice = length(ATLAS);  end


% note that .img as (y,x)
aimg = ATLAS(iSlice).img;
if tmpx > size(aimg,2), tmpx = size(aimg,2);  end
if tmpx < 1,            tmpx = 1;             end
if tmpy > size(aimg,1), tmpy = size(aimg,1);  end
if tmpy < 1,            tmpy = 1;             end

%keyboard
%size(aimg)

tmpv = aimg(round(tmpy),round(tmpx));
if tmpv == 0,  return;  end

tmptxt = '';
for N = 1:length(ROI_TABLE),
  if ROI_TABLE{N}{1} == tmpv,
    if get(wgts.GroupRoisCheck,'value') > 0,
      tmptxt = ROI_TABLE{N}{3};
      GROI = getappdata(wgts.main,'GROI');
      for K = 1:length(GROI),
        if any(strcmpi(GROI{K}{4},tmptxt)),
          tmptxt = GROI{K}{1};
          break
        end
      end
    else
      %tmptxt = ROI_TABLE{N}{2};  % full name
      tmptxt = ROI_TABLE{N}{3};
    end
    tmptxt = strrep(tmptxt,'^','\^');
    tmptxt = strrep(tmptxt,'_','\_');
    %tmptxt = sprintf('%d/%s',tmpv,tmptxt);
    set(wgts.main,'CurrentAxes',wgts.AtlasAxs);
    text(tmpx,tmpy,tmptxt,'color','k','tag','label-atlas',...
         'horizontalalignment','center','verticalalignment','middle');
    break;
  end
end


return




% ========================================================================
function colv = sub_get_color(hEdt,DefaultColor)
% ========================================================================

colv = [];
tmpv = get(hEdt,'String');

% rgbcmykw
switch lower(tmpv)
 case {'r' 'red'}
  colv = [1.0  0.0  0.0];
 case {'g' 'green'}
  colv = [0.0  1.0  0.0];
 case {'b' 'blue'}
  colv = [0.0  0.0  1.0];
 case {'c' 'cyan'}
  colv = [0.0  1.0  1.0];
 case {'m' 'magenta'}
  colv = [1.0  0.0  1.0];
 case {'y' 'yellow'}
  colv = [1.0  1.0  0.0];
 case {'k' 'black'}
  colv = [0.0  0.0  0.0];
 case {'w' 'white'}
  colv = [1.0  1.0  1.0];
 otherwise
  tmpv = str2num(tmpv);
  if length(tmpv) == 3,  colv = tmpv;  end
end


if isempty(colv),  colv = DefaultColor;  end


return



% ========================================================================
function sub_create_roi(wgts,T_ATLAS)
% ========================================================================

ses = getappdata(wgts.main,'Ses');
grp = getappdata(wgts.main,'Grp');

tcAvgImg = sigload(ses,grp.exps(1),'tcImg');


% make ATLAS as EPI-volume size
nx = size(tcAvgImg.dat,1);
ny = size(tcAvgImg.dat,2);
nz = size(tcAvgImg.dat,3);
ATLAS.dat = zeros(nx,ny,nz);

aset  = get(wgts.AtlasSetCmb,'String');
aset  = aset{get(wgts.AtlasSetCmb,'Value')};
switch lower(aset),
 case {'rat : rat2013'}
  txtfile = fullfile(fileparts(which(mfilename,'fullpath')),'atlas_data/rathead16T_atlas.txt');
 otherwise
  txtfile = fullfile(fileparts(which(mfilename,'fullpath')),'atlas_data/atlas_structDefs');
end
ATLAS.roitable = mratatlas_roitable(txtfile);

for N = 1:length(T_ATLAS.atlas),
  % note that T_ATLAS.atlas(N).img as (y,x)
  tmpimg = T_ATLAS.atlas(N).img';
  tmpimg = imresize(tmpimg,[nx ny],'nearest');
  ATLAS.dat(:,:,N) = tmpimg;
end


% create roi
INFO.minvoxels = 1;

uniqroi = sort(unique(ATLAS.dat(:)));
ROIroi = {};
ROInames = {};
maskimg = zeros(nx,ny);

for N=1:length(uniqroi),
  roinum  = uniqroi(N);
  tmpname = '';
  for K=1:length(ATLAS.roitable),
    if ATLAS.roitable{K}{1} == roinum,
      tmpname = ATLAS.roitable{K}{3};
      break;
    end
  end
  %tmpname
  if isempty(tmpname),  continue;  end
  if roinum < 0,
    tmpname = fprintf('%s OH',tmpname);
  end
  
  idx = find(ATLAS.dat(:) == roinum);
  if length(idx) < INFO.minvoxels,  continue;  end
  %if length(idx) < 300,  continue;  end

  [tmpx tmpy tmpz] = ind2sub([nx ny nz],idx);
  uslice = sort(unique(tmpz(:)));
  for S=1:length(uslice),
    maskimg(:) = 0;
    slice = uslice(S);
    selvox = find(tmpz == slice);
    tmpidx = sub2ind([nx ny],tmpx(selvox),tmpy(selvox));
    maskimg(tmpidx) = 1;

    tmproiroi.name  = tmpname;
    tmproiroi.slice = slice;
    tmproiroi.px    = [];
    tmproiroi.py    = [];
    tmproiroi.mask  = logical(maskimg);

    ROIroi{end+1} = tmproiroi;
  end
  ROInames{end+1} = tmpname;
end



% finalize "Roi" structure
anaImg = anaload(ses,grp);
GAMMA = 1.8;
ROI = mroisct(ses,grp,tcAvgImg,anaImg,GAMMA);
ROI.roinames = ROInames;
ROI.roi = ROIroi;

% save ROI
if strcmpi(grp.grproi,'RoiGrp')
  % guessing the original grproi as 'RoiDef'...
  vname = sprintf('%s_atlas','RoiDef');
else
  vname = sprintf('%s_atlas',strrep(grp.grproi,'_atlas',''));
end


matfile = mroi_file(ses,vname);
mroi_save(ses,vname,ROI,'backup',1);

fprintf(' done.\n');
fprintf('\nEDIT ''%s.m''\n',ses.name);
fprintf('ROI.names = {');
for K=1:length(ROI.roinames),  fprintf(' ''%s''',ROI.roinames{K});  end
fprintf(' };\n');
fprintf('GRPP.grproi or GRP.%s.grproi as ''%s''.\n',grp.name,vname);

if get(wgts.CallPaxrenameCheck,'value'),
  aset  = get(wgts.AtlasSetCmb,'String');
  aset  = aset{get(wgts.AtlasSetCmb,'Value')};
  switch lower(aset)
   case {'rat : rat2013'}
    % do nothing
   otherwise
    fprintf('\n\n%s: calling paxrenameroi()...\n',mfilename);
    paxrenameroi(ses,'roiset',vname);
  end
end


return
