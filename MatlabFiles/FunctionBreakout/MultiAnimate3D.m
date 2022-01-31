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
global allGPS

%% Initialize User Variables
frameRate = 120;   % Output video frame rate
plotSpeed = 5;       % Number of rows to skip between plot points (lower = slow plot speed)
tailLength = 654654456;  % Tail length of plot (number of rows to show at one time)
tailWidth = 3;    % Width of tail behind marker

startProcessing(frameRate, plotSpeed, tailLength, tailWidth);

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
%% FUNC: startProcessing - Process Data Based on User Selection
% Take outputs from userSelection and begin processing
% INPUT
% * fig - Handle for the UI Figure
% * tabgp - Handle for the UITabGroup that runs each panel
% * iMetspn - Send number chosen from UI to iterative iMet read loop
% * spnTeensy - Send number chosen from UI to iterative Teensy read loop
function startProcessing(frameRate, plotSpeed, tailLength,tailWidth)

global rawDFL
global rawVars
global parsedVars
global arduPilotType
global redactStructDFL
global allGPS

% Ask user if extended analysis is required
singleMulti = questdlg('Single or Multi-Aircraft operation?', ...
    'Determine Quantity of Aircraft', ...
    'Single','Multiple','Single');
% Execute or dismiss based on response
switch singleMulti
    case 'Single'
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
        
        GPS_animate = parsedVars{4,2};
        Time = table2array(GPS_animate(:,3));
        Lat = table2array(GPS_animate(:,11));
        Long = table2array(GPS_animate(:,12));
        Alt = table2array(GPS_animate(:,13));
        
        Animation3D(Time,Lat,Long,Alt,frameRate,plotSpeed,tailLength,tailWidth);
        
    case 'Multiple'
        countAC = input('<strong>Enter number of aircraft to plot: </strong>');
        
        % Disable non-critical warning to ease user view
        warning('off','MATLAB:structOnObject')
        
        for m=1:countAC
            redactStructDFL = [];
            rawDFL = [];
            parsedVars = [];
            rawVars = [];
            GPS = [];
            
            [baseNameNoExt, baseName, folder, fullInputMatName] = ardupilogConvert();
            
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
            
            iterAC = append('Aircraft ',sprintf('%d',m));
            allGPS{m,1} = iterAC;
            allGPS{m,2} = parsedVars{loc(1),2};
            allGPS{m,3} = parsedVars{loc(1),3};
            
            GPS = table2array(parsedVars{loc(1),2});
            
            Lat{:,m} = GPS(2:end,11);
            Long{:,m} = GPS(2:end,12);
            Alt{:,m} = GPS(2:end,13);
            Time{:,m} = GPS(2:end,7);
            minTime(1,m) = min(GPS(:,7));
            maxTime(1,m) = max(GPS(:,7));
            
        end
        
        assignin('base','Alt',Alt);
        assignin('base','Time',Time);
        assignin('base','Lat',Lat);
        assignin('base','Long',Long);
        assignin('base','minTime',minTime);
        assignin('base','maxTime',maxTime);
        
        % Turn warnings on that we turned off previously
        warning('on','MATLAB:structOnObject')
 
        minT = min(minTime);
        maxT = max(maxTime);
        translate(:,1) = minT:200:maxT;
        translate(:,2) = 1:length(minT:200:maxT);
        startLat = cellfun(@(v)v(1),Lat);
        startLong = cellfun(@(v)v(1),Long);
        startAlt = cellfun(@(v)v(1),Alt);
        endLat = cellfun(@(v)v(end),Lat);
        endLong = cellfun(@(v)v(end),Long);
        endAlt = cellfun(@(v)v(end),Alt);
        
        finLat(1:length(translate(:,1)),1:m)=0;
        finLong(1:length(translate(:,1)),1:m)=0;
        finAlt(1:length(translate(:,1)),1:m)=0;
        finTime(:,1) = (translate(:,1) - translate(1,1))/1000;
        
        for n = 1:m
            curTime = cell2mat(Time(n));
            curLat = cell2mat(Lat(n));
            curLong = cell2mat(Long(n));
            curAlt = cell2mat(Alt(n));
            count=0;
            for k = 1:length(curTime);
                Catch = find(curTime(k,1)==translate(:,1),1,'first');
                if(Catch>=0)
                    count=count+1;
                    if(count ~= 1)
                        finLat(Catch,n) = curLat(k,1);
                        finLong(Catch,n) = curLong(k,1);
                        finAlt(Catch,n) = curAlt(k,1);
                    else
                        finLat(1:Catch,n)=curLat(k,1);
                        finLong(1:Catch,n)=curLong(k,1);
                        finAlt(1:Catch,n)=curAlt(k,1);
                    end
                end
            end
            finLat(Catch:end,n) = curLat(end,1);
            finLong(Catch:end,n) = curLong(end,1);
            finAlt(Catch:end,n) = curAlt(end,1);
            clear curTime curLat curLong curAlt
        end
        
        for col = 1:size(finLat,2)
            for row = 2:size(finLat,1)
                if finLat(row,col) == 0
                    finLat(row,col) = finLat(row-1,col);
                end
            end
        end
        
        for col = 1:size(finLong,2)
            for row = 2:size(finLong,1)
                if finLong(row,col) == 0
                    finLong(row,col) = finLong(row-1,col);
                end
            end
        end
        
        for col = 1:size(finAlt,2)
            for row = 2:size(finAlt,1)
                if finAlt(row,col) == 0
                    finAlt(row,col) = finAlt(row-1,col);
                end
            end
        end
        
        MultiAnimation3D(finTime,finLat,finLong,finAlt,frameRate,plotSpeed,tailLength,tailWidth);
        
end

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
global arduPilotType

% Generate new figure window, iterate global to prevent overwrite
figIter = figIter+1;
Figs{figIter}=figure(figIter);
Figs{figIter}.Name = 'Raw data from DFL. Click on graph for upper and lower bound for parsing.';

% If no CTUN data (ArduCopter), fill with array of zeros
if(isempty(varargin) | strcmpi(arduPilotType,'ArduCopter'))
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
plot(GPS(:,3),GPS(:,14),'b',CTUN(:,3),CTUN(:,12),'r')
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
plot(GPS(:,3),GPS(:,13),'b');
ylim([min(GPS(:,13))-25 max(GPS(:,13))+25])
ylabel({'GPS Altitude (blue)';'m MSL'})
title('Altitude vs Time')

% Altitude plot (BARO, right side)
yyaxis right
plot(BARO(:,3),BARO(:,6),'r')
ylim([min(BARO(:,6))-25 max(BARO(:,6))+25])
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
    y_vg(m)=GPS(find(GPS(:,3)>=x_m(m),1,'first'),14);      % Groundspeed
    y_thr(m)=RCOU(find(RCOU(:,3)>=x_m(m),1,'first'),7);     % Throttle Percent
    y_pitch(m)=ATT(find(ATT(:,3)>=x_m(m),1,'first'),8); % Aircraft Pitch
    y_GPSalt(m)=GPS(find(GPS(:,3)>=x_m(m),1,'first'),13);    % GPS Altitude
    y_BAROalt(m)=BARO(find(BARO(:,3)>=x_m(m),1,'first'),6);    % BARO Altitude
    
    % Replot same base graphs, but update with X markers at chosen location
    % Groundspeed plot
    subplot(4,1,1)
    plot(GPS(:,3),GPS(:,14),'b',CTUN(:,3),CTUN(:,12),'r',x_m,y_vg,'kx',x_m,y_va,'kx')
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
    plot(GPS(:,3),GPS(:,13),'b',x_m,y_GPSalt,'kx');
    ylim([min(GPS(:,13))-25 max(GPS(:,13))+25])
    ylabel({'GPS Altitude (blue)';'m MSL'})
    title('Altitude vs Time')
    
    % Altitude plot (BARO, right side)
    yyaxis right
    plot(BARO(:,3),BARO(:,6),'r',x_m,y_BAROalt,'kx')
    ylim([min(BARO(:,6))-25 max(BARO(:,6))+25])
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
plot(GPS(:,3)-x_m(1),GPS(:,14),'b',CTUN(:,3)-x_m(1),CTUN(:,12),'r')
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
plot(GPS(:,3)-x_m(1),GPS(:,13),'b');
ylim([min(GPS(:,13))-25 max(GPS(:,13))+25])
ylabel({'GPS Altitude (blue)';'m MSL'})
title('Altitude vs Time')

% Altitude plot (BARO, right side)
yyaxis right
plot(BARO(:,3)-x_m(1),BARO(:,6),'r')
ylim([min(BARO(:,6))-25 max(BARO(:,6))+25])
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
TimeUTC(:,1) = datetime(var_DateTime,'Format','hh:mm:ss.SSS');
DateUTC(:,1) = datetime(var_DateTime,'Format','MMM-dd-yyy');

% Save table with discrete DateUTC and TimeUTC for user view
varDataExternal = removevars(varDataInternal,{'DatenumUTC'});
varDataExternal = addvars(varDataExternal,DateUTC,TimeUTC,'After','TimeS');

% Send external version to user workspace
assignin('base',varName,varDataExternal);

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
%% FUNC: Animation3D - Animated 3D plot with color-changing tail
% Animate flight profile with colorbar tail based on VarData
% All entries must be of the same length or code will not run properly
% INPUT
% * Time - time (in seconds) starting at 0 going through entire flight
% * Lat - Latitude (decimal degrees)
% * Long - Longitude (decimal degrees)
% * Alt - Altitude (m)
% * frameRate - Playback frame rate of exported video
% * plotSpeed - Number of rows to plot in each frame
% * tailLength - Number of rows of data to show at any given time
% * tailWidth - Width of tail on the plot
function Animation3D(Time,Lat,Long,Alt,frameRate,plotSpeed,tailLength,tailWidth)

plotTitle = input('<strong>Enter Plot Title for animation function: </strong>','s');
%colorTitle = input('<strong>Enter Colorbar title: </strong>','s');
%colorUnits = input('<strong>Enter Colorbar units: </strong>','s');
%colorLabel = {sprintf('%s\n(%s)',colorTitle,colorUnits)};
userFileName = input('<strong>Enter an output file name for the animation sequence to save as: </strong>','s');

%% DO NOT CHANGE BEYOND THIS POINT
%% Animation Setup

timer = [0;Time];
%cAnim1=[nan;VarData];  % Variable to have colorbar
xAnim=[nan;Lat];  % Lattitude
yAnim=[nan;Long];  % Longitude
zAnim=[nan;Alt];  % Altitude
lx = length(xAnim);
ly = length(yAnim);
lz = length(zAnim);

fig10 = figure(10);
fig10.Position=[10 10 850 750];
fig10.Resize = 'Off';
%% 3D Axis Generation
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

%data_range1 = ceil(max(max(cAnim1(2:end)))) - floor(min(min(cAnim1(2:end)))) + 1;
%colormap(jet(data_range1*10));
%caxis([min(min(cAnim1(2:end))) max(max(cAnim1(2:end)))])
%cbh1 = colorbar();
%% Position Control
subfig = get(gcf,'children');
set(subfig(1),'position',[.1 .06 .8 .88]);
view(subfig(1),-45,20);
AnimPos = [.025 .88 .09 .1];


% subfig = get(gcf,'children');
%
% set(subfig(1),'position',[.92 .1 .03 .8]);    % Color bar
% set(subfig(2),'position',[.1 .06 .8 .88]);    % Main plotting area
%
% view(subfig(2),-45,20);
%
% AnimPos = [.025 .88 .09 .1];
%
% annotation(fig10,'textbox',[.8875 .9 .09 .1],'String',colorLabel,'HorizontalAlignment','center','VerticalAlignment','middle','EdgeColor','none','FontWeight','bold');
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
    %     if (jj < tailLength)
    %         p1 = patch(ax1,xAnim(1:jj),yAnim(1:jj),zAnim(1:jj),cAnim1(1:jj),'EdgeColor','interp','FaceColor','none','LineWidth',tailWidth); view(-45,45)
    %     else
    %         p1 = patch(ax1,xAnim(jj-tailLength:jj),yAnim(jj-tailLength:jj),zAnim(jj-tailLength:jj),cAnim1(jj-tailLength:jj),'EdgeColor','interp','FaceColor','none','LineWidth',tailWidth); view(-45,45)
    %     end
    
    if (jj < tailLength)
        p1 = patch(ax1,xAnim(1:jj),yAnim(1:jj),zAnim(1:jj),'r','EdgeColor','r','FaceColor','none','LineWidth',tailWidth); view(-45,45)
    else
        p1 = patch(ax1,xAnim(jj-tailLength:jj),yAnim(jj-tailLength:jj),zAnim(jj-tailLength:jj),'r','EdgeColor','r','FaceColor','none','LineWidth',tailWidth); view(-45,45)
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
    %annotation(fig10,'textbox',[.8875 .9 .09 .1],'String',colorLabel,'HorizontalAlignment','center','VerticalAlignment','middle','EdgeColor','none','FontWeight','bold');
    
    pause(1/50); %Pause and grab frame
    frame = getframe(gcf); %get frame
    writeVideo(animVid, frame);
    cla(ax1);
end
close(animVid);
disp('Animation plotting completed. Video file saved in same location as the data file.');
p1 = patch(ax1,xAnim(1:jj),yAnim(1:jj),zAnim(1:jj),'r','EdgeColor','r','FaceColor','none','LineWidth',2); view(-45,45)
end
%% FUNC: MultiAnimation3D - Animated 3D plot for multiple aircraft (7 max)
% Animate all flight profiles simultaneously
% Assumes all entries are of the same length against a common timing var
% INPUT
% * Time - time (in seconds) starting at 0 going through entire flight
% * Lat - Latitude (decimal degrees)
% * Long - Longitude (decimal degrees)
% * Alt - Altitude (m)
% * frameRate - Playback frame rate of exported video
% * plotSpeed - Number of rows to plot in each frame
% * tailLength - Number of rows of data to show at any given time
% * tailWidth - Width of tail on the plot
function MultiAnimation3D(Time,Lat,Long,Alt,frameRate,plotSpeed,tailLength,tailWidth)

plotTitle = input('<strong>Enter Plot Title for animation function: </strong>','s');
userFileName = input('<strong>Enter an output file name for the animation sequence to save as: </strong>','s');

%% DO NOT CHANGE BEYOND THIS POINT
%% Animation Setup

disp('Beginning animation setup.');

ColOrd = [1 0 0; 0 1 0; 0 0 1; 1 1 1; 0 0 0; 1 1 0; 1 0 1; 0 1 1];
[m,n] = size(ColOrd);

minLat = min(min(Lat));
maxLat = max(max(Lat));
minLong = min(min(Long));
maxLong = max(max(Long));
minAlt = min(min(Alt));
maxAlt = max(max(Alt));

fig10 = figure(10);
fig1.Position = [10 50 560 725];
fig10.Resize = 'Off';
%% 3D Axis Generation
ax = gca;
if(strcmpi(plotTitle,''))
    plotTitle = 'Default';
end
title(plotTitle);
xlim(ax, [minLat maxLat]);
ylim(ax, [minLong maxLong]);
zlim(ax, [minAlt maxAlt]);
view(ax, 3)
grid on
zl = zlabel('Altitude (m, AGL)');
yl = ylabel('Latitude');
xl = xlabel('Longitude');
xticks(minLat:((maxLat-minLat)/4):maxLat);
yticks(minLong:((maxLong-minLong)/4):maxLong);
zticks(minAlt:((maxAlt-minAlt)/5):maxAlt);
xtickformat('%.3f')
ytickformat('%.3f')
ztickformat('%.0f')
set(ax,'Color','k','xcolor','w','ycolor','w','zcolor','w','LineWidth',2)

%% Position Control
view(ax,-45,20);
AnimPos = [.025 .855 .09 .125];

%% Set Axis Colors

for i=1:length(ax.XTickLabel)
    ax.XTickLabel{i} = ['\color[rgb]{0,0,0}' ax.XTickLabel{i}];
end
for j=1:length(ax.YTickLabel)
    ax.YTickLabel{j} = ['\color[rgb]{0,0,0}' ax.YTickLabel{j}];
end
for k=1:length(ax.ZTickLabel)
    ax.ZTickLabel{k} = ['\color[rgb]{0,0,0}' ax.ZTickLabel{k}];
end

ax.XTickLabel(i) = {' '};
ax.YTickLabel(j) = {' '};

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

assignin('base','animAlt',Alt);
assignin('base','animTime',Time);
assignin('base','animLat',Lat);
assignin('base','animLong',Long);

for jj=1:plotSpeed:size(Alt,1)
    
    hold on
    for k = 1:size(Alt,2)
        ColRow = rem(k,m);
        if ColRow == 0
            ColRow = m;
        end
        Col = ColOrd(ColRow,:);
        hold on
        
        plot3(ax,Lat(1:jj,k),Long(1:jj,k),Alt(1:jj,k),'Color',Col,'LineWidth',1.5);
        plot3(ax,Lat(jj,k),Long(jj,k),Alt(jj,k),'LineStyle','none','Marker','o','MarkerSize',6,'MarkerFaceColor',Col,'MarkerEdgeColor',Col);
        
    end
    
    delete(findall(fig10,'type','annotation'));
    Minutes = fix(Time(jj,1)/60);
    Hours = fix(Time(jj,1)/3600);
    
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
    
    pause(1/50); %Pause and grab frame
    frame = getframe(gcf); %get frame
    writeVideo(animVid, frame);
    cla(ax);
    hold off
end
close(animVid);
disp('Animation plotting completed. Video file saved in same location as the data file.');
p1 = patch(ax1,xAnim(1:jj),yAnim(1:jj),zAnim(1:jj),'r','EdgeColor','r','FaceColor','none','LineWidth',2); view(-45,45)
end
