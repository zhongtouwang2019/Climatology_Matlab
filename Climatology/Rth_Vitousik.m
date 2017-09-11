% Script to retrieve water level data from the NOAA server using the CO-OPS data retrieval system.
% and perform a GEV analysis on it.
% See http://tidesandcurrents.noaa.gov/api/ for more details. Sean Vitousek.
clear all; close all; clc;
 

% Load data
dir_nm = '../../COOPS_tides/seattle/';
file_nm = 'seattle_6minV.mat';
file_load = strcat(dir_nm, file_nm);
load(file_load)
h = tides.WL_VALUE;
t = tides.time;
%% Detrend the data
 
 
h_detrend=detrend(h); % remove the SLR trend
 
% plot data
PLOT=1;
if PLOT
    subplot(2,1,1);
    p=polyfit(t,h,1);
    han1=plot(t,h,'-b',t,p(1)*t+p(2),'-r'); set(han1,'MarkerSize',2,'MarkerFaceColor','b'); datetick('x');
    han1=text(datenum(1915,1,1),0.75,['SLR=~',num2str(p(1)*1000*365.25),' mm/yr']); set(han1,'FontSize',14);
    xlabel('date'); datetick('x');
    ylabel('sea level [m]');
 
    subplot(2,1,2);
    han1=plot(t,h_detrend,'-b'); set(han1,'MarkerSize',2,'MarkerFaceColor','b'); datetick('x');
    xlabel('date'); datetick('x');
    ylabel('sea level [m] (detrended)');
end
%%
% find yearly peaks of the water level data
Npeaks=10;
[YYYY,~,~] =datevec(t);
Y=min(YYYY):max(YYYY);
len=length(Y);
 
t_events=NaN(len,Npeaks);
h_events=NaN(len,Npeaks);
 
for n=1:len % for each year of data, find the peaks
    
    t_part=t(YYYY==Y(n));         % temporary time vectors for a given year
    h_part=h_detrend(YYYY==Y(n)); % temporary water level vectors for a given year
    
    [peaks,ids]=findpeaks(h_part,'NPeaks',Npeaks,'MinPeakDistance',720,'SortStr','descend'); % find peaks
    
    t_events(n,:)=t_part(ids); % save the times of the peaks
    h_events(n,:)=h_part(ids); % save the peaks
    
    if 0 % PLOT work in progress?
        plot(t,h_detrend,'-b',t_events(n,:),h_events(n,:),'ro');
        xlabel('date'); datetick('x');
        ylabel('sea level [m] (detrended)');
        drawnow;
    end
    
end
 
% select top 3 events from the top 10 saved
Nmax=3; ri=1/Nmax; % select "r"-largest events per year
 
t_max=t_events(:,1:Nmax);
h_max=h_events(:,1:Nmax);
 
h_sort=sort(h_max(:),'descend'); % sort the events
len=length(h_sort);
 
% plot the max events
figure;
plot(t_max(:),h_max(:),'b.');
xlabel('date'); datetick('x');
ylabel('sea level [m] (detrended)');
title('Top 3 extreme sea-level events each year');
 
% perform GEV analysis
[parmhat,parmci] = gevfit(h_max(:));
 
k=parmhat(1);
sigma=parmhat(2);
mu=parmhat(3);
 
% Plot results
P1=(0.001:0.001:1)'; E1=1-P1;
E_data=linspace(1/(len+1),len/(len+1),len)';
P_data=1-E_data;
Tr_data=ri./E_data;
 
Tr1=(1:150)';
 
% anonymous functions to work with GEV data
F=@(x,mu,sig,k) gevcdf(x,k,sig,mu); % Cumulative probablity distribution function
E=@(x,mu,sig,k) 1-F(x,mu,sig,k);    % exceedance probablity function
E_inc=@(x,mu,sig,k,SLR) E(x,mu+SLR,sig,k)./E(x,mu,sig,k); % factor of increase in exceedance of probability
x_inv=@(E,mu,sig,k) gevinv(1-E,k,sig,mu);                 % calculate event level x based on exceedace probability
Tr=@(x,mu,sig,k) ri./E(x,mu,sig,k);                       % return period
x_Tr=@(yr,mu,sig,k) gevinv(1-(ri./yr),k,sig,mu);          % calculate event level x based on return period
Tr_pct_red=@(TR,mu,sig,k,SLR) (TR-Tr(x_Tr(TR,mu,sig,k),mu+SLR,sig,k))./TR; % calculate the percent reduction in return period
 
% plot GEV model
figure(2);
subplot(1,2,1);
plot(h_sort,E_data,'ro',x_inv(E1,mu,sigma,k),E1,'b');
xlabel('extreme sea level [m]');
ylabel('exceedance probability');
legend('data','model');
title('GEV model of water level');
SLR=0.05;
 
subplot(1,2,2); hold on; box on;
plot(Tr_data,h_sort,'ro',Tr1,x_Tr(Tr1,mu,sigma,k),'b');
 
%plot(Tr1,x_Tr(Tr1,mu+SLR,sigma,k),'m');
%plot(100,x_Tr(100,mu,sigma,k),'bo',100,x_Tr(100,mu+SLR,sigma,k),'mo');
%plot(100,x_inv(100,mu,sigma,k),'bo',Tr(x_Tr(100,mu,sigma,k),mu+SLR,sigma,k),x_Tr(100,mu,sigma,k),'co');
%plot([0 150],[x_Tr(100,mu,sigma,k) x_Tr(100,mu,sigma,k)],'k--');
 
xlabel('return period [yr]');
ylabel('extreme sea level [m]');
title('GEV model of return period');
han1=legend('data','model'); set(han1,'location','SouthEast');
axis([0 150 0.4 0.9]);
 
% plot impacts of SLR
dslr=0.01;
slr=(0:dslr:0.5)';
 
figure;
subplot(2,1,1)
plot(slr,100*Tr_pct_red(100,mu,sigma,k,slr),'b');
xlabel('sea-level rise [m]');
ylabel({'% reduction in return period','of the 100-yr water level'});
title('Impacts of SLR');
 
subplot(2,1,2);
plot(slr,1./(1-Tr_pct_red(100,mu,sigma,k,slr)),'b',slr,E_inc(x_Tr(100,mu,sigma,k),mu,sigma,k,slr),'r.');
xlabel('sea-level rise [m]');
ylabel({'factor of increase in frequency','of exceeding 100-yr water level'});
set(gca,'Yscale','log');
axis([0 0.5 0 350]);



k=parmhat(1);
sigma=parmhat(2);
mu=parmhat(3);
 
formatspec = 'k: %4.2f\n sigma: %4.2f\n, mu: %4.2f';
fprintf(formatspec, k, sigma, mu)