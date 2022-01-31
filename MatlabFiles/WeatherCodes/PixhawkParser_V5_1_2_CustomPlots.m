%% Initialize user workspace and close all Figures
close all
clear all
%% Global variables
% Intialize variables used between multiple functions
global arduPilotType
arduPilotType = 'Default';
global startingFolder
 startingFolder = pwd;
global figIter
figIter = 0;
global Figs
global uiFigIter
uiFigIter = 0;
global uiFigs
global rawVars
global parsedVars
global parseRangeUTC
global newOldDFL
newOldDFL = 'unknown';
global parsedIMET
global iMetNumber
iMetNumber = 0;
global btnClick
btnClick = 'no';
global rawDFL
global TPHNumber
TPHNumber = 0;
global MHPNumber
MHPNumber = 0;
global TeensyNumber
TeensyNumber = 0;
global parsedTeensy
global PLOTbtn
global redactStructDFL
%% UI Figure Setup
% Initialize UI Figure to hold all functionality
fig=uifigure(1,'Position',[15 45 1500 1000],'resize','off','Name',...
    'Pixhawk and External Data Parser and Animator','HandleVisibility','on');
% Create Tab Group to dynamic expand functionality via tabs
tabgp = uitabgroup(fig);
tabgp.Position = [5 5 1492 990];

% Start function calls
tabDataParse(fig, tabgp)

%% %%%%%%%%%%% UI FIGURE FUNCTIONS %%%%%%%%%%%
%% FUNC: tabDataParse - Generate UI components for Data Parse Tab
function tabDataParse(fig, tabgp)
tabDP = uitab(tabgp,'Title','Data Parse');

lblMain= uilabel(tabDP,'Text','User Selected Parsing Options','Position',...
    [400 800 450 50],'FontSize',32);

% Generate labels for extra data process needs (iMet, Teens Suite)
iMetlbl = uilabel(tabDP,'Text','iMet Count','Position',[400,700,125,30],...
    'FontSize',24);
iMetspn = uispinner(tabDP,'Limits',[0 10],'Value',0,'Position',...
    [400,650,125,30],'UserData','iMet');
lblTeensy = uilabel(tabDP,'Text','Teensy Suite','Position',...
    [540,700,150,30],'FontSize',24);
spnTeensy = uispinner(tabDP,'Limits',[0 10],'Value',0,'Position',...
    [550,650,125,30],'UserData','Teensy Suite');
% Generate button that starts processing the data based on checkbox entries
GObtn = uibutton(tabDP,'push','Text','Process','Position',[600 550 100 30],...
    'ButtonPushedFcn',@(GObtn,event) startProcessing(fig, tabgp, iMetspn, spnTeensy));

% Pause code until the button is pressed, allow for data to be captured
% Does not pause tic toc
uiwait(fig);
end
%% FUNC: tabAnimation2D - Generate Information for 2D Animation
function tabAnimation2D(fig, tabgp)

global parsedVars

tab = uitab(tabgp,'Title','2D Animation');

lblFrameRate = uilabel(tab,'Text','Frame Rate','Position',[1315 750 200 100],'FontSize',24);
lblSpeed = uilabel(tab,'Text','Animate Speed','Position',[1315 650 200 100],'FontSize',24);
lblLength = uilabel(tab,'Text','Tail Length','Position',[1340 550 200 100],'FontSize',24);
lblWidth = uilabel(tab,'Text','Tail Width','Position',[1345 450 200 100],'FontSize',24);
lblSize = uilabel(tab,'Text','Marker Size','Position',[1330 350 200 100],'FontSize',24);
lblAnim2DSaveName = uilabel(tab,'Text','Save as file name:','Position',[1083 935 300 25]);
lblTitle = uilabel(tab,'Text','Plot Title','Position',[1350 850 200 100],'FontSize',24);
lblFrame = uilabel(tab,'Text','Current Frame','Position',[1325 200 200 100],'FontSize',24);
lblFrameCount = uilabel(tab,'Text','0/0','Position',[1325 160 150 100],'FontSize',20','HorizontalAlignment','Center');
lblFramePercent = uilabel(tab,'Text','0%','Position',[1325 120 150 100],'FontSize',20','HorizontalAlignment','Center');

spnFrameRate = uispinner(tab,'Limits',[10 240],'Value',30,'Position',[1330,750,150,30]);
spnSpeed = uispinner(tab,'Limits',[1 100],'Value',10,'Position',[1330,650,150,30]);
spnLength = uispinner(tab,'Limits',[1 10000],'Value',150,'Position',[1330,550,150,30]);
spnWidth = uispinner(tab,'Limits',[1 10],'Value',3,'Position',[1330,450,150,30]);
spnSize = uispinner(tab,'Limits',[1 20],'Value',8,'Position',[1330,350,150,30]);
anim2DSaveName = uieditfield(tab,'text','Position',[1183 935 300 25]);
plotTitleName = uieditfield(tab,'text','Value','Plot Title','Position',[1330 850 150 30]);


% Find location of GPS table
for j=1:length(parsedVars)
    if(strcmpi('GPS_table',char(parsedVars{j,1})))
        locGPS=j;
    end
end

GPS_table = parsedVars{locGPS,2};

Lat = table2array(GPS_table(:,10));
Long = table2array(GPS_table(:,11));

% animate2D(fig, tab2A, Lat, Long,spnSpeed.Value, spnLength.Value,...
%     spnWidth.Value, spnSize.Value, anim2DSaveName.Value, plotTitleName.Value, spnFrameRate.Value);

animBtn2D = uibutton(tab,'push','Text','Animate in 2D','FontSize',22,...
    'Position',[1330 280 150 50],'ButtonPushedFcn',@(animBtn2D,event)...
    animate2D(fig, tab, Lat, Long,spnSpeed.Value, spnLength.Value,...
    spnWidth.Value, spnSize.Value, anim2DSaveName.Value,...
    plotTitleName.Value, spnFrameRate.Value, lblFrameCount, lblFramePercent));

end
%% FUNC: animate2D - 2D Animation of Lat and Long data with Satellite view
function animate2D(fig, tab, Lat, Long, Speed, Length, Width, Size,...
    fileName, plotTitle, frameRate, frameCount, framePercent)
global startingFolder
%% Animation Setup
animateTailLength = Length;
animateTailWidth = Width;
animateHeadSize = Size;
animateSpeed = Speed;

if(~isempty(fileName))
    vidName = fileName;
    videoOutputFileName = fullfile(startingFolder, vidName);
    
    animVid = VideoWriter(videoOutputFileName,'MPEG-4');
    animVid.FrameRate = frameRate;
    animVid.Quality = 100;
end

xAnim1=[nan;Long(:,1)];
yAnim1=[nan;Lat(:,1)];

lx = length(xAnim1);
ly = length(yAnim1);
%% USGS Mapping Data
baseURL = "https://basemap.nationalmap.gov/ArcGIS/rest/services";
usgsURL = baseURL + "/BASEMAP/MapServer/tile/${z}/${y}/${x}";
basemaps = ["USGSImageryOnly" "USGSImageryTopo" "USGSTopo" "USGSShadedReliefOnly" "USGSHydroCached"];
displayNames = ["USGS Imagery" "USGS Topographic Imagery" "USGS Shaded Topographic Map" "USGS Shaded Relief" "USGS Hydrography"];
attribution = 'Credit: U.S. Geological Survey';
%% GPS Plot 
% GPS Plotting data
tab2A_axes1 = geoaxes('parent',tab,'Position',[.075 .05 .8 .9]);
geobasemap(tab2A_axes1,'satellite')
basemapx = basemaps(2);
url = replace(usgsURL,"BASEMAP",basemapx);
view(tab2A_axes1,2)
geolimits(tab2A_axes1,[(min(yAnim1)-.0005) (max(yAnim1)+.0005)],[(min(xAnim1)-.0005) (max(xAnim1)+.0005)]);

pause(5);


display('Beginning animation sequence');
%% Animation Function (Saved vs Non-Saved)
pH1 = geoplot(tab2A_axes1,yAnim1(1,1),xAnim1(1,1),'r','LineWidth',animateTailWidth,'Marker','o','MarkerSize',animateHeadSize,'MarkerFaceColor','red','MarkerEdgeColor','none','MarkerIndices',1);
title(tab2A_axes1,plotTitle);

frameCount.Text = sprintf('%d / %d',0,lx);
framePercent.Text = sprintf('%s%s',num2str(0),'%');

j=0;
for i=1:animateSpeed:lx;
    
    if(i<=(animateTailLength+1))
        set(pH1,'XData',yAnim1(1:i,1),'YData',xAnim1(1:i,1),'Color','r','LineWidth',animateTailWidth,'Marker','o','MarkerSize',animateHeadSize,'MarkerFaceColor','red','MarkerEdgeColor','none','MarkerIndices',i);
    else
        set(pH1,'XData',[nan; yAnim1((i-animateTailLength):i,1)],'YData',[nan; xAnim1((i-animateTailLength):i,1)],'Color','r','LineWidth',animateTailWidth,'Marker','o','MarkerSize',animateHeadSize,'MarkerFaceColor','red','MarkerEdgeColor','none','MarkerIndices',animateTailLength+1);
    end
    
    frameCount.Text = sprintf('%d / %d',i,lx);
    framePercent.Text = sprintf('%s%s',num2str(round(i*1000/lx,1)/10),'%');
    geobasemap(tab2A_axes1,'satellite')
    geolimits(tab2A_axes1,[(min(yAnim1)-.0005) (max(yAnim1)+.0005)],[(min(xAnim1)-.0005) (max(xAnim1)+.0005)]);
    
    pause(.1) %Pause and grab frame
    j=j+1;
    if(~isempty(fileName))
    frame(j,:) = getframe(fig); %get frame
    end
    
end

frameCount.Text = sprintf('%d / %d',lx,lx);
framePercent.Text = sprintf('%s%s',num2str(100),'%');

if (~isempty(fileName))
    set(pH1,'XData',[nan; yAnim1((lx-animateTailLength):lx,1)],'YData',[nan; xAnim1((lx-animateTailLength):lx,1)],'Color','r','LineWidth',animateTailWidth,'Marker','o','MarkerSize',animateHeadSize,'MarkerFaceColor','red','MarkerEdgeColor','none','MarkerIndices',animateTailLength+1);
    geobasemap(tab2A_axes1,'satellite')
    geolimits(tab2A_axes1,[(min(yAnim1)-.0005) (max(yAnim1)+.0005)],[(min(xAnim1)-.0005) (max(xAnim1)+.0005)]);
    j=j+1;
    frame(j,:) = getframe(fig); %get frame
    
    open(animVid);
    writeVideo(animVid, frame);
    close(animVid);
end

set(pH1,yAnim1(1:lx,1),xAnim1(1:lx,1),'r','LineWidth',animateTailWidth,'Marker','o','MarkerSize',animateHeadSize,'MarkerFaceColor','red','MarkerEdgeColor','none','MarkerIndices',lx);
geobasemap(tab2A_axes1,'satellite')
geolimits(tab2A_axes1,[(min(yAnim1)-.0005) (max(yAnim1)+.0005)],[(min(xAnim1)-.0005) (max(xAnim1)+.0005)]);


end
%% FUNC: tabAnimation3D - Generate Information for 3D Animation
function tabAnimation3D(fig, tabgp)

global parsedVars

tab = uitab(tabgp,'Title','3D Animation');

lblFrameRate = uilabel(tab,'Text','Frame Rate','Position',[1315 750 200 100],'FontSize',24);
lblSpeed = uilabel(tab,'Text','Animate Speed','Position',[1315 650 200 100],'FontSize',24);
lblLength = uilabel(tab,'Text','Tail Length','Position',[1340 550 200 100],'FontSize',24);
lblWidth = uilabel(tab,'Text','Tail Width','Position',[1345 450 200 100],'FontSize',24);
lblSize = uilabel(tab,'Text','Marker Size','Position',[1330 350 200 100],'FontSize',24);
lblAnim3DSaveName = uilabel(tab,'Text','Save as file name:','Position',[1083 935 300 25]);
lblTitle = uilabel(tab,'Text','Plot Title','Position',[1350 850 200 100],'FontSize',24);
lblFrame = uilabel(tab,'Text','Current Frame','Position',[1325 200 200 100],'FontSize',24);
lblFrameCount = uilabel(tab,'Text','0/0','Position',[1325 160 150 100],'FontSize',20','HorizontalAlignment','Center');
lblFramePercent = uilabel(tab,'Text','0%','Position',[1325 120 150 100],'FontSize',20','HorizontalAlignment','Center');

spnFrameRate = uispinner(tab,'Limits',[10 240],'Value',30,'Position',[1330,750,150,30]);
spnSpeed = uispinner(tab,'Limits',[1 100],'Value',10,'Position',[1330,650,150,30]);
spnLength = uispinner(tab,'Limits',[1 10000],'Value',150,'Position',[1330,550,150,30]);
spnWidth = uispinner(tab,'Limits',[1 10],'Value',3,'Position',[1330,450,150,30]);
spnSize = uispinner(tab,'Limits',[1 20],'Value',8,'Position',[1330,350,150,30]);
anim3DSaveName = uieditfield(tab,'text','Position',[1183 935 300 25]);
plotTitleName = uieditfield(tab,'text','Value','Plot Title','Position',[1330 850 150 30]);

% Find location of GPS table
for j=1:length(parsedVars)
    if(strcmpi('GPS_table',char(parsedVars{j,1})))
        locGPS=j;
    end
end

GPS_table = parsedVars{locGPS,2};

Lat = table2array(GPS_table(:,10));
Long = table2array(GPS_table(:,11));
Alt = table2array(GPS_table(:,12));

animBtn3D = uibutton(tab,'push','Text','Animate in 3D','FontSize',22,...
    'Position',[1330 280 150 50],'ButtonPushedFcn',@(animBtn3D,event)...
    animate3D(fig, tab, Lat, Long, Alt, spnSpeed.Value, spnLength.Value,...
    spnWidth.Value, spnSize.Value, anim3DSaveName.Value,...
    plotTitleName.Value, spnFrameRate.Value, lblFrameCount, lblFramePercent));

end
%% FUNC: animate3D - 3D Animation of Lat, Long, and Alt Data
function animate3D(fig, tab, Lat, Long, Alt, Speed, Length, Width, Size,...
    fileName, plotTitle, frameRate, frameCount, framePercent)
global startingFolder
%% Animation Setup
animateTailLength = Length;
animateTailWidth = Width;
animateHeadSize = Size;
animateSpeed = Speed;

if(~isempty(fileName))
    vidName = fileName;
    videoOutputFileName = fullfile(startingFolder, vidName);
    
    animVid = VideoWriter(videoOutputFileName,'MPEG-4');
    animVid.FrameRate = frameRate;
    animVid.Quality = 100;
end

minAlt = min(Alt);
if(minAlt<0)
    Alt=Alt+abs(min(Alt));
elseif(minAlt>0)
    Alt=Alt-min(Alt);
end

xAnim1=[nan;Long(:,1)];
yAnim1=[nan;Lat(:,1)];
zAnim1=[nan;Alt(:,1)];

lx = length(xAnim1);
ly = length(yAnim1);
lz = length(zAnim1);

% GPS Plotting data
tab3A_axes1 = axes('parent',tab,'Position',[.075 .05 .8 .9]);
view(tab3A_axes1,2)

xlim(tab3A_axes1, [min(Long) max(Long)]);
ylim(tab3A_axes1, [min(Lat) max(Lat)]);
zlim(tab3A_axes1, [min(Alt) max(Alt)]);
xl = xlabel(tab3A_axes1,'Longitude');
yl = ylabel(tab3A_axes1,'Lattitude');
zl = zlabel(tab3A_axes1,'Alt (m, AGL)');

view(tab3A_axes1, 3)
xticks(tab3A_axes1,min(Long):((max(Long)-min(Long))/4):max(Long));
yticks(tab3A_axes1,min(Lat):((max(Lat)-min(Lat))/4):max(Lat));
zticks(tab3A_axes1,min(Alt):((max(Alt)-min(Alt))/4):max(Alt));
xtickformat(tab3A_axes1,'%.3f')
ytickformat(tab3A_axes1,'%.3f')
ztickformat(tab3A_axes1,'%.0f')
grid(tab3A_axes1,'on');
set(tab3A_axes1,'Color','k','xcolor','w','ycolor','w','zcolor','w','LineWidth',2)

axis(tab3A_axes1,[min(Long) max(Long) min(Lat) max(Lat) min(Alt) max(Alt)]);
%% Set Axis Colors
for i=1:length(tab3A_axes1.XTickLabel)
    tab3A_axes1.XTickLabel{i} = ['\color[rgb]{0,0,0}' tab3A_axes1.XTickLabel{i}];
end
for j=1:length(tab3A_axes1.YTickLabel)
    tab3A_axes1.YTickLabel{j} = ['\color[rgb]{0,0,0}' tab3A_axes1.YTickLabel{j}];
end
for k=1:length(tab3A_axes1.ZTickLabel)
    tab3A_axes1.ZTickLabel{k} = ['\color[rgb]{0,0,0}' tab3A_axes1.ZTickLabel{k}];
end

xl.Color = 'k';
yl.Color = 'k';
zl.Color = 'k';

view(tab3A_axes1,-45,45);
% set(tab3A_axes1,'Color','k','xcolor','w','ycolor','w','zcolor','w','LineWidth',2)

display('Beginning animation sequence');
%% Animation Function
pause(5);
pH1 = patch(tab3A_axes1,'XData',xAnim1(1:i),'YData',yAnim1(1:i),'ZData',zAnim1(1:i),'EdgeColor','r','FaceColor','none','LineWidth',animateTailWidth);
        title(tab3A_axes1,plotTitle);
j=0;

frameCount.Text = sprintf('%d / %d',0,lx);
framePercent.Text = sprintf('%s%s',num2str(0),'%');

clear frame
for i=1:animateSpeed:lx;
    
    if(i<=(animateTailLength+1))
        pH1 = patch(tab3A_axes1,'XData',xAnim1(1:i),'YData',yAnim1(1:i),'ZData',zAnim1(1:i),'EdgeColor','r','FaceColor','none','LineWidth',animateTailWidth);
        pH2 = patch(tab3A_axes1,'XData',xAnim1(i),'YData',yAnim1(i),'ZData',zAnim1(i),'Marker','o','MarkerSize',animateHeadSize,'MarkerFaceColor','red','MarkerEdgeColor','none');
    else
        pH1 = patch(tab3A_axes1,'XData',[nan; xAnim1((i-animateTailLength):i)],'YData',[nan; yAnim1((i-animateTailLength):i)],'ZData',[nan; zAnim1((i-animateTailLength):i)],'EdgeColor','r','FaceColor','none','LineWidth',animateTailWidth);
        pH2 = patch(tab3A_axes1,'XData',xAnim1(i),'YData',yAnim1(i),'ZData',zAnim1(i),'Marker','o','MarkerSize',animateHeadSize,'MarkerFaceColor','red','MarkerEdgeColor','none');
    end
    
    frameCount.Text = sprintf('%d / %d',i,lx);
    framePercent.Text = sprintf('%s%s',num2str(round(i*1000/lx,1)/10),'%');
    pause(1/25) %Pause and grab frame
    j=j+1;
    if(~isempty(fileName))
    frame(j,:) = getframe(fig); %get frame
    end
    cla(tab3A_axes1);
    
end

frameCount.Text = sprintf('%d / %d',lx,lx);
framePercent.Text = sprintf('%s%s',num2str(100),'%');

if(~isempty(fileName))
    pH1 = patch(tab3A_axes1,'XData',[nan; xAnim1((lx-animateTailLength):lx)],'YData',[nan; yAnim1((lx-animateTailLength):lx)],'ZData',[nan; zAnim1((lx-animateTailLength):lx)],'EdgeColor','r','FaceColor','none','LineWidth',animateTailWidth);
    pH2 = patch(tab3A_axes1,'XData',xAnim1(lx),'YData',yAnim1(lx),'ZData',zAnim1(lx),'Marker','o','MarkerSize',animateHeadSize,'MarkerFaceColor','red','MarkerEdgeColor','none');
    j=j+1;
    frame(j,:) = getframe(fig); %get frame

    open(animVid);
    writeVideo(animVid, frame);
    close(animVid);
end

cla(tab3A_axes1);

pH1 = patch(tab3A_axes1,'XData',xAnim1(1:i),'YData',yAnim1(1:i),'ZData',zAnim1(1:i),'EdgeColor','r','FaceColor','none','LineWidth',animateTailWidth);
pH2 = patch(tab3A_axes1,'XData',xAnim1(i),'YData',yAnim1(i),'ZData',zAnim1(i),'Marker','o','MarkerSize',animateHeadSize,'MarkerFaceColor','red','MarkerEdgeColor','none');
end
%% FUNC: tabCustomPlot - Generate Information for User-Selected Plots
function tabCustomPlot(fig, tabgp)

global redactStructDFL

tabCP = uitab(tabgp,'Title','Custom Plots');
cbt = uitree(tabCP,'checkbox','Position',[1285 2 200 960]);
fieldNamesDFL = fieldnames(redactStructDFL);
for i=1:length(fieldNamesDFL);
    fieldNamesVAR = fieldnames(redactStructDFL.(fieldNamesDFL{i}));
    varName = redactStructDFL.(fieldNamesDFL{i}).name;
    fieldNamesVAR = fieldNamesVAR(11:end,1);
    
    nodeMain(i) = uitreenode(cbt);
    nodeMain(i).Text = varName;
    
    for j=1:length(fieldNamesVAR)
        nodeSub(j) = uitreenode(nodeMain(i));
        nodeSub(j).Text = fieldNamesVAR{j};
    end
end

tabCP_axes1 = axes('parent',tabCP,'Position',[.05 .05 .8 .9]);

cbt.SelectionChangedFcn = @nodeChange;

end

%% %%%%%%%%%%% PRIMARY PARSING FUNCTIONS %%%%%%%%%%%
%% FUNC: ardupilogConvert - Loads in .BIN DFL, converts to Matlab data
% Asks user to find Pixhawk .BIN DataFlash Log files
% Converts the Binary to custom Matlab cell structure
% Stores data in cell structure for other functions to use
function [baseNameNoExt, baseName, folder, fullInputMatName] = ardupilogConvert()

global rawDFL

% Opens Pixhawk DFL file, saving the parts for use later (if we choose to)
[baseNameNoExt, baseName, folder,fullInputMatName] = file2open('*.bin',...
    'Select a .BIN Pixhawk DFL file');

% Convert the DFL (in binary) to custom Matlab cell structure
rawDFL = Ardupilog(fullInputMatName);

end
%% FUNC: file2open - Open File Based on File Input Type
% Prompt user to open a file of type "TYPE" with a heading of "TEXT"
% Saves file data as output
% INPUT
% * Type - File type to isolate for user to choose. Can be an array.
% * * Types: .csv, .txt, .xlsx, etc
% * * User will only be open the types provided
% * Text - Title of the UI figure that opens
% OUTPUT
% * baseNameNoExt - base file name with no extension or filepath details
% * baseName - base file name with extension but no filepath
% * folder - filepath to the file, but without any file information
% * fullInputMatName - file name with filepath and extension added
% * * These are used as passthrough to other functions
function [baseNameNoExt, baseName, folder, fullInputMatName] = file2open(type,text)

global startingFolder

% Get the name of the file that the user wants to use.
defaultName = fullfile(startingFolder,type);
% Grab baseName and folder directly from the loading process
[baseName, folder] = uigetfile(defaultName, text);

% Redefine starting folder as current folder
% Allows next file open to start in same folder
startingFolder = folder;

if baseName == 0
    % User clicked the Cancel button.
    return;
end

% Remove extension from the baseName
[~, baseNameNoExt, ~] = fileparts(baseName);

% Recombine all parts to recreate the full name
fullInputMatName = fullfile(folder, baseName);

end
%% FUNC: file2save - Save File Based on file2open Details
% Take file components from file2open and save in same location
% INPUT
% * baseNameNoExt - base file name with no extension or filepath details
% * folder - filepath to the file with no file information
% * varToSave - variable with data to save externally
function file2save(baseNameNoExt, folder, varToSave)

% Get the name of the intput.mat file and save as input_parsed.mat
baseFileName = sprintf('%s_Parsed.mat', baseNameNoExt);
% Generate output file name using folder details and new name
fullParsedMatFileName = fullfile(folder, baseFileName);
% Save file with parsed data as the original filename plus the added portion
save(fullParsedMatFileName,'varToSave');
end
%% FUNC: table2saveCSV - Save Specific Tables from Workspace To .CSV File
% Must be table (no arrays or structures)
% Before loading, define 'yourTable.Properties.Description = yourVarName;'
% * yourVarName will be appended after DFL file name as new .CSV file
% * * Ex: DFL Name: NimbusFlight2_5_27_2021.bin
% * *     varName : GPS
% * *     output  : NimbusFlight2_5_27_2021_varName.csv
% INPUT
% * baseNameNoExt - base file name with no extension or filepath details
% * folder - filepath to the file with no file information
% * tableToSave - table with data to save externally
function table2saveCSV(baseNameNoExt, folder, tableToSave)

% If Description of table is empty, use preset name. Else, use the name
if(isempty(tableToSave.Properties.Description))
    varName = 'undefinedVar';
else
    varName = tableToSave.Properties.Description;
end

% Save file as "PixhawkDFLname_VARNAME.csv"
% VARNAME can be undefinedVar if description is not set
baseFileName = sprintf('%s_%s.csv', baseNameNoExt, varName);
fullOutputMatFileName = fullfile(folder, baseFileName);
% Write data to .csv file
writetable(tableToSave, fullOutputMatFileName);

end
%% FUNC: startProcessing - Process Data Based on User Selection
% Take outputs from userSelection and begin processing
% INPUT
% * fig - Handle for the UI Figure
% * tabgp - Handle for the UITabGroup that runs each panel
% * iMetspn - Send number chosen from UI to iterative iMet read loop
% * spnTeensy - Send number chosen from UI to iterative Teensy read loop
function startProcessing(fig, tabgp, iMetspn, spnTeensy)

global rawDFL
global rawVars
global parsedVars
global btnClick
global arduPilotType
global redactStructDFL

% Unpause code now that processing can begin (does not pause tic toc)
uiresume(fig);

% If the first time the button has been clicked, parse the Pixhawk data
if(strcmpi(btnClick,'no'))
    
    % Change state so we know button has been pressed already
    btnClick = 'yes';
    
    [baseNameNoExt, baseName, folder, fullInputMatName] = ardupilogConvert();
    
    % Disable non-critical warning to ease user view
    warning('off','MATLAB:structOnObject')
    
    % Generate names from the DFL entires
    fieldNames = fieldnames(rawDFL);
    % Sort entries to match standard DFL output, remove static non-entries
    fieldNames = sort(fieldNames(11:end,:));
    % Determine length of DFL after static, unused data is removed
    len = length(fieldNames);
    
    for i=1:len
        
        % If no data is in the LineNo column, skip to next dataset
        if(isempty(rawDFL.(fieldNames{i}).LineNo))
            % If the empty is CTUN, warn that ArduCopter doesnt use it at all
            if(contains(rawDFL.(fieldNames{i}).name,'CTUN'))
                warning('CTUN data not available for ArduCopter files; no airspeed data.');
            end
            continue
        end
        
        % Generate redacted structure of non-empty data
        redactStructDFL.(fieldNames{i}) = struct(getfield(rawDFL,fieldNames{i}));
        
    end
    
    assignin('base','redactStructDFL',redactStructDFL);
    
    % Initialize check for ArduPilot Type
    Rover = 0;
    Copter = 0;
    QuadPlane = 0;
    Plane = 0;
    
    % Scan message log to determine what ArduPilot type it is
    for i=1:length(redactStructDFL.MSG.LineNo);
        if(contains(redactStructDFL.MSG.Message(i,1:length(redactStructDFL.MSG.Message(1,:))),'ArduCopter'))
            Copter = 1;
        elseif(contains(redactStructDFL.MSG.Message(i,1:length(redactStructDFL.MSG.Message(1,:))),'QuadPlane'))
            QuadPlane = 1;
        elseif(contains(redactStructDFL.MSG.Message(i,1:length(redactStructDFL.MSG.Message(1,:))),'ArduRover'))
            Rover = 1;
        elseif(contains(redactStructDFL.MSG.Message(i,1:length(redactStructDFL.MSG.Message(1,:))),'ArduPlane'))
            Plane = 1;
        end
    end
    
    % Depending on what values were found, set ArduPilot type
    % This structure prevents false analysis as more than 1 can be present
    if(Rover == 1)
        arduPilotType = 'ArduRover';
    elseif(Copter == 1)
        arduPilotType = 'ArduCopter';
    elseif(QuadPlane == 1)
        arduPilotType = 'QuadPlane';
    elseif(Plane == 1)
        arduPilotType = 'FixedWing';
    end
    
    % Combine all function arguments together, assing to workspace
    totalVars = {iMetspn, spnTeensy};
    assignin('base','totalVars',totalVars);
    
    fieldNamesIter = fieldnames(redactStructDFL);
    % Counter for variables copmpleted processing
    k=0;
    for i=1:length(fieldNamesIter)
        % If an un-selected checkbox, dont process the data
        if(strcmpi(fieldNamesIter{i},'GPS') | strcmpi(fieldNamesIter{i},'CTUN')...
                | strcmpi(fieldNamesIter{i},'ATT') | strcmpi(fieldNamesIter{i},...
                'RCOU') | strcmpi(fieldNamesIter{i},'IMU') |...
                strcmpi(fieldNamesIter{i},'NKF1') |...
                strcmpi(fieldNamesIter{i},'BARO') | strcmpi(fieldNamesIter{i},'XKF1'))
            
            % Keep track of valid entries
            k=k+1;
            rawVarLoop(fieldNamesIter{i},k);
        end
    end
    
    % Turn warnings on that we turned off previously
    warning('on','MATLAB:structOnObject')
    % Set target variables to find location in rawVars structure
    target = {'GPS_table','RCOU_table','ATT_table','CTUN_table','IMU_table','BARO_table'};
    
    % Find location in rawVars structure that targets reside in
    % Store location data for later use
    for i=1:length(target)
        for j=1:length(rawVars)
            res(j,1)= strcmpi(target(i),char(rawVars{j,1}));
            if(res(j,1) == 1)
                loc(i,1)=j;
                break
            end
        end
    end
    
    % If CTUN wasnt found, dont use
    if(loc(4)==0)
        chooseSubset(rawVars{loc(1),2}, rawVars{loc(2),2},...
            rawVars{loc(3),2}, rawVars{loc(5),2}, rawVars{loc(6),2})
    else
        chooseSubset(rawVars{loc(1),2}, rawVars{loc(2),2},...
            rawVars{loc(3),2}, rawVars{loc(5),2}, rawVars{loc(6),2}, rawVars{loc(4),2})
    end
    
    % Parse data using endpoints from chooseSubset across data chosen in UI
    for i=1:length(rawVars)
        % Parse data based on selection
        dataParsePix(i);
    end
    
    % Save current parsedVars array as external Parsed file for user review
    file2save(baseNameNoExt, folder, parsedVars);
    
end

% Parse iMet data (if enabled in UI)
for i=1:length(iMetspn)
    spnData = iMetspn(1,i);
    % Confirm spinner has iMet data before parsing
    if(strcmpi(spnData.UserData,'iMet'));
        for j=1:spnData.Value
            iMetRead(baseNameNoExt);
        end
    end
end

% Parse Teensy data (if enabled in UI)
for i=1:length(spnTeensy)
    spnData = spnTeensy(1,i);
    % Confirm spinner has Teensy data before parsing
    if(strcmpi(spnData.UserData,'Teensy Suite'));
        for j=1:spnData.Value
            processTeensy(baseNameNoExt);
        end
    end
end

tabAnimation2D(fig, tabgp);
tabAnimation3D(fig, tabgp);
%tabCustomPlots(fig, tabgp);

end
%% FUNC: chooseSubset - User-Chosen Start and End Parse Points
% Generate 4 base plots, user selects start and end points
% Start and End points saved to parseRangeUTC for parsing
% INPUT
% * GPS - raw GPS data, used for altitude and groundspeed data
% * RCOU - raw RCOU data, used for throttle output data (converted to %)
% * ATT - raw ATT data, used for state variables (degrees roll, pitch, etc)
% * IMU - raw IMU data, used for highest resolution timing data
% * BARO - raw BARO data, used for most accurate altitude data
% * CTUN - raw CTUN data (in varargin, optional), used for airspeed data
function chooseSubset(GPS, RCOU, ATT, IMU, BARO, varargin)

global figIter
global Figs
global parseRangeUTC

% Generate new figure window, iterate global to prevent overwrite
figIter = figIter+1;
Figs{figIter}=figure(figIter);
Figs{figIter}.Name = 'Raw data from DFL. Click on graph for upper and lower bound for parsing.';

% If no CTUN data (ArduCopter), fill with array of zeros
if(isempty(varargin))
    CTUN = [zeros(1000,2) linspace(IMU(1,3),IMU(end,4),1000)' zeros(1000,9)];
else
    CTUN = varargin{1};
end

% Initialize guess max and min throttle (accounts for max never achieved)
thrMinPWM = 1100;
thrMaxPWM = 1900;
thrPercent(:,1) = (RCOU(:,7)-thrMinPWM)/(thrMaxPWM-thrMinPWM)*100;

% Groundspeed and Airspeed plot
plt1 = subplot(4,1,1);
plot(GPS(:,3),GPS(:,13),'b',CTUN(:,3),CTUN(:,12),'r')
title('Groundspeed, Airspeed vs Time')
ylabel({'Groundspeed (blue)';'Airspeed (red)';'(m/s)'})

% Throttle Output
plt2 = subplot(4,1,2);
plot(RCOU(:,3),thrPercent(:,1),'b')
title('Throttle vs Time')
ylabel({'Throttle';'(%)'})
ylim([0 100])

% For the dotted line along x-axis zero point of pitch plot
zeroPitch=int8(zeros(length(ATT(:,3)),1));

% Aircraft Pitch angle: Can change ylim to something more relevant.
% TIV uses -20 to 50 to see high AoA landing
plt3 = subplot(4,1,3);
plot(ATT(:,3),ATT(:,8),'b',ATT(:,3),zeroPitch,'r:')
title('Aircraft Pitch Angle vs Time')
ylabel({'Aircraft Pitch';'Angle (°)'})
ylim([-10 40])

% Altitude plot (GPS, left side)
plt4 = subplot(4,1,4);
yyaxis left
plot(GPS(:,3),GPS(:,12),'b');
ylim([min(GPS(:,12))-25 max(GPS(:,12))+25])
ylabel({'GPS Altitude (blue)';'m MSL'})
title('Altitude vs Time')

% Altitude plot (BARO, right side)
yyaxis right
plot(BARO(:,3),BARO(:,5),'r')
ylim([min(BARO(:,5))-25 max(BARO(:,5))+25])
ylabel({'BARO Altitude (red)';'m AGL'})
xlabel('Time (seconds)')
linkaxes([plt1 plt2 plt3 plt4],'x')
xlim([min(GPS(:,3)) max(GPS(:,3))])

% Initialize parsing counter, max out at two (one start, one end)
m=0;
% Loop allowing user to select start and end points
while true
    % Grab horiz and vert information from plot, use as output for parsing
    % button tracks mouse clicks
    [horiz, vert, button] = ginput(1);
    % If user closes window with no data or only one data point, exit
    if isempty(horiz) || button(1) == 3; break; end
    % User clicked a valid entry, so iterate and continue
    m = m+1;
    % Save x value of data point clicked, use to find respective Y points
    x_m(m) = horiz(1);
    % Prevent plot updates until all locations are found
    hold on
    y_va(m)=CTUN(find(CTUN(:,3)>=x_m(m),1,'first'),12);     % Airspeed
    y_vg(m)=GPS(find(GPS(:,3)>=x_m(m),1,'first'),13);      % Groundspeed
    y_thr(m)=RCOU(find(RCOU(:,3)>=x_m(m),1,'first'),7);     % Throttle Percent
    y_pitch(m)=ATT(find(ATT(:,3)>=x_m(m),1,'first'),8); % Aircraft Pitch
    y_GPSalt(m)=GPS(find(GPS(:,3)>=x_m(m),1,'first'),12);    % GPS Altitude
    y_BAROalt(m)=BARO(find(BARO(:,3)>=x_m(m),1,'first'),5);    % BARO Altitude
    
    % Replot same base graphs, but update with X markers at chosen location
    % Groundspeed plot
    subplot(4,1,1)
    plot(GPS(:,3),GPS(:,13),'b',CTUN(:,3),CTUN(:,12),'r',x_m,y_vg,'kx',x_m,y_va,'kx')
    title('Groundspeed, Airspeed vs Time')
    ylabel({'Groundspeed (blue)';'Airspeed (red)';'(m/s)'})
    
    % Throttle Output
    subplot(4,1,2)
    plot(RCOU(:,3),thrPercent(:,1),'b',x_m, ((y_thr-thrMinPWM)/(thrMaxPWM-thrMinPWM)*100),'kx')
    title('Throttle vs Time')
    ylabel({'Throttle';'(%)'})
    ylim([0 100])
    
    % Aircraft Pitch angle: Can change ylim to something more relevant.
    % TIV uses -20 to 50 to see high AoA landing
    subplot(4,1,3)
    plot(ATT(:,3),ATT(:,8),'b',ATT(:,3),zeroPitch,'r:',x_m,y_pitch,'kx')
    title('Aircraft Pitch Angle vs Time')
    ylabel({'Aircraft Pitch';'Angle (°)'})
    ylim([-10 40])
    
    % Altitude plot (GPS, left side)
    plt4 = subplot(4,1,4);
    yyaxis left
    plot(GPS(:,3),GPS(:,12),'b',x_m,y_GPSalt,'kx');
    ylim([min(GPS(:,12))-25 max(GPS(:,12))+25])
    ylabel({'GPS Altitude (blue)';'m MSL'})
    title('Altitude vs Time')
    
    % Altitude plot (BARO, right side)
    yyaxis right
    plot(BARO(:,3),BARO(:,5),'r',x_m,y_BAROalt,'kx')
    ylim([min(BARO(:,5))-25 max(BARO(:,5))+25])
    ylabel({'BARO Altitude (red)';'m AGL'})
    xlabel('Time (seconds)')
    linkaxes([plt1 plt2 plt3 plt4],'x')
    xlim([min(GPS(:,3)) max(GPS(:,3))])
    
    % Update plots now that all locations are found
    drawnow
    
    % If both start and end are chosen, exit loop
    if(m>=2)
        break;
    end
    
end

% Create new figure to show only parsed data
figIter = figIter+1;
Figs{figIter}=figure(figIter);
Figs{figIter}.Name = 'Preview of user-parsed DFL data.';

% Recreate all plots using only parsed data
% Groundspeed plot
plt1 = subplot(4,1,1);
plot(GPS(:,3)-x_m(1),GPS(:,13),'b',CTUN(:,3)-x_m(1),CTUN(:,12),'r')
title('Groundspeed, Airspeed vs Time')
ylabel({'Groundspeed (blue)';'Airspeed (red)';'(m/s)'})

% Throttle Output
plt2 = subplot(4,1,2);
plot(RCOU(:,3)-x_m(1),thrPercent(:,1),'b')
title('Throttle vs Time')
ylabel({'Throttle';'(%)'})
ylim([0 100])

% Aircraft Pitch angle: Can change ylim to something more relevant.
% TIV uses -20 to 50 to see high AoA landing
plt3 = subplot(4,1,3);
plot(ATT(:,3)-x_m(1),ATT(:,8),'b',ATT(:,3)-x_m(1),zeroPitch,'r:')
title('Aircraft Pitch Angle vs Time')
ylabel({'Aircraft Pitch';'Angle (°)'})
ylim([-10 40])

% Altitude plot (GPS, left side)
plt4 = subplot(4,1,4);
yyaxis left
plot(GPS(:,3)-x_m(1),GPS(:,12),'b');
ylim([min(GPS(:,12))-25 max(GPS(:,12))+25])
ylabel({'GPS Altitude (blue)';'m MSL'})
title('Altitude vs Time')

% Altitude plot (BARO, right side)
yyaxis right
plot(BARO(:,3)-x_m(1),BARO(:,5),'r')
ylim([min(BARO(:,5))-25 max(BARO(:,5))+25])
ylabel({'BARO Altitude (red)';'m AGL'})
xlabel('Time (seconds)')
linkaxes([plt1 plt2 plt3 plt4],'x')
xlim([0 x_m(2)-x_m(1)])

% If starting data point is glitched, find first non-glitched point
checkLoc1 = find(IMU(:,3)>x_m(1),1,'first')-1;
while(IMU(checkLoc1+1,3)-IMU(checkLoc1,3)>=1)
    checkLoc1 = find(IMU(checkLoc1+5:end,3)>x_m(1),1,'first')-1;
end

% Save IMU-based DatenumUTC, TimeS, LineNo data (highest resolution)
parseRangeUTC(1,1)=IMU(checkLoc1,4); % Highest resolution DatenumUTC start
parseRangeUTC(1,3)=IMU(checkLoc1,3); % Highest resolution TimeS start
parseRangeUTC(1,5)=IMU(checkLoc1,1); % Highest resolution LineNo start

% If ending data point is glitched, find last non-glitched point
checkLoc2 = find(IMU(:,3)>x_m(2),1,'first')-1;
while(IMU(checkLoc2+1,3)-IMU(checkLoc2,3)>=1)
    checkLoc2 = find(IMU(checkLoc2+5:end,3)>x_m(2),1,'first')-1;
end

% Save IMU-based DatenumUTC, TimeS, LineNo data (highest resolution)
parseRangeUTC(1,2)=IMU(checkLoc2,4); % Highest resolution DatenumUTC end
parseRangeUTC(1,4)=IMU(checkLoc2,3); % Highest resolution TimeS end
parseRangeUTC(1,6)=IMU(checkLoc2,1); % Highest resolution LineNo end

end
%% FUNC: dataParsePix - Redact Variable Set by End Points
% Parse Pixhawk data based on parseRangeUTC start and end points
% INPUT
% * i - iteration in loop acted on, gives location in rawVars to grab data
function dataParsePix(i)

global parseRangeUTC
global parsedVars
global rawVars

% Grab and convert rawVar data into useful data for parsing
varName = rawVars{i,1};
varData = rawVars{i,2};
varFields(:,1) = rawVars{i,3};

% Finf effective start (TO) and end (LND) times based on time comparisons
TO = find(varData(:,1)>parseRangeUTC(5),1,'first');
LND = find(varData(:,1)>parseRangeUTC(6),1,'first');

% Parse all columns in data set by the row numbers generated above
varData = varData(TO:LND,:);

% Convert col3 (TimeS) into TimeSinceParse (seconds)
% Very useful metric for data plots
varData(:,3) = varData(:,3)-parseRangeUTC(1,3);
% Generate internally-referenced table (no Date or Time, just DatenumUTC)
varDataInternal = array2table(varData,'VariableNames',varFields);
parsedVars{i,1} = varName;
parsedVars{i,2} = varDataInternal;
parsedVars{i,3} = varFields;
varDataInternal.Properties.Description = strrep(varName,'_table','');

% For external table, generate discrete DateUTC and TimeUTC values
var_DateTime(:,1) = datetime(varData(:,4),'ConvertFrom','datenum');
TimeUTC(:,1) = datetime(var_DateTime,'Format','HH:mm:ss.SSS');
DateUTC(:,1) = datetime(var_DateTime,'Format','MMM-dd-yyy');

% Save table with discrete DateUTC and TimeUTC for user view
varDataExternal = removevars(varDataInternal,{'DatenumUTC'});
varDataExternal = addvars(varDataExternal,DateUTC,TimeUTC,'After','TimeS');

% Send external version to user workspace
assignin('base',varName,varDataExternal);

end
%% FUNC: iMetRead - Read and Parse Data From iMet XQ and XQ2 Sensors
% Parse Based On Pixhawk DatenumUTC Start/Stop Points
% For multiple iMet runs, output names will iterate (1, 2, 3, etc.)
% INPUT
% * baseNameNoExt - Pix base file name with no extension or filepath details
function iMetRead(baseNameNoExt)

global parsedIMET
global Figs
global figIter
global parsedVars
global parseRangeUTC
global iMetNumber

% Iterate iMet number with each iMet parsing call
iMetNumber=iMetNumber+1;

% Find location of IMU data for highest resolution DatenumUTC time
for j=1:length(parsedVars)
    if(strcmpi('IMU_table',char(parsedVars{j,1})))
        loc=j;
        break
    end
end

% Generate array of IMU data from parsedVars table
IMU_arr = table2array(parsedVars{loc,2});

% Load iMet data
[baseNameNoExtiMet, baseFileNameiMet, folderiMet,...
    fullInputMatFileNameiMet] = file2open('.csv','Select an iMet .CSV file');

% Turn off non-ctritical warning, as this is tested to be stable
warning('off','MATLAB:textio:io:UnableToGuessFormat');
warning('off','MATLAB:table:ModifiedAndSavedVarnames');
% Read iMet data and store to table
iMetData_temp = readtable(fullInputMatFileNameiMet);
% Remove first row of data, sometimes has headers present
iMetData = iMetData_temp(2:end,:);
% Turn warnings back on
warning('on','MATLAB:table:ModifiedAndSavedVarnames');
warning('on','MATLAB:textio:io:UnableToGuessFormat');
% Find length of dataset
dataLen = width(iMetData);

% Convert table data to datetime array
iMet_date_ref = iMetData.XQ_iMet_XQDate;
iMet_date = datetime(iMet_date_ref,'InputFormat','yyyy/MM/dd','Format','MMM-dd-yyyy');
iMet_time_ref = iMetData.XQ_iMet_XQTime;
iMet_time = datetime(datevec(iMet_time_ref),'Format','HH:mm:ss');

% Convert datetime arrays into datetime vectors
[iM_y, iM_m, iM_d] = datevec(iMet_date(:,1));
[ no, no, no,iM_h, iM_M, iM_s] = datevec(iMet_time);
iM_vec = [iM_y iM_m iM_d iM_h iM_M iM_s];

% Convert datetime vectorsm to datetime serials
iMet_serial = datenum(iM_vec);

% Find iMet data at start and end of Pixhawk parsing
TO_iMet = find(iMet_serial(:)>=parseRangeUTC(1),1,'first');
LND_iMet = find(iMet_serial(:)>=parseRangeUTC(2),1,'first')-1;

% Parse iMet data based on the above conditions
iMet_serial = iMet_serial(TO_iMet:LND_iMet);

% Generate Pixhawk time since arming using IMU data for comparison
for i=1:length(iMet_serial)
    iM_Pix(i,1)=IMU_arr(find(IMU_arr(:,4)>=iMet_serial(i),1,'first'),3);
end

% Vectorize the parsing of all iMet data, store in variables
i=TO_iMet:LND_iMet;
iM_time(:,1) = iMet_time(i,1);
iM_date(:,1) = iMet_date(i,1);
iM_pres(:,1) = iMetData.XQ_iMet_XQPressure(i,1);
iM_temp(:,1) = iMetData.XQ_iMet_XQAirTemperature(i,1);
iM_humid(:,1) = iMetData.XQ_iMet_XQHumidity(i,1);
iM_lat(:,1) = iMetData.XQ_iMet_XQLatitude(i,1);
iM_long(:,1) = iMetData.XQ_iMet_XQLongitude(i,1);
iM_alt(:,1) = iMetData.XQ_iMet_XQAltitude(i,1);
iM_sat(:,1) = iMetData.XQ_iMet_XQSatCount(i,1);

% Generate user-sided output table, which has DateUTC and TimeUTC data
iMet_tableExternal = table(iM_date, iM_time, iM_Pix, iM_pres, iM_temp, iM_humid,...
    iM_lat, iM_long, iM_alt, iM_sat,'VariableNames',{'DateUTC','TimeUTC',...
    'Time from Parsing (sec)','Barometric Pressure (hPa)','Air Temp (°C)',...
    'Relative Humidity (%)','GPS Lat','GPS Long','GPS Alt (m)','Sat Count'});
iMet_tableExternal.Properties.Description = sprintf('iMet%d',iMetNumber);
% Send external table to user worksapce, iterate number
assignin('base',sprintf('iMet%d',iMetNumber),iMet_tableExternal);

% Generate seperate internal table with DatenumUTC instead
iMet_tableInternal = table(iMet_serial, iM_Pix, iM_pres, iM_temp, iM_humid,...
    iM_lat, iM_long, iM_alt, iM_sat,'VariableNames',{'DatenumUTC',...
    'Time from Parsing (sec)','Barometric Pressure (hPa)','Air Temp (°C)',...
    'Relative Humidity (%)','GPS Lat','GPS Long','GPS Alt (m)','Sat Count'});
iMet_tableInternal.Properties.Description = sprintf('iMet%d',iMetNumber);
% Save data to global parsedIMET for internal referencing
parsedIMET{iMetNumber,1} = iMet_tableInternal.Properties.Description;
parsedIMET{iMetNumber,2} = iMet_tableInternal;
parsedIMET{iMetNumber,3} = iMet_tableInternal.Properties.VariableNames;

% Create new figure, iterate number to prevent overwriting
figIter = figIter+1;
Figs{figIter}=figure(figIter);
Figs{figIter}.Name = sprintf('Parsed iMet%d data.',iMetNumber);
% Prevent autoUpdate of axis bounds
set(Figs{figIter},'defaultLegendAutoUpdate','off');

%Plot Temp and Humidity on left axis
yyaxis left
plt = plot(iM_Pix(:), iM_temp(:),'y-',iM_Pix(:),iM_humid,'c-');
title('Temp, Humidity, and Pressure vs Time')
xlabel('Time (ms)');
ylabel('Temp (°C) and Humidity (%)');
% Plot barometric pressure on right axis
yyaxis right
plt = plot(iM_Pix(:), iM_pres(:),'k-');
ylabel('Pressure (hPa)');
legend({'iMet Temp','iMet Humid','iMet Pres'},'Location','southeast')

% Save external (user-sided) iMet data to external file
table2saveCSV(baseNameNoExt, folderiMet, iMet_tableExternal)

end
%% FUNC: processTeensy - Read Teensy data, determine which datasets exist
% Determine which of MultiHoleProbe or TPH suite exists
% INPUT
% * baseNameNoExt - Pix base file name with no extension or filepath details
function processTeensy(baseNameNoExt)
global MHPNumber
global TPHNumber
global TeensyNumber
global parsedTeensy

% Get the name of the file that the user wants to use.
[baseNameNoExtTeensy, ~, folderTeensy, fullInputMatFileNameTeensy]...
    = file2open('*.csv','Select a Teensy Suite .CSV file');
% Read data in as matri=x
data = readmatrix(fullInputMatFileNameTeensy);
% Convert all NaN to -1
data(isnan(data)) = -1;

% Check if MHP data exists
if(max(data(:,4))>0)
    % If data exists, iterate MHP number (in case more than one is used)
    MHPNumber = MHPNumber+1;
    outputMHP = processMHP(data, folderTeensy, baseNameNoExt);
else
    % If no data exists, output as empt
    outputMHP = [];
end

% Check if TPH data exists
if(max(data(:,15))>0)
    % If data exists, iterate TPH number (in case more than one is used)
    TPHNumber=TPHNumber+1;
    outputTPH = processTPH(data, folderTeensy, baseNameNoExt);
else
    % If no data exists, output as empt
    outputTPH = [];
end

% Iterate Teensy call number, in case mixed sets are used
TeensyNumber=TeensyNumber+1;

% Save data according to Teensy call number
% Preserves all Teensy-specific data even if some entries are empty
parsedTeensy{TeensyNumber,1} = baseNameNoExtTeensy;
parsedTeensy{TeensyNumber,2} = outputMHP;
parsedTeensy{TeensyNumber,3} = outputTPH;

end
%% FUNC: processMHP - Parse and process MHP data
% Parse MHP data based on parseRangeUTC data from Pixhawk
% Output external table (DateUTC, TimeUTC) to user workspace
% Preseve internal table (DatenumUTC) for other uses
% INPUT
% * data - Teensy full dataset
% * folder - folder containing raw Teensy data
% * baseNameNoExt - Pix base file name with no extension or filepath details
% OUTPUT
% * outputMHP - Internal version of resulting table (DatenumUTC)
function outputMHP = processMHP(data, folder, baseNameNoExt)

global parsedVars
global parseRangeUTC
global MHPNumber

% Generate list of probes with calibrations for user to choose
list = {'Probe 1', 'Probe 2', 'Probe 3', 'Metal Probe'};
[Probe, tf] = listdlg('ListString', list, 'SelectionMode','single');

% Depending on probe chosen, use that calibration data
% Will up upgraded to a file search instead of hardcode
if Probe==1
    %%
    Probe_matrix =reshape([-45 5.4503245929122812 -40 3.6344070134585587 ...
        -35 2.6910078916419944 -30 2.0741227786203615 ...
        -25 1.6177891317119037 -20 1.3047139241276557 ...
        -15 0.99765981580647944 -10 0.72488341948754176 ...
        -5 0.42287858693961322 0 0.11269996848776841 5 ...
        -0.18844278909812986 10 -0.51552305940602694 15 ...
        -0.82527532291594985 20 -1.0827862740935248 25 ...
        -1.3747195966697383 30 -1.7399669009211871 35 ...
        -2.2261994229329716 40 -2.83647895638291 45 -3.7775455967008882 ...
        -45 5.6088602743478519 -40 3.8471216439542708 ...
        -35 2.758014522232052 -30 2.1393612470974079 -25 ...
        1.6846516032825758 -20 1.2812487641404717 -15 ...
        0.99769242818437875 -10 0.7108466648491224 -5 ...
        0.39522993924508154 0 0.055666210297281971 5 -0.26040468531481231 ...
        10 -0.60604077802968226 15 -0.91007141723872353 ...
        20 -1.2115256139194885 25 -1.5914907297890892 ...
        30 -2.0768170988494874 35 -2.7082025856213936 ...
        40 -3.6672797432896682 45 -5.11308906747139 -45 ...
        0.40153363672050385 -40 0.58252778411973083 -35 ...
        0.76207165540900135 -30 0.91124757982052851 -25 ...
        1.0297461281014839 -20 1.1162791106122567 -15 ...
        1.1602402228108957 -10 1.1682637817844033 -5 1.1717460580991859 ...
        0 1.1705980442512705 5 1.1742807474113173 10 1.1750681375621821 ...
        15 1.1761267609636077 20 1.1541350590812145 25 ...
        1.0909288620176854 30 0.99477056787113616 35 0.8677013434826869 ...
        40 0.71724821586753418 45 0.55890366509478218 ...
        -45 0.45693864133494283 -40 0.63502634767094046 ...
        -35 0.81900446405055538 -30 0.98505044428739341 ...
        -25 1.0967311790193095 -20 1.1760591378284164 ...
        -15 1.2105339434476543 -10 1.225378332775521 -5 ...
        1.2208141810618345 0 1.2167930824763777 5 1.213004218757056 ...
        10 1.202293865820901 15 1.1664968024605715 20 ...
        1.1003915504970527 25 0.99694948648152915 30 0.86274285528505079 ...
        35 0.70827366374370193 40 0.5425004640691633 45 ...
        0.3714015525546091], 2, 19, 4);
    %%
end
if Probe==2
    %%
    Probe_matrix= reshape([-45 8.0413125757286483 -40 4.595840988208745 -35 ...
        3.1960983613503395 -30 2.3438686451680391 -25 ...
        1.7998009251294775 -20 1.3568843785915969 -15 ...
        1.0417025439286454 -10 0.6719271337912911 -5 0.31594859127806313 ...
        0 -0.027775383920766113 5 -0.38525870149950231 ...
        10 -0.76967960249393741 15 -1.0870073516266328 ...
        20 -1.378333118288662 25 -1.7338076966226417 30 ...
        -2.1416605956464423 35 -2.672348394280156 40 -3.4957062360550872 ...
        45 -4.9947263023335022 -45 5.4644672199708184 ...
        -40 3.7051459239570832 -35 2.7802502582437754 ...
        -30 2.1909163813094055 -25 1.745552975533075 -20 ...
        1.3193857267226774 -15 0.989568212585923 -10 0.68976185302006032 ...
        -5 0.34537219692610427 0 0.00070104058184836159 ...
        5 -0.35188215190568023 10 -0.70334097827774844 ...
        15 -1.0151026074394103 20 -1.3372013554379576 ...
        25 -1.7119408626720383 30 -2.1780237220699625 ...
        35 -2.7495578563807559 40 -3.577709672348806 45 ...
        -4.9039267737627332 -45 0.27126131923904334 -40 ...
        0.438829235484768 -35 0.6069713454411777 -30 0.76007586890568246 ...
        -25 0.8757553537646996 -20 0.97230935336276991 ...
        -15 1.0163124604875853 -10 1.0494565940075169 ...
        -5 1.0440081543412782 0 1.0521140361945402 5 1.0617346368847278 ...
        10 1.0640740038270755 15 1.0530416652892758 20 ...
        1.0150305427048212 25 0.93933046605058423 30 0.84632064730305567 ...
        35 0.71412230618293648 40 0.56257867097066894 ...
        45 0.4088708445506693 -45 0.40039661393475073 ...
        -40 0.56253456955569414 -35 0.71741173034906691 ...
        -30 0.83895154863814991 -25 0.945508433447679 ...
        -20 1.048989338380182 -15 1.1079676863677939 -10 ...
        1.1217507631454158 -5 1.1213365893922569 0 1.1102349448662681 ...
        5 1.1103023687637184 10 1.0907471029595337 15 ...
        1.0731456995653772 20 1.0326480971143717 25 0.96008313343852325 ...
        30 0.85664753210489064 35 0.74804723263594852 ...
        40 0.60691269332640829 45 0.47048729685494273], 2, 19, 4);
    %%
end
if Probe==3
    %%
    Probe_matrix= reshape([-45 8.0413125757286483 -40 4.595840988208745 -35 ...
        3.1960983613503395 -30 2.3438686451680391 -25 ...
        1.7998009251294775 -20 1.3568843785915969 -15 ...
        1.0417025439286454 -10 0.6719271337912911 -5 0.31594859127806313 ...
        0 -0.027775383920766113 5 -0.38525870149950231 ...
        10 -0.76967960249393741 15 -1.0870073516266328 ...
        20 -1.378333118288662 25 -1.7338076966226417 30 ...
        -2.1416605956464423 35 -2.672348394280156 40 -3.4957062360550872 ...
        45 -4.9947263023335022 -45 5.4644672199708184 ...
        -40 3.7051459239570832 -35 2.7802502582437754 ...
        -30 2.1909163813094055 -25 1.745552975533075 -20 ...
        1.3193857267226774 -15 0.989568212585923 -10 0.68976185302006032 ...
        -5 0.34537219692610427 0 0.00070104058184836159 ...
        5 -0.35188215190568023 10 -0.70334097827774844 ...
        15 -1.0151026074394103 20 -1.3372013554379576 ...
        25 -1.7119408626720383 30 -2.1780237220699625 ...
        35 -2.7495578563807559 40 -3.577709672348806 45 ...
        -4.9039267737627332 -45 0.27126131923904334 -40 ...
        0.438829235484768 -35 0.6069713454411777 -30 0.76007586890568246 ...
        -25 0.8757553537646996 -20 0.97230935336276991 ...
        -15 1.0163124604875853 -10 1.0494565940075169 ...
        -5 1.0440081543412782 0 1.0521140361945402 5 1.0617346368847278 ...
        10 1.0640740038270755 15 1.0530416652892758 20 ...
        1.0150305427048212 25 0.93933046605058423 30 0.84632064730305567 ...
        35 0.71412230618293648 40 0.56257867097066894 ...
        45 0.4088708445506693 -45 0.40039661393475073 ...
        -40 0.56253456955569414 -35 0.71741173034906691 ...
        -30 0.83895154863814991 -25 0.945508433447679 ...
        -20 1.048989338380182 -15 1.1079676863677939 -10 ...
        1.1217507631454158 -5 1.1213365893922569 0 1.1102349448662681 ...
        5 1.1103023687637184 10 1.0907471029595337 15 ...
        1.0731456995653772 20 1.0326480971143717 25 0.96008313343852325 ...
        30 0.85664753210489064 35 0.74804723263594852 ...
        40 0.60691269332640829 45 0.47048729685494273], 2, 19, 4);
    %%
end
if Probe==4
    %%
    Probe_matrix=reshape([-45 6.8270286994312324 -40 3.9272264704959947 ...
        -35 2.7098630146680343 -30 2.0311527134073506 ...
        -25 1.5648399326122149 -20 1.2097555239893774 ...
        -15 0.99401689018022032 -10 0.7109304970157786 ...
        -5 0.39798725583059297 0 0.10610929666786524 5 ...
        -0.16157327211291675 10 -0.45721492832552874 15 ...
        -0.73051006787347961 20 -1.0206346484460449 25 ...
        -1.3758360236897476 30 -1.7831603701441343 35 ...
        -2.377357311604094 40 -3.464604213809888 45 -5.902768693651109 ...
        -45 7.4133939397891409 -40 4.1198674730828735 ...
        -35 2.7770897996831905 -30 2.0145359604997175 ...
        -25 1.5078827091567195 -20 1.1318223410844281 ...
        -15 0.86433128769217948 -10 0.5558516056739059 ...
        -5 0.26359452098651637 0 -0.028656763433599269 ...
        5 -0.34839374505470783 10 -0.65948481869867559 ...
        15 -0.96825549560038959 20 -1.3025459837101847 ...
        25 -1.7237901125815069 30 -2.2978387224876857 ...
        35 -3.2329872283805456 40 -5.1776511809601873 ...
        45 -13.031656173662968 -45 0.32254048615943415 ...
        -40 0.52205954626286333 -35 0.68966672023071152 ...
        -30 0.831269693794436 -25 0.9490842976748094 -20 ...
        1.0427975635210041 -15 1.0930205988684738 -10 ...
        1.1249929311810012 -5 1.1393737524485081 0 1.1365874970433751 ...
        5 1.1398409797574214 10 1.1325220268485772 15 ...
        1.1008008398450571 20 1.0435222498791885 25 0.96164376880806623 ...
        30 0.84143329041748371 35 0.69288464852455156 ...
        40 0.52373434130229513 45 0.32906938976100375 ...
        -45 0.290471428675032 -40 0.50325598712500985 ...
        -35 0.68854268208577729 -30 0.84765291448530922 ...
        -25 0.97823914779086751 -20 1.0667329519213851 ...
        -15 1.1137584193430363 -10 1.1390572418989386 ...
        -5 1.1394729063509146 0 1.1372390682609228 5 1.1429838322264543 ...
        10 1.1285412771221324 15 1.0857994109712712 20 ...
        1.0227196623145753 25 0.90281324987619327 30 0.75359921806475 ...
        35 0.5861378670636509 40 0.38887273357229107 45 ...
        0.15966154155110446], 2, 19, 4);
    %%
end

% Get number of Rows and Columns of the data
nrows = length(data(:,1));
ncols = length(data(1,:));

% Air desnity, pre-set for now but will be calc'ed from TPH data
rho=1.197; % kg/m3

% Find location of IMU, CTUN, GPS, and NKF1 tables (all required)
for j=1:length(parsedVars)
    if(strcmpi('IMU_table',char(parsedVars{j,1})))
        locIMU=j;
    end
    if(strcmpi('CTUN_table',char(parsedVars{j,1})))
        locCTUN=j;
    end
    if(strcmpi('GPS_table',char(parsedVars{j,1})))
        locGPS=j;
    end
    if(strcmpi('NKF1_table',char(parsedVars{j,1})))
        locNKF1=j;
    end
    if(strcmpi('XKF1_table',char(parsedVars{j,1})))
        locNKF1=j;
    end
end

% Convert the parsedVars tables to arrays
IMU = table2array(parsedVars{locIMU,2});
CTUN = table2array(parsedVars{locCTUN,2});
GPS = table2array(parsedVars{locGPS,2});
NKF1 = table2array(parsedVars{locNKF1,2});

% Convert rawData into arrays of relevant data
time = data(:,1);
PitotB1 = data(:,2);
PitotB2 = data(:,3);
AlphaB1 = data(:,6);
AlphaB2 = data(:,7);
BetaB1 = data(:,10);
BetaB2 = data(:,11);
UnixT = data(:,26);
PixT = data(:,27);

% Backfill Pixhawk BOOT and UNIX times via linear interpolation
filledPixT(:,1)=timeInterpolation(time(:,1),PixT(:,1));
filledUnixT(:,1)=timeInterpolation(time(:,1),UnixT(:,1));

% Convert MHP data to Alpha, Beta, and Pitot base values
PitotCount = ((PitotB1*256)+PitotB2);
AlphaCount =  ((AlphaB1*256)+AlphaB2);
BetaCount  =  ((BetaB1*256)+BetaB2);

% Convert base values to pressure values (psi)
Pitot_psi=((PitotCount-1638)*(1+1))/(14745-1638)-1;
Alpha_psi=((AlphaCount-1638)*(1+1))/(14745-1638)-1;
Beta_psi=((BetaCount-1638)*(1+1))/(14745-1638)-1;

% Convert psi pressure values to Pascals
Pitot_pa=Pitot_psi*6894.74;
Alpha_pa=Alpha_psi*6894.74;
Beta_pa=Beta_psi*6894.74;

% Calcualte Cp of Alpha and Beta
CP_a=Alpha_pa./Pitot_pa;
CP_b=Beta_pa./Pitot_pa;

% Calculate Alpha and Beta probe values
% Just doing 1D interp for now until more speeds ran
Alpha=interp1(Probe_matrix(2,:,1), Probe_matrix(1,:,1),...
    CP_a(:), 'linear', 45);
Beta=interp1(Probe_matrix(2,:,2), Probe_matrix(1,:,2),...
    CP_b(:), 'linear', 45);

% Calculate CP across the entire probe range for Alpha and Beta
CP_pitot1 = interp1(Probe_matrix(1,:,4),...
    Probe_matrix(2,:,4), Beta(:), 'makima', .5);
CP_pitot2 = interp1(Probe_matrix(1,:,3),...
    Probe_matrix(2,:,3), Alpha(:),'makima', .5);

% Determine which CP is greater, use lower value
for i=1:nrows
    
    if CP_pitot1(i) > CP_pitot2(i)
        CP_pitot = CP_pitot2(i);
    else
        CP_pitot = CP_pitot1(i);
    end
    
    % User lower value to generate freestream velocity
    U(i) = ((2/rho)*(abs(Pitot_pa(i)/CP_pitot))) .^.5;
    
end

% Generate 3D velocity vector
u = U'.*cosd(Alpha).*cosd(Beta);
v = U'.*sind(Beta);
w = U'.*sind(Alpha).*cosd(Beta);
% Generate total velocity from 3D vector
total = sqrt(abs(u).^2 + abs(v).^2 + abs(2).^2);

% Add all relevant data to MHPData matrix
MHPData(:,1)=time;        % Sensor board time
MHPData(:,2)=filledPixT;  % Pix board time
MHPData(:,3)=filledUnixT; % Pix Unix Time (GPS)
MHPData(:,4)=u;           % probe u velocity
MHPData(:,5)=v;           % probe v velocity
MHPData(:,6)=w;           % probe w velocity
MHPData(:,7)=Alpha;       % alpha angle of the probe
MHPData(:,8)=Beta;        % beta angle of the probe
MHPData(:,9)=total;       % calculated total velocity of the probe (body frame)

% Cut out trailing data that wasnt interpolated
MHPData(isnan(MHPData(:,3)),:)=[];

% Generate DateUTC and TimeUTC datasets for user view
MHP_DateTime=datetime(MHPData(:,3),...
    'ConvertFrom','posixTime','Format','MMM-dd-yyyy HH:mm:ss.S');
MHP_Date=datestr(MHP_DateTime,'mmm-dd-yyyy');
MHP_Time=datestr(MHP_DateTime,'HH:MM:SS.FFF');

% Generate DatenumUTC for internal use
datenumMHP = datenum(MHP_DateTime);

% Find MHP start time from Pixhawk parse
if (min(datenumMHP) < parseRangeUTC(1,1))
    TO_MHP = find(datenumMHP(:)>=parseRangeUTC(1,1),1,'first');
else
    TO_MHP = 1;
end

% Find MHP end time from Pixhawk parse
if (max(datenumMHP) > parseRangeUTC(1,2))
    LND_MHP = find(datenumMHP(:)>=parseRangeUTC(1,2),1,'first');
else
    LND_MHP = length(datenumMHP);
end

% Parse all MHP data based on Pixhawk parsing
MHP_entry = MHPData(TO_MHP:LND_MHP,:);
MHP_Date = MHP_Date(TO_MHP:LND_MHP,:);
MHP_Time = MHP_Time(TO_MHP:LND_MHP,:);
MHP_time_out = (MHP_entry(:,1)-min(MHP_entry(:,1)))/1000;
datenumMHP = datenumMHP(TO_MHP:LND_MHP,:);

% Create external table for user view
MHP_tableExternal = table(MHP_entry(:,1),MHP_entry(:,2),MHP_time_out,...
    MHP_Date, MHP_Time,MHP_entry(:,4),MHP_entry(:,5),...
    MHP_entry(:,6),MHP_entry(:,7),MHP_entry(:,8),MHP_entry(:,9),...
    'VariableNames', {'Board Time from PowerUp (msec)',...
    'Pix Time from PowerUp (msec)','Pix time from parse',...
    'DateUTC','TimeUTC','U (m/s)','V (m/s)','W (m/s)',...
    'Alpha(deg)','Beta(deg)','Total Velocity (m/s)'} );
MHP_tableExternal.Properties.Description = sprintf('MHP%d',MHPNumber);
% Output table to user workspace
assignin('base',sprintf('MHP_table%d',MHPNumber),MHP_tableExternal);
% Save tabele for user review
table2saveCSV(baseNameNoExt, folder, MHP_tableExternal)

% Generate internal-use table that uses DatenumUTC
MHP_tableInternal = table(MHP_entry(:,1),MHP_entry(:,2),MHP_time_out,...
    datenumMHP(:,1),MHP_entry(:,4),MHP_entry(:,5),...
    MHP_entry(:,6),MHP_entry(:,7),MHP_entry(:,8),MHP_entry(:,9),...
    'VariableNames', {'Board Time from PowerUp (msec)',...
    'Pix Time from PowerUp (msec)','Pix time from parse',...
    'DatenumUTC','U (m/s)','V (m/s)','W (m/s)',...
    'Alpha(deg)','Beta(deg)','Total Velocity (m/s)'} );
MHP_tableInternal.Properties.Description = sprintf('MHP%d',MHPNumber);
% Ouput internally-used table
outputMHP = MHP_tableInternal;

% Ask user if extended analysis is required
answer = questdlg('Execute extended analysis on MHP data?', ...
    'Extended MHP Analysis', ...
    'Yes','No','Yes');
% Execute or dismiss based on response
switch answer
    case 'Yes'
        MHP = table2array(MHP_tableInternal);
        analysisMHP(MHP, NKF1, IMU, GPS);
        warning('MHP Analysis data currently not saved.');
    case 'No'
end

end
%% FUNC: processTPH - Parse and process TPH data
% Parse TPH data based on parseRangeUTC data from Pixhawk
% Output external table (DateUTC, TimeUTC) to user workspace
% Preseve internal table (DatenumUTC) for other uses
% INPUT
% * data - Teensy full dataset
% * folder - folder containing raw Teensy data
% * baseNameNoExt - Pix base file name with no extension or filepath details
% OUTPUT
% * outputTPH - Internal version of resulting table (DatenumUTC)
function outputTPH = processTPH(data,folder,baseNameNoExt)

global parseRangeUTC
global TPHNumber

% Get number of Rows and Columns of the data
nrows = length(data(:,1));
ncols = length(data(1,:));

% Air desnity, pre-set for now but will be calc'ed from TPH data
rho=1.197; % kg/m3

% Backfill Pixhawk BOOT and UNIX times via linear interpolation
filledPixT(:,1)=timeInterpolation(data(:,1),data(:,27));
filledUnixT(:,1)=timeInterpolation(data(:,1),data(:,26));

SScount=0;
for i=1:nrows
    Temp = data(i,16);
    
    if(Temp~=-1)
        SScount=SScount+1;
        THSense(SScount,1)=data(i,1);      % Sensor board time
        THSense(SScount,2)=filledPixT(i);  % Pixhawk board time
        THSense(SScount,3)=filledUnixT(i); % Pixhawk Unix Time (GPS)
        THSense(SScount,4)=data(i,16);     % Temp 1
        THSense(SScount,5)=data(i,20);     % Temp 2
        THSense(SScount,6)=data(i,24);     % Temp 3
        THSense(SScount,7)=data(i,15);     % Humidity 1
        THSense(SScount,8)=data(i,19);     % Humidity 2
        THSense(SScount,9)=data(i,23);     % Humidity 3
    end
end

% Cut out trailing data that wasnt interpolated
THSense(isnan(THSense(:,3)),:)=[];

% Generate DateUTC and TimeUTC for user view
TH_DateTime=datetime(THSense(:,3),'ConvertFrom',...
    'posixTime','Format','MMM-dd-yyyy HH:mm:ss.S');
TH_Date=datestr(TH_DateTime,'mmm-dd-yyyy');
TH_Time=datestr(TH_DateTime,'HH:MM:SS.FFF');

% Generate DatenumUTC for parsing and internal use
datenumTH = datenum(TH_DateTime);

% Find TPH start time from Pixhawk parsing
if (min(datenumTH) < parseRangeUTC(1,1))
    TO_TPH = find(datenumTH(:)>=parseRangeUTC(1,1),1,'first');
else
    TO_TPH = 1;
end

% Find TPH end time from Pixhawk parsing
if (max(datenumTH) > parseRangeUTC(1,2))
    LND_TPH = find(datenumTH(:)>=parseRangeUTC(1,2),1,'first');
else
    LND_TPH = length(datenumTH);
end

% Parse TPH data set based on above start/stop times
TPH_entry = THSense(TO_TPH:LND_TPH,:);
TH_Date = TH_Date(TO_TPH:LND_TPH,:);
TH_Time = TH_Time(TO_TPH:LND_TPH,:);
TPH_time_out = (TPH_entry(:,1)-min(TPH_entry(:,1)))/1000;
datenumTH = datenumTH(TO_TPH:LND_TPH,:);

% Create external tables for user view
TPH_tableExternal = table(TPH_entry(:,1),TPH_entry(:,2),...
    TPH_time_out,TH_Date, TH_Time,...
    TPH_entry(:,4),TPH_entry(:,5),TPH_entry(:,6),...
    TPH_entry(:,7),TPH_entry(:,8),TPH_entry(:,9), 'VariableNames'...
    , {'Board Time from PowerUp (msec)',...
    'Pixhawk Time from PowerUp (msec)',...
    'Pix Time from parse','DateUTC','TimeUTC',...
    'Temp 1 (°C)','Temp 2 (°C)','Temp 3 (°C)',...
    'Humidity 1 (%)','Humidity 2 (%)','Humidity 3 (%)'} );
TPH_tableExternal.Properties.Description = sprintf('TPH%d',TPHNumber);
% Send external table to user workspace
assignin('base',sprintf('TPH_table%d',TPHNumber),TPH_tableExternal);
% Save external table for user view
table2saveCSV(baseNameNoExt, folder, TPH_tableExternal)

% Generate internal-use table that uses DatenumUTC
TPH_tableInternal = table(TPH_entry(:,1),TPH_entry(:,2),...
    TPH_time_out,datenumTH(:,1),...
    TPH_entry(:,4),TPH_entry(:,5),TPH_entry(:,6),...
    TPH_entry(:,7),TPH_entry(:,8),TPH_entry(:,9), 'VariableNames'...
    , {'Board Time from PowerUp (msec)',...
    'Pixhawk Time from PowerUp (msec)',...
    'Pix Time from parse','DatenumUTC',...
    'Temp 1 (°C)','Temp 2 (°C)','Temp 3 (°C)',...
    'Humidity 1 (%)','Humidity 2 (%)','Humidity 3 (%)'} );
TPH_tableInternal.Properties.Description = sprintf('TPH%d',TPHNumber);
% Ouput internal-use table
outputTPH = TPH_tableInternal;

end
%% FUNC: analysisMHP - MHP Estimation and Statistical Analysis
% Further analysis on MHP data using accepted methods
% INPUT
% * MHP - MHP data from processMHP (internal table)
% * NKF1 - Parsed Pixhawk Kalman Filter data
% * IMU - Parsed Pixhawk IMU data
% * GPS - Parsed Pixhawk GPS data
% OUTPUT
% * None currently
function analysisMHP(MHP, NKF1, IMU, GPS)

global figIter
global Figs

% Generate rounded average time steps for MHP data
fs_avgmhp = round(length(MHP(:,3))/MHP(end,3));
% Execute Kolmogorov -5/3 law comparison
[freq, psdx] = kolmogorov(MHP(:,10),fs_avgmhp);

% Removal of aircraft velocities from 5hp data (no removal of rotational velocities)
% Roll, Pitch, Yaw (degrees)
bDATA = [NKF1(:,5),NKF1(:,6),NKF1(:,7)];

% Aircraft Velocity Vectors [U_ac, V_ac, W_ac] from GPS/Filter data
% VN, VE, VD (will need to be rotated into body frame)
gDATA = [NKF1(:,8), NKF1(:,9), NKF1(:,10)];

% data fusion for 5hp data and pixhawk velocities
% Pixhawk Kalman Filter Runs at ~25hz (not formated to run yet)
for i = 1:length(NKF1(:,3))
    NKF1_5HP(i,1) = find(NKF1(i,3)>=MHP(:,3),1,'last');
    NKF1_IMU(i,1) = find(NKF1(i,3)>=IMU(:,3),1,'last');
end

% Redefine components from MHP dataset
ProbeSpeed = MHP(:,10);
Alpha = MHP(:,8);
Beta = MHP(:,9);

%Windowing of data for fusion
for i = 1:length(NKF1(:,3))-1
    % Average multi hole probe speed
    avgMHP(i,1) = mean(ProbeSpeed(NKF1_5HP(i,1):NKF1_5HP(i+1,1)));
    % Average probe alpha
    avgMHP(i,2) = mean(Alpha(NKF1_5HP(i,1):NKF1_5HP(i+1,1)));
    % Average probe Beta
    avgMHP(i,3) = mean(Beta(NKF1_5HP(i,1):NKF1_5HP(i+1,1)));
    % Take MHP board time
    avgMHPBoardTime(i,1) = MHP(NKF1_5HP(i,1),3);
    % Take Pixhawk board time
    avgIMU(i,1) = IMU(NKF1_IMU(i,1),3);
    % Average IMU gyro x
    avgIMU(i,2) = mean(IMU((NKF1_IMU(i,1):NKF1_IMU(i+1,1)),5));
    % Average IMU gyro y
    avgIMU(i,3) = mean(IMU((NKF1_IMU(i,1):NKF1_IMU(i+1,1)),6));
    % Average IMU gyro z
    avgIMU(i,4) = mean(IMU((NKF1_IMU(i,1):NKF1_IMU(i+1,1)),7));
end

% Reduce Probespeed dataset to match above sets
avgMHP(length(NKF1(:,3)),1) = ProbeSpeed(length(NKF1(:,3)),1);
avgMHPBoardTime(length(NKF1(:,3)),1) = avgMHPBoardTime(i,1);
avgIMU(length(NKF1(:,3)),1) = avgIMU(i,1);

% Gyro rate data from Pixhawk IMU
% RollRate, PitchRate, YawRate
rDATA = [avgIMU(:,2),avgIMU(:,3), avgIMU(:,4)];

% Ask user which aircraft ran the MHP flight
answer = questdlg('Which aircraft flew this dataset?', ...
    'Aircraft Selection', ...
    'Nimbus','NanoTalon','Nimbus');
% Determine length of probe from center based on aircraft selection
switch answer
    case 'Nimbus'
        L = .40; % Nimbus
    case 'NanoTalon'
        L = .23; % NT
end

% Removes first order state and second order acceleration terms
[mhpVELr, mhpANGr, mhpSPEEDr]=MHPA_wRATES(avgMHP, gDATA, bDATA, rDATA,L);

% Generate GPS time array
for i = 1:length(GPS(:,8))
    GPS_5HP(i,1) = find(GPS(i,3)>=avgMHPBoardTime(:,1),1,'last');
end

% Windowing for altitude vs windspeed plots
for i = 1:length(GPS(:,8))-1
    avgWS4alt(i,1) = mean(mhpSPEEDr(GPS_5HP(i,1):GPS_5HP(i+1,1)));
end
% Reduce dataset length based on available data
avgWS4alt(length(GPS(:,8)),1) = mhpSPEEDr(length(GPS(:,8)),1);

% Initialize arrays for Sepctral Analysis
fs_avg = round(length(NKF1_5HP)/MHP(end,3)); % post window sampling frequency
L_avg = length(NKF1_5HP); % sample length
% Execute spectral analysis
[P1_avg, f_avg] = freq_this(mhpSPEEDr, fs_avg, L_avg);

% Generate new figure window, iterate global to prevent overwrite
figIter = figIter+1;
Figs{figIter}=figure(figIter);
Figs{figIter}.Name = 'Select (non-zero) peak of FFT plot below.';
plot(f_avg,P1_avg)
title('Single-Sided Amplitude Spectrum of X(t)')
xlabel('f (Hz)')
ylabel('|P1(f)|')
xlim([0 .5])

% User grabs the peak of the fft graph
% * Should be the frequency of the orbit
[loop_freq, vert, button] = ginput(1);
% Get orrbitTime from orbitFrequency
orbitTIME = 1/loop_freq;
% Generate total sample from orbitTime and samplingFrequency
n_samples = round(orbitTIME*fs_avg); % number of samples to average over

% Averaging of orbits
for i = 1:length(NKF1(:,3))
    if i < n_samples + 1
        windSPEEDavg(i,1) = mean(mhpSPEEDr(1:i+1));
        windANGLEavg(i,1) = mean(mhpANGr(1:i+1));
        mhpVNavg(i,1) = mean(mhpVELr((1:i+1),1));
        mhpVEavg(i,1) = mean(mhpVELr((1:i+1),2));
        mhpVDavg(i,1) = mean(mhpVELr((1:i+1),3));
    else
        windSPEEDavg(i,1) = mean(mhpSPEEDr(i-n_samples:i));
        windANGLEavg(i,1) = mean(mhpANGr(i-n_samples:i));
        mhpVNavg(i,1) = mean(mhpVELr((i-n_samples:i),1));
        mhpVEavg(i,1) = mean(mhpVELr((i-n_samples:i),2));
        mhpVDavg(i,1) = mean(mhpVELr((i-n_samples:i),3));
    end
end

% Windowing for altitude vs windspeed plots
for i = 1:length(GPS(:,8))-1
    avgWS4alt2(i,1) = mean(windSPEEDavg(GPS_5HP(i,1):GPS_5HP(i+1,1)));
end
% Reduce dataset length based on available data
avgWS4alt2(length(GPS(:,8)),1) = windSPEEDavg(length(GPS(:,8)),1);

end
%% FUNC: debugFile - Only run Ardupilog and output to workspace (debugDFL)
% Replaces main() to help with debugging issues with the raw DataFlash Log
% No true inputs or outputs, though debugDFL will be exported to workspace
function debugFile()

[baseFileNameNoExtDFL, baseFileNameDFL, folderDFL,...
    fullInputMatFileNameDFL] = file2open('*.bin','Select a Pixhawk DFL file');

% Convert the DFL (in binary) to .mat format (for use here)
rawDFL = Ardupilog(fullInputMatFileNameDFL);

% Output rawDFL to user workspace for review
assignin('base','debugDFL',rawDFL);

end
%% FUNC: freq_this - Make Spectral Analysis of Data Set
% INPUT
% * X - dataset to act on
% * Fs - Sampling frequency of the dataset
% * L - Sample length
% OUTPUT
% * P1 - Amplitude of the corresponding frequency
% * f - Frequency the amplitude corresponds to
function [P1, f] = freq_this(X,Fs, L)

% Convert sampling data to timing data
T = 1/Fs;             % Sampling period from frequency
t = (0:(L-1))*T;      % Time vector

% Execute FFT of the dataset
Y = fft(X);

% Convert power data
P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);

% Convert frequency data
f = Fs*(0:(L/2))/L;

end
%% FUNC: MHPA_wRATES - Convert MHP data to ground-reference wind vectors
% Implementation of the MHPA as derived in Lenschow1989
% Incorporates angular rates
% OUTPUTS
% * windVELOCITY = [VN, VE, VD (m/s)]
% * windDIRECTION = [Angle(Degrees)]
% * windSPEED = [U(m/s)]
% INPUTS
% * aDATA = [U,alpha,beta]   - AirData
% * gDATA = [VN,VE,VD]       - GroundData
% * bDATA = [phi,theta,psi]  - BodyData
% * rDATA = [pitch,roll,yaw] - RateData
% * L = distance from CG to probe tip

function [windVELOCITY, windDIRECTION, windSPEED] = MHPA_wRATES(aDATA, gDATA, bDATA, rDATA, L)

% tTEMP is singular does not need to be defined

% Air-reference data
u_a=aDATA(:,1); % aircraft airspeed derived from 5HP data (m/s)
alpha=aDATA(:,2); % aircraft angle of attack ''  '' (deg)
beta= aDATA(:,3); % aircraft sideslip angle '' ''  (deg)

% Ground-reference data
VN=gDATA(:,1); % Northern Velocity from NKF (m/s)
VE=gDATA(:,2); % Easting Velocity from NKF (m/s)
VD=gDATA(:,3); % Vertical Velocity from NKF (m/s)

% Body-reference data
phi=bDATA(:,1); % aircraft roll data from ATT (deg)
theta=bDATA(:,2); % aircraft pitch data from ATT (deg)
psi=bDATA(:,3); % aircraft heading angle from ATT (deg)

% Aircraft rate data
p=rDATA(:,1); % aircraft roll rate (deg/s)
q=rDATA(:,2); % aircraft pitch rate (deg/s)
r=rDATA(:,3); % aircraft heading rate (deg/s)

% Rotation matrix for rotation from wind to ground based reference frame.
% This rotation allows for the probe data to be merged with the rate data.
for i=1:length(bDATA(:,1))
    RM_gw(:,i) = [cosd(psi(i))*cosd(theta(i))+tand(alpha(i))*(sind(phi(i))*sind(psi(i))+ ...
        cosd(phi(i))*cosd(psi(i))*sind(theta(i)))+tand(beta(i))*(cosd(psi(i))*sind(phi(i))*sind(theta(i))-...
        cosd(phi(i))*sind(psi(i)));
        cosd(theta(i))*sind(psi(i))+tand(alpha(i))*(cosd(phi(i))*sind(psi(i))*sind(theta(i))-cosd(psi(i))*sind(phi(i)))+ ...
        tand(beta(i))*(cosd(phi(i))*cosd(psi(i))+sind(phi(i))*sind(psi(i))*sind(theta(i)));
        -sind(theta(i))+cosd(phi(i))*cosd(theta(i))*tand(alpha(i))+cosd(theta(i))*sind(phi(i))*tand(beta(i))];
    
    rates(i,1) =L*(deg2rad(q(i))*sind(theta(i))*cosd(psi(i))-r(i)*sind(psi(i)));
    rates(i,2) =L*(deg2rad(r(i))*cosd(psi(i))*cosd(theta(i))-q(i)*sind(psi(i))*sind(theta(i)));
    rates(i,3) =-L*(deg2rad(q(i))*cosd(theta(i)));
    
    D(i,1) = sqrt(1+tand(beta(i))^2+tand(alpha(i))^2);
    
    bodyU(i,1)=abs(u_a(i))/D(i);
end

% Convert body-reference velocity to ground-reference velocity
groundMHP = bodyU.*RM_gw';

% Remove body-reference rates and dynamics from ground data
windGROUND = abs(gDATA) - abs(groundMHP) - rates;

% Define this new ground-reference velocty as windVELOCITY
windVELOCITY = windGROUND;

% Arctan on N and E vector for a wind direction
for i=1:length(windGROUND)
    windDIRECTION(i) = atan2d(windVELOCITY(i,1),windVELOCITY(i,2))+90;
end
% Combine the 3 wind vectors for a windspeed.
windSPEED=sqrt(windVELOCITY(:,1).^2+windVELOCITY(:,2).^2+windVELOCITY(:,3).^2);
end
%% FUNC: kolmogorov - Power Spectral Density analysis on velocity data
% Kolmogorov -5/3 Function to check if wind data is following turbulence
% models.
% INPUT
% * x - Dataset being acted on
% * Fs - Sampling frequency of the dataset (x)
% OUTPUT
% * freq - Frequency array
% * psdx - Power Spectral Density of x

function [freq, psdx] = kolmogorov(x,Fs)

global figIter
global Figs

% Initial FFT analysis
N = length(x);                    % Total number of samples
xdft = fft(x);                    % Transform x into frequency domain
xdft = xdft(1:N/2+1);             % Nyqyst frequncy reduction
psdx = (1/(Fs*N)) * abs(xdft).^2; % Power spectral density of xdft
psdx(2:end-1) = 2*psdx(2:end-1);  % Double psdx values over range w/o endpoints
freq = 0:Fs/length(x):Fs/2;       % Range of freq's from 0 to max/2

% Kolmogorov plot
Kolo = freq.^(-5/3);

% Generate new figure window, iterate global to prevent overwrite
figIter = figIter+1;
Figs{figIter}=figure(figIter);
Figs{figIter}.Name = 'Kolmogorov -5/3 Function';
loglog(freq,(psdx),freq,Kolo)
grid on
title('Periodogram Using FFT')
legend('MHP U','-5/3 Law');
xlabel('Frequency (Hz)')
ylabel('Power (m^2/s)')
end
%% FUNC: fuze - Dataset fusion using common timing variable
% Requires lowFreqTime and highFreqTime to:
% * Be over same base timespan
% * Be different array lengths
% INPUT
% * lowFreqTime  - Timing variable of Low Frequency dataset
% * lowFreq      - Full Low Frequency dataset
% * highFreqTime - Timing variable of High Frequency dataset
% * highFreq     - Full High Frequency dataset
% OUTPUT
% * fDATA - highFreq reduced down to same timing as lowFreq
% * * timeVar - positions in highFreq that match lowFreq
% * * highFreqFuz - averaged highFreq data of same size as lowFreq

function fDATA = fuze(lowFreqTime, lowFreq, highFreqTime, highFreq)

% Generate array of high frequncy data of same length as low frequency data
for i = 1:length(lowFreq)
    timeVar(i,1) = find(highFreqTime(:,1)>=lowFreqTime(i,1),1,'first');
end

% Average high frequency data between target reduction points
for i = 1:length(timeVar(:,1))-1
    highFreqFuz(i,:) = mean(highFreq(timeVar(i,1):timeVar(i+1,1),:));
end

% Add final row of highFrequency data to flesh out final averaged row
highFreqFuz(length(timeVar(:,1)),:) = highFreq(timeVar(end,1),:);

% Output both the timing array and averaged array data
fDATA = [timeVar, highFreqFuz];
end
%% FUNC: statAnalysis - Statistical Analysis of Dataset
% Computes basic statistical data
% INPUT
% * x - Target dataset
% OUTPUT
% * statData - Array of statistical analysis data performed on x
% * * mean(x) - Average of dataset
% * * var(x) - Variability of the dataset
% * * std(x) - Standard Deviation of the dataset
% * * skew(x) - Skewness of the dataset
% * * kurt(x) - Kurtosis of the dataset

function statData = statAnalysis(x)

%mean
meanx = mean(x);

%variance
varx = var(x);

%standard deviation
stdx = std(x);

% Skewness function and result
skewns = @(x) (sum((x-mean(x)).^3)./length(x)) ./ (var(x,1).^1.5);
skewx = skewns(x);

% Kurtosis function and result
kurtoss = @(x) (sum((x-mean(x)).^4)./length(x)) ./ (var(x,1).^2);
kurtx = kurtoss(x);

% Output dataset
statData=[meanx, varx, stdx, skewx, kurtx];
end
%% FUNC: timeInterpolation - Uses board time to interpolate other time
% externTime is assumed to be the same length as board time
% Back fills empty data in externTime by:
% * Using boardTime as the constant interpolated against
% * Using partial externTime as the interpolant, or truth data
% INPUT
% * boardTime - highspeed board time
% * externTime - same length as boardTime, but different timing variable
% OUTPUT
% * interpolatedArray - externTime with empties filled

function interpolatedArray = timeInterpolation(boardTime,externTime)

% Initialize the counter for output array
Interpcount=0;

% Interpolation BuildUp
for i=1:length(boardTime(:,1))
    boardTimeInt = boardTime(i);   % Logger time (Teensy, Arduino, etc.)
    externTimeInt = externTime(i); % External time (Pix, Unix, GPS, etc.)
    
    % If valid timing value, add to interpolation array
    if(externTimeInt~=-1)
        Interpcount=Interpcount+1;
        InterpData(Interpcount,1)=boardTimeInt;   % Sensor board time
        InterpData(Interpcount,2)=externTimeInt;  % External Time
    end
end

% Remove Duplicate External Time interpolation points
NewVals=unique(InterpData(:,2));
% Concatenate data based on unique datapoints only
for i=1:length(NewVals(:,1))
    TempVal = find(InterpData(:,2)==NewVals(i,1),1,'first');
    conCat(i,1) = InterpData(TempVal,1);
    conCat(i,2) = NewVals(i,1);
end

% Backfill gaps in full dataset
for j = 1:length(boardTime(:,1))
    if(externTime(j,1) == -1)
        externTime(j,1) = interp1(conCat(:,1),conCat(:,2),boardTime(j,1),'linear');
    end
end

% Output the interpolated External Time array
interpolatedArray = externTime;

end
%% FUNC: rawVarLoop - Function to parse specific data from redactStructDFL
% Parse over NKF1, GPS, IMU, CTUN, ATT, BARO, RCOU
% INPUT
% * name - Fieldname that is housed in redactStructDFL
% * k - iterator from main loop of which valid entry is active
function rawVarLoop(name,k)

global rawVars
global redactStructDFL

% Use as varName for parsing purposes
varName = name;

% Get varName data from structDFL
% Use it to get the fieldUnits array or variable names
% Convert the array to a structure (in case it isnt already)
% Use "fieldnames" to export the data as a cell array
posArray = fieldnames(struct(getfield(getfield(redactStructDFL,varName),'fieldUnits')));
% Add in extra Variable Names to finish out the array setup
posArray = ['LineNo'; posArray(1,1); 'TimeS'; 'DatenumUTC'; posArray(2:end,1)];

% Get varName from structDFL and convert it to a structure
tempData = struct(getfield(redactStructDFL,varName));
% Convert structure to array in an order specified by posArray
for j=1:length(posArray)
    newData(:,j) = tempData.(char(posArray(j,1)));
end

% Check for random data spikes
% Remove if present (hardward error/software glitch)
for jj=length(newData):-1:2
    if(newData(jj,3)-newData(jj-1,3)<0)
        newData(jj-1,:)=[];
    end
end

% Create new table using the data and variables created above
newDataTable = array2table(newData,'VariableNames',posArray);
% Add '_table' at the end of the name
varName = strcat(varName,'_table');
% Store data in rawVars structure for internal use
rawVars{k,1} = varName;
rawVars{k,2} = newData;
rawVars{k,3} = posArray;
% Add fetchable table name to Description
newDataTable.Properties.Description = varName;
% Send table to base workspace for user view
assignin('base',varName,newDataTable);
end

%% %%%%%%%% FUNCTION STORAGE - NOT OPERABLE IN MAIN LOOP %%%%%%%%%%
%% FUNC: AlyssaData - Function to get GPS, DateTime, and Airspeed data
function AlyssaData()


GPS_red = GPS_table;
GPS_red([1,2,(end-1),end],:) = [];

CTUN_red = CTUN_table;

startCTUN = find(CTUN_red.LineNo(:)> GPS_red.LineNo(1),1);
endCTUN = find(CTUN_red.LineNo(:)> GPS_red.LineNo(end),1);
    

CTUN_red(1:startCTUN-1,:) = [];
CTUN_red(endCTUN+1:end,:) = [];

CTUN_red = CTUN_red(1:5:end,:);

if(height(CTUN_red) > height(GPS_red))
    
    CTUN_red((end+1-(height(CTUN_red) - height(GPS_red))):end,:) = [];
    
elseif(height(CTUN_red) < height(GPS_red))
    
    GPS_red((end+1-(height(GPS_red) - height(CTUN_red))):end,:) = [];
    
end

AlyssaData = table(GPS_red.DateUTC, GPS_red.TimeUTC, GPS_red.Lat, GPS_red.Lng, GPS_red.Alt, CTUN_red.Aspd,'VariableNames',{'Date','Time (UTC)','Lat','Long','Alt (m, MSL)','Airspeed (m/s)'});

writetable(AlyssaData,'Believer_Flight2_01-17-2022.csv');

end
