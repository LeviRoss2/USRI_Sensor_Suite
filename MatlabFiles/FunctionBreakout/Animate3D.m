close all
clear all

%% Initialize User Variables
frameRate = 120;   % Output video frame rate
plotSpeed = 100;       % Number of rows to skip between plot points (lower = slow plot speed)
tailLength = 34345345;  % Tail length of plot (number of rows to show at one time)
tailWidth = 3;    % Width of tail behind marker

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
Time = table2array(FlightData(:,1));
Lat = table2array(FlightData(:,15));
Long = table2array(FlightData(:,14));
Alt = table2array(FlightData(:,16));
VarData = table2array(FlightData(:,20));  % Currently Temp, change to what you want

Animation3D(Time,Lat,Long,Alt,VarData,frameRate,plotSpeed,tailLength,tailWidth);

%% FUNC: Animation3D - Animated 3D plot with color-changing tail
% Animate flight profile with colorbar tail based on VarData
% All entries must be of the same length or code will not run properly
% INPUT
% * Time - time (in seconds) starting at 0 going through entire flight
% * Lat - Latitude (decimal degrees)
% * Long - Longitude (decimal degrees)
% * Alt - Altitude (m)
% * VarData - Variable to use colorbar with, will determine tail color
% * frameRate - Playback frame rate of exported video
% * plotSpeed - Number of rows to plot in each frame
% * tailLength - Number of rows of data to show at any given time
% * tailWidth - Width of tail on the plot
function Animation3D(Time,Lat,Long,Alt,VarData,frameRate,plotSpeed,tailLength,tailWidth)

arguments
    options.frameRate
end


plotTitle = input('<strong>Enter Plot Title for animation function: </strong>','s');
colorTitle = input('<strong>Enter Colorbar title: </strong>','s');
colorUnits = input('<strong>Enter Colorbar units: </strong>','s');
colorLabel = {sprintf('%s\n(%s)',colorTitle,colorUnits)};
userFileName = input('<strong>Enter an output file name for the animation sequence to save as: </strong>','s');

%% DO NOT CHANGE BEYOND THIS POINT
%% Animation Setup

timer = [0;Time];
cAnim1=[nan;VarData];  % Variable to have colorbar
xAnim=[nan;Lat];  % Lattitude
yAnim=[nan;Long];  % Longitude
zAnim=[nan;Alt];  % Altitude
lx = length(xAnim);
ly = length(yAnim);
lz = length(zAnim);

fig10 = figure(10);
fig10.Position=[10 10 850 750];
fig10.Resize = 'Off';
%% Temperature Plot
ax1 = gca;
if(strcmpi(plotTitle,''))
    plotTitle = 'Default';
end
title(plotTitle);
xlim(ax1, [min(xAnim(2:lx)) max(xAnim(2:lx))]);
ylim(ax1, [min(yAnim(2:ly)) max(yAnim(2:ly))]);
zlim(ax1, [min(zAnim(2:end)) max(zAnim(2:end))]);
view(ax1, 3)
grid on
zl = zlabel('Altitude (m, MSL)');
yl = ylabel('Latitude');
xl = xlabel('Longitude');
xticks(min(xAnim):((max(xAnim)-min(xAnim))/4):max(xAnim));
yticks(min(yAnim):((max(yAnim)-min(yAnim))/4):max(yAnim));
zticks(min(zAnim(2:end)):((max(zAnim)-min(zAnim(2:end)))/5):max(zAnim(2:end)));
xtickformat('%.3f')
ytickformat('%.3f')
ztickformat('%.0f')
set(ax1,'Color','k','xcolor','w','ycolor','w','zcolor','w','LineWidth',2)

data_range1 = ceil(max(max(cAnim1(2:end)))) - floor(min(min(cAnim1(2:end)))) + 1;
colormap(jet(data_range1*10));
caxis([min(min(cAnim1(2:end))) max(max(cAnim1(2:end)))])
cbh1 = colorbar();
%% Position Control
subfig = get(gcf,'children');

set(subfig(1),'position',[.92 .1 .03 .8]);    % Color bar
set(subfig(2),'position',[.1 .06 .8 .88]);    % Main plotting area

view(subfig(2),-45,20);

AnimPos = [.025 .88 .09 .1];

annotation(fig10,'textbox',[.8875 .9 .09 .1],'String',colorLabel,'HorizontalAlignment','center','VerticalAlignment','middle','EdgeColor','none','FontWeight','bold');
%% Set Axis Colors

for i=1:length(ax1.XTickLabel)
    ax1.XTickLabel{i} = ['\color[rgb]{0,0,0}' ax1.XTickLabel{i}];
end
for j=1:length(ax1.YTickLabel)
    ax1.YTickLabel{j} = ['\color[rgb]{0,0,0}' ax1.YTickLabel{j}];
end
for k=1:length(ax1.ZTickLabel)
    ax1.ZTickLabel{k} = ['\color[rgb]{0,0,0}' ax1.ZTickLabel{k}];
end

ax1.XTickLabel(i) = {' '};
ax1.YTickLabel(j) = {' '};

zl.Color = 'k';
xl.Color = 'k';
yl.Color = 'k';
%% Animation Function
% Allow user to define output file name, save in same location as function
if(strcmpi(userFileName,''))
    userFileName = 'defaultAnimationOutput';
end
vidFileName = regexprep(userFileName, ' +', ' ');
videoOutputFileName = fullfile(pwd, vidFileName);

% Define video to be .MP4, 100% quality, and 30 frames per second
animVid = VideoWriter(videoOutputFileName,'MPEG-4');
animVid.FrameRate = frameRate; 
animVid.Quality = 100;

disp('Beginning animation plotting...');
open(animVid);
for jj=1:plotSpeed:length(xAnim);
    if (jj < tailLength)
        p1 = patch(ax1,xAnim(1:jj),yAnim(1:jj),zAnim(1:jj),cAnim1(1:jj),'EdgeColor','interp','FaceColor','none','LineWidth',tailWidth); view(-45,45)
    else
        p1 = patch(ax1,xAnim(jj-tailLength:jj),yAnim(jj-tailLength:jj),zAnim(jj-tailLength:jj),cAnim1(jj-tailLength:jj),'EdgeColor','interp','FaceColor','none','LineWidth',tailWidth); view(-45,45)
    end
    
    delete(findall(fig10,'type','annotation'));
    Minutes = fix(timer(jj,1)/60);
    Hours = fix(timer(jj,1)/3600);
    
    if (Minutes > 59)
        for a = 1:fix(Minutes/60)
            if(Minutes > 59)
                Minutes = Minutes - 60;
            end
        end
    end
    
    if(Minutes<10)
        String = {sprintf('Time (hr:min)\n%.0f:0%.0f',Hours,Minutes)};
    else
        String = {sprintf('Time (hr:min)\n%.0f:%.0f',Hours,Minutes)};
    end
    annotation(fig10,'textbox',AnimPos,'String',String,'HorizontalAlignment','center','VerticalAlignment','middle');
    annotation(fig10,'textbox',[.8875 .9 .09 .1],'String',colorLabel,'HorizontalAlignment','center','VerticalAlignment','middle','EdgeColor','none','FontWeight','bold');
    
    pause(1/50); %Pause and grab frame
    frame = getframe(gcf); %get frame
    writeVideo(animVid, frame);
    cla(ax1);
end
close(animVid);
disp('Animation plotting completed. Video file saved in same location as the data file.');
p1 = patch(ax1,xAnim(1:jj),yAnim(1:jj),zAnim(1:jj),cAnim1(1:jj),'EdgeColor','interp','FaceColor','none','LineWidth',2); view(-45,45)
end