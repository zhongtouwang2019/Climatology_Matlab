%% GEV Fit for Block Maxima

clearvars

%first load in the data
%dir_nm = '../../hourly_data/';
dir_nm = '../../COOPS_tides/';
station_name = 'Seattle';
station_nm = 'seattle';

load_file = strcat(dir_nm,station_nm,'/',station_nm,'_6minV');
load(load_file)
clear dir_nm file_nm load_file


%% Find yearly max
yr_vec = year(tides.time(1)):year(tides.time(end)); %make a year vec
maxima = NaN(length(yr_vec),1); %create vector to house all of the block maxima
for i = 1:length(yr_vec)
    yr_ind = find(year(tides.time) == yr_vec(i));
    % If there is more than 50% of the hours missing for that year, I will
    % skip it
    if length(yr_ind) < 8760 * .5
        maxima(i) = NaN;
    else
    %max_val = max(wndspd(yr_ind));
        maxima(i) = max(tides.WL_VALUE(yr_ind));
    end
end

nan_ind = isnan(maxima); % Find any nans and get rid of them
maxima(nan_ind) = [];

clear j yr_ind

% Get GEV statistics about the data
[paramEsts, paramCIs] = gevfit(maxima);
%----------------Results from GEV-------------------------------
% % % kMLE = paramEsts(1);        % Shape parameter
% % % sigmaMLE = paramEsts(2);    % Scale parameter
% % % muMLE = paramEsts(3);       % Location parameter
%% Plot the GEV

clf

lowerBnd = 2;
x = maxima;  
xmax = 1.1*max(x);
bins = floor(lowerBnd):.1:ceil(xmax);

% plot the hist with GEV line
subplot(2,2,[1 3])
h = bar(bins,histc(x,bins)/length(x),'histc');
h.FaceColor = [.8 .8 .8];
xgrid = linspace(lowerBnd,xmax,100);
line(xgrid,.1*gevpdf(xgrid,paramEsts(1),paramEsts(2),paramEsts(3)));
xlim([lowerBnd xmax]);
plot_tit = sprintf('GEV - Block Maxima - %s', station_name);
title(plot_tit)

ax = gca;  % Play with the Axes 
ax.XLim = [2 xmax];


% Add GEV parameters to the plot
tbox = sprintf('mu = %4.2f \nsigma = %4.2f \nk = %4.2f \nn: %d',...
    paramEsts(1),paramEsts(2),paramEsts(3), length(maxima));
%text(10,0.25, tbox)

% Add box around the text
dim = [.16 .5 .3 .3];
annotation('textbox',dim,'String',tbox,'FitBoxToText','on');



xlabel('Total Water Level [m]')
ylabel('Probability Density')
%legend('Hourly','Six-Hr Avg.','Location','NorthEast')
box on

% Calculate the CDF - CDF will give me the probability of values 
cdf = 1 - gevcdf(xgrid,paramEsts(1),paramEsts(2),paramEsts(3)); % create CDF from GEV PDF


% ----------Notes-----------
% - PDF sums to 1, represents probability density
% - CDF is the cumulative PDF, represents probability
% - CDF is the probability of the random variable being less than X

%% Calculate Recurrence Interval

%-------Note-----------%
%RI = 1/Probability
%Knowing CDF and thus the probability, I can calculate the Recurrence

RI = 1./cdf;
subplot(2,2,[2 4])
plot(xgrid, RI)
ylim([0 100])
plot_tit = sprintf('Recurrence Interval - %s', station_name);
title(plot_tit)
xlabel('Total Water Level [m]')
ylabel('Time [years]')


ax = gca;
set(gca,'XMinorTick','on')  %add minor tick marks on x-axis

box on 
grid on


% Generate specific values for recurrence levels

R100MLE = gevinv(1-1./100,paramEsts(1),paramEsts(2),paramEsts(3));
R50MLE = gevinv(1-1./50,paramEsts(1),paramEsts(2),paramEsts(3));
R25MLE = gevinv(1-1./25,paramEsts(1),paramEsts(2),paramEsts(3));
R10MLE = gevinv(1-1./10,paramEsts(1),paramEsts(2),paramEsts(3));
R5MLE = gevinv(1-1./5,paramEsts(1),paramEsts(2),paramEsts(3));
R2MLE = gevinv(1-1./2,paramEsts(1),paramEsts(2),paramEsts(3));

% Add GEV parameters to the plot
tbox = sprintf('100 yr: %4.2f m\n50 yr: %4.2f m\n25 yr: %4.2f m\n10 yr: %4.2f m\n5 yr: %4.2f m\n2 yr: %4.2f m'...
    ,R100MLE, R50MLE, R25MLE, R10MLE, R5MLE, R2MLE);
%text(6,60, tbox)

dim = [.62 .3 .3 .3];
annotation('textbox',dim,'String',tbox,'FitBoxToText','on');






%%
% % % % Save the Plot
% % % cd('../../Matlab_Figures/GEV/Tides/')
% % % 
% % % outname = sprintf('GEV_%s',station_nm);
% % % hFig = gcf;
% % % hFig.PaperUnits = 'inches';
% % % hFig.PaperSize = [8.5 11];
% % % hFig.PaperPosition = [0 0 7 7];
% % % print(hFig,'-dpng','-r350',outname) %saves the figure, (figure, filetype, resolution, file name)
% % % close(hFig)
% % % 
% % % cd('../../../matlab/Climatology')
