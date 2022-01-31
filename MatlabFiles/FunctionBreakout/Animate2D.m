close all
clear all

%% Initialize User Variables
frameRate = 120;   % Output video frame rate
plotSpeed = 5;       % Number of rows to skip between plot points (lower = slow plot speed)
tailLength = 100;  % Tail length of plot (number of rows to show at one time)
tailWidth = 3;    % Width of tail behind marker
markerSize = 5;

%% Gather Flight Data
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
Lat = table2array(FlightData(:,15));
Long = table2array(FlightData(:,14));
Var = table2array(FlightData(:,20));  % Currently Temp, change to what you want
Animation2D(Lat,Long,Var,frameRate,plotSpeed,tailLength,tailWidth,markerSize);

%% FUNC: animate2D - 2D Animation of Lat and Long data with Satellite view
function Animation2D(Lat, Long, Var, frameRate, plotSpeed, tailLength, tailWidth, markerSize)

%% Animation Setup
plotTitle = input('<strong>Enter Plot Title for animation function: </strong>','s');
colorTitle = input('<strong>Enter Colorbar title: </strong>','s');
colorUnits = input('<strong>Enter Colorbar units: </strong>','s');
colorLabel = {sprintf('%s\n(%s)',colorTitle,colorUnits)};
userFileName = input('<strong>Enter an output file name for the animation sequence to save as: </strong>','s');

if(strcmpi(userFileName,''))
    userFileName = 'defaultAnimationOutput';
end
vidFileName = regexprep(userFileName, ' +', ' ');
videoOutputFileName = fullfile(pwd, vidFileName);

animVid = VideoWriter(videoOutputFileName,'MPEG-4');
animVid.FrameRate = frameRate;
animVid.Quality = 100;

xAnim1=[nan;Long(:,1)];
yAnim1=[nan;Lat(:,1)];

lx = length(xAnim1);
ly = length(yAnim1);

data_range1 = ceil(max(max(Var))) - floor(min(min(Var))) + 1;
colorMap = colormap(jet(data_range1*10));

varLin = linspace(min(Var),max(Var),length(colorMap))';

for i=1:length(Var)
    varScale(i,1) = find(varLin(:,1) >= Var(i,1),1);
end

for i=1:length(Var)
    varMap (i,:) = colorMap(varScale(i,1),1:3);
end
%% USGS Mapping Data
baseURL = "https://basemap.nationalmap.gov/ArcGIS/rest/services";
usgsURL = baseURL + "/BASEMAP/MapServer/tile/${z}/${y}/${x}";
basemaps = ["USGSImageryOnly" "USGSImageryTopo" "USGSTopo" "USGSShadedReliefOnly" "USGSHydroCached"];
displayNames = ["USGS Imagery" "USGS Topographic Imagery" "USGS Shaded Topographic Map" "USGS Shaded Relief" "USGS Hydrography"];
attribution = 'Credit: U.S. Geological Survey';
%% GPS Plot
% GPS Plotting data

fig1 = figure(1);
fig1.Position = [100 100 1000 700];
ax1 = geoaxes('parent',fig1,'Position',[.1 .075 .8 .875]);
geobasemap(ax1,'satellite')
basemapx = basemaps(2);
url = replace(usgsURL,"BASEMAP",basemapx);
view(ax1,2)
geolimits(ax1,[(min(yAnim1)-.0005) (max(yAnim1)+.0005)],[(min(xAnim1)-.0005) (max(xAnim1)+.0005)]);
title(plotTitle);

pause(5);

display('Beginning animation sequence');
%% Colorbar Setup
caxis([min(Var) max(Var)])
cbh1 = colorbar();
cbh1.Position = [.93 .05 .025 .85];

colorAnn = annotation(fig1,'textbox',[.8975 .905 .09 .1],'String',colorLabel,'HorizontalAlignment','center','VerticalAlignment','middle','EdgeColor','none','FontWeight','bold');

%% Animation Function (Saved vs Non-Saved)
pH = gobjects(1,length(varMap));

pH(1) = geoplot(ax1,Lat(1),Long(1),'Color',[varMap(1,1) varMap(1,2) varMap(1,3)],'LineWidth',tailWidth,'Marker','none');
mH = geoplot(Lat(1),Long(1),'Marker','o','MarkerSize',markerSize,'MarkerFaceColor',[0 0 1],'MarkerEdgeColor',[0 0 0]);
geolimits(ax1,[(min(yAnim1)-.0005) (max(yAnim1)+.0005)],[(min(xAnim1)-.0005) (max(xAnim1)+.0005)]);
title(plotTitle);
drawnow

caxis([min(Var) max(Var)])
cbh1 = colorbar();
cbh1.Position = [.93 .075 .025 .85];

tic
open(animVid);
hold on
for i=2:(lx-1);
    
    pH(i) = geoplot(ax1,[Lat(i) Lat(i-1)],[Long(i) Long(i-1)],'Color',[varMap(i,1) varMap(i,2) varMap(i,3)],'LineWidth',tailWidth,'Marker','none');
    set(mH,'XData',Lat(i),'YData',Long(i),'MarkerFaceColor',[varMap(i,1) varMap(i,2) varMap(i,3)]);
    geobasemap(ax1,'satellite')
    geolimits(ax1,[(min(yAnim1)-.0005) (max(yAnim1)+.0005)],[(min(xAnim1)-.0005) (max(xAnim1)+.0005)]);
    
    if(i>(tailLength+1))
        pH(i-tailLength).Visible = 'Off';
    end
    
    title(plotTitle);
    
    drawnow
    frame = getframe(gcf); %get frame
    writeVideo(animVid, frame);
    
end
hold off

close(animVid);
toc

disp('Animation sequence completed.');

geobasemap(ax1,'satellite')
geolimits(ax1,[(min(yAnim1)-.0005) (max(yAnim1)+.0005)],[(min(xAnim1)-.0005) (max(xAnim1)+.0005)]);
end