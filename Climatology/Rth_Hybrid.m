%% Rth largest GEV

clearvars

%first load in the data
%dir_nm = '../../hourly_data/';
dir_nm = '../../COOPS_tides/';
station_name = 'La Conner';
station_nm ='LaConner';

load_file = strcat(dir_nm,station_nm,'/',station_nm);
load(load_file)
clear dir_nm file_nm load_file


%%  Find maximum yearly max
% Number of r values to look for
r_val = 3;

% Combine tide predictions and NTR for total water level estimates
twl_est = tide_pred + ntr;

%make a year vec
yr_vec = year(time(1)):year(time(end)); 

%create matrix to house all of the block maxima
maxima = zeros(length(yr_vec), r_val); 
%Detrend water
%twl_est = detrend(twl_est);

for y = 1:length(yr_vec)
    % Grab all of the years
    yr_ind = find(year(time) == yr_vec(y));
    temp_time = time(yr_ind);
    temp_wl = twl_est(yr_ind);
    
    %Make sure atleast half of the dates exist
    if length(yr_ind) < 17520*.5  %525600 minutes in a year, get in 6 minute increments so use 87600
        continue                  %17520 for 30 minute data
    else                          %87600 for 6 minute data
        % Genearte empty vector to house maximum values
        max_block = NaN(1,r_val);

        % Loop through and grab the maximum values and delete a window
        % around each maximum to ensure different tide cycles
        for m = 1:r_val
            % Grab the maximum
            [M, I] = max(temp_wl);

            % Generate a window to delete values
            if I < 144
                window = I - (I-1):1:I + 144;
            elseif length(temp_wl) - I < 144
                window = I - 144:1:length(temp_wl);
            elseif I - 144 <= 0
                window = 1:1:144 - (144 - I);
            else
                window = I-144:1:I+144;
            end
            temp_wl(window) = [];
            temp_time(window) = [];
            
            % Add the maximum value to the empty vector
            max_block(m) = M;
        end
    end
    
    % Now populate matrix with maximum values
    maxima(y,:) = max_block;
end

n = length(maxima);

%% Get GEV statistics about the data
% Reshape to be a single vector
%maxima = reshape(maxima, [length(yr_vec)*r_val, 1]);
maxima = maxima(:);
ind_del = find(maxima == 0);
maxima(ind_del) = [];

[paramEsts, paramCIs] = gevfit(maxima);
%----------------Results from GEV-------------------------------
% % % kMLE = paramEsts(1);        % Shape parameter
% % % sigmaMLE = paramEsts(2);    % Scale parameter
% % % muMLE = paramEsts(3);       % Location parameter



clf

lowerBnd = min(maxima)-.8;
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
plot_tit = sprintf('GEV - Rth Largest - %s', station_name);
title(plot_tit)

ax = gca;  % Play with the Axes 
ax.XLim = [lowerBnd xmax];

% % % Taken from R
%paramEsts(1) = -0.4386770;
%paramEsts(2) = 0.1129527;
%paramEsts(3) = 2.9607970;

% Add GEV parameters to the plot
tbox = sprintf('mu = %4.2f \nsigma = %4.2f \nk = %4.2f \nr: %d \nn: %d',...
    paramEsts(1),paramEsts(2),paramEsts(3), r_val, n);
%text(10,0.25, tbox)

% Add box around the text
dim = [.15 .6 .3 .3];
annotation('textbox',dim,'String',tbox,'FitBoxToText','on');



xlabel('Total Water Level [m]')
ylabel('Probability Density')
%legend('Hourly','Six-Hr Avg.','Location','NorthEast')
box on




% Calculate the CDF - CDF will give me the probability of values 
cdf = 1 - gevcdf(xgrid,paramEsts(1),paramEsts(2),paramEsts(3)); % create CDF from GEV PDF
%cdf = 1 - gevcdf(xgrid,-0.3771048, 0.1034551, 3.4687437); % create CDF from GEV PDF


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
xlim([3 4.5])
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

dim = [.61 .3 .3 .3];
annotation('textbox',dim,'String',tbox,'FitBoxToText','on');


%%
% Save the Plot
%cd('../../Matlab_Figures/GEV/Tides/Rth/')
%cd('../../swin/GEV/10_block/')
cd('../../');
outname = sprintf('GEV_meters_%s',station_nm);
hFig = gcf;
hFig.PaperUnits = 'inches';
hFig.PaperSize = [8.5 11];
hFig.PaperPosition = [0 0 7 7];
print(hFig,'-dpng','-r350',outname) %saves the figure, (figure, filetype, resolution, file name)
close(hFig)

%cd('../../../matlab/Climatology')
cd('matlab/Climatology')


%% 
%%%%%%%%%
% Now Plot with Feet as units 
%%%%%%%%%
%% Get GEV statistics about the data
% First conver to feet
maxima = maxima * 3.28084;
%%
[paramEsts, paramCIs] = gevfit(maxima);
%----------------Results from GEV-------------------------------
% % % kMLE = paramEsts(1);        % Shape parameter
% % % sigmaMLE = paramEsts(2);    % Scale parameter
% % % muMLE = paramEsts(3);       % Location parameter



clf

lowerBnd = min(maxima)-.6;
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
plot_tit = sprintf('GEV - Rth Largest - %s', station_name);
title(plot_tit)

ax = gca;  % Play with the Axes 
ax.XLim = [lowerBnd xmax];

% % % Taken from R
%paramEsts(1) = -0.4386770;
%paramEsts(2) = 0.1129527;
%paramEsts(3) = 2.9607970;

% Add GEV parameters to the plot
tbox = sprintf('mu = %4.2f \nsigma = %4.2f \nk = %4.2f \nr: %d \nn: %d',...
    paramEsts(1),paramEsts(2),paramEsts(3), r_val, n);
%text(10,0.25, tbox)

% Add box around the text
dim = [.29 .6 .3 .3];
annotation('textbox',dim,'String',tbox,'FitBoxToText','on');



xlabel('Total Water Level [ft]')
ylabel('Probability Density')
%legend('Hourly','Six-Hr Avg.','Location','NorthEast')
box on




% Calculate the CDF - CDF will give me the probability of values 
cdf = 1 - gevcdf(xgrid,paramEsts(1),paramEsts(2),paramEsts(3)); % create CDF from GEV PDF
%cdf = 1 - gevcdf(xgrid,-0.3771048, 0.1034551, 3.4687437); % create CDF from GEV PDF


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
xlim([11 14])
plot_tit = sprintf('Recurrence Interval - %s', station_name);
title(plot_tit)
xlabel('Total Water Level [ft]')
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
tbox = sprintf('100 yr: %4.2f ft\n50 yr: %4.2f ft\n25 yr: %4.2f ft\n10 yr: %4.2f ft\n5 yr: %4.2f ft\n2 yr: %4.2f ft'...
    ,R100MLE, R50MLE, R25MLE, R10MLE, R5MLE, R2MLE);
%text(6,60, tbox)

dim = [.62 .3 .3 .3];
annotation('textbox',dim,'String',tbox,'FitBoxToText','on');


%%
% Save the Plot
%cd('../../Matlab_Figures/GEV/Tides/Rth/')
%cd('../../swin/GEV/10_block/')
cd('../../');
outname = sprintf('GEV_feet_%s',station_nm);
hFig = gcf;
hFig.PaperUnits = 'inches';
hFig.PaperSize = [8.5 11];
hFig.PaperPosition = [0 0 7 7];
print(hFig,'-dpng','-r350',outname) %saves the figure, (figure, filetype, resolution, file name)
close(hFig)

%cd('../../../matlab/Climatology')
cd('matlab/Climatology')

