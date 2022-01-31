clear all
clc
close all

%% Gather Data Files
[baseFileName, folder] = uigetfile({'*.xlsx;*.xlsm;*.csv'}, 'Select a Flight Data file');
if baseFileName == 0
    % User clicked the Cancel button.
    return;
end
% Get the name of the input .mat file.
fullInputMatFileName = fullfile(folder, baseFileName);
% Get filename without the extension, used by Save Function
[~, baseNameNoExt, ~] = fileparts(baseFileName);
% Load file in
FlightData = readtable(fullInputMatFileName);

%% DEFINE WHERE TO FIND DATA IN YOUR TABLE
% Replace the column numner (row,col) that corresponds with data in the log
Temp = table2array(FlightData(:,20));
Humid = table2array(FlightData(:,));

% If Pressure in mbar, use this
Press = table2array(FlightData(:,7))/1000;

% If Pressure is in Altitude (not in units of presure) use this
%PressAlt = table2array(FlightData(:,18));
%Press = 1013.25*(1-(.000022557 * PressAlt)).^5.25588;

if(exist('Press'))
    SkewT(Press,Temp,Humid);
else
    error('Plots not generated. Choose which type of pressure reading to use.');
end

%% FUNC: SkewT - Plots Temp, Pressure, Humid on SkewT LogP plot
% Temp, Pressure, and Humidity must all be of the same length

function SkewT(Press,Temp,Humid)


fig10 = figure(10);
ez=6.112.*exp(17.67.*Temp./(243.5+Temp));
qz=Humid.*0.622.*ez./(Press-ez);
chi=log(Press.*qz./(6.112.*(0.622+qz)));
tdz=243.5.*chi./(17.67-chi);
%
p=[1050:-25:100];
pplot=transpose(p);
t0=[-48:2:50];
[ps1,ps2]=size(p);
ps=max(ps1,ps2);
[ts1,ts2]=size(t0);
ts=max(ts1,ts2);
for i=1:ts,
    for j=1:ps,
        tem(i,j)=t0(i)+30.*log(0.001.*p(j));
        thet(i,j)=(273.15+tem(i,j)).*(1000./p(j)).^.287;
        es=6.112.*exp(17.67.*tem(i,j)./(243.5+tem(i,j)));
        q(i,j)=622.*es./(p(j)-es);
        thetaea(i,j)=thet(i,j).*exp(2.5.*q(i,j)./(tem(i,j)+273.15));
    end
end
p=transpose(p);
t0=transpose(t0);
temp=transpose(tem);
theta=transpose(thet);
thetae=transpose(thetaea);
qs=transpose(sqrt(q));
h=contour(t0,pplot,temp,16,'k');
hold on
set(gca,'ytick',[1000:100:100])
set(gca,'yscale','log','ydir','reverse')
set(gca,'fontweight','bold')
set(gca,'ytick',[100:100:1000])
set(gca,'ygrid','on')
hold on
h=contour(t0,pplot,theta,24,'b');
h=contour(t0,pplot,qs,24,'g');
h=contour(t0,pplot,thetae,24,'r');
tzm=Temp-30.*log(0.001.*Press);
tdzm=tdz-30.*log(0.001.*Press);
h=plot(tzm,Press,'k',tdzm,Press,'k--');
set(h,'linewidth',2)
hold off
xlabel('Temperature (C)','fontweight','bold')
ylabel('Pressure (mb)','fontweight','bold')
% Zoom in on target area
ylim([min(Press)-100 1000]);
xlim([min(tzm)-10 max(tzm)+10]);

end
