% Pixhawk DFL Analyzer V4.3.
% Created by:    Levi Ross
% Edited by:     Kyle Hickman, James Brenner
% Unmanned Systems Research Institute
% Creation Date: 11/17/2019
% Last Modified: 11/5/2020
% New features:
%    * Replay _Parsed files
%    * No longer need to set Ardupilot type, auto-selected from MSG1 log
%    * Added Wind Rose to view estimated wind speed data form Pixhawk
%    * Added PlotMergedData codeset, allowing for simultaneous or series data plots
%    * Added custom .bin -> .mat converter, eliminating the need for Mission Planner

%% Clear All Data
close all
clear all
clc

%% Initialize User-Defined Content
thrMinPWM = 1100;              % Default, scales THR% plots
thrMaxPWM = 1900;              % Default, scales THR% plots

DFL_NewOld = 'Unknown';
ArduPilotType = 'Default';
Single_Multi = 'Single';
graphToggle = 'Yes';            % Show plots of parsed data
animateToggle = 'Yes';         % Flight animation based on GPS and Alt(AGL)
recordAnimation = 'No';
StateSpace = 'No';             % Pixhawk recorded SS variable output (new file)
iMetValue = 'No';             % Load iMet data (XQ1 - small | XQ2 - large)
MHPValue = 'No';              % Load 5HP/TPH data (use 5HP)
TPHValue = 'No';              % Load 5HP/TPH data (use TPH)
Overlay = 'Yes';               % Show iMet & 5HP/TPH alongside Pixhawk data plots
GPS_out = 'No';               % Output GPS data as individual file (lat, long, alt)
Sensor_out = 'No';             % Output parsed sensor data (iMet seperate from 5HP/TPH)
Attitude_out = 'No';          % Output parsed attitude data
SensorCompare = 'Yes';         % Show iMet, 5HP/TPH, and Pixhawk atmoshperic sensors on same plots
pitchToggle = 'No';            % TIA-Specific
throttleToggle = 'No';         % TIA-Specific
Aircraft = 'N/A';              % TIA-Specific
TVToggle = 'No';               % TIA-Specific
indvToggle = 'No';             % TIA-Specific

Plot_Title = 'Test Custom Title';
animateSpeed = 5;             % Overall speed
animateHeadSize = 2;           % Icon size
animateTailWidth = 1;          % Width of tail
animateTailLength = 100;       % Length of tail
animateFPS = 30;

animateHeadSize = animateHeadSize + 5;

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
            ArduPilotType = 'ArduRover';
        elseif(Copter == 1)
            ArduPilotType = 'ArduCopter';
        elseif(QuadPlane == 1)
            ArduPilotType = 'QuadPlane';
        elseif(Plane == 1)
            ArduPilotType = 'FixedWing';
        end
        
        if(strcmpi(ArduPilotType,'FixedWing') | strcmpi(ArduPilotType,'QuadPlane'))
            
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
            
        elseif(strcmpi(ArduPilotType,'ArduCopter') | strcmpi(ArduPilotType,'CopterSonde'))
            
            try
                rawDFL.IMET;
                ArduPilotType = 'CopterSonde';
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
            
            if(strcmpi(ArduPilotType,'ArduCopter'))
                save(fullParsedMatFileName,'GPS','GPS_label','ATT','ATT_label','BARO','BARO_label','NKF2','NKF2_label','IMU','IMU_label','RCOU','RCOU_label','MSG1');
            elseif(strcmpi(ArduPilotType,'CopterSonde'))
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
            MHPValue = 'Yes';
        else MHPValue = 'No';
        end
        
        if(ismember('TPH_table',variableInfo))
            TPHValue = 'Yes';
        else TPHValue = 'No';
        end
        
        if(ismember('iMet_table',variableInfo))
            iMetValue = 'Yes';
        else iMetValue = 'No';
        end
        
        if(ismember('CSIMET_table',variableInfo))
            ArduPilotType = 'CopterSonde';
        end
        
    else
        DFL_NewOld = 'New';
        
        % Parser for ArduPilotType
        if(strcmpi(ArduPilotType,'Default'))
            
            if(ismember('IMET',variableInfo))
                ArduPilotType = 'Coptersonde';
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
                            ArduPilotType = 'Quadcopter';
                        end
                        
                    catch
                    end
                end
                
                if((QuadPlane + ArduPlane) == 2)
                    ArduPilotType = 'Quad-Plane';
                elseif((QuadPlane + ArduPlane) == 1)
                    ArduPilotType = 'Fixed Wing';
                end
            end
        end
        
        % Execution of ArduPilotType
        if(strcmpi(ArduPilotType,'FixedWing'))
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
        
        if(strcmpi(ArduPilotType,'QuadPlane'))
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
        if(strcmpi(ArduPilotType,'ArduCopter'))
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
        if(strcmpi(ArduPilotType,'CopterSonde'))
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
        if(strcmpi(ArduPilotType,'ArduRover'))
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
        
        if(strcmpi(Aircraft,'TIA'))
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
        
        if(strcmpi(Aircraft,'TIA'))
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
        
        fig1=figure('Name','Raw data from DFL. Click on graph for upper and lower bound for parsing.');
        
        if(strcmpi(ArduPilotType,'ArduCopter') | strcmpi(ArduPilotType,'CopterSonde'))
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
            if(strcmpi(ArduPilotType,'ArduCopter') | strcmpi(ArduPilotType,'CopterSonde'))
            else y_va(m)=CTUN(find(CTUN(:,2)>=x_m(m),1,'first'),6);     % Airspeed
            end
            y_vg(m)=GPS(find(GPS(:,2)>=x_m(m),1,'first'),8);      % Groundspeed
            y_thr(m)=RCOU(find(RCOU(:,2)>=x_m(m),1,'first'),5);     % Throttle Percent
            y_pitch(m)=ATT(find(ATT(:,2)>=x_m(m),1,'first'),4); % Aircraft Pitch
            y_alt(m)=GPS(find(GPS(:,2)>=x_m(m),1,'first'),7);    % Altitude
            
            if(strcmpi(ArduPilotType,'ArduCopter') | strcmpi(ArduPilotType,'CopterSonde'))
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
        
        fig2=figure('Name','Preview of user-parsed DFL data.');
        
        if(strcmpi(ArduPilotType,'ArduCopter') | strcmpi(ArduPilotType,'CopterSonde'))
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
        if(strcmpi(ArduPilotType,'ArduCopter'))
            TO_NKF = find(NKF2(:,1)>TO,1,'first')-1;
            LND_NKF = find(NKF2(:,1)>LND,1,'first')-1;
        elseif(strcmpi(ArduPilotType,'CopterSonde'))
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
        if(strcmpi(ArduPilotType,'CopterSonde'))
            wind = WIND(TO_WIND:LND_WIND,4);
            VWN = cos(deg2rad(WIND(TO_WIND:LND_WIND,3))).*wind;
            VWE = sin(deg2rad(WIND(TO_WIND:LND_WIND,3))).*wind;
        elseif(strcmpi(ArduPilotType,'ArduCopter'))
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
        
        if(strcmpi(ArduPilotType,'ArduCopter') | strcmpi(ArduPilotType,'CopterSonde'))
        else
            % Parsed CTUN data output
            CTUN_LN = CTUN(TO_CTUN:LND_CTUN,1);
            CTUN_time = CTUN(TO_CTUN:LND_CTUN,2);
            CTUN_time_out= (CTUN_time-min(CTUN_time))/1000000;
            CTUN = [CTUN_LN, CTUN_time, CTUN_time_out, v_a];
            CTUN_label = {'Line No','Time since boot (us)','Time from Arming (sec)','Airspeed (m/s)'};
            CTUN_table = table(CTUN_LN,CTUN_time,CTUN_time_out,v_a,'VariableNames',{'Line Number','Time from boot (us)','Time from parse (sec)','Airspeed (m/s)'});
        end
        
        if(strcmpi(ArduPilotType,'CopterSonde'))
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
        
        if(strcmpi(ArduPilotType,'ArduCopter'))
            save(fullParsedMatFileName,'ATT_table','GPS_table','NKF2_table','RCOU_table','BARO_table','IMU_table');
        elseif(strcmpi(ArduPilotType,'CopterSonde'))
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
            
            fig3=figure('Name','Parsed iMet data.');
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
            
            if(strcmpi(Sensor_out,'Yes'))
                % Get the name of the input.mat file and save as input_Parsed_TPH.csv
                baseFileName = sprintf('%s_iMet.csv', baseNameNoExtDFL);
                fullOutputMatFileName = fullfile(folderDFL, baseFileName);
                % Write data to text file
                writetable(iMet_table, fullOutputMatFileName);
            end
        end
        
    elseif(strcmpi(DFL_NewOld,'Old'))
        if(exist('iMet_table'))
            if (strcmpi(iMetValue,'Yes'))
                
                fig3=figure('Name','Parsed iMet data.');
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
                
                if(strcmpi(Sensor_out,'Yes'))
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
    if(strcmpi(DFL_NewOld,'New'))
        if (strcmpi(MHPValue,'Yes') | strcmpi(TPHValue,'Yes'))
            
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
            
            list = {'Probe 1', 'Probe 2'}; %user select which probe used, can be added to or changed to aircraft
            [Probe, tf] = listdlg('ListString', list, 'SelectionMode','single');
            
            % preload alpha tables for each probe
            Probe1_alpha_matrix= [-45,-40,-35,-30,-25,-20,-15,-10,-5,0,5,10,15,20,25,30,35,40,45;0.00890950449349955,0.00457311916858462,0.00176531256908854,-0.00384503506543701,-0.00629785482541360,0.00545246173247114,0.00180361752017460,-0.0134706403064275,-0.0209283381586332,0.00161285533724483,-0.00560008335729128,0.00767032479448327,0.00448131173266848,-0.00272215983941427,-0.00785090440434213,-0.00727564907826283,-0.0184637805270442,-0.0370242325174744,-0.0561445552881891;0.00890950449349955,0.00457311916858462,0.00176531256908854,-0.00384503506543701,-0.00629785482541360,0.00545246173247114,0.00180361752017460,-0.0134706403064275,-0.0209283381586332,0.00161285533724483,-0.00560008335729128,0.00767032479448327,0.00448131173266848,-0.00272215983941427,-0.00785090440434213,-0.00727564907826283,-0.0184637805270442,-0.0370242325174744,-0.0561445552881891;-0.0281164870232703,-0.0339345133123480,-0.0447818402609818,-0.0496940217587644,-0.0242475521047252,-0.0117264871876231,-0.0115696568615130,-0.0250751986590787,-0.00694590665125139,-0.00714957678533877,0.000725667229518117,-0.00680065470334982,-0.0180247033199839,-0.0285420721501812,-0.0254202783784962,-0.0259682621478350,-0.0464065013322731,-0.0625425130948133,-0.0404861779430812];
            Probe1_beta_matrix= [-45,-40,-35,-30,-25,-20,-15,-10,-5,0,5,10,15,20,25,30,35,40,45;1.92795857684824,1.86640585880821,1.78333854720023,1.68830618894100,1.48190162295814,1.23007636776323,0.989942128905559,0.714933402777932,0.411757733789909,0.0412836130748961,-0.278289656746039,-0.641333612183352,-0.941173264310510,-1.16344358897035,-1.44969947874859,-1.66524561466847,-1.83235788322404,-1.92531837461670,-1.96114235762177;2.07175085435385,2.01588362356834,1.95731196306822,1.86776316096592,1.68046836139265,1.40618166564641,1.12837516766683,0.804287849511338,0.417473316952088,0.0260789109987813,-0.340765068849449,-0.735715607850259,-1.05241615185050,-1.33683222681374,-1.56705666019825,-1.79889141184890,-1.95376747845494,-2.05113247869176,-2.05826202435863;0.0707290944111967,0.0376513543446743,0.0226534563294856,0.0264146307134629,0.00609391866281019,-0.00506643052956358,-0.0130907730454455,-0.0287532222888066,-0.0569511978027162,-0.0472950752809539,-0.0605531685378152,-0.0575732762134579,-0.0502828667972820,-0.0407598948082382,-0.0568664870215310,-0.0751029239499308,-0.0954227496552539,-0.114525277676976,-0.133946707397796];
            Probe2_alpha_matrix= [-45,-40,-35,-30,-25,-20,-15,-10,-5,0,5,10,15,20,25,30,35,40,45;-0.131242052837307,-0.136389485007933,-0.0809909059420208,-0.0943698966408916,-0.107179638507995,-0.0970363404597239,-0.0878088465662149,-0.0950166849941877,-0.0905382724207439,-0.0997775269439496,-0.0931654202828387,-0.0966954373330949,-0.0974433932122797,-0.0766313531667302,-0.0667290094541538,-0.0620515713369645,-0.0593983197145785,-0.0554435716423099,-0.0487238048745688;4.31105238806679,3.32803564700737,2.64007652102070,2.10583986073405,1.63822159402096,1.24217879451540,0.953015040309201,0.635678243745440,0.304460571816443,-0.0308525655399159,-0.373803002934950,-0.709460058948898,-1.01485174133808,-1.31758819523727,-1.67417295300184,-2.10384223226049,-2.68318423743897,-3.52271057583887,-4.94177953516455;3.63425718124077,2.86316966777994,2.22604557233219,1.72871522342427,1.34583379337387,1.05820130310302,0.759491235826697,0.422458537492854,0.0647766899671877,-0.277326552181110,-0.635443304694023,-0.964413464739489,-1.22766258871014,-1.55942598587771,-1.99792512263178,-2.39196571030306,-2.99692812897453,-3.97483297736893,-5.62531779097425];
            Probe2_beta_matrix= [-45,-40,-35,-30,-25,-20,-15,-10,-5,0,5,10,15,20,25,30,35,40,45;-0.0190106225135046,0.0382333797314247,0.0512317425915240,0.0631388747930030,0.0522869055160835,0.0864766781442044,0.0976082365167135,0.110771223406251,0.128893249247102,0.111788218561612,0.108186757288006,0.111533072107942,0.102716700427734,0.0868793990847530,0.0738948568776470,0.0635370997301279,0.0435495422613849,-0.0284170445218643,-0.115067631331364;5.75688479464282,3.70436182220555,3.02430543922597,2.37319757925664,1.87677428552943,1.45295079193687,1.12626464106161,0.835761939179333,0.504257748113699,0.148612098606411,-0.154484026859164,-0.510025524555466,-0.830916330809970,-1.14102546194907,-1.48533749275955,-1.90925885298210,-2.42553149327421,-3.08747021230988,-4.13177277655773;5.83639065570778,3.54448304087544,2.84150187005140,2.31923900712636,1.78885345267533,1.42383382429329,1.13565584211568,0.853402415828206,0.503305472471274,0.149988335647144,-0.190193536255105,-0.554480064365479,-0.882051407409919,-1.18504801788553,-1.50829204883482,-1.90414734138032,-2.46731350470407,-3.17460754326493,-4.02477177523444];
            
            nrows = length(data(:,1));
            ncols = length(data(1,:));
            
            pressures = zeros(nrows, 4);
            
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
            H1 = data(i,14);
            T1 = data(i,16);
            H2 = data(i,18);
            T2 = data(i,20);
            H3 = data(i,22);
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
            
            pressures(i,1) = time;
            pressures(i,2) = Pitot_pa;
            pressures(i,3) = Alpha_pa;
            pressures(i,4) = Beta_pa;
            
            %Moving Average Calcs
            Pitot_pa_MA=movmean(Pitot_pa,500);
            Alpha_pa_MA=movmean(Alpha_pa,500);
            Beta_pa_MA=movmean(Beta_pa,500);
            
            %Cp Averaged Calcs
            CP_a_MA=Alpha_pa_MA./Pitot_pa_MA;
            CP_b_MA=Beta_pa_MA./Pitot_pa_MA;
            
            % Alpha & Beta Averaged Calcs.
            Alpha_MA=interp1(Probe1_alpha_matrix(2,:), Probe1_alpha_matrix(1,:), CP_a_MA(i)); %just doing 1d interp for now until more speeds ran
            Beta_MA=interp1(Probe1_beta_matrix(2,:), Probe1_beta_matrix(1,:), CP_b_MA(i));
            
            %Cp Calc
            CP_a=Alpha_pa./Pitot_pa;
            CP_b=Beta_pa./Pitot_pa;
            
            % Converts reduced data set pitot measurements to velocity (move down
            % at some point)
            Velocity(i,1)=time;
            Velocity(i,2)=((2/rho)*(abs(Pitot_pa))) .^.5;
            Velocity(i,3)=((2/rho)*(abs(Alpha_pa))) .^.5;
            Velocity(i,4)=((2/rho)*(abs(Beta_pa))) .^.5;
            
            % Calculate alpha and beta probe values
            Alpha=interp1(Probe1_alpha_matrix(2,:), Probe1_alpha_matrix(1,:), CP_a(i)); %just doing 1d interp for now until more speeds ran
            Beta=interp1(Probe1_beta_matrix(2,:), Probe1_beta_matrix(1,:), CP_b(i));
            
            MHPData(i,1)=time;            % Sensor board time
            MHPData(i,2)=-1;              % Will become Pixhawk board time
            MHPData(i,3)=Velocity(i,2);
            MHPData(i,4)=Velocity(i,3);
            MHPData(i,5)=Velocity(i,4);
            MHPData(i,6)=Alpha(i);
            MHPData(i,7)=Beta(i);
            MHPData(i,8)=Alpha_MA(i);
            MHPData(i,9)=Beta_MA(i);
            
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
            
            MHP_DateTime=datetime(MHPData_Unix,'ConvertFrom','posixTime','Format','MMM-dd-yyyy HH:mm:ss.S');
            MHP_Date=datestr(MHP_DateTime,'mmm-dd-yyyy');
            MHP_Time=datestr(MHP_DateTime,'HH:MM:SS.FFF');
            
            if(exist('THSense'))
                THSense(:,2)=round((THSense(:,1)+PixAv),0);
                THSense_Unix=round((THSense(:,1)/1000)+GPS_av,1);
                
                TH_DateTime=datetime(THSense_Unix,'ConvertFrom','posixTime','Format','MMM-dd-yyyy HH:mm:ss.S');
                TH_Date=datestr(TH_DateTime,'mmm-dd-yyyy');
                TH_Time=datestr(TH_DateTime,'HH:MM:SS.FFF');
            end
            
            
            % 5HP and TPH parsing
            if (min(MHP_DateTime) < min(GPS_final))
                TO_MHP = find(MHP_DateTime(:)>=min(GPS_final),1,'first');
            else
                TO_MHP = 1;
            end
            
            if(exist('THSense'))
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
            
            if(exist('THSense'))
                if (max(TH_DateTime) > max(GPS_final))
                    LND_TPH = find(TH_DateTime(:)>=max(GPS_final),1,'first');
                else
                    LND_TPH = length(TH_DateTime);
                end
            end
            
            if(exist('THSense'))
                TPH = THSense(TO_TPH:LND_TPH,:);
                TH_Date = TH_Date(TO_TPH:LND_TPH,:);
                TH_Time = TH_Time(TO_TPH:LND_TPH,:);
                TPH_time_out = (TPH(:,1)-min(TPH(:,1)))/1000;
            end
            
            MHP = MHPData(TO_MHP:LND_MHP,:);
            MHP_Date = MHP_Date(TO_MHP:LND_MHP,:);
            MHP_Time = MHP_Time(TO_MHP:LND_MHP,:);
            MHP_time_out = (MHP(:,1)-min(MHP(:,1)))/1000;
            
            Pix_time_out = (PixData(:,1)-min(PixData(:,1)))/1000;
            
            % Create tables with the data and variable names
            MHP_table = table(MHP(:,1),MHP(:,2),MHP_time_out, MHP_Date, MHP_Time, MHP(:,3),MHP(:,4),MHP(:,5),MHP(:,6),MHP(:,7),MHP(:,8),MHP(:,9), 'VariableNames', {'Board Time from PowerUp (msec)','Pix Time from PowerUp (msec)','Pix time from parse','UTC Date','UTC Time','Pitot-Static (m/s)','V (m/s)','U (m/s)','Alpha(deg)','Beta(deg)','Alpha Mean Aver.','Beta Mean Aver.'} );
            save(fullParsedMatFileName,'MHP_table','-append');
            
            PixData_table = table(PixData(:,1),PixData(:,2),Pix_time_out,PixData(:,3),'VariableNames',{'Sensor board time (ms)','GPS Unix Time (sec)','Pix board time (sec)','Pix board time (ms)'});
            save(fullParsedMatFileName,'PixData_table','-append');
            
            if(exist('THSense'))
                TPH_table = table(TPH(:,1),TPH(:,2),TPH_time_out,TH_Date, TH_Time, TPH(:,3),TPH(:,4),TPH(:,5),TPH(:,6),TPH(:,7),TPH(:,8) , 'VariableNames', {'Board Time from PowerUp (msec)','Pixhawk Time from PowerUp (msec)','Pix Time from parse','UTC Date','UTC Time','Temp 1 (°C)','Temp 2 (°C)','Temp 3 (°C)','Humidity 1 (%)','Humidity 2 (%)','Humidity 3 (%)'} );
                save(fullParsedMatFileName,'TPH_table','-append');
            end
            
            if(strcmpi(MHPValue,'Yes') && strcmpi(TPHValue,'Yes'))
                
                fig4=figure('Name','Parsed 5HP and TPH Data');
                set(fig4,'defaultLegendAutoUpdate','off');
                subplot(2,1,1);
                plt2 = plot(TPH(:,2)/1000,TPH(:,3),'r-',TPH(:,2)/1000,TPH(:,4),'b-',TPH(:,2)/1000,TPH(:,5),'g-',TPH(:,2)/1000,TPH(:,6),'r.',TPH(:,2)/1000,TPH(:,7),'b.',TPH(:,2)/1000,TPH(:,8),'g.');
                title('Temp and Humidity vs Time')
                legend({'Temp 1','Temp 2', 'Temp 3','Humid 1','Humid 2', 'Humid 3'},'Location','southeast')
                xlabel('Time (sec)');
                ylabel('Temp (°C) and Humidity (%)');
                xlim([min(TPH(:,2)/1000) max(TPH(:,2)/1000)])
                
                plt3 = plot(MHP(:,2)/1000,MHP(:,6),'m',MHP(:,2)/1000,MHP(:,7),'c');
                
                title('Alpha Raw, Beta Raw')
                legend({'Alpha Raw', 'Beta Raw'},'Location','northwest')
                ylabel('Angle (Degree)');
                xlim([(min(MHP(:,2)/1000)) (max(MHP(:,2)/1000))])
                subplot(2,1,2)
                plt4=plot(MHP(:,2)/1000,MHP(:,8),'m',MHP(:,2)/1000,MHP(:,7),'c');
                
                title('Alpha Averaged, Beta Raw')
                legend({'Alpha Averaged', 'Beta Raw'},'Location','northwest')
                ylabel('Angle(Degree)');
                xlim([(min(MHP(:,2)/1000)) (max(MHP(:,2)/1000))])
                
                fig5=figure('Name','Parsed 5HP and TPH Data');
                set(fig5,'defaultLegendAutoUpdate','off');
                subplot(2,1,1);
                plt1 = plot(MHP(:,2)/1000,MHP(:,3),'r',CTUN(:,2)/1000000,CTUN(:,4),'k');
                title('MHP-Pitot Raw,and Pix Airspeeds with Time')
                legend({'MHP-Pitot Raw', 'Pix Arspd'},'Location','northwest')
                ylabel('Airspeed (m/s)');
                xlim([(min(MHP(:,2)/1000)) (max(MHP(:,2)/1000))])
                
                subplot(2,1,2)
                plt1 = plot(MHP(:,2)/1000,MHP(:,3),'r',MHP(:,2)/1000,MHP(:,4),'b',MHP(:,2)/1000,MHP(:,5),'g',CTUN(:,2)/1000000,CTUN(:,4),'k');
                title('MHP-Pitot Raw,and Pix Airspeeds with Time')
                legend({'MHP-Pitot Raw', 'Pix Arspd'},'Location','northwest')
                ylabel('Airspeed (m/s)');
                xlim([(min(MHP(:,2)/1000)) (max(MHP(:,2)/1000))])
                
                if(strcmpi(Sensor_out,'Yes'))
                    % Output parsed TPH data
                    baseFileName = sprintf('%s_TPH.csv', baseNameNoExtDFL);
                    fullOutputMatFileName = fullfile(folderDFL, baseFileName);
                    % Write data to text file
                    writetable(TPH_table, fullOutputMatFileName);
                    
                    % Get the name of the input.mat file and save as input_Parsed_MHP.csv
                    baseFileName = sprintf('%s_Parsed_MHP.csv', baseNameNoExtDFL);
                    fullOutputMatFileName = fullfile(folderDFL, baseFileName);
                    % Write data to text file
                    writetable(MHP_table, fullOutputMatFileName);
                end
                
            elseif(strcmpi(MHPValue,'Yes') && strcmpi(TPHValue,'No'))
                
                fig4=figure('Name','Parsed 5HP Data');
                set(fig4,'defaultLegendAutoUpdate','off');
                plt1 = plot(MHP(:,2)/1000,MHP(:,3),'r',MHP(:,2)/1000,MHP(:,4),'b',MHP(:,2)/1000,MHP(:,5),'g',CTUN(:,2)/1000000,CTUN(:,4),'k');
                title('Alpha, Beta, Pitot, and Pix Airspeeds with Time')
                legend({'Pitot','Alpha', 'Beta','Pix Arspd'},'Location','northwest')
                ylabel('Airspeed (m/s)');
                xlabel('Time (sec)');
                xlim([(min(MHP(:,2)/1000)) (max(MHP(:,2)/1000))])
                
                if(strcmpi(Sensor_out,'Yes'))
                    % Get the name of the input.mat file and save as input_Parsed_MHP.csv
                    baseFileName = sprintf('%s_MHP.csv', baseNameNoExtDFL);
                    fullOutputMatFileName = fullfile(folderDFL, baseFileName);
                    % Write data to text file
                    writetable(MHP_table, fullOutputMatFileName);
                end
                
                
            elseif(strcmpi(MHPValue,'No') && strcmpi(TPHValue,'Yes'))
                
                fig4=figure('Name','Parsed TPH Data');
                plt2 = plot(TPH(:,2)/1000,TPH(:,3),'r-',TPH(:,2)/1000,TPH(:,4),'b-',TPH(:,2)/1000,TPH(:,5),'g-',TPH(:,2)/1000,TPH(:,6),'r.',TPH(:,2)/1000,TPH(:,7),'b.',TPH(:,2)/1000,TPH(:,8),'g.');
                title('Temp and Humidity vs Time')
                legend({'Temp 1','Temp 2', 'Temp 3','Humid 1','Humid 2', 'Humid 3'},'Location','southeast')
                xlabel('Time (sec)');
                ylabel('Temp (°C) and Humidity (%)');
                xlim([(min(TPH(:,2)/1000)) (max(TPH(:,2)/1000))])
                
                if(strcmpi(Sensor_out,'Yes'))
                    % Output parsed TPH data
                    baseFileName = sprintf('%s_TPH.csv', baseNameNoExtDFL);
                    fullOutputMatFileName = fullfile(folderDFL, baseFileName);
                    % Write data to text file
                    writetable(TPH_table, fullOutputMatFileName);
                end
                
            end
            
        end
        
    elseif(strcmpi(DFL_NewOld,'Old'))
        if(strcmpi(MHPValue,'Yes') && strcmpi(TPHValue,'Yes'))
            
            TPH_mat = [table2array(TPH_table(:,1:3)) table2array(TPH_table(:,6:end))];
            MHP_mat = [table2array(MHP_table(:,1:3)) table2array(MHP_table(:,6:end))];
            CTUN_mat = table2array(CTUN_table);
            
            fig4=figure('Name','Parsed 5HP and TPH Data');
            set(fig4,'defaultLegendAutoUpdate','off');
            subplot(3,1,1);
            plt2 = plot(TPH_mat(:,2)/1000,TPH_mat(:,4),'r-',TPH_mat(:,2)/1000,TPH_mat(:,5),'b-',TPH_mat(:,2)/1000,TPH_mat(:,6),'g-',TPH_mat(:,2)/1000,TPH_mat(:,7),'r.',TPH_mat(:,2)/1000,TPH_mat(:,8),'b.',TPH_mat(:,2)/1000,TPH_mat(:,9),'g.');
            title('Temp and Humidity vs Time')
            legend({'Temp 1','Temp 2', 'Temp 3','Humid 1','Humid 2', 'Humid 3'},'Location','southeast')
            xlabel('Time (sec)');
            ylabel('Temp (°C) and Humidity (%)');
            xlim([(min(TPH_mat(:,2)/1000)) (max(TPH_mat(:,2)/1000))])
            
            subplot(3,1,2);
            plt3 = plot(MHP_mat(:,2)/1000,MHP_mat(:,7),'m',MHP_mat(:,2)/1000,MHP_mat(:,8),'c');
            title('Alpha Raw, Beta Raw')
            legend({'Alpha Raw', 'Beta Raw'},'Location','northwest')
            ylabel('Angle (Degree)');
            xlim([(min(MHP_mat(:,2)/1000)) (max(MHP_mat(:,2)/1000))])
            
            subplot(3,1,3)
            plt4=plot(MHP_mat(:,2)/1000,MHP_mat(:,9),'m',MHP_mat(:,2)/1000,MHP_mat(:,8),'c');
            title('Alpha Averaged, Beta Raw')
            legend({'Alpha Averaged', 'Beta Raw'},'Location','northwest')
            ylabel('Angle(Degree)');
            xlim([(min(MHP_mat(:,2)/1000)) (max(MHP_mat(:,2)/1000))])
            
            fig5=figure('Name','MHP vs Pixhawk Airspeed Data');
            set(fig5,'defaultLegendAutoUpdate','off');
            subplot(2,1,1);
            plt1 = plot(MHP_mat(:,2)/1000,MHP_mat(:,4),'r',CTUN_mat(:,3),CTUN_mat(:,4),'k');
            title('MHP-Pitot and Pix Airspeed vs Time')
            legend({'MHP-Pitot Raw', 'Pix Arspd'},'Location','northwest')
            ylabel('Airspeed (m/s)');
            xlim([(min(MHP_mat(:,2)/1000)) (max(MHP_mat(:,2)/1000))])
            
            subplot(2,1,2)
            plt2 = plot(MHP_mat(:,2)/1000,MHP_mat(:,4),'r',MHP_mat(:,2)/1000,MHP_mat(:,5),'b',MHP_mat(:,2)/1000,MHP_mat(:,6),'g',CTUN_mat(:,3),CTUN_mat(:,4),'k');
            title('MHP Velocities (Raw) and Pix Airspeed vs Time')
            legend({'MHP-Pitot','MHP-Alpha','MHP-Beta','Pix Arspd'},'Location','northwest')
            ylabel('Airspeed (m/s)');
            xlim([(min(MHP_mat(:,2)/1000)) (max(MHP_mat(:,2)/1000))])
            
            if(strcmpi(Sensor_out,'Yes'))
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
            
        elseif(strcmpi(MHPValue,'Yes') && strcmpi(TPHValue,'No'))
            MHP_mat = [table2array(MHP_table(:,1:3)) table2array(MHP_table(:,6:end))];
            CTUN_mat = table2array(CTUN_table);
            
            fig5=figure('Name','MHP vs Pixhawk Airspeed Data');
            set(fig5,'defaultLegendAutoUpdate','off');
            subplot(2,1,1);
            plt1 = plot(MHP_mat(:,2)/1000,MHP_mat(:,4),'r',CTUN_mat(:,3),CTUN_mat(:,4),'k');
            title('MHP-Pitot and Pix Airspeed vs Time')
            legend({'MHP-Pitot Raw', 'Pix Arspd'},'Location','northwest')
            ylabel('Airspeed (m/s)');
            xlim([(min(MHP_mat(:,2)/1000)) (max(MHP_mat(:,2)/1000))])
            
            subplot(2,1,2)
            plt2 = plot(MHP_mat(:,2)/1000,MHP_mat(:,4),'r',MHP_mat(:,2)/1000,MHP_mat(:,5),'b',MHP_mat(:,2)/1000,MHP_mat(:,6),'g',CTUN_mat(:,3),CTUN_mat(:,4),'k');
            title('MHP Velocities (Raw) and Pix Airspeed vs Time')
            legend({'MHP-Pitot','MHP-Alpha','MHP-Beta','Pix Arspd'},'Location','northwest')
            ylabel('Airspeed (m/s)');
            xlim([(min(MHP_mat(:,2)/1000)) (max(MHP_mat(:,2)/1000))])
            
            if(strcmpi(Sensor_out,'Yes'))
                % Get the name of the input.mat file and save as input_Parsed_MHP.csv
                baseFileName = sprintf('%s_MHP_NS.csv', baseNameNoExtDFL);
                fullOutputMatFileName = fullfile(folderDFL, baseFileName);
                % Write data to text file
                writetable(MHP_table, fullOutputMatFileName);
            end
            
        elseif(strcmpi(MHPValue,'No') && strcmpi(TPHValue,'Yes'))
            TPH_mat = [table2array(TPH_table(:,1:3)) table2array(TPH_table(:,6:end))];
            CTUN_mat = table2array(CTUN_table);
            
            fig4=figure('Name','Parsed 5HP and TPH Data');
            set(fig4,'defaultLegendAutoUpdate','off');
            plt2 = plot(TPH_mat(:,2)/1000,TPH_mat(:,4),'r-',TPH_mat(:,2)/1000,TPH_mat(:,5),'b-',TPH_mat(:,2)/1000,TPH_mat(:,6),'g-',TPH_mat(:,2)/1000,TPH_mat(:,7),'r.',TPH_mat(:,2)/1000,TPH_mat(:,8),'b.',TPH_mat(:,2)/1000,TPH_mat(:,9),'g.');
            title('Temp and Humidity vs Time')
            legend({'Temp 1','Temp 2', 'Temp 3','Humid 1','Humid 2', 'Humid 3'},'Location','southeast')
            xlabel('Time (sec)');
            ylabel('Temp (°C) and Humidity (%)');
            xlim([(min(TPH_mat(:,2)/1000)) (max(TPH_mat(:,2)/1000))])
            
            if(strcmpi(Sensor_out,'Yes'))
                % Output parsed TPH data
                baseFileName = sprintf('%s_TPH_NS.csv', baseNameNoExtDFL);
                fullOutputMatFileName = fullfile(folderDFL, baseFileName);
                % Write data to text file
                writetable(TPH_table, fullOutputMatFileName);
            end
        end
    end
    %% CSV Output of GPS Data
    if (strcmpi(GPS_out,'Yes'))
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
    if (strcmpi(Attitude_out,'Yes'))
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
    if (strcmpi(StateSpace,'Yes'))
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
        
        if(strcmpi(ArduPilotType,'ArduCopter'))
        elseif(strcmpi(ArduPilotType,'CopterSonde'))
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
        if(exist('MHP_table'))
            MHP_mat = [table2array(MHP_table(:,1:3)) table2array(MHP_table(:,6:end))];
            PixData_mat = table2array(PixData_table);
        else MHPValue = 'No';
        end
        if(exist('TPH_table'))
            TPH_mat = [table2array(TPH_table(:,1:3)) table2array(TPH_table(:,6:end))];
            PixData_mat = table2array(PixData_table);
        else TPHValue = 'No';
        end
        if(exist('iMet_table'))
            iMet_mat = [table2array(iMet_table(:,1)) table2array(iMet_table(:,4:end))];
        else iMetValue = 'No';
        end
        NKF2_mat = table2array(NKF2_table);
        RCOU_mat = table2array(RCOU_table);
        
        
        
        if (strcmpi(Overlay,'Yes'))
            
            fig5=figure('Name','Data Plots from Parsed Sensor data and Autopilot DFL');
            
            if(strcmpi(MHPValue,'Yes'))
                if(exist('MHP_table'))
                    % Groundspeed plot
                    plt1 = subplot(5,1,1);
                    plot(t_GPS,GPS_mat(:,8),'k',t_ctun,CTUN_mat(:,4),'b',t_NKF,NKF2_mat(:,6),'r',MHP_mat(:,2)/1000,MHP_mat(:,4),'g')
                    title('Groundspeed (black), Airspeed (blue), Windspeed (red), MHP-Pitot (green) vs Time')
                    ylabel({'Velocity (m/s)'})
                end
            elseif(strcmpi(ArduPilotType,'ArduCopter') | strcmpi(ArduPilotType,'CopterSonde'))
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
                if(exist('iMet_table'))
                    % Barometric Pressure of Pixhawk and Sensor Packages
                    plt4 = subplot(5,1,4);
                    plot(t_BARO, BARO_mat(:,4),'b-',iMet_mat(:,1),iMet_mat(:,2),'r-');
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
            
            if(strcmpi(ArduPilotType,'CopterSonde'))
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
            
            if(strcmpi(TPHValue,'Yes') && strcmpi(MHPValue,'Yes') && strcmpi(iMetValue,'Yes'))
                if(exist('TPH_mat') && exist('MHP_table') && exist('iMet_table'))
                    fig6=figure('Name','Pixhawk, iMet, TPH, and MHP Data Comparisons');
                    
                    if(strcmpi(ArduPilotType,'ArduCopter') | strcmpi(ArduPilotType,'CopterSonde'))
                        plt1 = subplot(3,1,1);
                        plot(MHP_mat(:,3),MHP_mat(:,4),'r',MHP_mat(:,3),MHP_mat(:,5),'b',MHP_mat(:,3),MHP_mat(:,6),'g');
                        title('5HP Alpha, Beta, and Pitot Velocities');
                        ylabel({'Velocity (m/s)'});
                    else
                        plt1 = subplot(3,1,1);
                        plot(t_ctun,CTUN_mat(:,4),'k',MHP_mat(:,3),MHP_mat(:,4),'r',MHP_mat(:,3),MHP_mat(:,5),'b',MHP_mat(:,3),MHP_mat(:,6),'g');
                        title('Pixhawk Airspeed vs 5HP Alpha, Beta, and Pitot Velocities');
                        ylabel({'Velocity (m/s)'});
                    end
                    
                    plt2 = subplot(3,1,2);
                    plot(iMet_mat(:,1),iMet_mat(:,3),'k',iMet_mat(:,1),iMet_mat(:,4),'k-',TPH_mat(:,3),TPH_mat(:,7),'r',TPH_mat(:,3),TPH_mat(:,4),'r-',TPH_mat(:,3),TPH_mat(:,8),'b',TPH_mat(:,3),TPH_mat(:,5),'b-',TPH_mat(:,3),TPH_mat(:,7),'g',TPH_mat(:,3),TPH_mat(:,6),'g-');
                    title('iMet vs Sensor Package Temperature and Humidity');
                    ylabel({'Temp (°C) and Humidity (%)'});
                    
                    plt3 = subplot(3,1,3);
                    plot(BARO_mat(:,3),BARO_mat(:,4),'k',iMet_mat(:,1),iMet_mat(:,2),'r');
                    title('Pixhawk (internal) vs iMet (external) Pressure Readings');
                    ylabel({'Pressure (mbar)'});
                    xlabel({'Time (sec)'});
                    linkaxes([plt1 plt2 plt3],'x')
                    xlim([min(t_BARO) max(t_BARO)])
                end
            end
            
        else
            
            fig5=figure('Name','Data Plots from Parsed Autopilot DFL');
            
            if(strcmpi(ArduPilotType,'ArduCopter') | strcmpi(ArduPilotType,'CopterSonde'))
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
            close(fig1)
            fig3=figure('Name','Interactive Plot - Right click or press Return/Enter when finished') ;
            
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
                
                figure(4)
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
            
            if (strcmpi(throttleToggle,'Yes')) & (strcmpi(pitchToggle,'Yes'))
                
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
                
                figure(4)
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
        
        fig = figure(10);
        fig.Position=[130 130 800 600];
        fig.Resize = 'off';
        
        xAnim1=[nan;Long(:,1)];
        yAnim1=[nan;Lat(:,1)];
        zAnim1=[nan;Alt(:,1)];
        
        lx = length(xAnim1);
        ly = length(yAnim1);
        lz = length(zAnim1);
        
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
        
        subplot(1,2,2)
        % GPS Plotting data
        ax2 = gca;
        xlim(ax2, [min(Long) max(Long)]);
        ylim(ax2, [min(Lat) max(Lat)]);
        zlim(ax2, [min(Alt) max(Alt)]);
        xl = xlabel('Longitude');
        yl = ylabel('Lattitude');
        zl = zlabel('Alt (m, AGL)');
        
        if(strcmpi(Plot_Title,'Default'))
            Plot_Title = baseNameNoExtDFL;
        end
        
        t = title({Plot_Title,' '},'Interpreter', 'none');
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
        
        subfig1 = get(gcf,'children');
        set(subfig1(1),'position',[.1 .075 .8 .8]);     % GPS animation space
        set(subfig1(2),'position',[.725 .725 .225 .225]);   % Wind rose
        
        view(subfig1(1),-45,45);
        
        display('Beginning animation sequence');
        
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
                delete(findall(fig,'type','annotation'));
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
                
                delete(findall(fig,'type','annotation'));
                cla(ax2);
                
            end
        end
    end
else
    %% User Controls
    %%%%%%%% Animation
    % 'Yes' = Dynamic Animation (can take extended periods of time to finish)
    % 'No' = Static image (a couple minutes to run, recommended for first run
    %        to ensure animation finishes satisfactorily.
    
    % Yes will output as an M-PEG4 video file
    % No will output as a J-PEG image file
    % Both will output in the folder the Pixhawk files are in
    
    %%%%%%%% Simultaneous
    % 'Yes' = All profiles plot at same time as different colors (swarm-style)
    % 'No' = Profiles plotted one at a time in different colors with
    %        auto-scaling map (single aircraft with multiple flights)
    
    %%%%%%%% Iteration Skip
    % Number of entries to skip between plot calls (still plots all data)
    % DOES NOT SKIP DATA POINTS, only speeds up animation
    % Higher = faster, but jumpier playback
    % Lower = slower, smoother playback
    % 100 is a good starting point for all file types
    
    Animation = 'No';
    Simultaneous = 'No';
    Plot_Title = 'Muwanika Test';
    iteration_skip = 100;
    %% USGS Mapping Data
    baseURL = "https://basemap.nationalmap.gov/ArcGIS/rest/services";
    usgsURL = baseURL + "/BASEMAP/MapServer/tile/${z}/${y}/${x}";
    basemaps = ["USGSImageryOnly" "USGSImageryTopo" "USGSTopo" "USGSShadedReliefOnly" "USGSHydroCached"];
    displayNames = ["USGS Imagery" "USGS Topographic Imagery" "USGS Shaded Topographic Map" "USGS Shaded Relief" "USGS Hydrography"];
    attribution = 'Credit: U.S. Geological Survey';
    %% Load All GPS Files
    
    [baseFileName, folder]=uigetfile('*.mat','Select the INPUT DATA FILE(s)','MultiSelect','on');
    disp('Parsing and merging Pixhawk files.')
    
    if(strcmpi(Simultaneous,'Yes'))
        for i=1:length(baseFileName)
            fullInputMatFileName(i) = fullfile(folder, baseFileName(i));
            load(char(fullInputMatFileName(i)),'GPS');
            
            Time{:,i} = GPS(2:end,4);
            Speed{:,i} = GPS(2:end,11);
            Lat{:,i} = GPS(2:end,8);
            Long{:,i} = GPS(2:end,9);
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
            rawSpeed{:,i} = GPS(2:end,11);
            clear GPS
            
        end
        
        for k=1:i
            Speed = [rawSpeed{k}];
            tempLat = [rawLat{k}];
            tempLong = [rawLong{k}];
            Lat{k} = tempLat(Speed>.5);
            Long{k} = tempLong(Speed>.5);
            clear tempLat tempLong Speed
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
    
    if(strcmpi(Simultaneous,'Yes'))
        
        minT = min(minTime);
        maxT = max(maxTime);
        translate(:,1) = minT:200:maxT;
        translate(:,2) = 1:length(minT:200:maxT);
        startLat = cellfun(@(v)v(1),Lat);
        startLong = cellfun(@(v)v(1),Long);
        endLat = cellfun(@(v)v(end),Lat);
        endLong = cellfun(@(v)v(end),Long);
        
        finLat(1:length(translate(:,1)),1:i)=0;
        finLong(1:length(translate(:,1)),1:i)=0;
        finTime(:,1) = translate(:,2);
        finSpeed(1:length(translate(:,1)),1:i) = 0;
        
        for(j = 1:i)
            curTime = round(cell2mat(Time(j)),-2);
            curLat = cell2mat(Lat(j));
            curLong = cell2mat(Long(j));
            curSpeed = cell2mat(Speed(j));
            count=0;
            for k = 1:length(curTime);
                Catch = find(curTime(k,1)==translate(:,1),1,'first');
                if(Catch>=0)
                    count=count+1;
                    if(count ~= 1)
                        finLat(Catch,j) = curLat(k,1);
                        finLong(Catch,j) = curLong(k,1);
                        finSpeed(Catch,j) = curSpeed(k,1);
                    else
                        finLat(1:Catch,j)=curLat(k,1);
                        finLong(1:Catch,j)=curLong(k,1);
                        finSpeed(1:Catch,j) = curSpeed(k,1);
                    end
                end
            end
            finLat(Catch:end,j) = curLat(end,1);
            finLong(Catch:end,j) = curLong(end,1);
            finSpeed(Catch:end,j) = curSpeed(end,1);
            clear curTime curLat curLong
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
        finTime = finTime(trimStart:trimEnd,:);
    end
    %% Animation Function
    
    % Color Setup
    ColOrd = [1 0 0; 0 1 0; 0 0 1; 1 1 1; 0 0 0; 1 1 0; 1 0 1; 0 1 1];
    [m,n] = size(ColOrd);
    
    % Animation of the Pixhawk Log from recorded GPS coordinates
    if(strcmpi(Simultaneous,'Yes'))
        minLat = min(min(finLat));
        maxLat = max(max(finLat));
        minLong = min(min(finLong));
        maxLong = max(max(finLong));
        
        if(strcmpi(Animation,'No'))
            
            disp('Beginning plot setup.');
            
            fig=figure(1);
            fig.Position = [10 50 560 725];
            fig.Resize = 'off';
            
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
            
            title(Plot_Title);
            
            baseFileNamePic = sprintf('MergedData_Image10');
            fullParsedMatFileNamePic = fullfile(folder, baseFileNamePic);
            
            saveas(fig,fullParsedMatFileNamePic,'png')
            
            
            disp('Successfully completed plot.');
            
        elseif (strcmpi(Animation,'Yes'))
            
            disp('Beginning animation setup.');
            
            % Get the name of the intput.mat file and save as input_parsed.mat
            baseFileName = sprintf('MergedData_Animation1');
            fullParsedMatFileName = fullfile(folder, baseFileName);
            finished = 'false';
            
            animVid = VideoWriter(fullParsedMatFileName,'MPEG-4');
            animVid.FrameRate = 20;  %can adjust this, 5 - 10 works well for me
            animVid.Quality = 100;
            
            tot = ceil(length(finLat(:,1))/iteration_skip);
            
            figure(1);
            fig.Position = [10 50 560 725];
            fig.Resize = 'off';
            
            ax = geoaxes();
            geobasemap('satellite')
            basemapx = basemaps(2);
            url = replace(usgsURL,"BASEMAP",basemapx);
            view(ax,2)
            title(Plot_Title);
            
            disp('Starting the animation process.');
            
            open(animVid);
            
            ptot = 0;
            
            for jj=1:iteration_skip:length(finLat(:,1))
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
        end
        
    else
        % Animation of the Pixhawk Log from recorded GPS coordinates
        minLat = min(min(cell2mat(Lat(:))));
        maxLat = max(max(cell2mat(Lat(:))));
        minLong = min(min(cell2mat(Long(:))));
        maxLong = max(max(cell2mat(Long(:))));
        
        if(strcmpi(Animation,'No'))
            
            disp('Beginning plot setup.');
            
            fig=figure(1);
            fig.Position = [10 50 750 600];
            fig.Resize = 'off';
            
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
            title(Plot_Title);
            
            baseFileNamePic = sprintf('MergedData_Image10');
            fullParsedMatFileNamePic = fullfile(folder, baseFileNamePic);
            
            saveas(fig,fullParsedMatFileNamePic,'png')
            
            
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
            
            tot=ceil(tot/iteration_skip)+1;
            
            animVid = VideoWriter(fullParsedMatFileName,'MPEG-4');
            animVid.FrameRate = 20;  %can adjust this, 5 - 10 works well for me
            animVid.Quality = 100;
            
            figure(1);
            fig.Position = [10 50 750 600];
            fig.Resize = 'off';
            
            ax = geoaxes();
            geobasemap('satellite')
            basemapx = basemaps(2);
            url = replace(usgsURL,"BASEMAP",basemapx);
            view(ax,2)
            title(Plot_Title);
            
            disp('Starting the animation process.');
            
            open(animVid);
            
            ptot = 0;
            for k=1:i
                hold on
                tLat = cell2mat(Lat(k));
                tLong = cell2mat(Long(k));
                for jj=1:iteration_skip:length(tLat)
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
