function varargout = setback(handles)
%SETBACK - sets graphic object(s) at back of others
%  SETBACK(HANDLES) sets graphic object(s) at back of others.
%
%  VERSION :
%    0.90 31.10.05 YM  pre-release
%
%  See also SETFRONT

if nargin == 0,  help setback; return;  end

handles = handles(find(ishandle(handles)));
if isempty(handles),  return;  end


% get the current order of handles
hParent = get(handles(1),'Parent');
hChildren = get(hParent,'Children');

% change the order
for N = length(handles):-1:1,
  tmpflags = hChildren == handles(N);
  idx  = find(tmpflags);
  if ~isempty(idx),
    idx2 = find(~tmpflags);
    hChildren = hChildren([idx2(:)' idx]);
  end
end

% set the new order of handles
set(hParent,'Children',hChildren);
drawnow;	% update to draw


return;
