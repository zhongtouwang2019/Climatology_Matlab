%---------Code to Compare Station Data with Obs Data-----------------------
clearvars

% Establish Station Name Here
stationName = 'Whidbey_NAS';

% Load Station Data
dir_nm = '../../hourly_data/';
file_nm = 'whidbey_hourly'; % you will have to change this variable for each station
load_file = strcat(dir_nm,file_nm);
O = load(load_file); %--------O means observation data
clear dir_nm file_nm load_file
O.wnddir = O.wnddir';

% Generate 6-hour smoothed records (match more closely with NNRP predictions
O.wnddir_hourly = O.wnddir;
O.wndspd_hourly = O.wndspd;
O.wnddir = conv(O.wnddir_hourly,1/6*ones(1,6),'same');
O.wndspd = conv(O.wndspd_hourly,1/6*ones(1,6),'same');

% Load NNRP Predictions
dir_nm = '/Users/andrewmcauliffe/Desktop/pred_data';
fol_nm = 'NNRP_Data';
stn_nm = 'NNRP_whidbey.mat';
fname = sprintf('%s/%s/%s',dir_nm, fol_nm, stn_nm);
N = load(fname);
N.time = datenum(1950,1,1):(1/4):datenum(2010,12,31,18,0,0); % Add time vector

% Load HRDPS Predictions
dir_nm = '/Users/andrewmcauliffe/Desktop/pred_data';
fol_nm = 'HRDPS_Data';
stn_nm = 'HRDPS_whidbey.mat';
fname = sprintf('%s/%s/%s',dir_nm, fol_nm, stn_nm);
H = load(fname);

clear dir_nm fname fol_nm stn_nm


%% Plot Wind Roses of Obs and Predicted 


% NEED TO FIX THE PLOTTING ON THIS

% Set Wind Rose options
options.nDirections = 32*2;
options.vWinds = [0 5 10 15 20 25];
options.AngleNorth = 0;
options.AngleEast = 90;
options.labels = {'North (360�)','South (180�)','East (90�)','West (270�)'};
options.scalefactor = 1;
options.legendtype = 0; % removes legend if 0, 1 for color bar
%options.freqlabelangle = 120;




clf
options.TitleString = [{'Obs';' '}]; %Set Title
ax = subplot(1,3,1);
options.axes = ax;
[figure_handle,count,speeds,directions,Table] = WindRose(O.wnddir,O.wndspd,options);


options.TitleString = [{'NNRP';' '}];
ax = subplot(1,3,2);
options.axes = ax;
[figure_handle,count,speeds,directions,Table] = WindRose(N.wnddir,N.wndspd_10m,options);


options.TitleString = [{'HRDPS';' '}];
ax = subplot(1,3,3);
options.axes = ax;
[figure_handle,count,speeds,directions,Table] = WindRose(H.wnddir,H.wndspd_10m,options);


% Change to location of folder to save figure
cd('../../Matlab_Figures/compare_stations/Windrose')



outname = sprintf('WindRose_Compare_%s',stationName);
hFig = gcf;
hFig.PaperUnits = 'inches';
hFig.PaperSize = [8.5,11];
hFig.PaperPosition = [0 0 7 7];
print(hFig,'-dpng','-r500',outname, '-painters') %saves the figure, (figure, filetype, resolution, file name)
close(hFig)


%% Print Max winds observed/predicted to the command window

fprintf('Obs Max Wind Speed %4.2f m/s \n',(max(O.wndspd)))
fprintf('NNRP Max Wind Speed %4.2f m/s \n',(max(N.wndspd_10m)))
fprintf('HRDPS Max Wind Speed %4.2f m/s \n',(max(H.wndspd_10m(:,3))))



%% EVT Analysis

% Find yearly maxima
%------Obs maxima-----------------
yr = year(O.time(1)):year(O.time(end));
Omax = zeros(1,length(yr));
Omax_hourly = zeros(1,length(yr));
for yy = 1:length(yr)
    Omax(yy) = max(O.wndspd(year(O.time)==yr(yy)));  % 6 hour max per year
    Omax_hourly(yy) = max(O.wndspd_hourly(year(O.time)==yr(yy)));  % hourly max per year
end

%------NNRP maxima-----------------
yr = year(N.time(1)):year(N.time(end));
Nmax = zeros(1,length(yr));
for yy = 1:length(yr)
    Nmax(yy) = max(N.wndspd_10m(year(N.time)==yr(yy)));  %predicted max wndspd per year
end

%%
clf

%--------------Observations------------------

% Compares the 6 and hourly data
% 6 hourly average data is in blue
subplot(221)
x = Omax;  % 6 hour max
nblocks = length(Omax);
x_min = 0;
x_max = 30;
x_bin = 0.1;
hist_bin = 0.5;

% location parameter �, scale parameter ?, and shape parameter k 
paramEsts = gevfit(x);  % grab GEV values 
xgrid = 0:x_bin:30;  % create evenly spaced grid
histgrid = x_min:hist_bin:x_max;  % create locations for bars
pdf = gevpdf(xgrid,paramEsts(1),paramEsts(2),paramEsts(3));  % create PDF from GEV parameters
O.cdf = 1 - gevcdf(xgrid,paramEsts(1),paramEsts(2),paramEsts(3)); % create CDF from GEV PDF

%CDF is 1 - PDF, concerned about probability up to specific threshold


myhist = histc(x,histgrid);  % counts the number of values within the binned ranges of histgrid
myhist = myhist/sum(myhist*hist_bin);
myhist_hourly = histc(Omax_hourly,histgrid);
myhist_hourly = myhist_hourly/sum(myhist_hourly*hist_bin);
hold on
bar(histgrid,myhist_hourly,'FaceColor',[1 .8 .8])
bar(histgrid,myhist,'FaceColor',[.8 .8 1])

line(xgrid,pdf);
 
ax = gca;
ax.XLim = [10 28];

tbox = sprintf('mu = %4.2f \nsigma = %4.2f \nk = %4.2f',paramEsts(1),paramEsts(2),paramEsts(3));
%text(ax.XLim(1)*1.01,ax.YLim(2)*.9,tbox)
text(21,max(myhist_hourly), tbox)

xlabel('Max Yearly 6-hourly Wind Speed Obs[m/s]')
ylabel('Probability')
%legend('Hourly','Six-Hr Avg.','Location','NorthEast')
box on

%--------------NNRP------------------
subplot(223)
x = Nmax;
nblocks = length(Nmax);
x_min = min(x);
x_max = max(x);
x_bin = 0.1;
hist_bin = 0.5;

% location parameter �, scale parameter ?, and shape parameter k 
paramEsts = gevfit(x);
xgrid = 0:x_bin:30;
histgrid = x_min:hist_bin:x_max;
pdf = gevpdf(xgrid,paramEsts(1),paramEsts(2),paramEsts(3));
N.cdf = 1 - gevcdf(xgrid,paramEsts(1),paramEsts(2),paramEsts(3)); % create CDF from GEV PDF

% kMLE = paramEsts(1);        % Shape parameter
% sigmaMLE = paramEsts(2);    % Scale parameter
% muMLE = paramEsts(3);       % Location parameter


myhist = histc(x,histgrid);
myhist = myhist/sum(myhist*hist_bin);
bar(histgrid,myhist,'FaceColor',[.8 .8 1])
hold on
line(xgrid,pdf);
 
ax = gca; % current axes
ax.XLim = [12 28];
ax.YLim = [0 max(myhist) * 1.1];

tbox = sprintf('mu = %4.2f \nsigma = %4.2f \nk = %4.2f',paramEsts(1),paramEsts(2),paramEsts(3));
%text(ax.XLim(1)*1.01,ax.YLim(2)*.9,tbox)
text(22,max(myhist) * 0.9, tbox)

xlabel('Max Yearly 6-hourly Wind Speed Pred [m/s]')
ylabel('Probability')


% CDF and Return Invtervals   
subplot(2,2,[2 4])
hold on
N.recur = 1./N.cdf; % Recurrence Interval = 1/probability, prob = CDF
O.recur = 1./O.cdf; 
plot(xgrid,O.recur)
plot(xgrid,N.recur)
xlim([12 25])
ylim([0 100])
ylabel('Reoccurence Interval [years]')
xlabel('Max 6-hour Yearly wind Speed [m/s]')
grid on
box on
legend('Obs','Pred','Location','NorthWest')


cd('../EVT')
%printfig(gcf,sprintf('GEVYearlyMaxima_%s',stationName),[11 8.5],'pdf')
outname = sprintf('GEVYearlyMaxima_%s',stationName);
hFig = gcf;
hFig.PaperUnits = 'inches';
hFig.PaperSize = [8.5 11];
hFig.PaperPosition = [0 0 7 7];
print(hFig,'-dpng','-r500',outname) %saves the figure, (figure, filetype, resolution, file name)
close(hFig)

% Return to Climatology Directory
cd('../../../Matlab/Climatology')
