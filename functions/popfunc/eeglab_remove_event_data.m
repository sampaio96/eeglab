% eeglab_remove_event_data() - Remove continuous data within time interval
% of specific events.
% Useful for removing bad data intervals from BVA.
%
% Usage:
%   >> OUTEEG = eeglab_remove_event_data (EEG, typerange);
%
% Inputs:
%   EEG        - Input dataset. Not tested for epoched data.
%   typerange  - Cell array of event types to time lock to.
%                (Note: An event field called 'type' must be defined in 
%                the 'EEG.event' structure).
%   
% Outputs:
%   OUTEEG     - output dataset
%
% Authors: Gonçalo Sampaio ? Music, Imaging, and Neural Dynamics (MIND) Lab


% Script created by Gonçalo Sampaio to remove data around specified events.
% As of now, works only for events specified by their description.
% Returns a continuous EEG file.
% Adapted from pop_rmdat, an EEGLAB function.

function [EEG] = eeglab_remove_event_data (EEG, typerange)

if nargin < 2
   help pop_rmdat;
	return;
end;	
com = '';

if isempty(EEG.event)
    error( [ 'No event. This function removes data' 10 'based on event latencies' ]);
end;
if isempty(EEG.trials)
    error( [ 'This function only works with continuous data' ]);
end;
if ~isfield(EEG.event, 'latency'),
    error( 'Absent latency field in event array/structure: must name one of the fields ''latency''');
end;

tmpevent = EEG.event;

% Checking for numeric values in fieldnames and changing them to string
 for i = 1: length(tmpevent)
     checknum(i) = isnumeric(tmpevent(i).type);
 end
  if sum(checknum)~=0
       tmpindx = find(checknum == 1);
       for i = 1: length(tmpindx)
           tmpevent(tmpindx(i)).type = num2str(tmpevent(tmpindx(i)).type);
       end
  end
  
% compute event indices
allinds = [];
for index = 1:length(typerange)
    inds = strmatch(typerange{index},{ tmpevent.type }, 'exact');
    allinds = [allinds(:); inds(:) ]';
end;
allinds = sort(allinds);
if isempty(allinds)
    disp('No event found');
    return;
end;

% compute time limits
array = [];
bnd = strmatch('boundary', lower({tmpevent.type }));
bndlat = [ tmpevent(bnd).latency ];
for bind = 1:length(allinds)
    evtlat = EEG.event(allinds(bind)).latency;
    evtbeg = evtlat;
    evtend = evtlat+EEG.event(allinds(bind)).Points-1; % This is the main edited line!!
    if any(bndlat > evtbeg & bndlat < evtend)
        % find the closer upper and lower boundaries
        bndlattmp = bndlat(bndlat > evtbeg & bndlat < evtend);
        diffbound = bndlattmp-evtlat;
        allneginds = find(diffbound < 0);
        allposinds = find(diffbound > 0);
        if ~isempty(allneginds), evtbeg = bndlattmp(allneginds(1)); end;
        if ~isempty(allposinds), evtend = bndlattmp(allposinds(1)); end;       
        fprintf('Boundary found: time limits for event %d reduced from %3.2f to %3.2f\n', allinds(bind), ...
            (evtbeg-evtlat)/EEG.srate, (evtend-evtlat)/EEG.srate);
    end
    if ~isempty(array) && evtbeg < array(end) && array(end) < evtend % This line was also edited.
        array(end) = evtend;
    else
        array = [ array; evtbeg  evtend];
    end;
end;
array

if ~isempty(array) && array(1) < 1, array(1) = 1; end;
if ~isempty(array) && array(end) > EEG.pnts, array(end) = EEG.pnts; end;
if isempty(array)
    disp('No event found');
    return;
end;

EEG = pop_select(EEG, 'notime', (array-1)/EEG.srate);