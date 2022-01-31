% Pixhawk DFL Analyzer V4.8.2
% Created by:    Levi Ross | levi.ross@okstate.edu
% Edited by:     Kyle Hickman | kthickm@okstate.edu
% Unmanned Systems Research Institute
% Creation Date: 11/17/2019
% Last Modified: 03/25/2021 - Levi
%
% New features:
%    * Replay _Parsed files
%    * No longer need to set Ardupilot type, auto-selected from MSG1 log
%    * Added Wind Rose to view estimated wind speed data form Pixhawk
%    * Added PlotMergedData codeset, allowing for simultaneous or series data plots
%    * Added custom .bin -> .mat converter, eliminating the need for Mission Planner
%    * Complete CopterSonde support
%    * Added met data averaging for vertical profiles or stationary hovers
%    * Added Animation of side-by-side T, P, and H graphs against GPS data
%    * 3D-isometric viewing of Multi-Aircraft animation
%    * Added altitude parsing to allow for multi-aircraft 3D plots
%
% General Updates:
%    * Consolidated DFL_New and DFL_Old 5HP plots and output file saving
%
% Bug Fixes:
%    * Properly referencing Temp and Humidty values in Sensor Suite data
%    * Explicitly defined all figures so there's no chance to overwrite
%
% Current Fig Count:
%    * Single: 10
%    * Multi: 1

%% Clear All Data
close all
clear all
clc

%% Initialize User-Defined Content
display('Initializing user-defined variable space.');

thrMinPWM = 1100;              % Default, scales THR% plots
thrMaxPWM = 1900;              % Default, scales THR% plots

Single_Multi = 'Single';

% Single Controls
animateToggle = 'Yes';         % Flight animation based on GPS and Alt(AGL)
recordAnimation = 'No';       % Record animation for future playback
gpsOut = 'No';               % Output GPS data as individual file (lat, long, alt)
dflNewOld = 'Unknown';
arduPilotType = 'Fixed Wing';

% Animation Controls
animateSpeed = 2;             % Overall speed
animateHeadSize = 3;           % Icon size
animateTailWidth = 2;          % Width of tail
animateTailLength = 100;       % Length of tail
animateFPS = 30;
animateHeadSize = animateHeadSize + 5;
plotTitle = '';

% Only used for Multi Animation
animation = 'Yes';        % Default: Yes | Yes: turn on animation | No: turn Off
simultaneous = 'No';     % Default: Yes | Yes: Files in same time frame | No: Files in concurrent time frames
isometric = 'No';        % Default: Yes | Yes: view in 3D space | No: view in 2D with Satellite map overlay
azimuthAngle = 45;        % Default: 45 | Rotation angle in x-y plane to view the 3D plot (positive values -> CCW rotation, negative CW)
elevationAngle = 15;      % Default: 15 | Elevation angle above the X-Y plane (90 is top down X-Y plot, 0 is looking from the X-Y plane depending on azimuthAngle)
iterationSkip = 5;       % Default: 5  | High numbers: increase animation speed, reduce smoothness. If increasing, decrease animFrameRate to have useful video time
animFrameRate = 30;       % Default: 30 | High numbers: increase animation speed, increase smoothness. If increasing, decrease iteration_skip to have useful video time

%% Main Code
display('Executing user-defined operations.');
if(strcmpi(Single_Multi,'Single'))
    %% Gather All Files For Parsing
    
    % Have user browse for a file, from a specified "starting folder."
    % For convenience in browsing, set a starting folder from which to browse.
    % Start in the current folder.
    startingFolderDFL = pwd;
    % Get the name of the file that the user wants to use.
    defaultFileNameDFL = fullfile(startingFolderDFL,{'*.bin;*.mat'});
    [baseFileNameDFL, folderDFL] = uigetfile(defaultFileNameDFL, 'Select a Pixhawk DFL file (.bin or .mat only)');
    startingFolderDFL = folderDFL;
    if baseFileNameDFL == 0
        % User clicked the Cancel button.
        return;
    end
    
    fullInputMatFileNameDFL = fullfile(folderDFL, baseFileNameDFL);
    %% Gather Additional Files
    variableInfo = who('-file',fullInputMatFileNameDFL);
    
    if(length(variableInfo)<20 && strcmpi(dflNewOld,'Unknown') && ismember('GPS_table',variableInfo))
        
        
        load(fullInputMatFileNameDFL);
        dflNewOld = 'Old';
        
        if(ismember('MHP_table',variableInfo))
            mhpValue = 'Yes';
        else mhpValue = 'No';
        end
        
        if(ismember('TPH_table',variableInfo))
            tphValue = 'Yes';
        else tphValue = 'No';
        end
        
        if(ismember('iMet_table',variableInfo))
            iMetValue = 'Yes';
        else iMetValue = 'No';
        end
        
        if(ismember('CSIMET_table',variableInfo))
            arduPilotType = 'CopterSonde';
        end
        
    else
        dflNewOld = 'New';
        
        % Parser for ArduPilotType
        if(strcmpi(arduPilotType,'Default'))
            
            if(ismember('IMET',variableInfo))
                arduPilotType = 'Coptersonde';
            else
                load(fullInputMatFileNameDFL,'MSG1');
                
                QuadPlane = 0;
                ArduPlane = 0;
                for(i=1:length(MSG1))
                    try
                        if(strcmpi(MSG1{1,i}{3,1}(1,1:9),{'QuadPlane'}))
                            QuadPlane = 1;
                        elseif(strcmpi(MSG1{1,i}{3,1}(1,1:9),{'ArduPlane'}))
                            ArduPlane = 1;
                        elseif(strcmpi(MSG1{1,i}{3,1}(1,1:10),{'ArduCopter'}))
                            arduPilotType = 'ArduCopter';
                        end
                        
                    catch
                    end
                end
                
                if((QuadPlane + ArduPlane) == 2)
                    arduPilotType = 'Quad-Plane';
                elseif((QuadPlane + ArduPlane) == 1)
                    arduPilotType = 'Fixed Wing';
                end
            end
        end
        
        % Execution of ArduPilotType
        if(strcmpi(arduPilotType,'Fixed Wing'))
            load(fullInputMatFileNameDFL,'ATT','ATT_label','BARO','BARO_label','CTUN','CTUN_label','GPS','GPS_label','IMU','IMU_label','NKF2','NKF2_label','RCOU','RCOU_label');
            
            % Pre-parse for only relevant data series
            ATT = [ATT(:,1),ATT(:,2),ATT(:,4),ATT(:,6),ATT(:,8)];
            ATT_label = [ATT_label(1),ATT_label(2),ATT_label(4),ATT_label(6),ATT_label(8)];
            BARO = [BARO(:,1:4)];
            BARO_label = [BARO_label(1:4)];
            CTUN = [CTUN(:,1),CTUN(:,2),CTUN(:,4),CTUN(:,6),CTUN(:,8),CTUN(:,10)];
            CTUN_label = [CTUN_label(1),CTUN_label(2),CTUN_label(4),CTUN_label(6),CTUN_label(8),CTUN_label(10)];
            GPS = [GPS(:,1),GPS(:,2),GPS(:,4),GPS(:,5),GPS(:,8),GPS(:,9),GPS(:,10),GPS(:,11)];
            GPS_label = [GPS_label(1),GPS_label(2),GPS_label(4),GPS_label(5),GPS_label(8),GPS_label(9),GPS_label(10),GPS_label(11)];
            IMU = [IMU(:,1:8)];
            IMU_label = [IMU_label(1:8)];
            NKF2 = [NKF2(:,1),NKF2(:,2),NKF2(:,7),NKF2(:,8)];
            NKF2_label = [NKF2_label(1),NKF2_label(2),NKF2_label(7),NKF2_label(8)];
            RCOU = [RCOU(:,1:6)];
            RCOU_label = [RCOU_label(1:6)];
        end
        
        if(strcmpi(arduPilotType,'Quad-Plane'))
            load(fullInputMatFileNameDFL,'ATT','ATT_label','BARO','BARO_label','CTUN','CTUN_label','IMU','IMU_label','GPS','GPS_label','XKF2','XKF2_label','RCOU','RCOU_label');
            
            % Pre-parse for only relevant data series
            ATT = [ATT(:,1),ATT(:,2),ATT(:,4),ATT(:,6),ATT(:,8)];
            ATT_label = [ATT_label(1),ATT_label(2),ATT_label(4),ATT_label(6),ATT_label(8)];
            BARO = [BARO(:,1:4)];
            BARO_label = [BARO_label(1:4)];
            CTUN = [CTUN(:,1),CTUN(:,2),CTUN(:,4),CTUN(:,6),CTUN(:,8),CTUN(:,10)];
            CTUN_label = [CTUN_label(1),CTUN_label(2),CTUN_label(4),CTUN_label(6),CTUN_label(8),CTUN_label(10)];
            GPS=[GPS(:,1),GPS(:,2),GPS(:,4),GPS(:,5),GPS(:,8),GPS(:,9),GPS(:,10),GPS(:,11)];
            GPS_label = [GPS_label(1),GPS_label(2),GPS_label(4),GPS_label(5),GPS_label(8),GPS_label(9),GPS_label(10),GPS_label(11)];
            IMU = [IMU(:,1:8)];
            IMU_label = [IMU_label(1:8)];
            NKF2 = [XKF2(:,1),XKF2(:,2),XKF2(:,6),XKF2(:,7)];
            NKF2_label = [XKF2_label(1),XKF2_label(2),XKF2_label(6),XKF2_label(7)];
            RCOU = [RCOU(:,1:6)];
            RCOU_label = [RCOU_label(1:6)];
        end
        
        % Not configured
        if(strcmpi(arduPilotType,'ArduCopter'))
            load(fullInputMatFileNameDFL,'ATT','ATT_label','BARO','BARO_label','IMU','IMU_label','GPS','GPS_label','NKF2','NKF2_label','RCOU','RCOU_label');
            
            % Pre-parse for only relevant data series
            ATT = [ATT(:,1),ATT(:,2),ATT(:,4),ATT(:,6),ATT(:,8)];
            ATT_label = [ATT_label(1),ATT_label(2),ATT_label(4),ATT_label(6),ATT_label(8)];
            BARO = [BARO(:,1:4)];
            BARO_label = [BARO_label(1:4)];
            GPS=[GPS(:,1),GPS(:,2),GPS(:,4),GPS(:,5),GPS(:,8),GPS(:,9),GPS(:,10),GPS(:,11)];
            GPS_label = [GPS_label(1),GPS_label(2),GPS_label(4),GPS_label(5),GPS_label(8),GPS_label(9),GPS_label(10),GPS_label(11)];
            IMU = [IMU(:,1:8)];
            IMU_label = [IMU_label(1:8)];
            NKF2 = [NKF2(:,1),NKF2(:,2),NKF2(:,6),NKF2(:,7)];
            NKF2_label = [NKF2_label(1),NKF2_label(2),NKF2_label(6),NKF2_label(7)];
            RCOU = [RCOU(:,1:6)];
            RCOU_label = [RCOU_label(1:6)];
        end
        
        % Not configured
        if(strcmpi(arduPilotType,'CopterSonde'))
            load(fullInputMatFileNameDFL,'ATT','ATT_label','WIND','WIND_label','IMET','IMET_label','BARO','BARO_label','IMU','IMU_label','GPS','GPS_label','RCOU','RCOU_label');
            
            % Pre-parse for only relevant data series
            ATT = [ATT(:,1),ATT(:,2),ATT(:,4),ATT(:,6),ATT(:,8)];
            ATT_label = [ATT_label(1),ATT_label(2),ATT_label(4),ATT_label(6),ATT_label(8)];
            BARO = [BARO(:,1:4)];
            BARO_label = [BARO_label(1:4)];
            GPS=[GPS(:,1),GPS(:,2),GPS(:,4),GPS(:,5),GPS(:,8),GPS(:,9),GPS(:,10),GPS(:,11)];
            GPS_label = [GPS_label(1),GPS_label(2),GPS_label(4),GPS_label(5),GPS_label(8),GPS_label(9),GPS_label(10),GPS_label(11)];
            IMU = [IMU(:,1:8)];
            IMU_label = [IMU_label(1:8)];
            RCOU = [RCOU(:,1:6)];
            RCOU_label = [RCOU_label(1:6)];
        end
        
        % Not configured, placeholder only
        if(strcmpi(arduPilotType,'ArduRover'))
            load(fullInputMatFileNameDFL,'ATT','ATT_label','BARO','BARO_label','CTUN','CTUN_label','GPS','GPS_label','IMU','IMU_label','NKF2','NKF2_label','RCOU','RCOU_label','STAT','STAT_label');
            
            % Pre-parse for only relevant data series
            ATT = [ATT(:,1),ATT(:,2),ATT(:,4),ATT(:,6),ATT(:,8)];
            ATT_label = [ATT_label(1),ATT_label(2),ATT_label(4),ATT_label(6),ATT_label(8)];
            BARO = [BARO(:,1:4)];
            BARO_label = [BARO_label(1:4)];
            CTUN = [CTUN(:,1),CTUN(:,2),CTUN(:,4),CTUN(:,6),CTUN(:,8),CTUN(:,10)];
            CTUN_label = [CTUN_label(1),CTUN_label(2),CTUN_label(4),CTUN_label(6),CTUN_label(8),CTUN_label(10)];
            GPS = [GPS(:,1),GPS(:,2),GPS(:,4),GPS(:,5),GPS(:,8),GPS(:,9),GPS(:,10),GPS(:,11)];
            GPS_label = [GPS_label(1),GPS_label(2),GPS_label(4),GPS_label(5),GPS_label(8),GPS_label(9),GPS_label(10),GPS_label(11)];
            IMU = [IMU(:,1:8)];
            IMU_label = [IMU_label(1:8)];
            NKF2 = [NKF2(:,1),NKF2(:,2),NKF2(:,7),NKF2(:,8)];
            NKF2_label = [NKF2_label(1),NKF2_label(2),NKF2_label(7),NKF2_label(8)];
            RCOU = [RCOU(:,1:6)];
            RCOU_label = [RCOU_label(1:6)];
            STAT = [STAT(:,1:5)];
            STAT_label = [STAT_label(1:5)];
        end
        
    end
    
    % Get filename without the extension, used by Save Function
    [~, baseNameNoExtDFL, ~] = fileparts(baseFileNameDFL);
    
    if (strcmpi(pitchToggle,'Yes'))
        
        if(strcmpi(aircraft,'TIA'))
            pitchMap=[1139,-7.9 ; 1150,-7.1 ; 1200,-6.3 ; 1250,-5.6 ; 1300,-4.8 ; 1350,-4.0 ; 1400,-3.2 ; 1450,-1.6 ; 1500,0.0 ; 1550,6.3 ; 1600,7.9 ; 1650,9.5 ; 1700,11.0 ; 1750,12.5 ; 1800,14.0 ; 1850,15.5 ; 1900,17.0 ; 1939,17.0];
        else
            % Have user browse for a file, from a specified "starting folder."
            % For convenience in browsing, set a starting folder from which to browse.
            % Start in the current folder.
            startingFolder = pwd;
            
            % Get the name of the file that the user wants to use.
            defaultFileName = fullfile(startingFolder, '*.txt');
            [baseFileName, folder] = uigetfile(defaultFileName, 'Select a Pitch PWM text file');
            if baseFileName == 0
                % User clicked the Cancel button.
                return;
            end
            
            % Get the name of the input .mat file.
            fullInputMatFileName = fullfile(folder, baseFileName);
            pitchMap = load(fullInputMatFileName);
        end
    end
    
    if (strcmpi(throttleToggle,'Yes'))
        
        if(strcmpi(aircraft,'TIA'))
            throttleMap=[0,0.00 ; 10,1.02 ; 20,1.91 ; 30,2.85 ; 40,3.93 ; 50,5.00 ; 60,6.31 ; 70,7.92 ; 80,9.57 ; 89,11.17 ; 100,13.37];
        else
            % Have user browse for a file, from a specified "starting folder."
            % For convenience in browsing, set a starting folder from which to browse.
            % Start in the current folder.
            startingFolder = pwd;
            
            % Get the name of the file that the user wants to use.
            defaultFileName = fullfile(startingFolder, '*.txt');
            [baseFileName, folder] = uigetfile(defaultFileName, 'Select a Throttle Mapping text file');
            if baseFileName == 0
                % User clicked the Cancel button.
                return;
            end
            
            % Get the name of the input .mat file.
            fullInputMatFileName = fullfile(folder, baseFileName);
            throttleMap = load(fullInputMatFileName);
        end
    end
    %% Set Parsing Bounds
    if(strcmpi(dflNewOld,'New'))
        
        fig1=figure(1);
        fig1.Name = 'Raw data from DFL. Click on graph for upper and lower bound for parsing.';
        
        if(strcmpi(arduPilotType,'ArduCopter') | strcmpi(arduPilotType,'CopterSonde'))
            plt1 = subplot(4,1,1);
            plot(GPS(:,2),GPS(:,8),'b')
            title('Groundspeed vs Time')
            ylabel({'Groundspeed (blue)';'(m/s)'})
        else
            % Groundspeed plot
            plt1 = subplot(4,1,1);
            plot(GPS(:,2),GPS(:,8),'b',CTUN(:,2),CTUN(:,6),'r')
            title('Groundspeed, Airspeed vs Time')
            ylabel({'Groundspeed (blue)';'Airspeed (red)';'(m/s)'})
        end
        
        % Throttle Output
        plt2 = subplot(4,1,2);
        plot(RCOU(:,2),((RCOU(:,5)-thrMinPWM)/(thrMaxPWM-thrMinPWM)*100),'b')
        title('Throttle vs Time')
        ylabel({'Throttle';'(%)'})
        ylim([0 100])
        
        % For the dotted line along x-axis of pitch plot
        zero=int8(zeros(length(ATT(:,2)),1));
        
        % Aircraft Pitch angle: Can change ylim to something more relevant.
        % TIV uses -20 to 50 to see high AoA landing
        plt3 = subplot(4,1,3);
        plot(ATT(:,2),ATT(:,4),'b',ATT(:,2),zero,'r:')
        title('Aircraft Pitch Angle vs Time')
        ylabel({'Aircraft Pitch';'Angle (°)'})
        ylim([-10 40])
        
        % Altitude plot
        plt4 = subplot(4,1,4);
        plot(GPS(:,2),GPS(:,7),'b')
        title('Altitude vs Time')
        ylabel({'Altitude MSL';'(m)'})
        xlabel('Time (microseconds)')
        linkaxes([plt1 plt2 plt3 plt4],'x')
        xlim([min(GPS(:,2)) max(GPS(:,2))])
        
        m=0;
        while true
            [horiz, vert, button] = ginput(1);
            if isempty(horiz) || button(1) == 3; break; end
            m = m+1;
            x_m(m) = horiz(1); % save all points you continue getting
            hold on
            if(strcmpi(arduPilotType,'ArduCopter') | strcmpi(arduPilotType,'CopterSonde'))
            else y_va(m)=CTUN(find(CTUN(:,2)>=x_m(m),1,'first'),6);     % Airspeed
            end
            y_vg(m)=GPS(find(GPS(:,2)>=x_m(m),1,'first'),8);      % Groundspeed
            y_thr(m)=RCOU(find(RCOU(:,2)>=x_m(m),1,'first'),5);     % Throttle Percent
            y_pitch(m)=ATT(find(ATT(:,2)>=x_m(m),1,'first'),4); % Aircraft Pitch
            y_alt(m)=GPS(find(GPS(:,2)>=x_m(m),1,'first'),7);    % Altitude
            
            if(strcmpi(arduPilotType,'ArduCopter') | strcmpi(arduPilotType,'CopterSonde'))
                % Groundspeed plot
                subplot(4,1,1)
                plot(GPS(:,2),GPS(:,8),'b',x_m,y_vg,'kx')
                title('Groundspeed vs Time')
                ylabel({'Groundspeed (blue)';'(m/s)'})
            else
                % Groundspeed plot
                subplot(4,1,1)
                plot(GPS(:,2),GPS(:,8),'b',CTUN(:,2),CTUN(:,6),'r',x_m,y_vg,'kx',x_m,y_va,'kx')
                title('Groundspeed, Airspeed vs Time')
                ylabel({'Groundspeed (blue)';'Airspeed (red)';'(m/s)'})
            end
            
            % Throttle Output
            subplot(4,1,2)
            plot(RCOU(:,2),((RCOU(:,5)-thrMinPWM)/(thrMaxPWM-thrMinPWM)*100),'b',x_m, ((y_thr-thrMinPWM)/(thrMaxPWM-thrMinPWM)*100),'kx')
            title('Throttle vs Time')
            ylabel({'Throttle';'(%)'})
            ylim([0 100])
            
            % For the dotted line along x-axis of pitch plot
            zero=int8(zeros(length(ATT(:,2)),1));
            
            % Aircraft Pitch angle: Can change ylim to something more relevant.
            % TIV uses -20 to 50 to see high AoA landing
            subplot(4,1,3)
            plot(ATT(:,2),ATT(:,4),'b',ATT(:,2),zero,'r:',x_m,y_pitch,'kx')
            title('Aircraft Pitch Angle vs Time')
            ylabel({'Aircraft Pitch';'Angle (°)'})
            ylim([-10 40])
            
            % Altitude plot
            subplot(4,1,4)
            plot(GPS(:,2),GPS(:,7),'b',x_m,y_alt,'kx')
            title('Altitude vs Time')
            ylabel({'Altitude MSL';'(m)'})
            xlabel('Time (microseconds)')
            xlim([min(GPS(:,2)) max(GPS(:,2))])
            
            drawnow
            
            if(m>=2)
                break;
            end
            
        end
        
        fig2=figure(2);
        fig2.Name = 'Preview of user-parsed DFL data.';
        
        if(strcmpi(arduPilotType,'ArduCopter') | strcmpi(arduPilotType,'CopterSonde'))
            % Groundspeed plot
            plt1 = subplot(4,1,1);
            plot(GPS(:,2)/1000000,GPS(:,8),'b')
            title('Groundspeed vs Time')
            ylabel({'Groundspeed (blue)';'(m/s)'})
        else
            % Groundspeed plot
            plt1 = subplot(4,1,1);
            plot(GPS(:,2)/1000000,GPS(:,8),'b',CTUN(:,2)/1000000,CTUN(:,6),'r')
            title('Groundspeed, Airspeed vs Time')
            ylabel({'Groundspeed (blue)';'Airspeed (red)';'(m/s)'})
        end
        
        % Throttle Output
        plt2 = subplot(4,1,2);
        plot(RCOU(:,2)/1000000,((RCOU(:,5)-thrMinPWM)/(thrMaxPWM-thrMinPWM)*100),'b')
        title('Throttle vs Time')
        ylabel({'Throttle';'(%)'})
        ylim([0 100])
        
        % For the dotted line along x-axis of pitch plot
        zero=int8(zeros(length(ATT(:,2)),1));
        
        % Aircraft Pitch angle: Can change ylim to something more relevant.
        % TIV uses -20 to 50 to see high AoA landing
        plt3 = subplot(4,1,3);
        plot(ATT(:,2)/1000000,ATT(:,4),'b',ATT(:,2)/1000000,zero,'r:')
        title('Aircraft Pitch Angle vs Time')
        ylabel({'Aircraft Pitch';'Angle (°)'})
        ylim([-10 40])
        
        % Altitude plot
        plt4 = subplot(4,1,4);
        plot(GPS(:,2)/1000000,GPS(:,7),'b')
        title('Altitude vs Time')
        ylabel({'Altitude MSL';'(m)'})
        xlabel('Time (seconds)')
        linkaxes([plt1 plt2 plt3 plt4],'x')
        xlim([x_m(1)/1000000 x_m(2)/1000000])
        
    end
    %% Configure Start/Stop Conditions
    if(strcmpi(dflNewOld,'New'))
        
        % Finding the applicable data range based on minimum settings above
        % GPS line number of starting relavent data (used for parsing)
        TO = IMU(find(IMU(:,2)>=x_m(1), 1, 'first'),1);
        LND = IMU(find(IMU(:,2)>=x_m(2), 1, 'first'),1);
        
        % Potision in each major dataset (GPS, CTUN, NKF2, RCOU) for Takeoff (TO)
        % and Landing (LND)
        if(strcmpi(arduPilotType,'ArduCopter'))
            TO_NKF = find(NKF2(:,1)>TO,1,'first')-1;
            LND_NKF = find(NKF2(:,1)>LND,1,'first')-1;
        elseif(strcmpi(arduPilotType,'CopterSonde'))
            TO_WIND = find(WIND(:,1)>TO,1,'first')-1;
            LND_WIND = find(WIND(:,1)>LND,1,'first')-1;
            TO_IMET = find(IMET(:,1)>TO,1,'first')-1;
            LND_IMET = find(IMET(:,1)>LND,1,'first')-1;
        else
            TO_CTUN = find(CTUN(:,1)>TO,1,'first')-1;
            LND_CTUN = find(CTUN(:,1)>LND,1,'first')-1;
            TO_NKF = find(NKF2(:,1)>TO,1,'first')-1;
            LND_NKF = find(NKF2(:,1)>LND,1,'first')-1;
        end
        TO_GPS = find(GPS(:,1)>TO,1,'first')-1;
        LND_GPS = find(GPS(:,1)>LND,1,'first')-1;
        TO_ATT = find(ATT(:,1)>TO,1,'first')-1;
        LND_ATT = find(ATT(:,1)>LND,1,'first')-1;
        TO_RCOU = find(RCOU(:,1)>TO,1,'first')-1;
        LND_RCOU = find(RCOU(:,1)>LND,1,'first')-1;
        TO_IMU = find(IMU(:,1)>TO,1,'first')-1;
        LND_IMU = find(IMU(:,1)>LND,1,'first')-1;
        TO_BARO = find(BARO(:,1)>TO,1,'first')-1;
        LND_BARO = find(BARO(:,1)>LND,1,'first')-1;
        
        %%%%%%%%% GPS Logs Parsing %%%%%%%%%
        % Latitude
        x=GPS(TO_GPS:LND_GPS,5);
        % Longitude
        y=GPS(TO_GPS:LND_GPS,6);
        % Altitude
        z=GPS(TO_GPS:LND_GPS,7);
        z_AGL = z(:)-z(1);
        
        %%%%%%%%% Airspeed and Windspeed Data %%%%%%%%%
        % Ground speed
        v_g=GPS(TO_GPS:LND_GPS,8);
        % Max ground speed
        max_v_g=max(GPS(TO_GPS:LND_GPS,8));
        if(strcmpi(arduPilotType,'CopterSonde'))
            wind = WIND(TO_WIND:LND_WIND,4);
            VWN = cos(deg2rad(WIND(TO_WIND:LND_WIND,3))).*wind;
            VWE = sin(deg2rad(WIND(TO_WIND:LND_WIND,3))).*wind;
        elseif(strcmpi(arduPilotType,'ArduCopter'))
            % North winds
            VWN=NKF2(TO_NKF:LND_NKF,3);
            % East winds
            VWE=NKF2(TO_NKF:LND_NKF,4);
            % Wind vector
            wind=(VWN.^2+VWE.^2).^0.5;
        else
            % Airspeed
            v_a=CTUN(TO_CTUN:LND_CTUN,6);
            % North winds
            VWN=NKF2(TO_NKF:LND_NKF,3);
            % East winds
            VWE=NKF2(TO_NKF:LND_NKF,4);
            % Wind vector
            wind=(VWN.^2+VWE.^2).^0.5;
        end
        
        %%%%%%%%% Aircraft Data %%%%%%%%%
        % Pitch PWM signal
        pitchPWM=RCOU(TO_RCOU:LND_RCOU,3);
        % Aircraft pitch angle
        pitchAC=ATT(TO_ATT:LND_ATT,4);
        % Aircraft roll angle
        rollAC = ATT(TO_ATT:LND_ATT,3);
        % Aircraft yaw (Earth reference, degrees)
        yawAC = ATT(TO_ATT:LND_ATT,5);
        % Throttle output from Pixhawk
        thr=(RCOU(TO_RCOU:LND_RCOU,5)-thrMinPWM)/(thrMaxPWM-thrMinPWM)*100;
    end
    %% Parse All Data and Save To Respective Tables
    if(strcmpi(dflNewOld,'New'))
        % Parsed GPS data output
        GPS_LN = GPS(TO_GPS:LND_GPS,1);
        GPS_time = GPS(TO_GPS:LND_GPS,2);
        GPS_ms = GPS(TO_GPS:LND_GPS,3);
        GPS_wk = GPS(TO_GPS:LND_GPS,4);
        GPS_time_out= (GPS_time-min(GPS_time))/1000000;
        % Convert GPS timestamps to UTC time
        leap_second_table = datenum(['Jul 01 1981';'Jul 01 1982';'Jul 01 1983';'Jul 01 1985';'Jan 01 1988';'Jan 01 1990';'Jan 01 1991';'Jul 01 1992';'Jul 01 1993';'Jul 01 1994';'Jan 01 1996';'Jul 01 1997';'Jan 01 1999';'Jan 01 2006';'Jan 01 2009';'Jul 01 2012';'Jul 01 2015';'Jan 01 2017'], 'mmm dd yyyy');
        gps_zero_datenum = datenum('1980-01-06 00:00:00.000','yyyy-mm-dd HH:MM:SS.FFF');
        days_since_gps_zero = GPS_wk*7 + GPS_ms/1e3/60/60/24;
        recv_gps_datenum = gps_zero_datenum + days_since_gps_zero;
        leapseconds = 18;
        recv_utc_datenum = recv_gps_datenum - ((leapseconds)/60/60/24);
        GPS_date=datestr(recv_utc_datenum,'mmm-dd-yyyy');
        GPS_full_time=datestr(recv_utc_datenum,'HH:MM:SS.FFF');
        tempGPS_date = datetime(GPS_date,'InputFormat','MMM-dd-yyyy');
        tempGPS_time = datetime(GPS_full_time,'Format','HH:mm:ss.S');
        tempGPS_comb = tempGPS_date + timeofday(tempGPS_time);
        GPS_final = datetime(tempGPS_comb,'Format','MMM-dd-yyyy HH:mm:ss.S');
        % Output GPS table
        GPS = [GPS_LN, GPS_time, GPS_time_out, GPS_date, GPS_full_time, x, y, z, z_AGL, v_g];
        GPS_label = {'Line No','Time since boot (us)','Time from Arming (sec)','UTC Date','UTC Time','Lattitude','Longitude','Altitude (m, MSL)','Altitude (m, AGL)','Groundspeed (m/s)'};
        GPS_table = table(GPS_LN, GPS_time, GPS_time_out,tempGPS_date,tempGPS_time, x, y, z, z_AGL, v_g, 'VariableNames', {'Line Number','Time from boot (us)','Time from parse (sec)','UTC Date','UTC Time','Lat','Long','Altitude (m, MSL)','Altitude (m, AGL)','Groundspeed (m/s)'});
        
        % Parsed Attidue data output
        ATT_LN = ATT(TO_ATT:LND_ATT,1);
        ATT_time = ATT(TO_ATT:LND_ATT,2);
        ATT_time_out= (ATT_time-min(ATT_time))/1000000;
        ATT = [ATT_LN, ATT_time, ATT_time_out, rollAC, pitchAC, yawAC];
        ATT_label = {'Line No','Time since boot (us)','Time from Arming (sec)','Aircraft Roll (deg)','Aircraft Pitch (deg)','Aircraft Yaw (deg)'};
        ATT_table = table(ATT_LN,ATT_time,ATT_time_out, rollAC, pitchAC, yawAC, 'VariableNames', {'Line Number','Time from boot (us)','Time from parse (sec)','Aircraft Roll (deg)','Aircraft Pitch (deg)','Aircraft Yaw (deg, magnetic)'});
        
        if(strcmpi(arduPilotType,'ArduCopter') | strcmpi(arduPilotType,'CopterSonde'))
        else
            % Parsed CTUN data output
            CTUN_LN = CTUN(TO_CTUN:LND_CTUN,1);
            CTUN_time = CTUN(TO_CTUN:LND_CTUN,2);
            CTUN_time_out= (CTUN_time-min(CTUN_time))/1000000;
            CTUN = [CTUN_LN, CTUN_time, CTUN_time_out, v_a];
            CTUN_label = {'Line No','Time since boot (us)','Time from Arming (sec)','Airspeed (m/s)'};
            CTUN_table = table(CTUN_LN,CTUN_time,CTUN_time_out,v_a,'VariableNames',{'Line Number','Time from boot (us)','Time from parse (sec)','Airspeed (m/s)'});
        end
        
        if(strcmpi(arduPilotType,'CopterSonde'))
            % Parsed WIND (NKF2) data output
            NKF_LN = WIND(TO_WIND:LND_WIND,1);
            NKF_time = WIND(TO_WIND:LND_WIND,2);
            NKF_time_out= (NKF_time-min(NKF_time))/1000000;
            NKF2 = [NKF_LN, NKF_time, NKF_time_out, VWN, VWE];
            NKF2_label = {'Line No','Time since boot (us)','Time from Arming (sec)','North Wind Vector (m/s)','East Wind Vector (m/s)'};
            NKF2_table = table(NKF_LN, NKF_time, NKF_time_out, VWN, VWE, wind,'VariableNames',{'Line Number','Time from boot (us)','Time from parse (sec)','North Wind Vector (m/s)','East Wind Vector (m/s)','Wind Speed (m/s)'});
            
            IMET_LN = IMET(TO_IMET:LND_IMET,1);
            IMET_time = IMET(TO_IMET:LND_IMET,2);
            IMET_time_out= (IMET_time-min(IMET_time))/1000000;
            CSIMET_table = table(IMET_LN, IMET_time, IMET_time_out, IMET(TO_IMET:LND_IMET,3), IMET(TO_IMET:LND_IMET,4), IMET(TO_IMET:LND_IMET,5), IMET(TO_IMET:LND_IMET,6), IMET(TO_IMET:LND_IMET,7), IMET(TO_IMET:LND_IMET,8), IMET(TO_IMET:LND_IMET,9), IMET(TO_IMET:LND_IMET,10), IMET(TO_IMET:LND_IMET,11), IMET(TO_IMET:LND_IMET,12), IMET(TO_IMET:LND_IMET,13), IMET(TO_IMET:LND_IMET,14), IMET(TO_IMET:LND_IMET,15), IMET(TO_IMET:LND_IMET,16),'VariableNames',{'LineNo','TimeUS','Time from parse (sec)','RH1','RH2','RH3','RH4','T1','T2','T3','T4','Health1','Health2','Health3','Health4','Fan','DatenumUTC'});
            
        else
            % Parsed NKF2 data output
            NKF_LN = NKF2(TO_NKF:LND_NKF,1);
            NKF_time = NKF2(TO_NKF:LND_NKF,2);
            NKF_time_out= (NKF_time-min(NKF_time))/1000000;
            NKF2 = [NKF_LN, NKF_time, NKF_time_out, VWN, VWE];
            NKF2_label = {'Line No','Time since boot (us)','Time from Arming (sec)','North Wind Vector (m/s)','East Wind Vector (m/s)'};
            NKF2_table = table(NKF_LN, NKF_time, NKF_time_out, VWN, VWE, wind,'VariableNames',{'Line Number','Time from boot (us)','Time from parse (sec)','North Wind Vector (m/s)','East Wind Vector (m/s)','Wind Speed (m/s)'});
        end
        
        % Parsed RCOU data output
        RCOU_LN = RCOU(TO_RCOU:LND_RCOU,1);
        RCOU_time = RCOU(TO_RCOU:LND_RCOU,2);
        RCOU_pitch = RCOU(TO_RCOU:LND_RCOU,3);
        RCOU_roll = RCOU(TO_RCOU:LND_RCOU,4);
        RCOU_thr = RCOU(TO_RCOU:LND_RCOU,5);
        RCOU_yaw = RCOU(TO_RCOU:LND_RCOU,6);
        RCOU_time_out = (RCOU_time-min(RCOU_time))/1000000;
        RCOU = [RCOU_LN, RCOU_time, RCOU_time_out, RCOU_pitch, RCOU_roll, RCOU_thr, RCOU_yaw];
        RCOU_label = {'Line No','Time since boot (us)','Time from Arming (sec)','C1 - Pitch PWM',' C2 - Roll PWM','C3 - Throttle PWM','C4 - Yaw PWM'};
        RCOU_table = table(RCOU_LN, RCOU_time, RCOU_time_out, RCOU_pitch, RCOU_roll, thr,RCOU_thr, RCOU_yaw, 'VariableNames',{'Line Number','Time from boot (us)','Time from parse (sec)','Pitch PWM','Roll PWM','Throttle (%)','Throttle PWM','Yaw PWM'});
        
        % Parsed IMU data output
        IMU_LN = IMU(TO_IMU:LND_IMU,1);
        IMU_time = IMU(TO_IMU:LND_IMU,2);
        IMU_GyrX = IMU(TO_IMU:LND_IMU,3);
        IMU_GyrY = IMU(TO_IMU:LND_IMU,4);
        IMU_GyrZ = IMU(TO_IMU:LND_IMU,5);
        IMU_AccX = IMU(TO_IMU:LND_IMU,6);
        IMU_AccY = IMU(TO_IMU:LND_IMU,7);
        IMU_AccZ = IMU(TO_IMU:LND_IMU,8);
        IMU_time_out = (IMU_time-min(IMU_time))/1000000;
        IMU = [IMU_LN, IMU_time, IMU_time_out, IMU_GyrX, IMU_GyrY, IMU_GyrZ, IMU_AccX, IMU_AccY, IMU_AccZ];
        IMU_label = {'Line No','Time since boot (us)','Time from parse (sec)','X Gyro rotation (°/sec)','Y Gyro rotation (°/sec)','Z Gyro rotation (°/sec)','X Acceleration (°/sec/sec)','Y Acceleration (°/sec/sec)','Z Acceleration (°/sec/sec)'};
        IMU_table = table(IMU_LN,IMU_time,IMU_time_out,IMU_GyrX, IMU_GyrY, IMU_GyrZ, IMU_AccX, IMU_AccY, IMU_AccZ,'VariableNames',{'Line Number','Time from boot (us)','Time from parse (sec)','X Gyro rotation (°/sec)','Y Gyro rotation (°/sec)','Z Gyro rotation (°/sec)','X Acceleration (°/sec/sec)','Y Acceleration (°/sec/sec)','Z Acceleration (°/sec/sec)'});
        
        % Parsed Pixhawk barometric data
        BARO_LN = BARO(TO_BARO:LND_BARO,1);
        BARO_time = BARO(TO_BARO:LND_BARO,2);
        BARO_time_out = (BARO_time-min(BARO_time))/1000000;
        BARO_alt = BARO(TO_BARO:LND_BARO,3);
        BARO_press = BARO(TO_BARO:LND_BARO,4)/100;
        BARO = [BARO_LN, BARO_time, BARO_time_out, BARO_press, BARO_alt];
        BARO_label = {'Line No','Time since boot (us)','Time from parse (sec)','Barometric pressure (mbar)','Barometric Altitude (m, AGL)'};
        BARO_table = table(BARO_LN,BARO_time,BARO_time_out,BARO_press, BARO_alt,'VariableNames',{'Line Number','Time from boot (us)','Time from parse (sec)','Barometric pressure (mbar)','Barometric Altitude (m, AGL)'});
        
        % Get the name of the intput.mat file and save as input_parsed.mat
        baseFileName = sprintf('%s_Parsed.mat', baseNameNoExtDFL);
        fullParsedMatFileName = fullfile(folderDFL, baseFileName);
        app.LocationofOutputFilesEditField.Value = fullParsedMatFileName;
        % Save file with parsed data as the original filename plus the added portion
        
        if(strcmpi(arduPilotType,'ArduCopter'))
            save(fullParsedMatFileName,'ATT_table','GPS_table','NKF2_table','RCOU_table','BARO_table','IMU_table');
        elseif(strcmpi(arduPilotType,'CopterSonde'))
            save(fullParsedMatFileName,'ATT_table','GPS_table','NKF2_table','RCOU_table','BARO_table','IMU_table','CSIMET_table');
        else
            save(fullParsedMatFileName,'ATT_table','GPS_table','CTUN_table','NKF2_table','RCOU_table','BARO_table','IMU_table');
        end
    end
    %% CSV Output of GPS Data
    if (strcmpi(gpsOut,'Yes'))
        if(strcmpi(dflNewOld,'New'))
            % Get the name of the input.mat file and save as input_GPS.csv
            baseFileName = sprintf('%s_GPS.csv', baseNameNoExtDFL);
        elseif(strcmpi(dflNewOld,'Old'))
            % Get the name of the input.mat file and save as input_GPS_NS.csv
            baseFileName = sprintf('%s_GPS_NS.csv', baseNameNoExtDFL);
        end
        fullOutputMatFileName = fullfile(folderDFL, baseFileName);
        % Write data to text file
        writetable(GPS_table, fullOutputMatFileName);
    end
    %% Animation of Flight
    
    if(strcmpi(animateToggle, 'Yes'))
        % Get animation plot titles and output file names for animations
        if(strcmpi(animation,'Yes'))
            plotTitle = input('<strong>Enter Plot Title for animation function: </strong>','s');
            % Get the name of the intput.mat file and save as input_parsed.mat
            userFileName = input('<strong>Enter an output file name for the animation sequence to save as: </strong>','s');
            if(strcmpi(userFileName,''))
                userFileName = 'defaultAnimationOutput';
            end
            vidFileName = regexprep(userFileName, ' +', ' ');
            videoOutputFileName = fullfile(startingFolderDFL, vidFileName);
            
            animVid = VideoWriter(videoOutputFileName,'MPEG-4');
            animVid.FrameRate = animFrameRate;  %can adjust this, 5 - 10 works well for me
            animVid.Quality = 100;
        end

        if(strcmpi(isometric,'Yes'))
            %% Animation Setup
            
            if(strcmpi(plotTitle,''))
                plotTitle = 'Default';
            end
            
            Lat = table2array(GPS_table(:,6));
            Long = table2array(GPS_table(:,7));
            Alt = table2array(GPS_table(:,9));
            minAlt = min(Alt);
            if(minAlt<0)
                Alt=Alt+abs(min(Alt));
            elseif(minAlt>0)
                Alt=Alt-min(Alt);
            end
            
            fig10 = figure(10);
            fig10.Position=[130 130 800 600];
            fig10.Resize = 'off';
            
            xAnim1=[nan;Long(:,1)];
            yAnim1=[nan;Lat(:,1)];
            zAnim1=[nan;Alt(:,1)];
            
            lx = length(xAnim1);
            ly = length(yAnim1);
            lz = length(zAnim1);
            %% GPS Plot %%%%%%%%%%%%%
            ax2 = gca;
            xlim(ax2, [min(Long) max(Long)]);
            ylim(ax2, [min(Lat) max(Lat)]);
            zlim(ax2, [min(Alt) max(Alt)]);
            xl = xlabel('Longitude');
            yl = ylabel('Lattitude');
            zl = zlabel('Alt (m, AGL)');
            
            if(strcmpi(plotTitle,'Default'))
                plotTitle = baseNameNoExtDFL;
            end
            
            t = title({plotTitle,' '},'Interpreter', 'none');
            t.FontSize = 16;
            
            view(ax2, 3)
            xticks(min(Long):((max(Long)-min(Long))/4):max(Long));
            yticks(min(Lat):((max(Lat)-min(Lat))/4):max(Lat));
            zticks(min(Alt):((max(Alt)-min(Alt))/4):max(Alt));
            xtickformat('%.3f')
            ytickformat('%.3f')
            ztickformat('%.0f')
            grid
            set(ax2,'Color','k','xcolor','w','ycolor','w','zcolor','w','LineWidth',2)
            
            axis(ax2,[min(Long) max(Long) min(Lat) max(Lat) min(Alt) max(Alt)]);
            %% Set Axis Colors
            for i=1:length(ax2.XTickLabel)
                ax2.XTickLabel{i} = ['\color[rgb]{0,0,0}' ax2.XTickLabel{i}];
            end
            for j=1:length(ax2.YTickLabel)
                ax2.YTickLabel{j} = ['\color[rgb]{0,0,0}' ax2.YTickLabel{j}];
            end
            for k=1:length(ax2.ZTickLabel)
                ax2.ZTickLabel{k} = ['\color[rgb]{0,0,0}' ax2.ZTickLabel{k}];
            end
            
            
            xl.Color = 'k';
            yl.Color = 'k';
            zl.Color = 'k';
            %% Position Control
            subfig1 = get(gcf,'children');
            set(subfig1(1),'position',[.1 .075 .8 .8]);     % GPS animation space
            
            view(subfig1(1),-45,45);
            
            display('Beginning animation sequence');
            %% Animation Function
            if(strcmpi(recordAnimation,'Yes'));
                open(animVid);
                
                for i=1:animateSpeed:length(xAnim1);
                    
                    if(i<=(animateTailLength+1))
                        pH1 = geoplot(ax2,'XData',xAnim1(1:i),'YData',yAnim1(1:i),'ZData',zAnim1(1:i),'EdgeColor','r','FaceColor','none','LineWidth',animateTailWidth);
                        pH2 = geoplot(ax2,'XData',xAnim1(i),'YData',yAnim1(i),'ZData',zAnim1(i),'Marker','o','MarkerSize',animateHeadSize,'MarkerFaceColor','red','MarkerEdgeColor','none');
                    else
                        pH1 = geoplot(ax2,'XData',[nan; xAnim1((i-animateTailLength):i)],'YData',[nan; yAnim1((i-animateTailLength):i)],'ZData',[nan; zAnim1((i-animateTailLength):i)],'EdgeColor','r','FaceColor','none','LineWidth',animateTailWidth);
                        pH2 = geoplot(ax2,'XData',xAnim1(i),'YData',yAnim1(i),'ZData',zAnim1(i),'Marker','o','MarkerSize',animateHeadSize,'MarkerFaceColor','red','MarkerEdgeColor','none');
                    end
                    
                    pause(1/(50)) %Pause and grab frame
                    frame = getframe(gcf); %get frame
                    writeVideo(animVid, frame);
                    cla(ax2);
                    
                end
                
                close(animVid);
            else
                for i=1:animateSpeed:length(xAnim1);
                    
                    if(i<=(animateTailLength+1))
                        pH1 = patch(ax2,'XData',xAnim1(1:i),'YData',yAnim1(1:i),'ZData',zAnim1(1:i),'EdgeColor','r','FaceColor','none','LineWidth',animateTailWidth);
                        pH2 = patch(ax2,'XData',xAnim1(i),'YData',yAnim1(i),'ZData',zAnim1(i),'Marker','o','MarkerSize',animateHeadSize,'MarkerFaceColor','red','MarkerEdgeColor','none');
                    else
                        pH1 = patch(ax2,'XData',[nan; xAnim1((i-animateTailLength):i)],'YData',[nan; yAnim1((i-animateTailLength):i)],'ZData',[nan; zAnim1((i-animateTailLength):i)],'EdgeColor','r','FaceColor','none','LineWidth',animateTailWidth);
                        pH2 = patch(ax2,'XData',xAnim1(i),'YData',yAnim1(i),'ZData',zAnim1(i),'Marker','o','MarkerSize',animateHeadSize,'MarkerFaceColor','red','MarkerEdgeColor','none');
                    end
                    
                    pause(1/(50)) %Pause and grab frame
                    
                    delete(findall(fig10,'type','annotation'));
                    cla(ax2);
                    
                end
            end
        else
            %% Animation Setup
            
            if(strcmpi(plotTitle,''))
                plotTitle = 'Default';
            end
            
            Lat = table2array(GPS_table(:,6));
            Long = table2array(GPS_table(:,7));
            Alt = table2array(GPS_table(:,9));
            minAlt = min(Alt);
            if(minAlt<0)
                Alt=Alt+abs(min(Alt));
            elseif(minAlt>0)
                Alt=Alt-min(Alt);
            end
            
            fig10 = figure(10);
            fig10.Position=[130 130 800 600];
            fig10.Resize = 'off';
            
            xAnim1=[nan;Long(:,1)];
            yAnim1=[nan;Lat(:,1)];
            zAnim1=[nan;Alt(:,1)];
            
            lx = length(xAnim1);
            ly = length(yAnim1);
            lz = length(zAnim1);
            %% USGS Mapping Data
            baseURL = "https://basemap.nationalmap.gov/ArcGIS/rest/services";
            usgsURL = baseURL + "/BASEMAP/MapServer/tile/${z}/${y}/${x}";
            basemaps = ["USGSImageryOnly" "USGSImageryTopo" "USGSTopo" "USGSShadedReliefOnly" "USGSHydroCached"];
            displayNames = ["USGS Imagery" "USGS Topographic Imagery" "USGS Shaded Topographic Map" "USGS Shaded Relief" "USGS Hydrography"];
            attribution = 'Credit: U.S. Geological Survey';
            %% GPS Plot %%%%%%%%%%%%%
            % GPS Plotting data
            ax2 = geoaxes();
            geobasemap('satellite')
            basemapx = basemaps(2);
            url = replace(usgsURL,"BASEMAP",basemapx);
            view(ax2,2)
            
            if(strcmpi(plotTitle,'Default'))
                plotTitle = baseNameNoExtDFL;
            end
            
            t = title({plotTitle,' '},'Interpreter', 'none');
            t.FontSize = 16;
            
            display('Beginning animation sequence');
            %% Animation Function
            if(strcmpi(recordAnimation,'Yes'));
                open(animVid);
                
                for i=1:animateSpeed:length(xAnim1);
                    
                    if(i<=(animateTailLength+1))
                        hold on
                        pH1 = geoplot(ax2,yAnim1(1:i),xAnim1(1:i),'r','LineWidth',animateTailWidth);
                        pH2 = geoplot(ax2,yAnim1(i),xAnim1(i),'Marker','o','MarkerSize',animateHeadSize,'MarkerFaceColor','red','MarkerEdgeColor','none');
                    else
                        hold on
                        pH1 = geoplot(ax2,[nan; yAnim1((i-animateTailLength):i)],[nan; xAnim1((i-animateTailLength):i)],'r','LineWidth',animateTailWidth);
                        pH2 = geoplot(ax2,yAnim1(i),xAnim1(i),'Marker','o','MarkerSize',animateHeadSize,'MarkerFaceColor','red','MarkerEdgeColor','none');
                    end
                    
                    geobasemap('satellite')
                    geolimits([min(yAnim1)-.0005 max(yAnim1)+.0005],[min(xAnim1)-.0005 max(xAnim1)+.0005]);
                    
                    pause(1/(50)) %Pause and grab frame
                    frame = getframe(gcf); %get frame
                    writeVideo(animVid, frame);
                    cla(ax2);
                    hold off
                    
                end
                
                close(animVid);
            else
                for i=1:animateSpeed:length(xAnim1);
                    
                    if(i<=(animateTailLength+1))
                        hold on
                        pH1 = geoplot(ax2,yAnim1(1:i),xAnim1(1:i),'r','LineWidth',animateTailWidth);
                        pH2 = geoplot(ax2,yAnim1(i),xAnim1(i),'Marker','o','MarkerSize',animateHeadSize,'MarkerFaceColor','red','MarkerEdgeColor','none');
                    else
                        hold on
                        pH1 = geoplot(ax2,[nan; yAnim1((i-animateTailLength):i)],[nan; xAnim1((i-animateTailLength):i)],'r','LineWidth',animateTailWidth);
                        pH2 = geoplot(ax2,yAnim1(i),xAnim1(i),'Marker','o','MarkerSize',animateHeadSize,'MarkerFaceColor','red','MarkerEdgeColor','none');
                    end
                    
                    geobasemap('satellite')
                    geolimits([min(yAnim1)-.0005 max(yAnim1)+.0005],[min(xAnim1)-.0005 max(xAnim1)+.0005]);
                    
                    pause(1/(50)) %Pause and grab frame
                    cla(ax2);
                    hold off
                end
            end
        end
    end
end

disp('All operations completed.');
