function hh = mstem(varargin)
%MSTEM - Discrete sequence or "mstem" plot.
%   MSTEM(Y) plots the data sequence Y as mstems from the x axis
%   terminated with circles for the data value.
%
%   MSTEM(X,Y) plots the data sequence Y at the values specified
%   in X.
%
%   MSTEM(...,'filled') produces a mstem plot with filled markers.
%
%   MSTEM(...,'LINESPEC') uses the linetype specified for the mstems and
%   markers.  See PLOT for possibilities.
%
%   H = MSTEM(...) returns a vector of line handles.
%
%   See also PLOT, BAR, STAIRS.

%   Copyright 1984-2002 The MathWorks, Inc. 
%   $Revision: 5.19 $  $Date: 2002/06/05 20:05:17 $

nin = nargin;

fill = 0;
ls = '-';
ms = 'o';
col = '';

% Parse the string inputs
while isstr(varargin{nin}),
  v = varargin{nin};
  if ~isempty(v) & strcmp(lower(v(1)),'f')
    fill = 1;
    nin = nin-1;
  else
    [l,c,m,msg] = colstyle(v);
    if ~isempty(msg), 
      error(sprintf('Unknown option "%s".',v));
    end
    if ~isempty(l), ls = l; end
    if ~isempty(c), col = c; end
    if ~isempty(m), ms = m; end
    nin = nin-1;
  end
end

error(nargchk(1,2,nin));

[msg,x,y] = xychk(varargin{1:nin},'plot');
if ~isempty(msg), error(msg); end

if min(size(x))==1, x = x(:); end
if min(size(y))==1, y = y(:); end

% Set up data using fancing indexing
[m,n] = size(x);
xx = zeros(3*m,n);
xx(1:3:3*m,:) = x;
xx(2:3:3*m,:) = x;
xx(3:3:3*m,:) = NaN;

[m,n] = size(y);
yy = zeros(3*m,n);
yy(2:3:3*m,:) = y;
yy(3:3:3*m,:) = NaN;

h1 = plot(x,y,[col,ms]); hold on,
h2 = plot(xx,yy,[col,ls]);
for i=1:length(h1), % Make the color of the 'o's the same as the lines.
  c = get(h2(i),'Color');
  set(h1(i),'Color',c)
  if fill, set(h1(i),'MarkerFaceColor',c), end
end

h3 = graph2d.constantline(0); % draw horizontal line through 0

h = [h1;h2;double(h3)];

if nargout>0, hh = h; end
