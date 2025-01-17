function coords = msubplotcoord(nrows, ncols, thisPlot,figHandle)
%MSUBPLOTCOORD - create axes in tiled positions.
%   H = MSUBPLOTCOORD(m,n,p), or MSUBPLOTCOORD(mnp), breaks the Figure window
%   into an m-by-n matrix of small axes, selects the p-th axes for 
%   for the current plot, and returns the axis handle.  The axes 
%   are counted along the top row of the Figure window, then the
%   second row, etc.  For example,
% 
%       MSUBPLOTCOORD(2,1,1), PLOT(income)
%       MSUBPLOTCOORD(2,1,2), PLOT(outgo)
% 
%   plots income on the top half of the window and outgo on the
%   bottom half.
% 
%   MSUBPLOTCOORD(m,n,p), if the axis already exists, makes it current.
%   MSUBPLOTCOORD(m,n,P), where P is a vector, specifies an axes position
%   that covers all the msubplotcoord positions listed in P.
%   MSUBPLOTCOORD(H), where H is an axis handle, is another way of making
%   an axis current for subsequent plotting commands.
%
%   MSUBPLOTCOORD('position',[left bottom width height]) creates an
%   axis at the specified position in normalized coordinates (in 
%   in the range from 0.0 to 1.0).
%
%   If a MSUBPLOTCOORD specification causes a new axis to overlap an
%   existing axis, the existing axis is deleted.  For example,
%   the statement MSUBPLOTCOORD(1,2,1) deletes all existing axes overlapping
%   the left side of the Figure window and creates a new axis on that
%   side.
%
%   MSUBPLOTCOORD(111) is an exception to the rules above, and is not
%   identical in behavior to MSUBPLOTCOORD(1,1,1).  For reasons of backwards
%   compatibility, it is a special case of msubplotcoord which does not
%   immediately create an axes, but instead sets up the figure so that
%   the next graphics command executes CLF RESET in the figure
%   (deleting all children of the figure), and creates a new axes in
%   the default position.  This syntax does not return a handle, so it
%   is an error to specify a return argument.  The delayed CLF RESET
%   is accomplished by setting the figure's NextPlot to 'replace'.

%   Copyright 1984-2000 The MathWorks, Inc. 
%   $Revision: 5.19 $  $Date: 2000/06/01 02:53:21 $

% we will kill all overlapping axes siblings if we encounter the mnp
% or m,n,p specifier (excluding '111').
% But if we get the 'position' or H specifier, we won't check for and
% delete overlapping siblings:
narg = nargin;
kill_siblings = 0;
create_axis = 1;
delay_destroy = 0;
tol = sqrt(eps);
if narg == 0 % make compatible with 3.5, i.e. msubplotcoord == msubplotcoord(111)
    nrows = 111;
    narg = 1;
end

%check for encoded format
handle = '';
position = '';
if narg == 1
    % The argument could be one of 3 things:
    % 1) a 3-digit number 100 < num < 1000, of the format mnp
    % 2) a 3-character string containing a number as above
    % 3) an axis handle
    code = nrows;

    % turn string into a number:
    if(isstr(code)) code = str2double(code); end

    % number with a fractional part can only be an identifier:
    if(rem(code,1) > 0)
        handle = code;
        if ~strcmp(get(handle,'type'),'axes')
            error('Requires valid axes handle for input.')
        end
        create_axis = 0;
    % all other numbers will be converted to mnp format:
    else
        thisPlot = rem(code, 10);
        ncols = rem( fix(code-thisPlot)/10,10);
        nrows = fix(code/100);
        if nrows*ncols < thisPlot
            error('Index exceeds number of msubplotcoords.');
        end
	kill_siblings = 1;
	if(code == 111)
	  create_axis   = 0;
	  delay_destroy = 1;
	else
	  create_axis   = 1;
	  delay_destroy = 0;
	end
      end
elseif narg == 2
    % The arguments MUST be the string 'position' and a 4-element vector:
    if(strcmp(lower(nrows), 'position'))
        pos_size = size(ncols);
        if(pos_size(1) * pos_size(2) == 4)
            position = ncols;
        else
            error(['msubplotcoord(''position'',',...
            ' [left bottom width height]) is what works'])
        end
    else
        error('Unknown command option')
    end
    kill_siblings = 1; % Kill overlaps here also.
elseif narg == 3
    % passed in msubplotcoord(m,n,p) -- we should kill overlaps
    % here too:
    kill_siblings = 1;
elseif narg == 4,
    kill_siblings = 1;
    handle = hFigure;
end

% if we recovered an identifier earlier, use it:
if(~isempty(handle))
    set(get(0,'CurrentFigure'),'CurrentAxes',handle);
% if we haven't recovered position yet, generate it from mnp info:
elseif(isempty(position))
    if (min(thisPlot) < 1)
        error('Illegal plot number.')
        elseif (max(thisPlot) > ncols*nrows)
                error('Index exceeds number of msubplotcoords.')
    else
        % This is the percent offset from the msubplotcoord grid of the plotbox.
        PERC_OFFSET_L = 2*0.030;
        PERC_OFFSET_R = 2*0.030;
        PERC_OFFSET_B = PERC_OFFSET_L;
        PERC_OFFSET_T = PERC_OFFSET_R;
        if nrows > 2
            PERC_OFFSET_T = 0.93*PERC_OFFSET_T;
            PERC_OFFSET_B = 0.93*PERC_OFFSET_B;
        end
        if ncols > 2
            PERC_OFFSET_L = 0.96*PERC_OFFSET_L;
            PERC_OFFSET_R = 0.96*PERC_OFFSET_R;
        end

        row = (nrows-1) -fix((thisPlot-1)/ncols);
        col = rem (thisPlot-1, ncols);

        % For this to work the default axes position must be in normalized coordinates
        if ~strcmp(get(gcf,'defaultaxesunits'),'normalized')
          warning('DefaultAxesUnits not normalized.')
          tmp = axes;
          set(axes,'units','normalized')
          def_pos = get(tmp,'position');
          delete(tmp)
        else
          def_pos = get(gcf,'DefaultAxesPosition');
        end
		def_pos(1) = def_pos(1)/4;
		def_pos(2) = def_pos(2)/2;
		def_pos(3) = def_pos(3)*1.1;
		def_pos(4) = def_pos(4)*1.05;

        col_offset = def_pos(3)*(PERC_OFFSET_L+PERC_OFFSET_R)/ ...
                                (ncols-PERC_OFFSET_L-PERC_OFFSET_R);
        row_offset = def_pos(4)*(PERC_OFFSET_B+PERC_OFFSET_T)/ ...
                                (nrows-PERC_OFFSET_B-PERC_OFFSET_T);

        totalwidth = def_pos(3) + col_offset;
        totalheight = def_pos(4) + row_offset;
		
		totalwidth = totalwidth * 1.1;
		totalheight = totalheight * 1.05;
		
        width = totalwidth/ncols*(max(col)-min(col)+1)-col_offset;
        height = totalheight/nrows*(max(row)-min(row)+1)-row_offset;
        position = [def_pos(1)+min(col)*totalwidth/ncols ...
                    def_pos(2)+min(row)*totalheight/nrows ...
                    width height];
        if width <= 0.5*totalwidth/ncols
            position(1) = def_pos(1)+min(col)*(def_pos(3)/ncols);
            position(3) = 0.8*(def_pos(3)/ncols)*(max(col)-min(col)+1);
        end
        if height <= 0.5*totalheight/nrows
            position(2) = def_pos(2)+min(row)*(def_pos(4)/nrows);
            position(4) = 0.8*(def_pos(4)/nrows)*(max(row)-min(row)+1);
        end
    end
end

% kill overlapping siblings if mnp specifier was used:
nextstate = get(gcf,'nextplot');
if strncmp(nextstate,'replace',7), nextstate = 'add'; end
if(kill_siblings)
    if delay_destroy
      if nargout
        error('Function called with too many output arguments')
      else
        set(gcf,'NextPlot','replace'); return,
      end
    end
    sibs = datachildren(gcf);
    got_one = 0;
    for i = 1:length(sibs)
        % Be aware that handles in this list might be destroyed before
        % we get to them, because of other objects' DeleteFcn callbacks...
        if(ishandle(sibs(i)) & strcmp(get(sibs(i),'Type'),'axes'))
            units = get(sibs(i),'Units');
            set(sibs(i),'Units','normalized')
            sibpos = get(sibs(i),'Position');
            set(sibs(i),'Units',units);
            intersect = 1;
            if(     (position(1) >= sibpos(1) + sibpos(3)-tol) | ...
                        (sibpos(1) >= position(1) + position(3)-tol) | ...
                        (position(2) >= sibpos(2) + sibpos(4)-tol) | ...
                        (sibpos(2) >= position(2) + position(4)-tol))
                         intersect = 0;
            end
            if intersect
                if got_one | any(abs(sibpos - position) > tol)
                    delete(sibs(i));
                else
                    got_one = 1;
                    set(gcf,'CurrentAxes',sibs(i));
                    if strcmp(nextstate,'new')
                        create_axis = 1;
                    else
                        create_axis = 0;
                    end
                end
            end
        end
    end
    set(gcf,'NextPlot',nextstate);
end

coords = position;
