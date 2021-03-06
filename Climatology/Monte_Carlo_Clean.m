%% Code to perform a Monte Carlo simulation on GEV parameters and Assess RI

% Load in data
clearvars                                                                  
dir_nm = '../../COOPS_tides/';
station_nm = 'seattle';
load_file = strcat(dir_nm,station_nm,'/',station_nm,'_hrV');
load(load_file)
clear dir_nm file_nm load_file
%% Run Monte Carlo on GEV estimates for data and calculate Recurrence Interval

% Years available
yr = year(tides.time(1)):year(tides.time(end));

% Find mean of last 10 years 
tinds = find(year(tides.time) == yr(end) - 10);
wl_inds = tinds(1):length(tides.WL_VALUE);
ten_mean = mean(tides.WL_VALUE(wl_inds));

% Detrend tides
tides.WL_VALUE = detrend(tides.WL_VALUE);
% Convert to feet
%tides.WL_VALUE = tides.WL_VALUE*3.28084;

% rth values to collect (can vary)
block_num = 10;
r_val = 3;

% Min distance between events (half hour incr) 
min_sep = 12;

% Preallocate
data = zeros(length(yr),block_num);

% Find rth number of max events per year
for yy=1:length(yr)
    wl_inds = year(tides.time) == yr(yy);
    val_ind = tides.WL_VALUE(wl_inds);
    for r=1:block_num
        [data(yy,r), I] = max(val_ind);
        pop_inds = max([1 I-min_sep]):min([length(val_ind) I+min_sep]);
        val_ind(pop_inds) = [];
    end
end

%%
% Grab GEV estimates
% - Block/Hybrid Method - must be a vector
% data = data(:,1:r_val);
% [parmhat, parmCI] = gevfit(data(:)); 

% - Rth Largest, can be multi-column going Increasing to decreasing
parmhat = gevfit_rth(data(:,1:r_val)); 

% Calculate Standard Error for each parameter 
% ---- Note ---- R gives Standard Error in terms of Location(mu),scale(sigma) and shape(k).  

% From R - Standard Error Values for r 
kSE = 0.027626061;
sigSE = 0.003790572;
muSE = 0.008569755;

% % % % Seattle SE estimates from R for r = 1:10 respectively 
% % % parmCI1k = 0.052853561; parmCI1sig = 0.008332192; parmCI1mu = 0.012107234;
% % % parmCI2k = 0.035790486; parmCI2sig = 0.005087182; parmCI2mu = 0.009950179;
% % % parmCI3k = 0.027626061; parmCI3sig = 0.003790572; parmCI3mu = 0.008569755;
% % % parmCI4k = 0.024745905; parmCI4sig = 0.003361619; parmCI4mu = 0.008046526; 
% % % parmCI5k = 0.022052276; parmCI5sig = 0.003066568; parmCI5mu = 0.007655433;
% % % parmCI6k = 0.021402956; parmCI6sig = 0.003030071; parmCI6mu = 0.007282214;
% % % parmCI7k = 0.019711360; parmCI7sig = 0.002892105; parmCI7mu = 0.006997288;
% % % parmCI8k = 0.019039934; parmCI8sig = 0.002866830; parmCI8mu = 0.006825072;
% % % parmCI9k = 0.018517831; parmCI9sig = 0.002872376; parmCI9mu = 0.006666725;
% % % parmCI10k = 0.017841100; parmCI10sig = 0.002857912; parmCI10mu = 0.006529347;


% For block maxima/hybrid approach.  Calculating SE from Matlabs Confidence
% Intervals
%kSE = (parmCI(1,1)-parmhat(1))/2;
%sigSE = (parmCI(1,2)-parmhat(2))/2;
%muSE = (parmCI(1,3)-parmhat(3))/2;

%% Run Monte Carlo simulation 

% Preallocate
num_its = 10000;
k_hat = zeros(1,num_its);
sig_hat = k_hat;
mu_hat = k_hat;

for jj = 1:num_its
    k_hat(1,jj) = parmhat(1) + (kSE * randn(1,1));
    sig_hat(1,jj) = parmhat(2) + (sigSE * randn(1,1));
    mu_hat(1,jj) = parmhat(3) + (muSE * randn(1,1));
end

% Create X-Axis for data for plotting 
xlims = [min(data(:))+ten_mean, 1.1*(max(data(:))+ten_mean)];
x_axis = linspace(xlims(1),xlims(2),1000);

% Preallocate
cdf_hat = zeros(length(x_axis),num_its);

% Estimate the CDF 
count = 1;
for ii = 1:num_its
    cdf_hat(:,count) = 1 - gevcdf(x_axis,k_hat(ii),sig_hat(ii),mu_hat(ii)+ten_mean);
    count = count + 1;
end

% Calculate RI
RI_hat = 1./cdf_hat;

%% Find the water level at each yearly recurrence interval

% Preallocate
years = 1:1:100;
indices = zeros(length(years),length(RI_hat));

% Find indices of each yearly water level
for col = 1:length(RI_hat)
    temp_col = RI_hat(:,col);
    for yr = 1:length(years)
        temp_ind = findnearest(yr, temp_col);
        indices(yr,col) = temp_ind(1);
    end
end

% Grab water levels for each indice 
wl_mat = x_axis(indices);

% Calculate mean and standard deviation for each yearly water level
mean_mat = mean(wl_mat,2);
std_mat = std(wl_mat,0,2);
std_mat = std_mat';
%% Plot to see 1 Standard Deviation and Histogram of water levels 
% % std_val = 50;
% % y = 1:.5:500;
% % x1 = ones(length(y))*(mean_mat(std_val,1)-std_mat(1,std_val));
% % x2 = ones(length(y))*(mean_mat(std_val,1)+std_mat(1,std_val));
% % 
% % clf
% % hist(wl_mat(std_val,:),100)
% % hold on
% % line(x1,y)
% % line(x2,y)
%% Plot GEV estimates for RI with confidence intervals for recurrence

% Create x_axis
x_axis = linspace((min(data(:))+ten_mean),4,length(std_mat));

% Grab CDF based on GEV parameters
cdf = 1 - gevcdf(x_axis,parmhat(1),parmhat(2),parmhat(3)+ten_mean);

% Grab the estimate for recurrence interval
RI = 1./cdf;

clf


% plot(x_axis, RI)
% line(x_axis - std_mat, RI, 'LineStyle', '--', 'Color', 'red');
% line(x_axis + std_mat, RI, 'LineStyle', '--', 'Color', 'red');
% mean_line = line(mean_mat, RI, 'Color', 'black');

% Add in monte carlo estimate lines
for k = 1:10:num_its
    temp_cdf = 1 - gevcdf(x_axis,k_hat(k),sig_hat(k),mu_hat(k)+ten_mean);
    temp_RI = 1./temp_cdf;
    line(x_axis, temp_RI, 'Color', [.7 .7 .7])
end
% Plot RI line with 95% CI intervals
ri_line = line(x_axis, RI, 'Color', 'blue', 'LineWidth', 2);
lower_bound = line(x_axis - std_mat, RI, 'LineStyle', '--', 'Color', 'red', 'LineWidth', 2);
upper_bound = line(x_axis + std_mat, RI, 'LineStyle', '--', 'Color', 'red', 'LineWidth', 2);

ax = gca;
ax.XLim = [3.4 3.85];
ax.YLim = [0 100];
xlabel('Maximum TWL [m]');
ylabel('Recurrence Interval [years]');
grid on


% Generate specific values for recurrence levels & Confidence intervals
R100MLE = gevinv(1-1./100,parmhat(1),parmhat(2),parmhat(3)+ten_mean);
R50MLE = gevinv(1-1./50,parmhat(1),parmhat(2),parmhat(3)+ten_mean);
R25MLE = gevinv(1-1./25,parmhat(1),parmhat(2),parmhat(3)+ten_mean);
R10MLE = gevinv(1-1./10,parmhat(1),parmhat(2),parmhat(3)+ten_mean);
R5MLE = gevinv(1-1./5,parmhat(1),parmhat(2),parmhat(3)+ten_mean);
R2MLE = gevinv(1-1./2,parmhat(1),parmhat(2),parmhat(3)+ten_mean);


CI100 = std_mat(100);
CI50 = std_mat(50);
CI25 = std_mat(25);
CI10 = std_mat(10);
CI5 = std_mat(5);
CI2 = std_mat(2);

% Add RI estimates to the plot
tbox = sprintf('100 yr: %4.2f m +/- %4.2f m\n50 yr: %4.2f m +/- %4.2f m\n25 yr: %4.2f m +/- %4.2f m\n10 yr: %4.2f m +/- %4.2f m\n5 yr: %4.2f m +/- %4.2f m\n2 yr: %4.2f m +/- %4.2f m'...
    ,R100MLE,CI100, R50MLE,CI50, R25MLE,CI25, R10MLE,CI10, R5MLE,CI5, R2MLE,CI2);
text(6,60, tbox)
dim = [.25 .3 .3 .3];
annotation('textbox',dim,'String',tbox,'FitBoxToText','on');


% print output to command window
fprintf('\n2yr: %4.2f+- %4.4f\n', R2MLE,CI2)
fprintf('5yr: %4.2f+- %4.4f\n', R5MLE,CI5)
fprintf('10yr: %4.2f+- %4.4f\n', R10MLE,CI10)
fprintf('25yr: %4.2f+- %4.4f\n', R25MLE,CI25)
fprintf('50yr: %4.2f+- %4.4f\n', R50MLE,CI50)
fprintf('100yr: %4.2f+- %4.4f\n', R100MLE,CI100)
%% Save Plot 

cd('../../');
outname = sprintf('RI_estimates_with95CI_MONTECARLOESTIMATES%s',station_nm);
hFig = gcf;
hFig.PaperUnits = 'inches';
hFig.PaperSize = [8.5 11];
hFig.PaperPosition = [0 0 7 7];
print(hFig,'-dpng','-r350',outname) %saves the figure, (figure, filetype, resolution, file name)
close(hFig)

%cd('../../../matlab/Climatology')
cd('matlab/Climatology')
