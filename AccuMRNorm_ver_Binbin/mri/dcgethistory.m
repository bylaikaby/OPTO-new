function hist = dcgethistory(theorder,sizeMe)
%DCGETHISTORY - used for event-related design; called by repeathistory etc.
%	hist = DCGETHISTORY(theorder,sizeMe)
%	each row of history is a condition
%	each column shows how many times trials of condition R are
%	preceded by condition C
%	assumes single column input


try,
[numtrials junk] = size(theorder);
[numconds junk]  = size(unique(theorder));

if(sizeMe==2),
	hist = zeros(numconds, numconds);
	for n = 2:numtrials,
		hist(theorder(n), theorder(n-1)) = hist(theorder(n), theorder(n-1))+1;
	end
end  

if(sizeMe==3),
  hist = zeros(numconds, numconds,numconds);
  for n = 3:numtrials,
	  hist(theorder(n), theorder(n-1),theorder(n-2)) = ...
			hist(theorder(n), theorder(n-1),theorder(n-2))+1;
  end
end

if(sizeMe==4),

  hist = zeros(numconds, numconds,numconds,numconds);
  for n = 4:numtrials,
	hist(theorder(n), ...
		theorder(n-1),theorder(n-2),theorder(n-3))=hist(theorder(n), ...
			theorder(n-1),theorder(n-2),theorder(n-3))+1;
  end

end
catch,
	disp(lasterr);
	keyboard;
end;
