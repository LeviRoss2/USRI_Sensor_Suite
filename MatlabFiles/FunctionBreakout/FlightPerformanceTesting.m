
%% Clear All Data
close all
clear all
clc
%% Initialize User-Defined Content
display('Initializing user-defined variable space.');

thrMinPWM = 1100;              % Default, scales THR% plots
thrMaxPWM = 1900;              % Default, scales THR% plots

% Single Controls
graphToggle = 'No';          % Show plots of parsed data
dflNewOld = 'Unknown';
tvToggle = 'Yes';            % TIA-Specific
throttleToggle = 'Yes';         % TIA-Specific
aircraft = 'TIA';              % TIA-Specific
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
    %% Check DFL File Type
    Rover = 0;
    Copter = 0;
    QuadPlane = 0;
    Plane = 0;
    
    rawDFL = Ardupilog(fullInputMatFileNameDFL);
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
        error('Rover Pixhawk file detected. Retry with Fixed Wing flight log');
    elseif(Copter == 1)
        arduPilotType = 'ArduCopter';
        error('QuadCopter Pixhawk file detected. Retry with Fixed Wing flight log');
    elseif(QuadPlane == 1)
        arduPilotType = 'QuadPlane';
        error('QuadPlane Pixhawk file detected. Retry with Standard Fixed Wing flight log');
    elseif(Plane == 1)
        arduPilotType = 'FixedWing';
    end
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
end
%% Gather Additional Files

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



% Get filename without the extension, used by Save Function
[~, baseNameNoExtDFL, ~] = fileparts(baseFileNameDFL);

if (strcmpi(tvToggle,'Yes'))
    
    if(strcmpi(aircraft,'TIA'))
        tvMap=[1139,-7.9 ; 1150,-7.1 ; 1200,-6.3 ; 1250,-5.6 ; 1300,-4.8 ; 1350,-4.0 ; 1400,-3.2 ; 1450,-1.6 ; 1500,0.0 ; 1550,6.3 ; 1600,7.9 ; 1650,9.5 ; 1700,11.0 ; 1750,12.5 ; 1800,14.0 ; 1850,15.5 ; 1900,17.0 ; 1939,17.0];
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
        tvMap = load(fullInputMatFileName);
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


fig1=figure(1);
fig1.Name = 'Raw data from DFL. Click on graph for upper and lower bound for parsing.';

% Groundspeed plot
plt1 = subplot(4,1,1);
plot(GPS(:,2),GPS(:,8),'b',CTUN(:,2),CTUN(:,6),'r')
title('Groundspeed, Airspeed vs Time')
ylabel({'Groundspeed (blue)';'Airspeed (red)';'(m/s)'})

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
    y_va(m)=CTUN(find(CTUN(:,2)>=x_m(m),1,'first'),6);     % Airspeed
    y_vg(m)=GPS(find(GPS(:,2)>=x_m(m),1,'first'),8);      % Groundspeed
    y_thr(m)=RCOU(find(RCOU(:,2)>=x_m(m),1,'first'),5);     % Throttle Percent
    y_pitch(m)=ATT(find(ATT(:,2)>=x_m(m),1,'first'),4); % Aircraft Pitch
    y_alt(m)=GPS(find(GPS(:,2)>=x_m(m),1,'first'),7);    % Altitude
    
    % Groundspeed plot
    subplot(4,1,1)
    plot(GPS(:,2),GPS(:,8),'b',CTUN(:,2),CTUN(:,6),'r',x_m,y_vg,'kx',x_m,y_va,'kx')
    title('Groundspeed, Airspeed vs Time')
    ylabel({'Groundspeed (blue)';'Airspeed (red)';'(m/s)'})
    
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

% Groundspeed plot
plt1 = subplot(4,1,1);
plot(GPS(:,2)/1000000,GPS(:,8),'b',CTUN(:,2)/1000000,CTUN(:,6),'r')
title('Groundspeed, Airspeed vs Time')
ylabel({'Groundspeed (blue)';'Airspeed (red)';'(m/s)'})

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
%% Configure Start/Stop Conditions

% Finding the applicable data range based on minimum settings above
% GPS line number of starting relavent data (used for parsing)
TO = IMU(find(IMU(:,2)>=x_m(1), 1, 'first'),1);
LND = IMU(find(IMU(:,2)>=x_m(2), 1, 'first'),1);

% Potision in each major dataset (GPS, CTUN, NKF2, RCOU) for Takeoff (TO)
% and Landing (LND)

TO_CTUN = find(CTUN(:,1)>TO,1,'first')-1;
LND_CTUN = find(CTUN(:,1)>LND,1,'first')-1;
TO_NKF = find(NKF2(:,1)>TO,1,'first')-1;
LND_NKF = find(NKF2(:,1)>LND,1,'first')-1;

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
% Airspeed
v_a=CTUN(TO_CTUN:LND_CTUN,6);
% North winds
VWN=NKF2(TO_NKF:LND_NKF,3);
% East winds
VWE=NKF2(TO_NKF:LND_NKF,4);
% Wind vector
wind=(VWN.^2+VWE.^2).^0.5;

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
%% Parse All Data and Save To Respective Tables

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

% Parsed CTUN data output
CTUN_LN = CTUN(TO_CTUN:LND_CTUN,1);
CTUN_time = CTUN(TO_CTUN:LND_CTUN,2);
CTUN_time_out= (CTUN_time-min(CTUN_time))/1000000;
CTUN = [CTUN_LN, CTUN_time, CTUN_time_out, v_a];
CTUN_label = {'Line No','Time since boot (us)','Time from Arming (sec)','Airspeed (m/s)'};
CTUN_table = table(CTUN_LN,CTUN_time,CTUN_time_out,v_a,'VariableNames',{'Line Number','Time from boot (us)','Time from parse (sec)','Airspeed (m/s)'});

% Parsed NKF2 data output
NKF_LN = NKF2(TO_NKF:LND_NKF,1);
NKF_time = NKF2(TO_NKF:LND_NKF,2);
NKF_time_out= (NKF_time-min(NKF_time))/1000000;
NKF2 = [NKF_LN, NKF_time, NKF_time_out, VWN, VWE];
NKF2_label = {'Line No','Time since boot (us)','Time from Arming (sec)','North Wind Vector (m/s)','East Wind Vector (m/s)'};
NKF2_table = table(NKF_LN, NKF_time, NKF_time_out, VWN, VWE, wind,'VariableNames',{'Line Number','Time from boot (us)','Time from parse (sec)','North Wind Vector (m/s)','East Wind Vector (m/s)','Wind Speed (m/s)'});

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

% Get the name of the intput.mat file and save as input_parsed.mat
baseFileName = sprintf('%s_Parsed.mat', baseNameNoExtDFL);
fullParsedMatFileName = fullfile(folderDFL, baseFileName);
app.LocationofOutputFilesEditField.Value = fullParsedMatFileName;
% Save file with parsed data as the original filename plus the added portion

save(fullParsedMatFileName,'ATT_table','GPS_table','CTUN_table','NKF2_table','RCOU_table');
%% Data Plots

% Converted timestamps to time (in seconds) from TO to LND
t_GPS = table2array(GPS_table(:,3));
t_NKF = table2array(NKF2_table(:,3));
t_RCOU = table2array(RCOU_table(:,3));
t_ATT = table2array(ATT_table(:,3));
t_ctun = table2array(CTUN_table(:,3));
CTUN_mat = table2array(CTUN_table);
t_low = min(GPS_table{:,3});
t_high = max(GPS_table{:,3});
GPS_mat = [table2array(GPS_table(:,1:3)) table2array(GPS_table(:,6:end))];
ATT_mat = table2array(ATT_table);
NKF2_mat = table2array(NKF2_table);
RCOU_mat = table2array(RCOU_table);

fig8=figure(8);
fig8.Name = 'Interactive Plot - Right click or press Return/Enter when finished';

% Airspeed Plot
subplot(4,1,1);
plot(t_GPS,GPS_mat(:,8),'b-',t_ctun,CTUN_mat(:,4),'r-',t_NKF,NKF2_mat(:,6),'g-')
title('Groundspeed and Airspeed vs Time')
ylabel({'Groundspeed (blue)';'Airspeed (red)';'Windspeed (green)';'(m/s)'})
xlim([min(t_GPS) max(t_GPS)])

% Throttle Output
subplot(4,1,2);
plot(t_RCOU,RCOU_mat(:,6),'b')
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
    subplot(4,1,2);
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

S = str2double(input('<strong>Enter Wing Area (ft^2): </strong>','s'));
rho = str2double(input('<strong>Enter air density (slug/ft^3) [.002377 STP]: </strong>','s'));
GTOW = str2double(input('<strong>Enter aircraft weight (lbf): </strong>','s'));

% fig10 = figure(10);
% dAir = gradient(CTUN_mat(1:26:end,4))./gradient(t_ctun(1:26:end,1));
% plot(t_ctun(1:26:end,1),dAir);
% 
% fig11 = figure(11);
% dAlt = gradient(GPS_mat(:,7))./gradient(t_GPS);
% plot(t_GPS, dAlt);
% 
% fig12 = figure(12);
% dAng = gradient(ATT_mat(1:26:end,5))./gradient(t_ATT(1:26:end));
% plot(t_ATT(1:26:end),dAng);
% 
% fig12 = figure(13);
% dThr = gradient(RCOU_mat(1:26:end,6))./gradient(t_RCOU(1:26:end));
% plot(t_RCOU(1:26:end),dThr);

if (strcmpi(throttleToggle,'Yes')) & (strcmpi(tvToggle,'No'))
    
    thrT = interp1(throttleMap(:,1),throttleMap(:,2),y_n4);
    
    % Drag = Thrust
    C_D = (thrT.*2)./(((y_n2.*3.28084).^2)*S*rho);
    % Lift = Weight
    C_L = (GTOW*2)./(S*rho*(y_n2.*3.28084).^2);
    % Ratio of C_L/C_D
    L_D = C_L./C_D;
    
    % Flight Analysis
    baseFileName = sprintf('%s_metricsFull.csv', baseNameNoExtDFL);
    fullOutputMatFileName = fullfile(folderDFL, baseFileName);
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
    
elseif (strcmpi(throttleToggle,'Yes')) & (strcmpi(tvToggle,'Yes'))
    
    % Mapping throttle Percent from User Input to Thrust Output
    thrT = interp1(throttleMap(:,1),throttleMap(:,2),y_n4);
    % Mapping pitch PWM from Pixhawk to true angular deflection
    tvT = interp1(tvMap(:,1),tvMap(:,2),y_n7);
    
    % Drag = Thrust*cos(angle)
    C_D = (thrT.*cos(tvT/180*3.14)*2)./(((y_n2.*3.28084).^2)*S*rho);
    % Lift = Weight + Drag*sin(angle)
    C_L = ((GTOW+(thrT.*sin(tvT/180*3.14)))*2)./(S*rho*(y_n2.*3.28084).^2);
    % Ratio of C_L/C_D
    L_D = C_L./C_D;
    
    % Flight Analysis
    baseFileName = sprintf('%s_metricsFull.csv', baseNameNoExtDFL);
    fullOutputMatFileName = fullfile(folderDFL, baseFileName);
    % Save file with parsed data as the original filename plus the added portion
    % Create a table with the data and variable names
    T = table(round(y_n1.',1), round(y_n2.',1), round(y_n3.',1), round(y_n4.',1), round(y_n5.',1), round(y_n6.',1), round(y_n7.',1), round(thrT.',2), round(tvT.',1), round(C_D.',6), round(C_L.',6), round(L_D.',4), 'VariableNames', {'Groundspeed (m/s)','Airspeed (m/s)','Windspeed (m/s)','Throttle (%)','Aircraft Pitch (°)','Altitude (m, AGL)','Pitch PWM','Thrust Output (units of Throttle Curve input file)','Servo Angular Deflection (°)','C_D','C_L','CD_CL'} )
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