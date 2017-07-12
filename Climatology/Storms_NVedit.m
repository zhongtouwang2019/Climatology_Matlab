clearvars

%first load in the data
%dir_nm = '/Users/andrewmcauliffe/Desktop/hourly_data/';
dir_nm = '../../'; % goes back 2 directories, to the desktop directory
file_nm = '/hourly_data/whidbey_hourly'; % you will have to change this variable for each station
load_file = strcat(dir_nm,file_nm);
load(load_file)
clear dir_nm file_nm load_file
wnddir = wnddir';

%% Establish Search parameters 
min_duration = 3; % minimum amount of time a storm can last
min_wndspd = 10; % anything less than 10 m/s I will avoid
min_seperation = 12; % anything not seperated by 12 hours will be considered the same event

%% Find all of storms greater than 10 m/s and lasting 3 or more hours
%----------------10 m/s--------------
wndspd10 = find(wndspd >= min_wndspd); %grab the indices of winds > 10 m/s
breaks = find(diff(wndspd10) ~= 1);  %find where the wind speeds >10 m/s indices
% are not consecutive aka the breaks in the index vector and thus a break
% in intense winds

beg = []; % Vector to contain beginning of storms
fin = []; % Vector to contain all the end locations of storms

for i = 1:length(breaks)
    
    if ismember(breaks(i) + 1, breaks) || ismember(breaks(i) - 1, breaks)  % If a sequential value exists before or after the current indice, this means that it is a single event
       
        beg(end+1) = breaks(i);                                            % Add the single event as beginning
        fin(end+1) = breaks(i);                                            % Add the single event as end
    
    else                                                                   % Otherwise, if there is a gap larger than 1, signifying a break in the hourly indices
        
        beg(end+1) = breaks(i-1) + 1;                                      % Grab the Start of the event, which is one value greater than the last end point
        fin(end+1) = breaks(i);                                            % Grab the end of the event which is the current indice
    end
end

% Change to vertical orientation
beg = beg';
fin = fin';

% Combine the two vectors into a single variable
events = [beg, fin];
clear beg fin
