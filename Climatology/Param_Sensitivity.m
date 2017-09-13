%% Parameter sensitivity analysis for GEV parameters
clearvars

%first load in the data
dir_nm = '../../COOPS_tides/';
%dir_nm = '../../hourly_data/gap_hourly/Station_Choice/';
station_name = 'Seattle';
station_nm = 'seattle';

load_file = strcat(dir_nm,station_nm,'/',station_nm,'_hrV');
load(load_file)
clear dir_nm file_nm load_file

%% Collect maxima

% Years available
yr = year(tides.time(1)):year(tides.time(end));

% Find mean of last 10 years 
tinds = find(year(tides.time) == yr(end) - 10);
inds = tinds(1):length(tides.WL_VALUE);
ten_mean = mean(tides.WL_VALUE(inds));

% Detrend tides
tides.WL_VALUE = detrend(tides.WL_VALUE);

% rth values to collect (can use less later)
r_num = 10;

% Min distance between events (half hour incr) 24 if half our, 12 if hour
min_sep = 12;

% Preallocate
data = zeros(length(yr),r_num);

% Loop
for yy=1:length(yr)
    inds = year(tides.time) == yr(yy);
    temp = tides.WL_VALUE(inds);
    for r=1:r_num
        [data(yy,r), I] = max(temp);
        pop_inds = max([1 I-min_sep]):min([length(temp) I+min_sep]);
        temp(pop_inds) = [];
    end
end
%% Estimate the GEV paramters and preliminary plot of fit

% limits
xlim = [(min(data(:))+ten_mean) (1.1*max(data(:))+ten_mean)];
figure(1)

clf
pdf_data = histogram(data(:,1)+ten_mean,8,'Normalization','pdf');
hold on

mycolors = jet(10);
% Get GEV parameters from distribution
[parmhat CIhat] = gevfit(data(:,1));
% Set up x axis
x_axis = linspace(xlim(1),xlim(2),100);
% Set up line of gev fit to data
pdf_gev = gevpdf(x_axis,parmhat(1),parmhat(2),parmhat(3)+ten_mean);
% Plot the line on the PDF
plot(x_axis,pdf_gev,'Color',mycolors(1,:));

ax = gca;
ax.XLim = [xlim(1) xlim(2)-.2];

%% Change parameters using confidence intervals (95% CI from Matlab)

%----------------Results from GEV----------------%
% kMLE = paramhat(1);       % Shape parameter
% sigmaMLE = paramhat(2);   % Scale parameter
% muMLE = paramhat(3);      % Location parameter


% First play around with k - paramhat(1)
figure(2)
pdf_data = histogram(data(:,1)+ten_mean,8,'Normalization','pdf');
hold on
% limits
ax = gca;
ax.XLim = [xlim(1) xlim(2)-.2];

kvec = linspace(CIhat(1,1),CIhat(2,1),10);



for k = 1:length(kvec)
% GEV pdf 
x_axis = linspace(xlim(1),xlim(2),100);
pdf_gev = gevpdf(x_axis,kvec(1),parmhat(2),parmhat(3)+ten_mean); 
plot(x_axis,pdf_gev,'Color',mycolors(k,:))
end
kvec = num2str(kvec,'%4.2f\n');
chan = colorbar;
colormap(mycolors)
kinc = diff(kvec);
%legend('r=1','r=10')

chan.YTick = .05:.1:.95;
chan.YTickLabel = kvec;
ylabel(chan,'k-value')
ylabel('Probability')
xlabel('Maximum yearly TWL [m]')
plot_tit = sprintf('%s - Varying K',station_name);
title(plot_tit)

%% Now for sigmahat - paramhat(2)
figure(3)
pdf_data = histogram(data(:,1)+ten_mean,8,'Normalization','pdf');
hold on
% limits
ax = gca;
ax.XLim = [xlim(1) xlim(2)-.2];

% Create vector for sigma
sigvec = linspace(CIhat(1,2),CIhat(2,2),10);

for s = 1:length(sigvec)
% GEV pdf 
x_axis = linspace(xlim(1),xlim(2),100);
pdf_gev = gevpdf(x_axis,parmhat(1),sigvec(s),parmhat(3)+ten_mean); 
plot(x_axis,pdf_gev,'Color',mycolors(s,:))
end
sigvec = num2str(sigvec,'%4.2f\n');
chan = colorbar;
colormap(mycolors)
sinc = diff(sigvec);
%legend('r=1','r=10')

chan.YTick = .05:.1:.95;
chan.YTickLabel = sigvec;
ylabel(chan,'sigma-value')
ylabel('Probability')
xlabel('Maximum yearly TWL [m]')
plot_tit = sprintf('%s - Varying Sigma',station_name);
title(plot_tit)

%% Now for muhat - paramhat(3)
figure(4)
pdf_data = histogram(data(:,1)+ten_mean,8,'Normalization','pdf');
hold on
% limits
ax = gca;
ax.XLim = [xlim(1) xlim(2)-.2];

% Create vector for sigma
muvec = linspace(CIhat(1,3),CIhat(2,3),10);

for m = 1:length(muvec)
% GEV pdf 
x_axis = linspace(xlim(1),xlim(2),100);
pdf_gev = gevpdf(x_axis,parmhat(1),parmhat(2),muvec(m)+ten_mean); 
plot(x_axis,pdf_gev,'Color',mycolors(m,:))
end
muvec = num2str(muvec,'%4.2f\n');
chan = colorbar;
colormap(mycolors)
minc = diff(muvec);
%legend('r=1','r=10')

chan.YTick = .05:.1:.95;
chan.YTickLabel = muvec;
ylabel(chan,'mu-value')
ylabel('Probability')
xlabel('Maximum yearly TWL [m]')
plot_tit = sprintf('%s - Varying Mu',station_name);
title(plot_tit)


%% 





%% Save Plot 

cd('../../');
outname = sprintf('Rvalue_sensitivity_%s',station_nm);
hFig = gcf;
hFig.PaperUnits = 'inches';
hFig.PaperSize = [8.5 11];
hFig.PaperPosition = [0 0 7 7];
print(hFig,'-dpng','-r350',outname) %saves the figure, (figure, filetype, resolution, file name)
close(hFig)

%cd('../../../matlab/Climatology')
cd('matlab/Climatology')
