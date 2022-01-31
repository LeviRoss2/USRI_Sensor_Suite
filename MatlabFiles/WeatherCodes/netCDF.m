
%% Define user data and create netCDF file

delete cdfTest.cdf

weatherVars{1,1} = 'Time';
weatherVars{1,2} = parsedIMET{1,2}{:,1};
weatherVars{1,3} = 'Serial (time from Jan 1 0000)';

weatherVars{2,1} = 'BaroPress';
weatherVars{2,2} = parsedIMET{1,2}{:,3};
weatherVars{2,3} = 'mbar';

weatherVars{3,1} = 'Temp';
weatherVars{3,2} = parsedIMET{1,2}{:,4};
weatherVars{3,3} = 'Celsius';

weatherVars{4,1} = 'Humid';
weatherVars{4,2} = parsedIMET{1,2}{:,5};
weatherVars{4,3} = 'Percent';

fileCDF = input('<strong>Enter name for netCDF file: </strong>','s');
fullNameCDF = sprintf('%s.cdf', fileCDF);


for(i=1:length(weatherVars))
    
    partStruct{1,1} = weatherVars{i,1};
    partStruct{1,2} = weatherVars{i,2};
    partStruct{1,3} = weatherVars{i,3};
    
    data2cdf(fullNameCDF,partStruct);
    
    clear partStruct
    
end

readCDF(fullNameCDF);



%% FUNC: data2cdf - Generates netCDF structure based on entered data
% Intended to be called recursively, filling in one "data type" at a time
% Ensure all data entries are the same length and timescale
% * INPUT:
% % * partStruct: 1x3 structure of data (varName, varData, varUnits)
function data2cdf(filename,partStruct)

name = partStruct{1,1};

nRows = height(partStruct{1,2});
nCols = width(partStruct{1,2});

nccreate(filename,name,'Dimensions',{'nRow',nRows,'nCol',nCols});
ncwrite(filename,name,partStruct{1,2});
ncwriteatt(filename,name,'units',partStruct{1,3});

end
%% FUNC: redCDF - Reads back data from existing netCDF file, plots SketT
% Opens netCDF file and plots data on SkewT LogP plot
% Ensure all variables in netCDF file are the same length before running
% * INPUT:
% % * filename: netCDF file to be read back
function readCDF(file)

if file == 0
    [baseFileName, folder] = uigetfile('*.cdf', 'Select a Flight Data file');
    if baseFileName == 0
        % User clicked the Cancel button.
        return;
    end
    % Get the name of the input .mat file.
    file = fullfile(folder, baseFileName);
    
else
    ncid=netcdf.open(file)
    ncdisp(file)
    netcdf.close(ncid);
    
    SkewT(ncread(file,'BaroPress'),ncread(file,'Temp'),ncread(file,'Humid'));
end
end
%% FUNC: SkewT - Plots Temp, Pressure, Humid on SkewT LogP plot
% Uses pre-parsed data and generates SketT LogP diagram
% Temp, Pressure, and Humidity must all be of the same length
% * INPUT:
% % * Press: Barometric pressure (mbar)
% % * Temp: Temperature (°C)
% % * Humid: Humidity (% Relative Humidty)

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

