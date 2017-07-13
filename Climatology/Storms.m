clearvars

%first load in the data
%dir_nm = '/Users/andrewmcauliffe/Desktop/hourly_data/';
dir_nm = '../../';                                                         % goes back 2 directories, to the desktop directory
file_nm = '/hourly_data/whidbey_hourly';                                   % you will have to change this variable for each station
load_file = strcat(dir_nm,file_nm);
load(load_file)
clear dir_nm file_nm load_file
wnddir = wnddir';

%% Establish Search parameters 
min_duration = 3;                                                          % minimum amount of time a storm can last
min_wndspd = 10;                                                           % anything less than 10 m/s I will avoid
event_sep = 3;                                                             % anything that is seperated by 3 hours is considered the same event


%% Find all of storms greater than 10 m/s and lasting 3 or more hours
%----------------10 m/s--------------

wndspd10 = find(wndspd >= min_wndspd);                                     %grab the indices of winds > 10 m/s

breaks = find(diff(wndspd10) ~= 1);                                        %find where the wind speeds >10 m/s indices
                                                                           % are not consecutive aka the breaks in the index vector and thus a break
                                                                           % in intense winds

beg = [];                                                                  % Vector to contain beginning of storms
fin = [];                                                                  % Vector to contain all the end locations of storms

% Find all the starting and stopping indices of events
for i = 1:length(breaks)    
    if i == 1        
        if ismember(breaks(i) + 1, breaks)                                 % this is the first value, if the sequential value exists in the second spot, signifying that the event is single            
            beg(end+1) = breaks(i);                                        % Same event so beg and fin are the same
            fin(end+1) = breaks(i);            
        else                                                               % Otherwise if the sequential value doesn't exist, such that from 1 - breaks(2) is a event, grab that window        
            beg(end+1) = breaks(i);
            fin(end+1) = breaks(i+1);
        end  
    elseif i > 1                                                           % For all other values after the first indice
        if ismember(breaks(i) + 1, breaks)                                 % if the value 1 larger than the current index exists, we know that the current index is a stopping point, because the next value is a single event
            beg(end+1) = breaks(i-1) + 1;                                  % Grab the starting index which is one after the last stopping point
            fin(end+1) = breaks(i);                                        % end on stopping point which is current index
        elseif ismember(breaks(i) - 1, breaks)                             % if the value 1 less than the current index exists, we know that the current value is a single event 
            beg(end+1) = breaks(i);                                        % these will be the same
            fin(end+1) = breaks(i);
        else                                                               %otherwise, if there is no sequential value surrounding the current index
            beg(end+1) = breaks(i-1) + 1;                                  %grab 1 value after the last stopping point
            fin(end+1) = breaks(i);                                        % Current Index is stopping point
        end
    end
end

% Change to vertical orientation
beg = beg';
fin = fin';

% Grab actual indices
beg = wndspd10(beg);
fin = wndspd10(fin);

%-------------Recap------------------
% I have generated 2 lists of events corresponding to times when winds are
% greater than 10m/s and grabbed the starting and stopping points of each
% event.  

% Now I need to go through these events and combine any start and stop
% locations that are closer than a specific threshold and get rid of any
% events that don't last more than a specific threshold.  

%% Combine any events that are within a specific threshold of time

% Threshold was established at the beginning of code
                                                        
beg_del = [];                                                              % Empty vector to house values to be deleted
fin_del = [];                                                              % Empty vector to house values to be deleted

% Loop and combine
for i = 2:length(beg)                                                      % For every starting point, starting at 2 because the first starting point is overlooked       
    if abs(beg(i) - fin(i-1)) <= event_sep                                 % If the absolute value of the ith beginning minus the jth end is less than or equal to 3
        beg_del(end+1) = i;                                                % Indice in beg to be deleted                    
        fin_del(end+1) = i-1;                                              % Indice in fin to be deleted                  
    end
end

beg(beg_del) = [];                                                         % Delete the cells that need to be deleted
fin(fin_del) = [];                                                         % Delete the cells that need to be deleted

events = [beg,fin];                                                        % Generate a 2 column matrix of beginning and ends of storm events


%% Remove any events that don't last for a specific duration

% Threshold was established at the beginning of the code

beg_del = [];                                                              % Empty vector to house values to be deleted
fin_del = [];                                                              % Empty vector to house values to be deleted

for i = 1:length(events)                                                   % For every value in events
    if abs(beg(i) - fin(i)) < 3                                            % If the difference between beginning and end is less than 3
        beg_del(end+1) = i;                                                % Grab indice to delete
        fin_del(end+1) = i;                                                % Grab indice to delete
    end
end

beg(beg_del) = [];                                                         % Delete the cells that need to be deleted
fin(fin_del) = [];                                                         % Delete the cells that need to be deleted

events = [beg,fin];                                                        % Generate a 2 column matrix of beginning and ends of storm events

clear breaks i beg beg_del fin fin_del i 
