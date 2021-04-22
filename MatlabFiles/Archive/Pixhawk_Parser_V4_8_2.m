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
tripleAnimateTPH = 'No';      % Side-by-side T, P, and H plots against GPS position
graphToggle = 'Yes';          % Show plots of parsed data
animateToggle = 'No';         % Flight animation based on GPS and Alt(AGL)
recordAnimation = 'No';       % Record animation for future playback
hoverProfile = 'None';      % Profile (vertical) or Hover (stationary) averaging
stateSpace = 'No';            % Pixhawk recorded SS variable output (new file)
iMetValue = 'No';             % Load iMet data (XQ1 - small | XQ2 - large)
mhpValue = 'Yes';             % Load 5HP/TPH data (use 5HP)
tphValue = 'Yes';             % Load 5HP/TPH data (use TPH)
overlay = 'No';              % Show iMet & 5HP/TPH alongside Pixhawk data plots
gpsOut = 'No';               % Output GPS data as individual file (lat, long, alt)
sensorOut = 'No';            % Output parsed sensor data (iMet seperate from 5HP/TPH)
attitudeOut = 'No';          % Output parsed attitude data
sensorCompare = 'No';        % Show iMet, 5HP/TPH, and Pixhawk atmoshperic sensors on same plots
dflNewOld = 'Unknown';
arduPilotType = 'Default';
pitchToggle = 'No';            % TIA-Specific
throttleToggle = 'No';         % TIA-Specific
aircraft = 'N/A';              % TIA-Specific
tvToggle = 'No';               % TIA-Specific
indvToggle = 'No';             % TIA-Specific
    
% Only used for Single Animation
animateSpeed = 5;             % Overall speed
animateHeadSize = 2;           % Icon size
animateTailWidth = 1;          % Width of tail
animateTailLength = 100;       % Length of tail
animateFPS = 30;
animateHeadSize = animateHeadSize + 5;
plotTitle = '';

% Multi Controls
   
% Only used for Multi Animation
animation = 'No';        % Default: Yes | Yes: turn on animation | No: turn Off
simultaneous = 'No';     % Default: Yes | Yes: Files in same time frame | No: Files in concurrent time frames
isometric = 'No';        % Default: Yes | Yes: view in 3D space | No: view in 2D with Satellite map overlay
azimuthAngle = 45;        % Default: 45 | Rotation angle in x-y plane to view the 3D plot (positive values -> CCW rotation, negative CW)
elevationAngle = 15;      % Default: 15 | Elevation angle above the X-Y plane (90 is top down X-Y plot, 0 is looking from the X-Y plane depending on azimuthAngle)
iterationSkip = 5;       % Default: 5  | High numbers: increase animation speed, reduce smoothness. If increasing, decrease animFrameRate to have useful video time
animFrameRate = 30;       % Default: 30 | High numbers: increase animation speed, increase smoothness. If increasing, decrease iteration_skip to have useful video time

% Get animation plot titles and output file names for animations
if(strcmpi(animateToggle,'Yes') | strcmpi(animation,'Yes'))
    plotTitle = input('<strong>Enter Plot Title for animation function: </strong>','s');
    % Get the name of the intput.mat file and save as input_parsed.mat
    userFileName = input('<strong>Enter an output file name for the animation sequence to save as: </strong>','s');
    if(strcmpi(userFileName,''))
        userFileName = 'defaultAnimationOutput';
    end
    vidFileName = regexprep(userFileName, ' +', ' ');
    videoOutputFileName = fullfile(folder, vidFileName);
    
    animVid = VideoWriter(videoOutputFileName,'MPEG-4');
    animVid.FrameRate = animFrameRate;  %can adjust this, 5 - 10 works well for me
    animVid.Quality = 100;
end
if(strcmpi(plotTitle,''))
       plotTitle = 'Default'; 
end

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
    %% Pixhawk bin->mat Converter
    if(strcmpi(baseFileNameDFL((end-2):end),'bin'))
        DFL_NewOld = 'New';
        
        rawDFL = Ardupilog(fullInputMatFileNameDFL);
        %% Check if CopterSonde or Standard DFL file
        Rover = 0;
        Copter = 0;
        QuadPlane = 0;
        Plane = 0;
        
        %% ArduPilotType Parser (MSG1)
        for i=1:length(rawDFL.MSG.LineNo);
            MSG1{1,i}{1,1} = 'MSG';
            MSG1{1,i}{2,1} = rawDFL.MSG.TimeUS(i);
            MSG1{1,i}{3,1} = rawDFL.MSG.Message(i,1:length(rawDFL.MSG.Message(1,:)));
            if(contains(rawDFL.MSG.Message(i,1:length(rawDFL.MSG.Message(1,:))),'ArduCopter'))
                Copter = 1;
            elseif(contains(rawDFL.MSG.Message(i,1:length(rawDFL.MSG.Message(1,:))),'QuadPlane'))
                QuadPlane = 1;
            elseif(contains(rawDFL.MSG.Message(i,1:length(rawDFL.MSG.Message(1,:))),'ArduRover'))
                Rover = 1;
            elseif(contains(rawDFL.MSG.Message(i,1:length(rawDFL.MSG.Message(1,:))),'ArduPlane'))
                Plane = 1;
            end
        end
        
        if(Rover == 1)
            arduPilotType = 'ArduRover';
        elseif(Copter == 1)
            arduPilotType = 'ArduCopter';
        elseif(QuadPlane == 1)
            arduPilotType = 'QuadPlane';
        elseif(Plane == 1)
            arduPilotType = 'FixedWing';
        end
        
        if(strcmpi(arduPilotType,'FixedWing') | strcmpi(arduPilotType,'QuadPlane'))
            
            %% GPS
            GPS(:,1) = rawDFL.GPS.LineNo;
            GPS(:,2) = fix(rawDFL.GPS.TimeS/rawDFL.GPS.fieldMultipliers.TimeUS);
            GPS(:,3) = rawDFL.GPS.Status;
            GPS(:,4) = rawDFL.GPS.GMS;
            GPS(:,5) = rawDFL.GPS.GWk;
            GPS(:,6) = rawDFL.GPS.NSats;
            GPS(:,7) = rawDFL.GPS.HDop;
            GPS(:,8) = rawDFL.GPS.Lat;
            GPS(:,9) = rawDFL.GPS.Lng;
            GPS(:,10) = rawDFL.GPS.Alt;
            GPS(:,11) = rawDFL.GPS.Spd;
            GPS(:,12) = rawDFL.GPS.GCrs;
            GPS(:,13) = rawDFL.GPS.VZ;
            GPS(:,14) = rawDFL.GPS.Yaw;
            GPS(:,15) = rawDFL.GPS.U;
            GPS(:,16) = rawDFL.GPS.DatenumUTC;
            GPS_label = {'LineNo';'TimeUS';'Status';'GMS';'GWk';'NSats';'HDop';'Lat';'Lng';'Alt';'Spd';'GCrs';'VZ';'Yaw';'U';'DatenumUTC'};
            %% ATT
            ATT(:,1) = rawDFL.ATT.LineNo;
            ATT(:,2) = fix(rawDFL.ATT.TimeS/rawDFL.ATT.fieldMultipliers.TimeUS);
            ATT(:,3) = rawDFL.ATT.DesRoll;
            ATT(:,4) = rawDFL.ATT.Roll;
            ATT(:,5) = rawDFL.ATT.DesPitch;
            ATT(:,6) = rawDFL.ATT.Pitch;
            ATT(:,7) = rawDFL.ATT.DesYaw;
            ATT(:,8) = rawDFL.ATT.Yaw;
            ATT(:,9) = rawDFL.ATT.ErrRP;
            ATT(:,10) = rawDFL.ATT.ErrYaw;
            ATT(:,11) = rawDFL.ATT.DatenumUTC;
            ATT_label = {'LineNo';'TimeUS';'DesRoll';'Roll';'DesPitch';'Pitch';'DesYaw';'Yaw';'ErrRP';'ErrYaw';'DatenumUTC'};
            %% BARO
            BARO(:,1) = rawDFL.BARO.LineNo;
            BARO(:,2) = fix(rawDFL.BARO.TimeS/rawDFL.BARO.fieldMultipliers.TimeUS);
            BARO(:,3) = rawDFL.BARO.Alt;
            BARO(:,4) = rawDFL.BARO.Press;
            BARO(:,5) = rawDFL.BARO.Temp;
            BARO(:,6) = rawDFL.BARO.CRt;
            BARO(:,7) = rawDFL.BARO.SMS;
            BARO(:,8) = rawDFL.BARO.Offset;
            BARO(:,9) = rawDFL.BARO.GndTemp;
            BARO(:,10) = rawDFL.BARO.Health;
            BARO(:,11) = rawDFL.BARO.DatenumUTC;
            BARO_label = {'LineNo';'TimeUS';'Alt';'Press';'Temp';'CRt';'SMS';'Offset';'GndTemp';'Health';'DatenumUTC'};
            %% CTUN
            CTUN(:,1) = rawDFL.CTUN.LineNo;
            CTUN(:,2) = fix(rawDFL.CTUN.TimeS/rawDFL.CTUN.fieldMultipliers.TimeUS);
            CTUN(:,3) = rawDFL.CTUN.NavRoll;
            CTUN(:,4) = rawDFL.CTUN.Roll;
            CTUN(:,5) = rawDFL.CTUN.NavPitch;
            CTUN(:,6) = rawDFL.CTUN.Pitch;
            CTUN(:,7) = rawDFL.CTUN.ThrOut;
            CTUN(:,8) = rawDFL.CTUN.RdrOut;
            CTUN(:,9) = rawDFL.CTUN.ThrDem;
            CTUN(:,10) = rawDFL.CTUN.Aspd;
            CTUN(:,11) = rawDFL.CTUN.DatenumUTC;
            CTUN_label = {'LineNo';'TimeUS';'NavRoll';'Roll';'NavPitch';'Pitch';'ThrOut';'RdrOut';'ThrDem';'Aspd';'DatenumUTC'};
            %% NKF2
            try
                NKF2(:,1) = rawDFL.NKF2.LineNo;
                NKF2(:,2) = fix(rawDFL.NKF2.TimeS/rawDFL.NKF2.fieldMultipliers.TimeUS);
                NKF2(:,3) = rawDFL.NKF2.AZbias;
                NKF2(:,4) = rawDFL.NKF2.GSX;
                NKF2(:,5) = rawDFL.NKF2.GSY;
                NKF2(:,6) = rawDFL.NKF2.GSZ;
                NKF2(:,7) = rawDFL.NKF2.VWN;
                NKF2(:,8) = rawDFL.NKF2.VWE;
                NKF2(:,9) = rawDFL.NKF2.MN;
                NKF2(:,10) = rawDFL.NKF2.ME;
                NKF2(:,11) = rawDFL.NKF2.MD;
                NKF2(:,12) = rawDFL.NKF2.MX;
                NKF2(:,13) = rawDFL.NKF2.MY;
                NKF2(:,14) = rawDFL.NKF2.MZ;
                NKF2(:,15) = rawDFL.NKF2.MI;
                NKF2(:,16) = rawDFL.NKF2.DatenumUTC;
                NKF2_label = {'LineNo';'TimeUS';'AZbias';'GSX';'GSY';'GSZ';'VWN';'VWE';'MN';'ME';'MD';'MX';'MY';'MZ';'MI';'DatenumUTC'};
                
            catch
                NKF2_label = {'LineNo';'TimeUS';'AZbias';'GSX';'GSY';'GSZ';'VWN';'VWE';'MN';'ME';'MD';'MX';'MY';'MZ';'MI';'DatenumUTC'};
            end
            %% XKF2
            try
                XKF2(:,1) = rawDFL.XKF2.LineNo;
                XKF2(:,2) = fix(rawDFL.NKF2.TimeS/rawDFL.XKF2.fieldMultipliers.TimeUS);
                XKF2(:,3) = rawDFL.XKF2.AX;
                XKF2(:,4) = rawDFL.XKF2.AY;
                XKF2(:,5) = rawDFL.XKF2.AZ;
                XKF2(:,6) = rawDFL.XKF2.VWN;
                XKF2(:,7) = rawDFL.XKF2.VWE;
                XKF2(:,8) = rawDFL.XKF2.MN;
                XKF2(:,9) = rawDFL.XKF2.ME;
                XKF2(:,10) = rawDFL.XKF2.MD;
                XKF2(:,11) = rawDFL.XKF2.MX;
                XKF2(:,12) = rawDFL.XKF2.MY;
                XKF2(:,13) = rawDFL.XKF2.MZ;
                XKF2(:,14) = rawDFL.XKF2.MI;
                XKF2(:,15) = rawDFL.XKF2.DatenumUTC;
                XKF2_label = {'LineNo';'TimeUS';'AX';'AY';'AZ';'VWN';'VWE';'MN';'ME';'MD';'MX';'MY';'MZ';'MI';'DatenumUTC'};
                
            catch
                XKF2_label = {'LineNo';'TimeUS';'AX';'AY';'AZ';'VWN';'VWE';'MN';'ME';'MD';'MX';'MY';'MZ';'MI';'DatenumUTC'};
            end
            %% RCOU
            RCOU(:,1) = rawDFL.RCOU.LineNo;
            RCOU(:,2) = fix(rawDFL.RCOU.TimeS/rawDFL.RCOU.fieldMultipliers.TimeUS);
            RCOU(:,3) = rawDFL.RCOU.C1;
            RCOU(:,4) = rawDFL.RCOU.C2;
            RCOU(:,5) = rawDFL.RCOU.C3;
            RCOU(:,6) = rawDFL.RCOU.C4;
            RCOU(:,7) = rawDFL.RCOU.C5;
            RCOU(:,8) = rawDFL.RCOU.C6;
            RCOU(:,9) = rawDFL.RCOU.C7;
            RCOU(:,10) = rawDFL.RCOU.C8;
            RCOU(:,11) = rawDFL.RCOU.C9;
            RCOU(:,12) = rawDFL.RCOU.C10;
            RCOU(:,13) = rawDFL.RCOU.C11;
            RCOU(:,14) = rawDFL.RCOU.C12;
            RCOU(:,15) = rawDFL.RCOU.C13;
            RCOU(:,16) = rawDFL.RCOU.C14;
            RCOU(:,17) = rawDFL.RCOU.DatenumUTC;
            RCOU_label = {'LineNo';'TimeUS';'C1';'C2';'C3';'C4';'C5';'C6';'C7';'C8';'C9';'C10';'C11';'C12';'C13';'C14';'DatenumUTC'};
            %% IMU
            IMU(:,1) = rawDFL.IMU.LineNo;
            IMU(:,2) = fix(rawDFL.IMU.TimeS/rawDFL.IMU.fieldMultipliers.TimeUS);
            IMU(:,3) = rawDFL.IMU.GyrX;
            IMU(:,4) = rawDFL.IMU.GyrY;
            IMU(:,5) = rawDFL.IMU.GyrZ;
            IMU(:,6) = rawDFL.IMU.AccX;
            IMU(:,7) = rawDFL.IMU.AccY;
            IMU(:,8) = rawDFL.IMU.AccZ;
            IMU(:,9) = rawDFL.IMU.EG;
            IMU(:,10) = rawDFL.IMU.EA;
            IMU(:,11) = rawDFL.IMU.T;
            IMU(:,12) = rawDFL.IMU.GH;
            IMU(:,13) = rawDFL.IMU.AH;
            IMU(:,14) = rawDFL.IMU.GHz;
            IMU(:,15) = rawDFL.IMU.AHz;
            IMU(:,16) = rawDFL.IMU.DatenumUTC;
            IMU_label = {'LineNo';'TimeUS';'GyrX';'GyrY';'GyrZ';'AccX';'AccY';'AccZ';'EG';'EA';'T';'GH';'AH';'GHz';'AHz';'DatenumUTC'};
            
            % Save as new file for integration with normal code
            [~, baseNameNoExtDFL, ~] = fileparts(baseFileNameDFL);
            baseFileName = sprintf('%s.mat', baseNameNoExtDFL);
            fullParsedMatFileName = fullfile(folderDFL, baseFileName);
            % Save file with parsed data as the original filename plus the added portion
            save(fullParsedMatFileName,'GPS','GPS_label','ATT','ATT_label','BARO','BARO_label','CTUN','CTUN_label','NKF2','NKF2_label','XKF2','XKF2_label','IMU','IMU_label','RCOU','RCOU_label','MSG1');
            
            fullInputMatFileNameDFL = fullParsedMatFileName;
            
        elseif(strcmpi(arduPilotType,'ArduCopter') | strcmpi(arduPilotType,'CopterSonde'))
            
            try
                rawDFL.IMET;
                arduPilotType = 'CopterSonde';
                %% WIND
                WIND(:,1) = rawDFL.WIND.LineNo;
                WIND(:,2) = rawDFL.WIND.Time;
                WIND(:,3) = rawDFL.WIND.wdir;
                WIND(:,4) = rawDFL.WIND.wspeed;
                WIND(:,5) = rawDFL.WIND.R13;
                WIND(:,6) = rawDFL.WIND.R23;
                WIND(:,7) = rawDFL.WIND.R33;
                WIND(:,8) = rawDFL.WIND.DatenumUTC;
                WIND_label = {'LineNo';'TimeUS';'wdir';'wspeed';'R13';'R23';'R33';'DatenumUTC'};
                %% IMET
                IMET(:,1) = rawDFL.IMET.LineNo;
                IMET(:,2) = rawDFL.IMET.Time;
                IMET(:,3) = rawDFL.IMET.R1./100;
                IMET(:,4) = rawDFL.IMET.R2./100;
                IMET(:,5) = rawDFL.IMET.R3./100;
                IMET(:,6) = rawDFL.IMET.R4./100;
                IMET(:,7) = rawDFL.IMET.T1;
                IMET(:,8) = rawDFL.IMET.T2;
                IMET(:,9) = rawDFL.IMET.T3;
                IMET(:,10) = rawDFL.IMET.T4;
                IMET(:,11) = rawDFL.IMET.Hth1;
                IMET(:,12) = rawDFL.IMET.Hth2;
                IMET(:,13) = rawDFL.IMET.Hth3;
                IMET(:,14) = rawDFL.IMET.Hth4;
                IMET(:,15) = rawDFL.IMET.Fan;
                IMET(:,16) = rawDFL.IMET.DatenumUTC;
                IMET_label = {'LineNo';'TimeUS';'RH1';'RH2';'RH3';'RH4';'T1';'T2';'T3';'T4';'Health1';'Health2';'Health3';'Health4';'Fan';'DatenumUTC'};
            end
            
            %% GPS
            GPS(:,1) = rawDFL.GPS.LineNo;
            GPS(:,2) = rawDFL.GPS.TimeUS;
            GPS(:,3) = rawDFL.GPS.Status;
            GPS(:,4) = rawDFL.GPS.GMS;
            GPS(:,5) = rawDFL.GPS.GWk;
            GPS(:,6) = rawDFL.GPS.NSats;
            GPS(:,7) = rawDFL.GPS.HDop;
            GPS(:,8) = rawDFL.GPS.Lat;
            GPS(:,9) = rawDFL.GPS.Lng;
            GPS(:,10) = rawDFL.GPS.Alt;
            GPS(:,11) = rawDFL.GPS.Spd;
            GPS(:,12) = rawDFL.GPS.GCrs;
            GPS(:,13) = rawDFL.GPS.VZ;
            GPS(:,14) = rawDFL.GPS.U;
            GPS(:,15) = rawDFL.GPS.DatenumUTC;
            GPS_label = {'LineNo';'TimeUS';'Status';'GMS';'GWk';'NSats';'HDop';'Lat';'Lng';'Alt';'Spd';'GCrs';'VZ';'U';'DatenumUTC'};
            %% ATT
            ATT(:,1) = rawDFL.ATT.LineNo;
            ATT(:,2) = rawDFL.ATT.TimeUS;
            ATT(:,3) = rawDFL.ATT.DesRoll;
            ATT(:,4) = rawDFL.ATT.Roll;
            ATT(:,5) = rawDFL.ATT.DesPitch;
            ATT(:,6) = rawDFL.ATT.Pitch;
            ATT(:,7) = rawDFL.ATT.DesYaw;
            ATT(:,8) = rawDFL.ATT.Yaw;
            ATT(:,9) = rawDFL.ATT.ErrRP;
            ATT(:,10) = rawDFL.ATT.ErrYaw;
            ATT(:,11) = rawDFL.ATT.DatenumUTC;
            ATT_label = {'LineNo';'TimeUS';'DesRoll';'Roll';'DesPitch';'Pitch';'DesYaw';'Yaw';'ErrRP';'ErrYaw';'DatenumUTC'};
            %% BARO
            BARO(:,1) = rawDFL.BARO.LineNo;
            BARO(:,2) = rawDFL.BARO.TimeUS;
            BARO(:,3) = rawDFL.BARO.Alt;
            BARO(:,4) = rawDFL.BARO.Press;
            BARO(:,5) = rawDFL.BARO.Temp;
            BARO(:,6) = rawDFL.BARO.CRt;
            BARO(:,7) = rawDFL.BARO.SMS;
            BARO(:,8) = rawDFL.BARO.Offset;
            BARO(:,9) = rawDFL.BARO.GndTemp;
            BARO(:,10) = rawDFL.BARO.DatenumUTC;
            BARO_label = {'LineNo';'TimeUS';'Alt';'Press';'Temp';'CRt';'SMS';'Offset';'GndTemp';'DatenumUTC'};
            %% RCOU
            RCOU(:,1) = rawDFL.RCOU.LineNo;
            RCOU(:,2) = rawDFL.RCOU.TimeUS;
            RCOU(:,3) = rawDFL.RCOU.C1;
            RCOU(:,4) = rawDFL.RCOU.C2;
            RCOU(:,5) = rawDFL.RCOU.C3;
            RCOU(:,6) = rawDFL.RCOU.C4;
            RCOU(:,7) = rawDFL.RCOU.C5;
            RCOU(:,8) = rawDFL.RCOU.C6;
            RCOU(:,9) = rawDFL.RCOU.C7;
            RCOU(:,10) = rawDFL.RCOU.C8;
            RCOU(:,11) = rawDFL.RCOU.C9;
            RCOU(:,12) = rawDFL.RCOU.C10;
            RCOU(:,13) = rawDFL.RCOU.C11;
            RCOU(:,14) = rawDFL.RCOU.C12;
            RCOU(:,15) = rawDFL.RCOU.C13;
            RCOU(:,16) = rawDFL.RCOU.C14;
            RCOU(:,17) = rawDFL.RCOU.DatenumUTC;
            RCOU_label = {'LineNo';'TimeUS';'C1';'C2';'C3';'C4';'C5';'C6';'C7';'C8';'C9';'C10';'C11';'C12';'C13';'C14';'DatenumUTC'};
            %% IMU
            IMU(:,1) = rawDFL.IMU.LineNo;
            IMU(:,2) = rawDFL.IMU.TimeUS;
            IMU(:,3) = rawDFL.IMU.GyrX;
            IMU(:,4) = rawDFL.IMU.GyrY;
            IMU(:,5) = rawDFL.IMU.GyrZ;
            IMU(:,6) = rawDFL.IMU.AccX;
            IMU(:,7) = rawDFL.IMU.AccY;
            IMU(:,8) = rawDFL.IMU.AccZ;
            IMU(:,9) = rawDFL.IMU.EG;
            IMU(:,10) = rawDFL.IMU.EA;
            IMU(:,11) = rawDFL.IMU.T;
            IMU(:,12) = rawDFL.IMU.GH;
            IMU(:,13) = rawDFL.IMU.AH;
            IMU(:,14) = rawDFL.IMU.GHz;
            IMU(:,15) = rawDFL.IMU.AHz;
            IMU(:,16) = rawDFL.IMU.DatenumUTC;
            IMU_label = {'LineNo';'TimeUS';'GyrX';'GyrY';'GyrZ';'AccX';'AccY';'AccZ';'EG';'EA';'T';'GH';'AH';'GHz';'AHz';'DatenumUTC'};
            %% NKF2
            try
                NKF2(:,1) = rawDFL.NKF2.LineNo;
                NKF2(:,2) = fix(rawDFL.NKF2.TimeS/rawDFL.NKF2.fieldMultipliers.TimeUS);
                NKF2(:,3) = rawDFL.NKF2.AZbias;
                NKF2(:,4) = rawDFL.NKF2.GSX;
                NKF2(:,5) = rawDFL.NKF2.GSY;
                NKF2(:,6) = rawDFL.NKF2.GSZ;
                NKF2(:,7) = rawDFL.NKF2.VWN;
                NKF2(:,8) = rawDFL.NKF2.VWE;
                NKF2(:,9) = rawDFL.NKF2.MN;
                NKF2(:,10) = rawDFL.NKF2.ME;
                NKF2(:,11) = rawDFL.NKF2.MD;
                NKF2(:,12) = rawDFL.NKF2.MX;
                NKF2(:,13) = rawDFL.NKF2.MY;
                NKF2(:,14) = rawDFL.NKF2.MZ;
                NKF2(:,15) = rawDFL.NKF2.MI;
                NKF2(:,16) = rawDFL.NKF2.DatenumUTC;
                NKF2_label = {'LineNo';'TimeUS';'AZbias';'GSX';'GSY';'GSZ';'VWN';'VWE';'MN';'ME';'MD';'MX';'MY';'MZ';'MI';'DatenumUTC'};
                
            catch
                NKF2_label = {'LineNo';'TimeUS';'AZbias';'GSX';'GSY';'GSZ';'VWN';'VWE';'MN';'ME';'MD';'MX';'MY';'MZ';'MI';'DatenumUTC'};
            end
            
            
            % Save asnew file for integration with normal code
            [~, baseNameNoExtDFL, ~] = fileparts(baseFileNameDFL);
            baseFileName = sprintf('%s.mat', baseNameNoExtDFL);
            fullParsedMatFileName = fullfile(folderDFL, baseFileName);
            % Save file with parsed data as the original filename plus the added portion
            
            if(strcmpi(arduPilotType,'ArduCopter'))
                save(fullParsedMatFileName,'GPS','GPS_label','ATT','ATT_label','BARO','BARO_label','NKF2','NKF2_label','IMU','IMU_label','RCOU','RCOU_label','MSG1');
            elseif(strcmpi(arduPilotType,'CopterSonde'))
                save(fullParsedMatFileName,'GPS','GPS_label','WIND','WIND_label','IMET','IMET_label','ATT','ATT_label','BARO','BARO_label','NKF2','NKF2_label','IMU','IMU_label','RCOU','RCOU_label','MSG1');
            end
            fullInputMatFileNameDFL = fullParsedMatFileName;
        end
    end
    %% Gather Additional Files
    variableInfo = who('-file',fullInputMatFileNameDFL);
    
    if(length(variableInfo)<20 && strcmpi(DFL_NewOld,'Unknown') && ismember('GPS_table',variableInfo))
        
        
        load(fullInputMatFileNameDFL);
        DFL_NewOld = 'Old';
        
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
        DFL_NewOld = 'New';
        
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
    if(strcmpi(DFL_NewOld,'New'))
        
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
    if(strcmpi(DFL_NewOld,'New'))
        
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
    if(strcmpi(DFL_NewOld,'New'))
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
    %% iMet Data Parsing and Output
    if(strcmpi(DFL_NewOld,'New'))
        if (strcmpi(iMetValue,'Yes'))
            
            % Get the name of the file that the user wants to use.
            defaultFileNameiMet = fullfile(startingFolderDFL, '*.csv');
            [baseFileNameiMet, folderiMet] = uigetfile(defaultFileNameiMet, 'Select an iMet .CSV file');
            if baseFileNameiMet == 0
                % User clicked the Cancel button.
                return;
            end
            
            % Get the name of the input .mat file.
            fullInputMatFileNameiMet = fullfile(folderiMet, baseFileNameiMet);
            % Get filename without the extension, used by Save Function
            [~, baseNameNoExtiMet, ~] = fileparts(baseFileNameiMet);
            % Load file in
            iMetData_temp = readtable(fullInputMatFileNameiMet);
            iMetData = iMetData_temp(2:end,:);
            clear iMetData_temp
            
            dataLen = width(iMetData);
            
            if(dataLen == 46)
                % Convert CSV data to general table to datetime array
                iMet_date_ref = iMetData(:,40);
                iMet_date_conv = table2array(iMet_date_ref);
                iMet_date = datetime(iMet_date_conv,'InputFormat','yyyy/MM/dd','Format','MMM-dd-yyyy');
                iMet_time_ref = iMetData(:,41);
                iMet_time_conv = table2array(iMet_time_ref);
                iMet_time = datetime(datevec(iMet_time_conv),'Format','HH:mm:ss');
                Pix_time = GPS(:,3);
                
            elseif(dataLen == 47)
                % Convert CSV data to general table to datetime array
                iMet_date_ref = iMetData(:,41);
                iMet_date_conv = table2array(iMet_date_ref);
                iMet_date = datetime(iMet_date_conv,'InputFormat','yyyy/MM/dd','Format','MMM-dd-yyyy');
                iMet_time_ref = iMetData(:,42);
                iMet_time_conv = table2array(iMet_time_ref);
                iMet_time = datetime(datevec(iMet_time_conv),'Format','HH:mm:ss');
                Pix_time = GPS(:,3);
            end
            
            % Convert datetime arrays into datetime vectors
            [iM_y, iM_m, iM_d] = datevec(iMet_date(:,1));
            [ no, no, no,iM_h, iM_M, iM_s] = datevec(iMet_time);
            iM_vec = [iM_y iM_m iM_d iM_h iM_M iM_s];
            
            GPS_vec = datevec(GPS_final);
            
            % Convert datetime vectors datetime serials
            GPS_serial = datenum(GPS_vec);
            iMet_serial = datenum(iM_vec);
            
            % Find iMet data at start and end of Pixhawk parsing
            TO_iMet = find(iMet_serial(:)>=min(GPS_serial),1,'first');
            LND_iMet = find(iMet_serial(:)>=max(GPS_serial),1,'first');
            
            % Parse iMet data
            iM_red = iM_vec(TO_iMet:LND_iMet,:);
            iMet_serial = iMet_serial(TO_iMet:LND_iMet);
            
            % Add Pixhawk time since arming variable
            iter = 1;
            for i=1:length(iMet_serial)
                for j=iter:length(GPS_serial)
                    if(iMet_serial(i)==GPS_serial(j))
                        iM_Pix(i,1)=GPS_time_out(j);
                        iter = j;
                    end
                end
            end
            
            for row = 1:length(iM_Pix)
                if iM_Pix(row,1) == 0
                    iM_Pix(row,1) = (iM_Pix(row-1,1)+iM_Pix(row+1,1))/2;
                end
            end
            
            if(dataLen == 46)
                i=TO_iMet:LND_iMet;
                iM_time_temp(:,1) = iMet_time(i,1);
                iM_date_temp(:,1) = iMet_date(i,1);
                iM_pres_temp(:,1) = iMetData(i,37);
                iM_temp_temp(:,1) = iMetData(i,38);
                iM_humid_temp(:,1) = iMetData(i,39);
                iM_lat_temp(:,1) = iMetData(i,42);
                iM_long_temp(:,1) = iMetData(i,43);
                iM_alt_temp(:,1) = iMetData(i,44);
                iM_sat_temp(:,1) = iMetData(i,45);
            elseif(dataLen == 47)
                i=TO_iMet:LND_iMet;
                iM_time_temp(:,1) = iMet_time(i,1);
                iM_date_temp(:,1) = iMet_date(i,1);
                iM_pres_temp(:,1) = iMetData(i,37);
                iM_temp_temp(:,1) = iMetData(i,38);
                iM_humid_temp(:,1) = iMetData(i,39);
                iM_humid_temp_t(:,1) = iMetData(i,40);
                iM_lat_temp(:,1) = iMetData(i,43);
                iM_long_temp(:,1) = iMetData(i,44);
                iM_alt_temp(:,1) = iMetData(i,45);
                iM_sat_temp(:,1) = iMetData(i,46);
            end
            
            len1 = size(iM_Pix,1);
            len2 = size(iM_time_temp,1);
            
            if(dataLen == 46)
                if(len1>len2)
                    iM_Pix = iM_Pix(1:len2);
                    iM_time = datestr(iM_time_temp(1:len2,1),'HH:MM:ss');
                    iM_date = datestr(iM_date_temp(1:len2,1),'mmm-dd-yyyy');
                    iM_pres = table2array(iM_pres_temp(1:len2,1));
                    iM_temp = table2array(iM_temp_temp(1:len2,1));
                    iM_humid = table2array(iM_humid_temp(1:len2,1));
                    iM_lat = table2array(iM_lat_temp(1:len2,1));
                    iM_long = table2array(iM_long_temp(1:len2,1));
                    iM_alt = table2array(iM_alt_temp(1:len2,1));
                    iM_sat = table2array(iM_sat_temp(1:len2,1));
                elseif(len2>len1)
                    iM_Pix = iM_Pix(1:len1);
                    iM_time = datestr(iM_time_temp(1:len1,1),'HH:MM:ss');
                    iM_date = datestr(iM_date_temp(1:len1,1),'mmm-dd-yyyy');
                    iM_pres = table2array(iM_pres_temp(1:len1,1));
                    iM_temp = table2array(iM_temp_temp(1:len1,1));
                    iM_humid = table2array(iM_humid_temp(1:len1,1));
                    iM_lat = table2array(iM_lat_temp(1:len1,1));
                    iM_long = table2array(iM_long_temp(1:len1,1));
                    iM_alt = table2array(iM_alt_temp(1:len1,1));
                    iM_sat = table2array(iM_sat_temp(1:len1,1));
                else
                    iM_Pix = iM_Pix(1:len1);
                    iM_time = datestr(iM_time_temp(:,1),'HH:MM:ss');
                    iM_date = datestr(iM_date_temp(:,1),'mmm-dd-yyyy');
                    iM_pres = table2array(iM_pres_temp(:,1));
                    iM_temp = table2array(iM_temp_temp(:,1));
                    iM_humid = table2array(iM_humid_temp(:,1));
                    iM_lat = table2array(iM_lat_temp(:,1));
                    iM_long = table2array(iM_long_temp(:,1));
                    iM_alt = table2array(iM_alt_temp(:,1));
                    iM_sat = table2array(iM_sat_temp(:,1));
                end
                
                iMet_table = table(iM_Pix, iM_date, iM_time, iM_pres, iM_temp, iM_humid, iM_lat, iM_long, iM_alt, iM_sat,'VariableNames',{'Time from Arming (sec)','Date UTC','Time UTC','Barometric Pressure (hPa)','Air Temp (°C)','Relative Humidity (%)','GPS Lat','GPS Long','GPS Alt (m)','Sat Count'});
                save(fullParsedMatFileName,'iMet_table','-append');
                
            elseif(dataLen == 47)
                if(len1>len2)
                    iM_Pix = iM_Pix(1:len2);
                    iM_time = datestr(iM_time_temp(1:len2,1),'HH:MM:ss');
                    iM_date = datestr(iM_date_temp(1:len2,1),'mmm-dd-yyyy');
                    iM_pres = table2array(iM_pres_temp(1:len2,1));
                    iM_temp = table2array(iM_temp_temp(1:len2,1));
                    iM_humid = table2array(iM_humid_temp(1:len2,1));
                    iM_humid_t = table2array(iM_humid_temp_t(1:len2,1));
                    iM_lat = table2array(iM_lat_temp(1:len2,1));
                    iM_long = table2array(iM_long_temp(1:len2,1));
                    iM_alt = table2array(iM_alt_temp(1:len2,1));
                    iM_sat = table2array(iM_sat_temp(1:len2,1));
                elseif(len2>len1)
                    iM_Pix = iM_Pix(1:len1);
                    iM_time = datestr(iM_time_temp(1:len1,1),'HH:MM:ss');
                    iM_date = datestr(iM_date_temp(1:len1,1),'mmm-dd-yyyy');
                    iM_pres = table2array(iM_pres_temp(1:len1,1));
                    iM_temp = table2array(iM_temp_temp(1:len1,1));
                    iM_humid = table2array(iM_humid_temp(1:len1,1));
                    iM_humid_t = table2array(iM_humid_temp_t(1:len1,1));
                    iM_lat = table2array(iM_lat_temp(1:len1,1));
                    iM_long = table2array(iM_long_temp(1:len1,1));
                    iM_alt = table2array(iM_alt_temp(1:len1,1));
                    iM_sat = table2array(iM_sat_temp(1:len1,1));
                else
                    iM_Pix = iM_Pix(1:len1);
                    iM_time = datestr(iM_time_temp(:,1),'HH:MM:ss');
                    iM_date = datestr(iM_date_temp(:,1),'mmm-dd-yyyy');
                    iM_pres = table2array(iM_pres_temp(:,1));
                    iM_temp = table2array(iM_temp_temp(:,1));
                    iM_humid = table2array(iM_humid_temp(:,1));
                    iM_humid_t = table2array(iM_humid_temp_t(:,1));
                    iM_lat = table2array(iM_lat_temp(:,1));
                    iM_long = table2array(iM_long_temp(:,1));
                    iM_alt = table2array(iM_alt_temp(:,1));
                    iM_sat = table2array(iM_sat_temp(:,1));
                end
                
                iMet_table = table(iM_Pix, iM_date, iM_time, iM_pres, iM_temp, iM_humid, iM_humid_t, iM_lat, iM_long, iM_alt, iM_sat,'VariableNames',{'Time from Arming (sec)','Date UTC','Time UTC','Barometric Pressure (hPa)','Air Temp (°C)','Relative Humidity (%)','Humidity Temperature (°C)','GPS Lat','GPS Long','GPS Alt (m)','Sat Count'});
                save(fullParsedMatFileName,'iMet_table','-append');
            end
            
            fig3=figure(3);
            fig3.Name = 'Parsed iMet data.';
            set(fig3,'defaultLegendAutoUpdate','off');
            yyaxis left
            plt = plot(iM_Pix(:), iM_temp(:),'y-',iM_Pix(:),iM_humid,'c-');
            title('Temp, Humidity, and Pressure vs Time')
            xlabel('Time (ms)');
            ylabel('Temp (°C) and Humidity (%)');
            
            yyaxis right
            plt = plot(iM_Pix(:), iM_pres(:),'k-');
            ylabel('Pressure (hPa)');
            legend({'iMet Temp','iMet Humid','iMet Pres'},'Location','southeast')
            
            if(strcmpi(sensorOut,'Yes'))
                % Get the name of the input.mat file and save as input_Parsed_TPH.csv
                baseFileName = sprintf('%s_iMet.csv', baseNameNoExtDFL);
                fullOutputMatFileName = fullfile(folderDFL, baseFileName);
                % Write data to text file
                writetable(iMet_table, fullOutputMatFileName);
            end
        end
        
    elseif(strcmpi(DFL_NewOld,'Old'))
        if(exist('iMet_table','var'))
            if (strcmpi(iMetValue,'Yes'))
                
                fig3=figure(3);
                fig3.Name = 'Parsed iMet data.';
                set(fig3,'defaultLegendAutoUpdate','off');
                yyaxis left
                plt = plot(iMet_table{:,1}, iMet_table{:,5},'y-',iMet_table{:,1},iMet_table{:,6},'c-');
                title('Temp, Humidity, and Pressure vs Time')
                xlabel('Time (ms)');
                ylabel('Temp (°C) and Humidity (%)');
                
                yyaxis right
                plt = plot(iMet_table{:,1}, iMet_table{:,4},'k-');
                ylabel('Pressure (hPa)');
                legend({'iMet Temp','iMet Humid','iMet Pres'},'Location','southeast')
                
                if(strcmpi(sensorOut,'Yes'))
                    % Get the name of the input.mat file and save as input_Parsed_TPH.csv
                    baseFileName = sprintf('%s_iMet_NS.csv', baseNameNoExtDFL);
                    fullOutputMatFileName = fullfile(folderDFL, baseFileName);
                    % Write data to text file
                    writetable(iMet_table, fullOutputMatFileName);
                end
            end
        end
    end
    %% 5HP Data Parsing and Output
    if (strcmpi(mhpValue,'Yes') | strcmpi(tphValue,'Yes'))
        if(strcmpi(DFL_NewOld,'New'))
            % Get the name of the file that the user wants to use.
            defaultFileNameMHP = fullfile(startingFolderDFL, '*.csv');
            [baseFileNameMHP, folderMHP] = uigetfile(defaultFileNameMHP, 'Select a 5HP/TPH .CSV file');
            if baseFileNameMHP == 0
                % User clicked the Cancel button.
                return;
            end
            
            % Get the name of the input .mat file.
            fullInputMatFileNameMHP = fullfile(folderMHP, baseFileNameMHP);
            % Get filename without the extension, used by Save Function
            [~, baseNameNoExtMHP, ~] = fileparts(baseFileNameMHP);
            
            data = readmatrix(fullInputMatFileNameMHP);
            data(isnan(data)) = -1;
            
            list = {'Probe 1', 'Probe 2', 'Probe 3'};
            [Probe, tf] = listdlg('ListString', list, 'SelectionMode','single');
            
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
            
            nrows = length(data(:,1));
            ncols = length(data(1,:));
            
            rho=1.197; %kg/m3 Lets move this down (calc it)
            
            CTUNTemp = CTUN;
            
            Pixcount=0;
            SScount=0;
            
            i=1:nrows; % vectorize instead of for loop (speed)
            
            time = data(i,1);
            PitotB1 = data(i,2);
            PitotB2 = data(i,3);
            AlphaB1 = data(i,6);
            AlphaB2 = data(i,7);
            BetaB1 = data(i,10);
            BetaB2 = data(i,11);
            H1 = data(i,15);
            T1 = data(i,16);
            H2 = data(i,19);
            T2 = data(i,20);
            H3 = data(i,23);
            T3 = data(i,24);
            UnixT = data(i,26);
            PixT = data(i,27);
            
            PitotCount = ((PitotB1*256)+PitotB2);
            AlphaCount =  ((AlphaB1*256)+AlphaB2);
            BetaCount  =  ((BetaB1*256)+BetaB2);
            
            Pitot_psi=((PitotCount-1638)*(1+1))/(14745-1638)-1;
            Alpha_psi=((AlphaCount-1638)*(1+1))/(14745-1638)-1;
            Beta_psi=((BetaCount-1638)*(1+1))/(14745-1638)-1;
            
            Pitot_pa=Pitot_psi*6894.74;
            Alpha_pa=Alpha_psi*6894.74;
            Beta_pa=Beta_psi*6894.74;
            
            %Cp Calc
            CP_a=Alpha_pa./Pitot_pa;
            CP_b=Beta_pa./Pitot_pa;
            
            % Calculate alpha and beta probe values
            Alpha=interp1(Probe_matrix(2,:,1), Probe_matrix(1,:,1), CP_a(i), 'linear', 45); %just doing 1d interp for now until more speeds ran
            Beta=interp1(Probe_matrix(2,:,2), Probe_matrix(1,:,2), CP_b(i), 'linear', 45);
            
            CP_pitot1 = interp1(Probe_matrix(1,:,4), Probe_matrix(2,:,4), Beta(i), 'makima', .5);
            CP_pitot2 = interp1(Probe_matrix(1,:,3), Probe_matrix(2,:,3), Alpha(i),'makima', .5);
            
            for i=1:nrows
                UnixTime = UnixT(i);
                Temp = T1(i);
                if(UnixTime~=-1)
                    Pixcount=Pixcount+1;
                    PixData(Pixcount,1)=time(i);   % Sensor board time
                    PixData(Pixcount,2)=UnixTime;  % Unix time from Pix GPS
                    PixData(Pixcount,3)=PixT(i);   % Pixhawk board time
                end
                
                if(Temp~=-1)
                    SScount=SScount+1;
                    THSense(SScount,1)=time(i);  % Sensor board time
                    THSense(SScount,2)=-1;    % Will become Pixhawk board time
                    THSense(SScount,3)=T1(i);
                    THSense(SScount,4)=T2(i);
                    THSense(SScount,5)=T3(i);
                    THSense(SScount,6)=H1(i);
                    THSense(SScount,7)=H2(i);
                    THSense(SScount,8)=H3(i);
                end
                
                if CP_pitot1(i) > CP_pitot2(i)
                    CP_pitot(i) = CP_pitot2(i);
                else
                    CP_pitot(i) = CP_pitot1(i);
                end
                
                U(i) = ((2/rho)*(abs(Pitot_pa(i)/CP_pitot(i)))) .^.5;
                
            end
            
            u = U'.*cosd(Alpha).*cosd(Beta);
            v = U'.*sind(Beta);
            w = U'.*sind(Alpha).*cosd(Beta);
            total = sqrt(abs(u).^2 + abs(v).^2 + abs(2).^2);
            
            for i=1:nrows
            MHPData(i,1)=time(i);            % Sensor board time
            MHPData(i,2)=-1;              % Will become Pixhawk board time
            MHPData(i,3)=u(i);
            MHPData(i,4)=v(i);
            MHPData(i,5)=w(i);
            MHPData(i,6)=Alpha(i);
            MHPData(i,7)=Beta(i);
            MHPData(i,8)=0;
            MHPData(i,9)=0;
%            MHPData(i,8)=Alpha_MA(i);
%            MHPData(i,9)=Beta_MA(i);
            MHPData(i,10)=total(i);
            MHPData(i,11)=0;
            MHPData(i,12)=0;
            MHPData(i,13)=0;
            MHPData(i,14)=0;
            end
            
            if (PixData(:,3) == -1)
                serialGPS = posixtime(GPS_final);
                tempPixTime = GPS_table(:,2)/100000;
                
                for i=length(GPS_table(:,1))
                    offset(i) = serialGPS(i) - tempPixTime(i);
                end
                AvOffset = mean(offset);
                PixData(:,3) = PixData(:,2) - AvOffset(:);
            end
            
            for i=1:length(PixData(:,1))
                PixOff(i)=PixData(i,3)-PixData(i,1);
                GPS_off(i)=PixData(i,2)-PixData(i,1)/1000;
            end
            
            PixAv=mean(PixOff);
            GPS_av = mean(GPS_off);
            
            leapseconds_unix = 28;
            
            % Offsets between board time and Pix time
            MHPData(:,2)=round((MHPData(:,1)+PixAv),0);
            MHPData_Unix=round((MHPData(:,1)/1000)+GPS_av,1);
            
            
            
            %% ADD CODE HERE
            
            
            
            %% REST OF CODE
            
            MHP_DateTime=datetime(MHPData_Unix,'ConvertFrom','posixTime','Format','MMM-dd-yyyy HH:mm:ss.S');
            MHP_Date=datestr(MHP_DateTime,'mmm-dd-yyyy');
            MHP_Time=datestr(MHP_DateTime,'HH:MM:SS.FFF');
            
            if(exist('THSense','var'))
                THSense(:,2)=round((THSense(:,1)+PixAv),0);
                THSense_Unix=round((THSense(:,1)/1000)+GPS_av,1);
                
                TH_DateTime=datetime(THSense_Unix,'ConvertFrom','posixTime','Format','MMM-dd-yyyy HH:mm:ss.S');
                TH_Date=datestr(TH_DateTime,'mmm-dd-yyyy');
                TH_Time=datestr(TH_DateTime,'HH:MM:SS.FFF');
            end
            
            if (min(MHP_DateTime) < min(GPS_final))
                TO_MHP = find(MHP_DateTime(:)>=min(GPS_final),1,'first');
            else
                TO_MHP = 1;
            end
            
            if(exist('THSense','var'))
                % 5HP and TPH parsing
                if (min(TH_DateTime) < min(GPS_final))
                    TO_TPH = find(TH_DateTime(:)>=min(GPS_final),1,'first');
                else
                    TO_TPH = 1;
                end
            end
            
            if (max(MHP_DateTime) > max(GPS_final))
                LND_MHP = find(MHP_DateTime(:)>=max(GPS_final),1,'first');
            else
                LND_MHP = length(MHP_DateTime);
            end
            
            if(exist('THSense','var'))
                if (max(TH_DateTime) > max(GPS_final))
                    LND_TPH = find(TH_DateTime(:)>=max(GPS_final),1,'first');
                else
                    LND_TPH = length(TH_DateTime);
                end
                
                TPH_entry = THSense(TO_TPH:LND_TPH,:);
                TH_Date = TH_Date(TO_TPH:LND_TPH,:);
                TH_Time = TH_Time(TO_TPH:LND_TPH,:);
                TPH_time_out = (TPH_entry(:,1)-min(TPH_entry(:,1)))/1000;
            end
            
            MHP_entry = MHPData(TO_MHP:LND_MHP,:);
            MHP_Date = MHP_Date(TO_MHP:LND_MHP,:);
            MHP_Time = MHP_Time(TO_MHP:LND_MHP,:);
            MHP_time_out = (MHP_entry(:,1)-min(MHP_entry(:,1)))/1000;
            
            Pix_time_out = (PixData(:,1)-min(PixData(:,1)))/1000;
            
            % Create tables with the data and variable names
            MHP_table = table(MHP_entry(:,1),MHP_entry(:,2),MHP_time_out, MHP_Date, MHP_Time,MHP_entry(:,3),MHP_entry(:,4),MHP_entry(:,5),MHP_entry(:,6),MHP_entry(:,7),MHP_entry(:,8),MHP_entry(:,9),MHP_entry(:,10),MHP_entry(:,11),MHP_entry(:,12),MHP_entry(:,13),MHP_entry(:,14),'VariableNames', {'Board Time from PowerUp (msec)','Pix Time from PowerUp (msec)','Pix time from parse','UTC Date','UTC Time','U (m/s)','V (m/s)','W (m/s)','Alpha(deg)','Beta(deg)','Alpha Mean Aver.','Beta Mean Aver.','Total Velocity (m/s)','TBD','TBD2','TBD3','TBD4'} );
            save(fullParsedMatFileName,'MHP_table','-append');
            
            PixData_table = table(PixData(:,1),PixData(:,2),Pix_time_out,PixData(:,3),'VariableNames',{'Sensor board time (ms)','GPS Unix Time (sec)','Pix board time (sec)','Pix board time (ms)'});
            save(fullParsedMatFileName,'PixData_table','-append');
            
            if(exist('THSense','var'))
                TPH_table = table(TPH_entry(:,1),TPH_entry(:,2),TPH_time_out,TH_Date, TH_Time, TPH_entry(:,3),TPH_entry(:,4),TPH_entry(:,5),TPH_entry(:,6),TPH_entry(:,7),TPH_entry(:,8) , 'VariableNames', {'Board Time from PowerUp (msec)','Pixhawk Time from PowerUp (msec)','Pix Time from parse','UTC Date','UTC Time','Temp 1 (°C)','Temp 2 (°C)','Temp 3 (°C)','Humidity 1 (%)','Humidity 2 (%)','Humidity 3 (%)'} );
                save(fullParsedMatFileName,'TPH_table','-append');
            end
            
        end
        if(exist('TPH_table','var'))
            TPH = [table2array(TPH_table(:,1:3)) table2array(TPH_table(:,6:end))];
        end
        if(exist('MHP_table','var'))
            MHP = [table2array(MHP_table(:,1:3)) table2array(MHP_table(:,6:end))];
            CTUN = table2array(CTUN_table);
        end

        if(strcmpi(mhpValue,'Yes') && strcmpi(tphValue,'Yes') && exist('THSense','var'))
            
            fig4=figure(4);
            fig4.Name = 'Parsed 5HP and TPH Data';
            set(fig4,'defaultLegendAutoUpdate','off');
            subplot(2,1,1);
            plt2 = plot(TPH(:,2)/1000,TPH(:,3),'r-',TPH(:,2)/1000,TPH(:,4),'b-',TPH(:,2)/1000,TPH(:,5),'g-',TPH(:,2)/1000,TPH(:,6),'r.',TPH(:,2)/1000,TPH(:,7),'b.',TPH(:,2)/1000,TPH(:,8),'g.');
            title('Temp and Humidity vs Time')
            legend({'Temp 1','Temp 2', 'Temp 3','Humid 1','Humid 2', 'Humid 3'},'Location','southeast')
            xlabel('Time (sec)');
            ylabel('Temp (°C) and Humidity (%)');
            xlim([min(TPH(:,2)/1000) max(TPH(:,2)/1000)])
            
            subplot(2,1,2);
            plt3 = plot(MHP(:,3),MHP(:,4),'r',MHP(:,3),MHP(:,5),'b',MHP(:,3),MHP(:,6),'g');
            title('Pitot, Alpha, and Beta (raw)')
            legend({'Pitot','Alpha','Beta'},'Location','northwest')
            ylabel('Velocity (m/s)');
            xlim([(min(MHP(:,3))) (max(MHP(:,3)))])
            
            fig5=figure(5);
            fig5.Name = 'MHP vs Pix Airspeeds';
            set(fig5,'defaultLegendAutoUpdate','off');
            subplot(2,1,1);
            plt1 = plot(MHP(:,3),MHP(:,4),'r',CTUN(:,2)/1000000,CTUN(:,4),'k');
            title('MHP Pitot and Pix Airspeeds with Time')
            legend({'MHP Pitot', 'Pix Arspd'},'Location','northwest')
            ylabel('Airspeed (m/s)');
            xlim([(min(MHP(:,3))) (max(MHP(:,3)))])
            
            subplot(2,1,2)
            plt2 = plot(MHP(:,3),MHP(:,4),'r',MHP(:,3),MHP(:,5),'b',MHP(:,3),MHP(:,6),'g',CTUN(:,3),CTUN(:,4),'k');
            title('MHP Pitot, Alpha, Beta, and Pix Airspeeds with Time')
            legend({'MHP-Pitot','MHP-Alpha','MHP-Beta', 'Pix Arspd'},'Location','northwest')
            ylabel('Airspeed (m/s)');
            xlim([(min(MHP(:,3))) (max(MHP(:,3)))])
            
            if(strcmpi(sensorOut,'Yes'))
                if(strcmpi(DFL_NewOld,'New'))
                    % Output parsed TPH data
                    baseFileName = sprintf('%s_Parsed_TPH.csv', baseNameNoExtDFL);
                    fullOutputMatFileName = fullfile(folderDFL, baseFileName);
                    % Write data to text file
                    writetable(TPH_table, fullOutputMatFileName);
                    
                    % Get the name of the input.mat file and save as input_Parsed_MHP.csv
                    baseFileName = sprintf('%s_Parsed_MHP.csv', baseNameNoExtDFL);
                    fullOutputMatFileName = fullfile(folderDFL, baseFileName);
                    % Write data to text file
                    writetable(MHP_table, fullOutputMatFileName);
                else
                    % Output parsed TPH data
                    baseFileName = sprintf('%s_TPH_NS.csv', baseNameNoExtDFL);
                    fullOutputMatFileName = fullfile(folderDFL, baseFileName);
                    % Write data to text file
                    writetable(TPH_table, fullOutputMatFileName);
                    
                    % Get the name of the input.mat file and save as input_Parsed_MHP.csv
                    baseFileName = sprintf('%s_MHP_NS.csv', baseNameNoExtDFL);
                    fullOutputMatFileName = fullfile(folderDFL, baseFileName);
                    % Write data to text file
                    writetable(MHP_table, fullOutputMatFileName);
                end
            end
            
        elseif(strcmpi(mhpValue,'Yes') && (strcmpi(tphValue,'No') | ~exist('THSense','var')))
            
            fig4=figure(4);
            fig4.Name = 'Parsed 5HP Data';
            set(fig4,'defaultLegendAutoUpdate','off');
            plt3 = plot(MHP(:,3),MHP(:,4),'r',MHP(:,3),MHP(:,5),'b',MHP(:,3),MHP(:,6),'g');
            title('Pitot, Alpha, and Beta (raw)')
            legend({'Pitot','Alpha','Beta'},'Location','northwest')
            xlabel('Time (sec)');
            ylabel('Velocity (m/s)');
            xlim([(min(MHP(:,3))) (max(MHP(:,3)))])
            
            fig5=figure(5);
            fig5.Name = 'MHP vs Pix Airspeeds';
            set(fig5,'defaultLegendAutoUpdate','off');
            subplot(2,1,1);
            plt1 = plot(MHP(:,3),MHP(:,4),'r',CTUN(:,3),CTUN(:,4),'k');
            title('MHP Pitot and Pix Airspeeds with Time')
            legend({'MHP Pitot', 'Pix Arspd'},'Location','northwest')
            ylabel('Airspeed (m/s)');
            xlim([(min(MHP(:,3))) (max(MHP(:,3)))])
            
            subplot(2,1,2)
            plt2 = plot(MHP(:,3),MHP(:,4),'r',MHP(:,3),MHP(:,5),'b',MHP(:,3),MHP(:,6),'g',CTUN(:,3),CTUN(:,4),'k');
            title('MHP Pitot, Alpha, Beta, and Pix Airspeeds with Time')
            legend({'MHP-Pitot','MHP-Alpha','MHP-Beta', 'Pix Arspd'},'Location','northwest')
            ylabel('Airspeed (m/s)');
            xlim([(min(MHP(:,3))) (max(MHP(:,3)))])
            
            if(strcmpi(sensorOut,'Yes'))
                if(strcmpi(DFL_NewOld,'New'))
                    % Get the name of the input.mat file and save as input_Parsed_MHP.csv
                    baseFileName = sprintf('%s_Parsed_MHP.csv', baseNameNoExtDFL);
                    fullOutputMatFileName = fullfile(folderDFL, baseFileName);
                    % Write data to text file
                    writetable(MHP_table, fullOutputMatFileName);
                else
                    % Get the name of the input.mat file and save as input_Parsed_MHP.csv
                    baseFileName = sprintf('%s_MHP_NS.csv', baseNameNoExtDFL);
                    fullOutputMatFileName = fullfile(folderDFL, baseFileName);
                    % Write data to text file
                    writetable(MHP_table, fullOutputMatFileName);
                end
            end
            
            
        elseif(strcmpi(mhpValue,'No') && strcmpi(tphValue,'Yes') && exist('THSense','var'))
            
            fig4=figure(4);
            fig4.Name = 'Parsed TPH Data';
            plt2 = plot(TPH(:,2)/1000,TPH(:,3),'r-',TPH(:,2)/1000,TPH(:,4),'b-',TPH(:,2)/1000,TPH(:,5),'g-',TPH(:,2)/1000,TPH(:,6),'r.',TPH(:,2)/1000,TPH(:,7),'b.',TPH(:,2)/1000,TPH(:,8),'g.');
            title('Temp and Humidity vs Time')
            legend({'Temp 1','Temp 2', 'Temp 3','Humid 1','Humid 2', 'Humid 3'},'Location','southeast')
            xlabel('Time (sec)');
            ylabel('Temp (°C) and Humidity (%)');
            xlim([(min(TPH(:,2)/1000)) (max(TPH(:,2)/1000))])
            
            if(strcmpi(sensorOut,'Yes'))
                if(strcmpi(DFL_NewOld,'New'))
                    % Output parsed TPH data
                    baseFileName = sprintf('%s_Parsed_TPH.csv', baseNameNoExtDFL);
                    fullOutputMatFileName = fullfile(folderDFL, baseFileName);
                    % Write data to text file
                    writetable(TPH_table, fullOutputMatFileName);
                else
                    % Output parsed TPH data
                    baseFileName = sprintf('%s_TPH_NS.csv', baseNameNoExtDFL);
                    fullOutputMatFileName = fullfile(folderDFL, baseFileName);
                    % Write data to text file
                    writetable(TPH_table, fullOutputMatFileName);
                end
            end
        end
    end
    %% CSV Output of GPS Data
    if (strcmpi(gpsOut,'Yes'))
        if(strcmpi(DFL_NewOld,'New'))
            % Get the name of the input.mat file and save as input_GPS.csv
            baseFileName = sprintf('%s_GPS.csv', baseNameNoExtDFL);
        elseif(strcmpi(DFL_NewOld,'Old'))
            % Get the name of the input.mat file and save as input_GPS_NS.csv
            baseFileName = sprintf('%s_GPS_NS.csv', baseNameNoExtDFL);
        end
        fullOutputMatFileName = fullfile(folderDFL, baseFileName);
        % Write data to text file
        writetable(GPS_table, fullOutputMatFileName);
    end
    %% CSV Output of Aircraft Attitude Data
    if (strcmpi(attitudeOut,'Yes'))
        if(strcmpi(DFL_NewOld,'New'))
            % Get the name of the input.mat file and save as input_Attitude.csv
            baseFileName = sprintf('%s_Attitude.csv', baseNameNoExtDFL);
        elseif(strcmpi(DFL_NewOld,'Old'))
            % Get the name of the input.mat file and save as input_Attitude_NS.csv
            baseFileName = sprintf('%s_Attitude_NS.csv', baseNameNoExtDFL);
        end
        fullOutputMatFileName = fullfile(folderDFL, baseFileName);
        % Write data to text file
        writetable(ATT_table, fullOutputMatFileName);
    end
    %% CSV Output of IMU Data
    if (strcmpi(stateSpace,'Yes'))
        if(strcmpi(DFL_NewOld,'New'))
            % Get the name of the input.mat file and save as input_IMU.csv
            baseFileName = sprintf('%s_IMU.csv', baseNameNoExtDFL);
        elseif(strcmpi(DFL_NewOld,'Old'))
            % Get the name of the input.mat file and save as input_IMU_NS.csv
            baseFileName = sprintf('%s_IMU_NS.csv', baseNameNoExtDFL);
        end
        fullOutputMatFileName = fullfile(folderDFL, baseFileName);
        % Write data to text file
        writetable(IMU_table, fullOutputMatFileName);
    end
    %% Plot Data According To User Input
    if (strcmpi(graphToggle,'Yes'))
        % Converted timestamps to time (in seconds) from TO to LND
        t_GPS = table2array(GPS_table(:,3));
        t_NKF = table2array(NKF2_table(:,3));
        t_RCOU = table2array(RCOU_table(:,3));
        t_BARO = table2array(BARO_table(:,3));
        t_ATT = table2array(ATT_table(:,3));
        
        if(strcmpi(arduPilotType,'ArduCopter'))
        elseif(strcmpi(arduPilotType,'CopterSonde'))
            t_CSIMET = table2array(CSIMET_table(:,3));
            CSIMET_mat = table2array(CSIMET_table);
        else
            t_ctun = table2array(CTUN_table(:,3));
            CTUN_mat = table2array(CTUN_table);
        end
        
        t_low = min(GPS_table{:,3});
        t_high = max(GPS_table{:,3});
        GPS_mat = [table2array(GPS_table(:,1:3)) table2array(GPS_table(:,6:end))];
        ATT_mat = table2array(ATT_table);
        BARO_mat = table2array(BARO_table);
        IMU_mat = table2array(IMU_table);
        if(exist('MHP_table','var') && ~exist('MHP','var'))
            MHP = [table2array(MHP_table(:,1:3)) table2array(MHP_table(:,6:end))];
        end
        if(exist('TPH_table','var') && ~exist('TPH','var'))
            TPH = [table2array(TPH_table(:,1:3)) table2array(TPH_table(:,6:end))];
        end
        if(exist('PixData_table','var') && ~exist('PixData','var'))
            PixData = table2array(PixData_table);
        end
        if(exist('iMet_table','var') && ~exist('iMet','var'))
            iMet = [table2array(iMet_table(:,1)) table2array(iMet_table(:,4:end))];
        end
        NKF2_mat = table2array(NKF2_table);
        RCOU_mat = table2array(RCOU_table);
        
        
        
        if (strcmpi(overlay,'Yes'))
            
            fig6=figure(6);
            fig6.Name = 'Data Plots from Parsed Sensor data and Autopilot DFL';
            
            if(strcmpi(mhpValue,'Yes'))
                if(exist('MHP','var'))
                    % Groundspeed plot
                    plt1 = subplot(5,1,1);
                    plot(t_GPS,GPS_mat(:,8),'k',t_ctun,CTUN_mat(:,4),'b',t_NKF,NKF2_mat(:,6),'r',MHP(:,3),MHP(:,4),'g')
                    title('Groundspeed (black), Airspeed (blue), Windspeed (red), MHP-Pitot (green) vs Time')
                    ylabel({'Velocity (m/s)'})
                end
            elseif(strcmpi(arduPilotType,'ArduCopter') | strcmpi(arduPilotType,'CopterSonde'))
                % Groundspeed plot
                plt1 = subplot(5,1,1);
                plot(t_GPS,GPS_mat(:,8),'k',t_NKF,NKF2_mat(:,6),'r')
                title('Groundspeed (black), Windspeed (red) vs Time')
                ylabel({'Velocity (m/s)'})
            else
                % Groundspeed plot
                plt1 = subplot(5,1,1);
                plot(t_GPS,GPS_mat(:,8),'k',t_ctun,CTUN_mat(:,4),'b',t_NKF,NKF2_mat(:,6),'r')
                title('Groundspeed (black), Airspeed (blue), Windspeed (red) vs Time')
                ylabel({'Velocity (m/s)'})
            end
            
            if(strcmpi(iMetValue,'Yes'))
                if(exist('iMet_table','var'))
                    % Barometric Pressure of Pixhawk and Sensor Packages
                    plt4 = subplot(5,1,4);
                    plot(t_BARO, BARO_mat(:,4),'b-',iMet(:,1),iMet(:,2),'r-');
                    title('Pixhawk (internal) vs iMet (external) Atmospheric Pressure Measurements')
                    %xticks([150:20:370])
                    ylabel({'Pixhawk Pressure (blue)';'iMet Pressure (red)';'(mbar)'});
                end
            else
                % Barometric Pressure of Pixhawk and Sensor Packages
                plt4 = subplot(5,1,4);
                plot(t_BARO,BARO_mat(:,4),'b-');
                title('Pixhawk (internal) Atmospheric Pressure Measurements')
                %xticks([150:20:370])
                ylabel({'Pixhawk Pressure (blue)';'(mbar)'});
            end
            
            if(strcmpi(arduPilotType,'CopterSonde'))
                plt11 = subplot(2,1,1);
                colors = {'k','r','b','g','k-','r-','b-','g-'};
                for i=0:3
                    if(min(CSIMET_mat(:,i+4))>0)
                        hold on
                        plot(t_CSIMET,CSIMET_mat(:,i+4)/100,colors{i+1});
                        plot(t_CSIMET,CSIMET_mat(:,i+8)-273.15,colors{i+5});
                    end
                end
                hold off
                title('CopterSonde Temperature and Humidity');
                ylabel({'Temp (°C) and Humidity (%)'});
                
                plt12 = subplot(2,1,2);
                plot(BARO_mat(:,3),BARO_mat(:,4),'k');
                title('Pixhawk (internal) Pressure Readings');
                ylabel({'Pressure (mbar)'});
                xlabel({'Time (sec)'});
                linkaxes([plt11 plt12],'x')
                xlim([min(t_CSIMET) max(t_CSIMET)])
            else
                % Throttle Output
                plt2 = subplot(5,1,2 );
                plot(t_RCOU,RCOU_mat(:,6),'b')
                title('Throttle vs Time')
                ylabel({'Throttle';'(%)'})
                %xticks([150:20:370])
                ylim([0 100])
                
                % For the dotted line along x-axis of pitch plot
                zero=int8(zeros(length(ATT_mat(:,5)),1));
                
                % Aircraft Pitch angle: Can change ylim to something more relevant.
                % TIV uses -20 to 50 to see high AoA landing
                plt3 = subplot(5,1,3);
                plot(t_ATT,ATT_mat(:,5),'b',t_ATT,zero,'r:')
                title('Aircraft Pitch Angle vs Time')
                ylabel({'Aircraft Pitch';'Angle (°)'})
                %xticks([150:20:370])
                ylim([-20 50])
                
                % Altitude plot
                plt5 = subplot(5,1,5);
                plot(t_GPS,GPS_mat(:,7),'b')
                title('Altitude vs Time')
                %xticks([150:20:370])
                ylabel({'Altitude AGL';'(m)'})
                xlabel('Time (seconds)')
                
                linkaxes([plt1 plt2 plt3 plt4 plt5],'x')
                xlim([t_low t_high])
            end
            
            if(strcmpi(tphValue,'Yes') && strcmpi(mhpValue,'Yes') && strcmpi(iMetValue,'Yes'))
                if(exist('TPH','var') && exist('MHP','var') && exist('iMet','var'))
                    fig7=figure(7);
                    fig7.Name = 'Pixhawk, iMet, TPH, and MHP Data Comparisons';
                    
                    if(strcmpi(arduPilotType,'ArduCopter') | strcmpi(arduPilotType,'CopterSonde'))
                        plt1 = subplot(3,1,1);
                        plot(MHP(:,3),MHP(:,4),'r',MHP(:,3),MHP(:,5),'b',MHP(:,3),MHP(:,6),'g');
                        title('5HP Alpha, Beta, and Pitot Velocities');
                        ylabel({'Velocity (m/s)'});
                    else
                        plt1 = subplot(3,1,1);
                        plot(t_ctun,CTUN_mat(:,4),'k',MHP(:,3),MHP(:,4),'r',MHP(:,3),MHP(:,5),'b',MHP(:,3),MHP(:,6),'g');
                        title('Pixhawk Airspeed vs 5HP Alpha, Beta, and Pitot Velocities');
                        ylabel({'Velocity (m/s)'});
                    end
                    
                    plt2 = subplot(3,1,2);
                    plot(iMet(:,1),iMet(:,3),'k',iMet(:,1),iMet(:,4),'k-',TPH(:,3),TPH(:,7),'r',TPH(:,3),TPH(:,4),'r-',TPH(:,3),TPH(:,8),'b',TPH(:,3),TPH(:,5),'b-',TPH(:,3),TPH(:,7),'g',TPH(:,3),TPH(:,6),'g-');
                    title('iMet vs Sensor Package Temperature and Humidity');
                    ylabel({'Temp (°C) and Humidity (%)'});
                    
                    plt3 = subplot(3,1,3);
                    plot(BARO_mat(:,3),BARO_mat(:,4),'k',iMet(:,1),iMet(:,2),'r');
                    title('Pixhawk (internal) vs iMet (external) Pressure Readings');
                    ylabel({'Pressure (mbar)'});
                    xlabel({'Time (sec)'});
                    linkaxes([plt1 plt2 plt3],'x')
                    xlim([min(t_BARO) max(t_BARO)])
                end
            end
            
        else
            
            fig6=figure(6);
            fig6.Name = 'Data Plots from Parsed Autopilot DFL';
            
            if(strcmpi(arduPilotType,'ArduCopter') | strcmpi(arduPilotType,'CopterSonde'))
                % Groundspeed plot
                plt1 = subplot(4,1,1);
                plot(t_GPS,GPS_mat(:,8),'b-',t_NKF,NKF2_mat(:,6),'g-')
                title('Groundspeed, and Windspeed vs Time')
                ylabel({'Groundspeed (blue)';'Windspeed (green)';'(m/s)'})
            else
                % Groundspeed plot
                plt1 = subplot(4,1,1);
                plot(t_GPS,GPS_mat(:,8),'b-',t_ctun,CTUN_mat(:,4),'r-',t_NKF,NKF2_mat(:,6),'g-')
                title('Groundspeed, Airspeed, and Windspeed vs Time')
                ylabel({'Groundspeed (blue)';'Airspeed (red)';'Windspeed (green)';'(m/s)'})
            end
            
            % Throttle Output
            plt2 = subplot(4,1,2);
            plot(t_RCOU,RCOU_mat(:,6),'b')
            title('Throttle vs Time')
            ylabel({'Throttle';'(%)'})
            ylim([0 100])
            
            % For the dotted line along x-axis of pitch plot
            zero=int8(zeros(length(ATT_mat(:,5)),1));
            
            % Aircraft Pitch angle: Can change ylim to something more relevant.
            % TIV uses -20 to 50 to see high AoA landing
            plt3 = subplot(4,1,3);
            plot(t_ATT,ATT_mat(:,5),'b',t_ATT,zero,'r:')
            title('Aircraft Pitch Angle vs Time')
            ylabel({'Aircraft Pitch';'Angle (°)'})
            ylim([-10 40])
            
            
            % Altitude plot
            plt4 = subplot(4,1,4);
            plot(t_GPS,GPS_mat(:,7),'b')
            title('Altitude vs Time')
            ylabel({'Altitude AGL';'(m)'})
            xlabel('Time (seconds)')
            
            linkaxes([plt1, plt2, plt3, plt4],'x')
            xlim([t_low t_high])
            
            
        end
        
        if (strcmpi(indvToggle,'Yes'))
            
            fig8=figure(8);
            fig8.Name = 'Interactive Plot - Right click or press Return/Enter when finished';
            
            % Groundspeed plot
            subplot(4,1,1);
            plot(t_GPS,GPS_mat(:,8),'b-',t_ctun,CTUN_mat(:,4),'r-',t_NKF,NKF2_mat(:,6),'g-')
            title('Groundspeed and Airspeed vs Time')
            ylabel({'Groundspeed (blue)';'Airspeed (red)';'Windspeed (green)';'(m/s)'})
            xlim([min(t_GPS) max(t_GPS)])
            
            % Throttle Output
            subplot(4,1,2);
            plot(t_RCOU,RCOU_tabl(:,6),'b')
            title('Throttle vs Time')
            ylabel({'Throttle';'(%)'})
            xlim([min(t_RCOU) max(t_RCOU)])
            ylim([0 100])
            
            % For the dotted line along x-axis of pitch plot
            zero=int8(zeros(length(ATT_mat(:,5)),1));
            
            % Aircraft Pitch angle: Can change ylim to something more relevant.
            % TIV uses -20 to 50 to see high AoA landing
            subplot(4,1,3);
            plot(t_ATT,ATT_mat(:,5),'b',t_ATT,zero,'r:')
            title('Aircraft Pitch Angle vs Time')
            ylabel({'Aircraft Pitch';'Angle (°)'})
            xlim([min(t_ctun) max(t_ctun)])
            ylim([-20 50])
            
            % Altitude plot
            subplot(4,1,4);
            plot(t_GPS,GPS_mat(:,7),'b')
            title('Altitude vs Time')
            xlim([min(t_GPS) max(t_GPS)])
            ylabel({'Altitude AGL';'(m)'})
            xlabel('Time (seconds)')
            n = 0;
            while true
                [horiz, vert, button] = ginput(1);
                if isempty(horiz) || button(1) == 3; break; end
                n = n+1;
                x_n(n) = horiz(1); % save all points you continue getting
                hold on
                y_n1(n)=GPS_mat(find(t_GPS>=x_n(n),1),8);      % Groundspeed
                y_n2(n)=CTUN_mat(find(t_ctun>=x_n(n),1),4);     % Airspeed
                y_n3(n)=NKF2_mat(find(t_NKF>=x_n(n),1),6);     % Windspeed
                y_n4(n)=RCOU_mat(find(t_ctun>=x_n(n),1),6);     % Throttle Percent
                y_n5(n)=ATT_mat(find(t_ctun>=x_n(n),1),5); % Aircraft Pitch
                y_n6(n)=GPS_mat(find(t_GPS>=x_n(n),1),7);    % Altitude
                y_n7(n)=RCOU_mat(find(t_ctun>=x_n(n),1),4);  % Pitch PWM
                
                % Groundspeed plot
                subplot(4,1,1);
                plot(t_GPS,GPS_mat(:,8),'b',t_ctun,CTUN_mat(:,4),'r',t_NKF,NKF2_mat(:,6),'g',x_n,y_n1,'kx',x_n,y_n2,'kx',x_n,y_n3,'kx')
                title('Groundspeed, Airspeed, and Windspeed vs Time')
                ylabel({'Groundspeed (blue)';'Airspeed (red)';'Windspeed (green)';'(m/s)'})
                xlim([min(t_GPS) max(t_GPS)])
                
                % Throttle Output
                subplot(4,1,5);
                plot(t_RCOU,RCOU_mat(:,6),'b',x_n, y_n4,'kx')
                title('Throttle vs Time')
                ylabel({'Throttle';'(%)'})
                xlim([min(t_RCOU) max(t_RCOU)])
                ylim([0 100])
                
                % For the dotted line along x-axis of pitch plot
                zero=int8(zeros(length(ATT_mat(:,5)),1));
                
                % Aircraft Pitch angle: Can change ylim to something more relevant.
                % TIV uses -20 to 50 to see high AoA landing
                subplot(4,1,3);
                plot(t_ATT,ATT_mat(:,5),'b',t_ATT,zero,'r:',x_n,y_n5,'kx');
                title('Aircraft Pitch Angle vs Time');
                ylabel({'Aircraft Pitch';'Angle (°)'});
                xlim([min(t_ctun) max(t_ctun)]);
                ylim([-20 50]);
                
                % Altitude plot
                subplot(4,1,4);
                plot(t_GPS,GPS_mat(:,7),'b',x_n,y_n6,'kx')
                title('Altitude vs Time')
                xlim([min(t_GPS) max(t_GPS)])
                ylabel({'Altitude AGL';'(m)'})
                xlabel('Time (seconds)')
                
                drawnow
                
            end
            
            if (strcmpi(throttleToggle,'Yes')) & (strcmpi(pitchToggle,'No'))
                
                thrT = interp1(throttleMap(:,1),throttleMap(:,2),y_n4);
                
                % Drag = Thrust
                C_D = (thrT.*2)./((y_n2.^2)*S*rho);
                % Lift = Weight
                C_L = (GTOW*2)./(S*rho*y_n2.^2);
                % Ratio of C_L/C_D
                L_D = C_L./C_D;
                
                % Flight Analysis
                baseFileName = sprintf('%s_metricsFull.csv', baseNameNoExtDFL);
                fullOutputMatFileName = fullfile(folder, baseFileName);
                % Save file with parsed data as the original filename plus the added portion
                % Create a table with the data and variable names
                T = table(round(y_n1.',1), round(y_n2.',1), round(y_n3.',1), round(y_n4.',1), round(y_n5.',1), round(y_n6.',1), round(y_n7.',1), round(thrT.',2), round(C_D.',6), round(C_L.',6), round(L_D.',4), 'VariableNames', {'Groundspeed (m/s)','Airspeed (m/s)','Windspeed (m/s)','Throttle (%)','Aircraft Pitch (°)','Altitude (m, AGL)','Pitch PWM','Thrust Output (units of Throttle Curve input file)','C_D','C_L','CD_CL'} )
                % Write data to text file
                writetable(T, fullOutputMatFileName)
                
                fig9 = figure(9);
                fig9.Name = 'Lift vs Drag Coefficients';
                subplot(1,2,1)
                scatter(C_D.',C_L.')
                title('C_L vs C_D')
                ylabel('C_L')
                xlabel('C_D')
                
                subplot(1,2,2)
                scatter(y_n2.',L_D.')
                title('L_D Ratio vs Airspeed')
                ylabel('L/D')
                xlabel('Airspeed (m/s)')
                
            elseif (strcmpi(throttleToggle,'Yes')) & (strcmpi(pitchToggle,'Yes'))
                
                % Mapping throttle Percent from User Input to Thrust Output
                thrT = interp1(throttleMap(:,1),throttleMap(:,2),y_n4);
                % Mapping pitch PWM from Pixhawk to true angular deflection
                pitchT = interp1(pitchMap(:,1),pitchMap(:,2),y_n7);
                
                % Drag = Thrust*cos(angle)
                C_D = (thrT.*cos(pitchT/180*3.14)*2)./((y_n2.^2)*S*rho);
                % Lift = Weight + Drag*sin(angle)
                C_L = ((GTOW+(thrT.*sin(pitchT/180*3.14)))*2)./(S*rho*y_n2.^2);
                % Ratio of C_L/C_D
                L_D = C_L./C_D;
                
                % Flight Analysis
                baseFileName = sprintf('%s_metricsFull.csv', baseNameNoExtDFL);
                fullOutputMatFileName = fullfile(folder, baseFileName);
                % Save file with parsed data as the original filename plus the added portion
                % Create a table with the data and variable names
                T = table(round(y_n1.',1), round(y_n2.',1), round(y_n3.',1), round(y_n4.',1), round(y_n5.',1), round(y_n6.',1), round(y_n7.',1), round(thrT.',2), round(pitchT.',1), round(C_D.',6), round(C_L.',6), round(L_D.',4), 'VariableNames', {'Groundspeed (m/s)','Airspeed (m/s)','Windspeed (m/s)','Throttle (%)','Aircraft Pitch (°)','Altitude (m, AGL)','Pitch PWM','Thrust Output (units of Throttle Curve input file)','Servo Angular Deflection (°)','C_D','C_L','CD_CL'} )
                % Write data to text file
                writetable(T, fullOutputMatFileName)
                
                fig9 = figure(9);
                fig9.Name = 'Lift vs Drag Coefficients';
                subplot(1,2,1)
                scatter(C_D.',C_L.')
                title('C_L vs C_D')
                ylabel('C_L')
                xlabel('C_D')
                
                subplot(1,2,2)
                scatter(y_n2.',L_D.')
                title('L_D Ratio vs Airspeed')
                ylabel('L/D')
                xlabel('Airspeed (m/s)')
                
            end
            
        end
    end
    %% Animation of Flight
    if(strcmpi(animateToggle, 'Yes'))
        if(strcmpi(tripleAnimateTPH,'Yes'))
            %% Animation Setup
            myVideo = VideoWriter('Kessler 8-4-2020, TriplePlot','MPEG-4'); %open video file
            myVideo.FrameRate = 20;  %can adjust this, 5 - 10 works well for me
            myVideo.Quality = 100;
            
            interval = 20;
            
            timer = table2array(BARO_table(1:2:8597-3,3));
            cAnim1 = [nan;table2array(TPH_table(1:2:end,6))];
            cAnim2 = [nan;table2array(TPH_table(1:2:end,9))];
            cAnim3 = [nan;table2array(BARO_table(1:2:8597-3,4))];
            xAnim=[nan;table2array(GPS_table(1:4297,6))];
            yAnim=[nan;table2array(GPS_table(1:4297,7))];
            zAnim=[nan;table2array(GPS_table(1:4297,9))];
            lx = length(xAnim);
            ly = length(yAnim);
            lz = length(zAnim);
            
            fig10 = figure(10);
            fig10.Position = [360 380 1180 400];
            %% Temperature Plot %%%%%%%%%%%%%
            subplot(1,3,1);
            ax1 = gca;
            title('Temperature (°C)');
            xlim(ax1, [min(xAnim(2:lx)) max(xAnim(2:lx))]);
            ylim(ax1, [min(yAnim(2:ly)) max(yAnim(2:ly))]);
            zlim(ax1, [min(zAnim(2:lz)) max(zAnim(2:lz))]);
            view(ax1, 3)
            grid on
            zl = zlabel('Altitude (m, AGL)');
            xticks(min(xAnim):((max(xAnim)-min(xAnim))/4):max(xAnim));
            yticks(min(yAnim):((max(yAnim)-min(yAnim))/4):max(yAnim));
            zticks(min(zAnim):((max(zAnim)-min(zAnim))/5):max(zAnim));
            xtickformat('%.3f')
            ytickformat('%.3f')
            ztickformat('%.0f')
            set(ax1,'Color','k','xcolor','w','ycolor','w','zcolor','w','LineWidth',2)
            
            data_range1 = ceil(max(max(cAnim1(2:end)))) - floor(min(min(cAnim1(2:end)))) + 1;
            colormap(jet(data_range1*10));
            caxis([min(min(cAnim1(2:end))) max(max(cAnim1(2:end)))])
            cbh1 = colorbar();
            cbh1.Ticks = round(min(min(cAnim1(2:end))):((max(max(cAnim1(2:end)))-min(min(cAnim1(2:end))))/5):max(max(cAnim1(2:end))),0);
            ticks1 = strsplit(num2str(cbh1.Ticks));
            ax01 = axes('Position', cbh1.Position);
            edges1 = linspace(0,1,numel(ticks1)+1);
            centers1 = edges1(2:end)-((edges1(2)-edges1(1))/2);
            text(ones(size(centers1))*0.5, centers1, ticks1, 'FontSize', cbh1.FontSize,'BackgroundColor','w','Margin',1,'HorizontalAlignment', 'Center', 'VerticalAlignment', 'Middle');
            ax01.Visible = 'off';   %turn off new axes
            cbh1.Ticks = [];
            %% Humidity Plot %%%%%%%%%%%%%
            subplot(1,3,2);
            ax2 = gca;
            title('Relative Humidity (%)');
            xlim(ax2, [min(xAnim(2:lx)) max(xAnim(2:lx))]);
            ylim(ax2, [min(yAnim(2:ly)) max(yAnim(2:ly))]);
            zlim(ax2, [min(zAnim(2:lz)) max(zAnim(2:lz))]);
            view(ax2, 3)
            grid on
            xticks(min(xAnim):((max(xAnim)-min(xAnim))/4):max(xAnim));
            yticks(min(yAnim):((max(yAnim)-min(yAnim))/4):max(yAnim));
            zticks(min(zAnim):((max(zAnim)-min(zAnim))/5):max(zAnim));
            xtickformat('%.3f')
            ytickformat('%.3f')
            ztickformat('%.0f')
            set(ax2,'Color','k','xcolor','w','ycolor','w','zcolor','w','LineWidth',2)
            
            data_range2 = ceil(max(max(cAnim2(2:end)))) - floor(min(min(cAnim2(2:end)))) + 1;
            colormap(jet(data_range2*10));
            caxis([min(min(cAnim2(2:end))) max(max(cAnim2(2:end)))])
            cbh2 = colorbar();
            cbh2.Ticks = round(min(min(cAnim2(2:end))):((max(max(cAnim2(2:end)))-min(min(cAnim2(2:end))))/5):max(max(cAnim2(2:end))),1);
            ticks2 = strsplit(num2str(cbh2.Ticks));
            ax02 = axes('Position', cbh2.Position);
            edges2 = linspace(0,1,numel(ticks2)+1);
            centers2 = edges2(2:end)-((edges2(2)-edges2(1))/2);
            text(ones(size(centers2))*0.5, centers2, ticks2, 'FontSize', cbh2.FontSize,'BackgroundColor','w','Margin',1,'HorizontalAlignment', 'Center', 'VerticalAlignment', 'Middle');
            ax02.Visible = 'off';   %turn off new axes
            cbh2.Ticks = [];
            %% Pressure Plot %%%%%%%%%%%%%
            subplot(1,3,3);
            ax3 = gca;
            title('Pressure (mbar)');
            xlim(ax3, [min(xAnim(2:lx)) max(xAnim(2:lx))]);
            ylim(ax3, [min(yAnim(2:ly)) max(yAnim(2:ly))]);
            zlim(ax3, [min(zAnim(2:lz)) max(zAnim(2:lz))]);
            view(ax3, 3)
            grid on
            xticks(min(xAnim):((max(xAnim)-min(xAnim))/4):max(xAnim));
            yticks(min(yAnim):((max(yAnim)-min(yAnim))/4):max(yAnim));
            zticks(min(zAnim):((max(zAnim)-min(zAnim))/5):max(zAnim));
            xtickformat('%.3f')
            ytickformat('%.3f')
            ztickformat('%.0f')
            set(ax3,'Color','k','xcolor','w','ycolor','w','zcolor','w','LineWidth',2)
            
            data_range3 = ceil(max(max(cAnim3(2:end)))) - floor(min(min(cAnim3(2:end)))) + 1;
            colormap(jet(data_range3*10));
            caxis([min(min(cAnim3(2:end))) max(max(cAnim3(2:end)))])
            cbh3 = colorbar();
            cbh3.Ticks = round(min(cAnim3(2:end)):((max(cAnim3(2:end))-min(cAnim3(2:end)))/5):max(cAnim3(2:end)),1);
            ticks3 = strsplit(num2str(cbh3.Ticks));
            ax03 = axes('Position', cbh3.Position);
            edges3 = linspace(0,1,numel(ticks3)+1);
            centers3 = edges3(2:end)-((edges3(2)-edges3(1))/2);
            text(ones(size(centers3))*0.5, centers3, ticks3, 'FontSize', cbh3.FontSize,'BackgroundColor','w','Margin',1,'HorizontalAlignment', 'Center', 'VerticalAlignment', 'Middle');
            ax03.Visible = 'off';   %turn off new axes
            cbh3.Ticks = [];
            %% Position Control
            subfig = get(gcf,'children');
            set(subfig(1),'position',[.98 -.115 0 2.1]);  % Pressure color bar labels
            %set(subfig(1),'position',[0.98 0.19 0 .62]);
            set(subfig(2),'position',[.97 .2125 .02 .58]);     % Pressure color bar
            set(subfig(3),'position',[.7025 .06 .265 .88]);    % Pressure mian plotting area
            set(subfig(4),'position',[.6545 0.19 0 .62]);   % Humidity color bar labels
            set(subfig(5),'position',[.645 .2125 .02 .58]);      % Humidity color bar
            set(subfig(6),'position',[.3775 .06 .265 .88]);   % Humidity main plotting area
            set(subfig(7),'position',[.33 0.19 0 .62]);   % Temperature color bar labels
            set(subfig(8),'position',[.32 .2125 .02 .58]);      % Temperature color bar
            set(subfig(9),'position',[.053 .06 .265 .88]);    % Temperature main plotting area
            
            view(subfig(3),-45,20);
            view(subfig(6),-45,20);
            view(subfig(9),-45,20);
            
            AnimPos = [.025 .88 .09 .1];
            zl.Position = [34.9796 -97.51672 744.2306];
            %% Set Axis Colors
            ax1.ZTickLabel(1) = {'0'};
            ax2.ZTickLabel(1) = {'0'};
            ax3.ZTickLabel(1) = {'0'};
            
            for i=1:length(ax1.XTickLabel)
                ax1.XTickLabel{i} = ['\color[rgb]{0,0,0}' ax1.XTickLabel{i}];
                ax2.XTickLabel{i} = ['\color[rgb]{0,0,0}' ax2.XTickLabel{i}];
                ax3.XTickLabel{i} = ['\color[rgb]{0,0,0}' ax3.XTickLabel{i}];
            end
            for j=1:length(ax1.YTickLabel)
                ax1.YTickLabel{j} = ['\color[rgb]{0,0,0}' ax1.YTickLabel{j}];
                ax2.YTickLabel{j} = ['\color[rgb]{0,0,0}' ax2.YTickLabel{j}];
                ax3.YTickLabel{j} = ['\color[rgb]{0,0,0}' ax3.YTickLabel{j}];
            end
            for k=1:length(ax1.ZTickLabel)
                ax1.ZTickLabel{k} = ['\color[rgb]{0,0,0}' ax1.ZTickLabel{k}];
                ax2.ZTickLabel{k} = ['\color[rgb]{0,0,0}' ax2.ZTickLabel{k}];
                ax3.ZTickLabel{k} = ['\color[rgb]{0,0,0}' ax3.ZTickLabel{k}];
            end
            
            ax1.XTickLabel(i) = {' '};
            ax2.XTickLabel(i) = {' '};
            ax3.XTickLabel(i) = {' '};
            ax1.YTickLabel(j) = {' '};
            ax2.YTickLabel(j) = {' '};
            ax3.YTickLabel(j) = {' '};
            
            zl.Color = 'k';
            %% Animation Function
            open(myVideo);
            for jj=1:interval:length(xAnim);
                try
                    p1 = patch(ax1,xAnim(1:jj),yAnim(1:jj),zAnim(1:jj),cAnim1(1:jj),'EdgeColor','interp','FaceColor','none','LineWidth',2); view(-45,45)
                    p2 = patch(ax2,xAnim(1:jj),yAnim(1:jj),zAnim(1:jj),cAnim2(1:jj),'EdgeColor','interp','FaceColor','none','LineWidth',2); view(-45,45)
                    p3 = patch(ax3,xAnim(1:jj),yAnim(1:jj),zAnim(1:jj),cAnim3(1:jj),'EdgeColor','interp','FaceColor','none','LineWidth',2); view(-45,45)
                    
                    delete(findall(fig10,'type','annotation'));
                    Seconds = floor(mod(timer(jj,1),60));
                    Minutes = fix(timer(jj,1)/60);
                    
                    if(Seconds<10)
                        String = {sprintf('Time (min:sec)\n%.0f:0%.0f',Minutes,Seconds)};
                    else
                        String = {sprintf('Time (min:sec)\n%.0f:%.0f',Minutes,Seconds)};
                    end
                    annotation(fig10,'textbox',AnimPos,'String',String,'HorizontalAlignment','center','VerticalAlignment','middle');
                    
                    
                    pause(1/50); %Pause and grab frame
                    frame = getframe(gcf); %get frame
                    writeVideo(myVideo, frame);
                    cla(ax1);
                    cla(ax2);
                    cla(ax3);
                catch
                    pause(1/50); %Pause and grab frame
                    frame = getframe(gcf); %get frame
                    writeVideo(myVideo, frame);
                    close(myVideo);
                    break
                    
                end
            end
            close(myVideo);
        else
            %% Animation Setup
            WindSpacing = NKF2_table(1:5:end,:);
            
            if(height(GPS_table)<height(WindSpacing))
                WindSpacing = WindSpacing(1:height(GPS_table),:);
            else GPS_table = GPS_table(1:height(WindSpacing),:);
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
            NW = table2array(WindSpacing(:,4));
            EW = table2array(WindSpacing(:,5));
            WindMag = round(table2array(WindSpacing(:,6)),1);
            
            limHigh = max(max(abs(EW),abs(NW)));
            limLow = -limHigh;
            
            fig10 = figure(10);
            fig10.Position=[130 130 800 600];
            fig10.Resize = 'off';
            
            xAnim1=[nan;Long(:,1)];
            yAnim1=[nan;Lat(:,1)];
            zAnim1=[nan;Alt(:,1)];
            
            lx = length(xAnim1);
            ly = length(yAnim1);
            lz = length(zAnim1);
            %% Wind Plot %%%%%%%%%%%%%
            subplot(1,2,1)
            % Wind Plotting Data
            ax1 = gca;
            % Modified compass figure with higher radial limit
            c1=compass(ax1,[0 0],[limHigh 0]);
            set(c1(1),'visible','off')
            set(ax1,'ydir','reverse')
            labels = findall(ax1,'type','text');
            % Altering the angular label
            set(findall(ax1, 'String', '0'),'String', 'N');
            set(findall(ax1, 'String', '90'),'String', 'E');
            set(findall(ax1, 'String', '180'),'String', 'S');
            set(findall(ax1, 'String', '270'),'String', 'W');
            set(labels(3:6),'visible','off');
            set(labels(9:12),'visible','off');
            
            view(ax1, -90,90)
            title({'Pixhawk-Estimated Wind Rose';''});
            %% GPS Plot %%%%%%%%%%%%%
            subplot(1,2,2)
            % GPS Plotting data
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
            
            %ax2.XTickLabel{i} = [];   ax2.YTickLabel{j} = [];
            
            xl.Color = 'k';
            yl.Color = 'k';
            zl.Color = 'k';
            %% Position Control
            subfig1 = get(gcf,'children');
            set(subfig1(1),'position',[.1 .075 .8 .8]);     % GPS animation space
            set(subfig1(2),'position',[.725 .725 .225 .225]);   % Wind rose
            
            view(subfig1(1),-45,45);
            
            display('Beginning animation sequence');
            %% Animation Function
            if(strcmpi(recordAnimation,'Yes'));
                myVideo = VideoWriter('WindBarbTest_2D','MPEG-4'); %open video file
                myVideo.FrameRate = animateFPS;  %can adjust this, 5 - 10 works well for me
                myVideo.Quality = 100;
                open(myVideo);
                
                for i=1:animateSpeed:length(EW);
                    c1=compass(ax1,[0 EW(i)],[limHigh NW(i)]);
                    set(c1(1),'visible','off');
                    labels = findall(ax1,'type','text');
                    view(ax1, -90,90);
                    set(ax1,'ydir','reverse');
                    set(labels(13),'visible','off');
                    set(labels(14),'visible','off');
                    
                    set(c1(2),'LineWidth',1.5,'color','red');
                    annotation('textbox',[.645 .55 .3 .3],'String',sprintf('%s %s',num2str(WindMag(i)),'m/s'),'FitBoxToText','on');
                    
                    if(i<=(animateTailLength+1))
                        pH1 = patch(ax2,'XData',xAnim1(1:i),'YData',yAnim1(1:i),'ZData',zAnim1(1:i),'EdgeColor','r','FaceColor','none','LineWidth',animateTailWidth);
                        pH2 = patch(ax2,'XData',xAnim1(i),'YData',yAnim1(i),'ZData',zAnim1(i),'Marker','o','MarkerSize',animateHeadSize,'MarkerFaceColor','red','MarkerEdgeColor','none');
                    else
                        pH1 = patch(ax2,'XData',[nan; xAnim1((i-animateTailLength):i)],'YData',[nan; yAnim1((i-animateTailLength):i)],'ZData',[nan; zAnim1((i-animateTailLength):i)],'EdgeColor','r','FaceColor','none','LineWidth',animateTailWidth);
                        pH2 = patch(ax2,'XData',xAnim1(i),'YData',yAnim1(i),'ZData',zAnim1(i),'Marker','o','MarkerSize',animateHeadSize,'MarkerFaceColor','red','MarkerEdgeColor','none');
                    end
                    
                    pause(1/(50)) %Pause and grab frame
                    frame = getframe(gcf); %get frame
                    writeVideo(myVideo, frame);
                    delete(findall(fig10,'type','annotation'));
                    cla(ax2);
                    
                end
                
                close(myVideo);
            else
                for i=1:animateSpeed:length(EW);
                    
                    c1=compass(ax1,[0 EW(i)],[limHigh NW(i)]);
                    set(c1(1),'visible','off');
                    labels = findall(ax1,'type','text');
                    view(ax1, -90,90);
                    set(ax1,'ydir','reverse');
                    set(findall(ax1, 'String', '0'),'String', 'N');
                    set(findall(ax1, 'String', '90'),'String', 'E');
                    set(findall(ax1, 'String', '180'),'String', 'S');
                    set(findall(ax1, 'String', '270'),'String', 'W');
                    set(labels(3:6),'visible','off');
                    set(labels(9:14),'visible','off');
                    
                    set(c1(2),'LineWidth',1.5,'color','red');
                    annotation('textbox',[.645 .55 .3 .3],'String',sprintf('%s %s',num2str(WindMag(i)),'m/s'),'FitBoxToText','on');
                    
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
        end
    end
    %% Hover/Profile Averaging
    if(strcmpi(hoverProfile,'Hover') | strcmpi(hoverProfile,'Profile'))
        warning('off','MATLAB:ISMEMBER:RowsFlagIgnored');
        warning('off','MATLAB:table:RowsAddedExistingVars');
        %% Merge Suite and GPS data
        for i=1:height(TPH_table)
            currentTPH = table2cell(TPH_table(i,5));
            currentTPH = currentTPH{1};
            A(i,1) = cellstr(currentTPH(1:end-2));
        end
        
        for i=1:height(GPS_table)
            currentGPS = table2cell(GPS_table(i,5));
            currentGPS = currentGPS{1};
            B(i,1) = cellstr(datetime(currentGPS,'Format','HH:mm:ss.S'));
        end
        
        idx1 = ismember(A, B, 'rows');
        
        count=1;
        for i=1:length(idx1)
            if(idx1(i) == 1)
                iteration1(count,1) = i;
                tempVals(count,1) = A(i);
                count=count+1;
            end
        end
        
        GPS_time_alone = cellstr(GPS_full_time(:,1:end-2));
        idx2 = ismember(GPS_time_alone,tempVals,'rows');
        
        count=1;
        for i=1:length(idx2)
            if(idx2(i) == 1)
                iteration2(count,1) = i;
                count=count+1;
            end
        end
        
        GPS_table_new = GPS_table(iteration2,:);
        
        count=1;
        for i=1:height(GPS_table_new)
            test = find(BARO(:,1)>=table2array(GPS_table_new(i,1)),1,'first');
            if (test >= 1)
                iteration3(count,1) = test;
                count=count+1;
            end
        end
        
        itLen = [length(iteration1) length(iteration2) length(iteration3)];
        
        finalTable = [GPS_table(iteration2(1:min(itLen)),4:10) BARO_table(iteration3(1:min(itLen)),4:5) TPH_table(iteration1(1:min(itLen)),6:11)];
        
        baseFileName = sprintf('%s_Parsed_Pix_Suite.csv', baseNameNoExtDFL);
        fullOutputMatFileName = fullfile(folderDFL, baseFileName);
        % Write data to text file
        writetable(finalTable, fullOutputMatFileName);
        %% Hover with 10 second averaging
        if(strcmpi(hoverProfile,'Hover'))
            count=1;
            for i=1:50:(height(finalTable)-50)
                tempArray1(count,1) = finalTable(i,1);
                tempArray1(count,2) = finalTable(i,2);
                tempArray1(count,3:7) = finalTable(i,3:7);
                tempArray1(count,8:15) = array2table(mean(table2array(finalTable(i:(i+50),8:15))));
                count=count+1;
            end
            
            tempArray1.Properties.VariableNames = finalTable.Properties.VariableNames;
            baseFileName = sprintf('%s_Suite_10sec_Av.csv', baseNameNoExtDFL);
            fullOutputMatFileName = fullfile(folderDFL, baseFileName);
            % Write data to text file
            writetable(tempArray1, fullOutputMatFileName);
        end
        %% Profile with 10 meter averaging
        if(strcmpi(hoverProfile,'Profile'))
            count=1;
            iter=1;
            startAlt = table2array(finalTable(iter,6));
            for i=1:height(finalTable)
                curAlt = table2array(finalTable(i,6));
                
                if((abs(curAlt - startAlt)) >= 10)
                    tempArray2(count,1) = array2table(mean(table2array(finalTable(iter:i,1))));
                    tempArray2(count,2) = array2table(mean(table2array(finalTable(iter:i,2))));
                    tempArray2(count,3:15) = array2table(mean(table2array(finalTable(iter:i,3:15))));
                    iter=i;
                    count=count+1;
                    startAlt = table2array(finalTable(iter,6));
                end
            end
            
            tempArray2.Properties.VariableNames = finalTable.Properties.VariableNames;
            baseFileName = sprintf('%s_Suite_10m_Av.csv', baseNameNoExtDFL);
            fullOutputMatFileName = fullfile(folderDFL, baseFileName);
            % Write data to text file
            writetable(tempArray2, fullOutputMatFileName);
        end
        warning('on','MATLAB:ISMEMBER:RowsFlagIgnored');
        warning('on','MATLAB:table:RowsAddedExistingVars');
    end
else
    
    %% USGS Mapping Data
    baseURL = "https://basemap.nationalmap.gov/ArcGIS/rest/services";
    usgsURL = baseURL + "/BASEMAP/MapServer/tile/${z}/${y}/${x}";
    basemaps = ["USGSImageryOnly" "USGSImageryTopo" "USGSTopo" "USGSShadedReliefOnly" "USGSHydroCached"];
    displayNames = ["USGS Imagery" "USGS Topographic Imagery" "USGS Shaded Topographic Map" "USGS Shaded Relief" "USGS Hydrography"];
    attribution = 'Credit: U.S. Geological Survey';
    %% Load All GPS Files
    
    [baseFileName, folder]=uigetfile('*.mat','Select the INPUT DATA FILE(s)','MultiSelect','on');
    disp('Parsing and merging Pixhawk files.')
    
    if(strcmpi(simultaneous,'Yes'))
        for i=1:length(baseFileName)
            fullInputMatFileName(i) = fullfile(folder, baseFileName(i));
            load(char(fullInputMatFileName(i)),'GPS');
            
            Time{:,i} = GPS(2:end,4);
            Speed{:,i} = GPS(2:end,11);
            Lat{:,i} = GPS(2:end,8);
            Long{:,i} = GPS(2:end,9);
            Alt{:,i} = GPS(2:end,10);
            minTime(i) = min(GPS(2:end,4));
            maxTime(i) = max(GPS(2:end,4));
            clear GPS
            
        end
    else
        for i=1:length(baseFileName)
            fullInputMatFileName(i) = fullfile(folder, baseFileName(i));
            load(char(fullInputMatFileName(i)),'GPS');
            
            rawLat{:,i} = GPS(2:end,8);
            rawLong{:,i} = GPS(2:end,9);
            rawAlt(:,i) = GPS(2:end,10);
            rawSpeed{:,i} = GPS(2:end,11);
            clear GPS
            
        end
        
        for k=1:i
            Speed = [rawSpeed{k}];
            tempLat = [rawLat{k}];
            tempLong = [rawLong{k}];
            tempAlt = [rawAlt{k}];
            Lat{k} = tempLat(Speed>.5);
            Long{k} = tempLong(Speed>.5);
            Alt{k} = tempAlt(Speed>.5);
            clear tempLat tempLong tempAlt Speed
        end
    end
    
    
    disp('Completed Pixhawk file manipulation.');
    %% Data Merging
    % Combine all datasets into arrays of same size
    % find all takeoff times
    % find first aircraft to takeoff
    % convert times to basic plotting number (incriment of 1)
    % keep lat/long of all grounded aircraft, but pad with plotting number
    % plot all aircraft according to plotting number, with lat/long being
    %   the only differntiating factor
    
    if(strcmpi(simultaneous,'Yes'))
        
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
        
        finLat(1:length(translate(:,1)),1:i)=0;
        finLong(1:length(translate(:,1)),1:i)=0;
        finAlt(1:length(translate(:,1)),1:i)=0;
        finTime(:,1) = translate(:,2);
        finSpeed(1:length(translate(:,1)),1:i) = 0;
        
        for(j = 1:i)
            curTime = round(cell2mat(Time(j)),-2);
            curLat = cell2mat(Lat(j));
            curLong = cell2mat(Long(j));
            curAlt = cell2mat(Alt(j));
            curSpeed = cell2mat(Speed(j));
            count=0;
            for k = 1:length(curTime);
                Catch = find(curTime(k,1)==translate(:,1),1,'first');
                if(Catch>=0)
                    count=count+1;
                    if(count ~= 1)
                        finLat(Catch,j) = curLat(k,1);
                        finLong(Catch,j) = curLong(k,1);
                        finAlt(Catch,j) = curAlt(k,1);
                        finSpeed(Catch,j) = curSpeed(k,1);
                    else
                        finLat(1:Catch,j)=curLat(k,1);
                        finLong(1:Catch,j)=curLong(k,1);
                        finAlt(1:Catch,j)=curAlt(k,1);
                        finSpeed(1:Catch,j) = curSpeed(k,1);
                    end
                end
            end
            finLat(Catch:end,j) = curLat(end,1);
            finLong(Catch:end,j) = curLong(end,1);
            finAlt(Catch:end,j) = curAlt(end,1);
            finSpeed(Catch:end,j) = curSpeed(end,1);
            clear curTime curLat curLong curAlt
        end
        
        for col = 1:size(finLat,2)
            for row = 1:size(finLat,1)
                if finLat(row,col) == 0
                    finLat(row,col) = finLat(row-1,col);
                end
            end
        end
        
        for col = 1:size(finLong,2)
            for row = 1:size(finLong,1)
                if finLong(row,col) == 0
                    finLong(row,col) = finLong(row-1,col);
                end
            end
        end
        
        for col = 1:size(finAlt,2)
            for row = 1:size(finAlt,1)
                if finAlt(row,col) == 0
                    finAlt(row,col) = finAlt(row-1,col);
                end
            end
        end
        
        for(k = 1:i)
            try startSpeed(k) = find(finSpeed(:,k) >=1,1,'first');
                endSpeed(k) = find(finSpeed(:,k) >=1,1,'last');
                
            catch startSpeed(k) = -1;
                endSpeed(k) = -1;
            end
        end
        
        firstSpeed = min(startSpeed(startSpeed > 0));
        lastSpeed = max(endSpeed(endSpeed > 0));
        
        startSpeed(startSpeed<0) = firstSpeed;
        endSpeed(endSpeed<0) = lastSpeed;
        
        trimStart = min(startSpeed);
        trimEnd = max(endSpeed);
        
        finLat = finLat(trimStart:trimEnd,:);
        finLong = finLong(trimStart:trimEnd,:);
        finAlt = finAlt(trimStart:trimEnd,:);
        finTime = finTime(trimStart:trimEnd,:);
    end
    %% Animation Function
    
    % Color Setup
    ColOrd = [1 0 0; 0 1 0; 0 0 1; 1 1 1; 0 0 0; 1 1 0; 1 0 1; 0 1 1];
    [m,n] = size(ColOrd);
    
    % Animation of the Pixhawk Log from recorded GPS coordinates
    if(strcmpi(simultaneous,'Yes'))
        minLat = min(min(finLat));
        maxLat = max(max(finLat));
        minLong = min(min(finLong));
        maxLong = max(max(finLong));
        minAlt = min(min(finAlt));
        maxAlt = max(max(finAlt));
        
        if(strcmpi(animation,'No'))
            
            disp('Beginning plot setup.');
            
            fig1=figure(1);
            fig1.Position = [10 50 560 725];
            fig1.Resize = 'off';
            
            ax = geoaxes();
            geobasemap('satellite')
            basemapx = basemaps(2);
            url = replace(usgsURL,"BASEMAP",basemapx);
            view(ax,2)
            
            disp('Starting the plotting process.');
            
            for(j =1:i)
                ColRow = rem(j,m);
                if ColRow == 0
                    ColRow = m;
                end
                Col = ColOrd(ColRow,:);
                
                hold on
                
                geoplot(ax,finLat(:,j),finLong(:,j),'Color',Col,'LineWidth',.8);
                geoplot(ax,finLat(end,j),finLong(end,j),'LineStyle','none','Marker','o','MarkerSize',6,'MarkerFaceColor',Col,'MarkerEdgeColor',Col);
                
                geobasemap('satellite')
                geolimits([minLat-.0005 maxLat+.0005],[minLong-.0005 maxLong+.0005]);
            end
            
            title(plotTitle);
            
            baseFileNamePic = sprintf('MergedData_Image10');
            fullParsedMatFileNamePic = fullfile(folder, baseFileNamePic);
            
            saveas(fig,fullParsedMatFileNamePic,'png')
            
            
            disp('Successfully completed plot.');
            
        elseif (strcmpi(animation,'Yes'))
            
            disp('Beginning animation setup.');
            
            tot = ceil(length(finLat(:,1))/iterationSkip);
            
            fig1 = figure(1);
            fig1.Position = [10 50 560 725];
            fig1.Resize = 'off';
            
            if(strcmpi(isometric,'No'))
                
                ax = geoaxes();
                geobasemap('satellite')
                basemapx = basemaps(2);
                url = replace(usgsURL,"BASEMAP",basemapx);
                view(ax,2)
                title(plotTitle);
                
                disp('Starting the animation process.');
                
                open(animVid);
                
                ptot = 0;
                
                for jj=1:iterationSkip:length(finLat(:,1))
                    hold on
                    for k = 1:i
                        ColRow = rem(k,m);
                        if ColRow == 0
                            ColRow = m;
                        end
                        Col = ColOrd(ColRow,:);
                        hold on
                        
                        geoplot(ax,finLat(1:jj,k),finLong(1:jj,k),'Color',Col,'LineWidth',.8);
                        geoplot(ax,finLat(jj,k),finLong(jj,k),'LineStyle','none','Marker','o','MarkerSize',6,'MarkerFaceColor',Col,'MarkerEdgeColor',Col);
                        
                        geobasemap('satellite')
                        geolimits([minLat-.0005 maxLat+.0005],[minLong-.0005 maxLong+.0005]);
                    end
                    pause(.001);
                    frame = getframe(gcf);
                    writeVideo(animVid,frame);
                    ptot = ptot+1;
                    display = sprintf('Iteration: %d of %d, %s%% complete',ptot,tot,num2str(round(ptot/tot*100,1)));
                    disp(display);
                    cla(ax);
                    hold off
                end
                
                close(animVid);
                
                disp('Successfully completed animation.');
            else
                ax = gca();
                axis([minLat maxLat minLong maxLong minAlt maxAlt]);
                view(ax, 3)
                xticks(minLat:((maxLat-minLat)/4):maxLat);
                yticks(minLong:((maxLong-minLong)/4):maxLong);
                zticks(minAlt:((maxAlt-minAlt)/5):maxAlt);
                xtickformat('%.1f')
                ytickformat('%.1f')
                ztickformat('%.0f')
                title(plotTitle);
                grid
                
                view(ax,[azimuthAngle elevationAngle]);
                
                disp('Starting the animation process.');
                
                open(animVid);
                
                ptot = 0;
                
                for jj=1:iterationSkip:length(finLat(:,1))
                    hold on
                    for k = 1:i
                        ColRow = rem(k,m);
                        if ColRow == 0
                            ColRow = m;
                        end
                        Col = ColOrd(ColRow,:);
                        hold on
                        
                        plot3(ax,finLat(1:jj,k),finLong(1:jj,k),finAlt(1:jj,k),'Color',Col,'LineWidth',.8);
                        plot3(ax,finLat(jj,k),finLong(jj,k),finAlt(jj,k),'LineStyle','none','Marker','o','MarkerSize',6,'MarkerFaceColor',Col,'MarkerEdgeColor',Col);

                    end
                    pause(.001);
                    frame = getframe(gcf);
                    writeVideo(animVid,frame);
                    ptot = ptot+1;
                    display = sprintf('Iteration: %d of %d, %s%% complete',ptot,tot,num2str(round(ptot/tot*100,1)));
                    disp(display);
                    cla(ax);
                    hold off
                end
                
                close(animVid);
                
                disp('Successfully completed animation.');
            end
        end
        
    else
        % Animation of the Pixhawk Log from recorded GPS coordinates
        minLat = min(min(cell2mat(Lat(:))));
        maxLat = max(max(cell2mat(Lat(:))));
        minLong = min(min(cell2mat(Long(:))));
        maxLong = max(max(cell2mat(Long(:))));
        minAlt = min(min(cell2mat(Alt(:))));
        maxAlt = max(max(cell2mat(Alt(:))));
        
        if(strcmpi(animation,'No'))
            
            disp('Beginning plot setup.');
            
            fig1=figure(1);
            fig1.Position = [10 50 750 600];
            fig1.Resize = 'off';
            
            ax = geoaxes();
            geobasemap('satellite')
            basemapx = basemaps(2);
            url = replace(usgsURL,"BASEMAP",basemapx);
            view(ax,2)
            
            disp('Starting the plotting process.');
            
            for(j =1:i)
                ColRow = rem(j,m);
                if ColRow == 0
                    ColRow = m;
                end
                Col = ColOrd(ColRow,:);
                
                hold on
                
                geoplot(ax,cell2mat(Lat(j)),cell2mat(Long(j)),'Color',Col);
                
                geobasemap('satellite')
                geolimits([minLat-.0005 maxLat+.0005],[minLong-.0005 maxLong+.0005]);
            end
            title(plotTitle);
            
            baseFileNamePic = sprintf('MergedData_Image10');
            fullParsedMatFileNamePic = fullfile(folder, baseFileNamePic);
            
            saveas(fig1,fullParsedMatFileNamePic,'png')
            
            
            disp('Successfully completed plot.');
            
        else
            
            disp('Beginning animation setup.');
            
            % Get the name of the intput.mat file and save as input_parsed.mat
            baseFileName = sprintf('MergedData_Animation1');
            fullParsedMatFileName = fullfile(folder, baseFileName);
            
            % Initialize total iteration count
            tot=0;
            for l=1:i
                tot = tot+numel(Lat{l});
            end
            
            tot=ceil(tot/iterationSkip)+1;
            
            animVid = VideoWriter(fullParsedMatFileName,'MPEG-4');
            animVid.FrameRate = 20;  %can adjust this, 5 - 10 works well for me
            animVid.Quality = 100;
            
            fig1 = figure(1);
            fig1.Position = [10 50 750 600];
            fig1.Resize = 'off';
            
            ax = geoaxes();
            geobasemap('satellite')
            basemapx = basemaps(2);
            url = replace(usgsURL,"BASEMAP",basemapx);
            view(ax,2)
            title(plotTitle);
            
            disp('Starting the animation process.');
            
            open(animVid);
            
            ptot = 0;
            for k=1:i
                hold on
                tLat = cell2mat(Lat(k));
                tLong = cell2mat(Long(k));
                for jj=1:iterationSkip:length(tLat)
                    ColRow = rem(k,m);
                    if ColRow == 0
                        ColRow = m;
                    end
                    Col = ColOrd(ColRow,:);
                    hold on
                    
                    
                    geoplot(ax,tLat(1:jj),tLong(1:jj),'Color',Col);
                    geoplot(ax,tLat(jj),tLong(jj),'LineStyle','none','Marker','o','MarkerSize',6,'MarkerFaceColor',Col);
                    
                    if(k>1)
                        for x = 1:(k-1)
                            ColRow = rem(x,m);
                            if ColRow == 0
                                ColRow = m;
                            end
                            Col = ColOrd(ColRow,:);
                            geoplot(ax,cell2mat(Lat(x)),cell2mat(Long(x)),'Color',Col);
                        end
                    end
                    
                    
                    geobasemap('satellite')
                    %geolimits([minLat-.0005 maxLat+.0005],[minLong-.0005 maxLong+.0005]);
                    
                    pause(.001);
                    frame = getframe(gcf);
                    writeVideo(animVid,frame);
                    ptot = ptot+1;
                    display = sprintf('Iteration: %d of %s, %s%% complete',ptot,num2str(tot),num2str(round(ptot/tot*100,1)));
                    disp(display);
                    cla(ax);
                    hold off
                end
            end
            
            
            close(animVid);
            
            disp('Successfully completed animation.');
            
        end
    end
end

disp('All operations completed.');
