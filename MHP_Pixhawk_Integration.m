
close all
clear all
clc

thrMinPWM = 1100;
thrMaxPWM = 1900;

pitchToggle = 'No';
throttleToggle = 'No';
graphToggle = 'On';
TVToggle = 'No';
indvToggle = 'No';
animateToggle = 'Off';
ArduPilotType = 'Quad-Plane';
StateSpace = 'No';
iMetValue = 'No';
MHPValue = 'Yes';
TPHValue = 'Yes';
Overlay = 'Yes';
GPS_out = 'Off';
Aircraft = 'N/A';
Sensor_out = 'No';
Attitude_out = 'Off';
SensorCompare = 'Yes';

animateSpeed = 10;
animateHeadSize = 2;
animateTailWidth = 1;
animateTailLength = 100;

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

% Have user browse for a file, from a specified "starting folder."
% For convenience in browsing, set a starting folder from which to browse.
% Start in the current folder.
startingFolderDFL = pwd;
% Get the name of the file that the user wants to use.
defaultFileNameDFL = fullfile(startingFolderDFL, '*.mat');
[baseFileNameDFL, folderDFL] = uigetfile(defaultFileNameDFL, 'Select an unparsed Pixhawk DFL file');
startingFolderDFL = folderDFL;
if baseFileNameDFL == 0
    % User clicked the Cancel button.
    return;
end

%Specific parsing for Fixed-Wing DFL's
if(strcmpi(ArduPilotType,'Fixed Wing'))
    % Get the name of the input .mat file.
    fullInputMatFileNameDFL = fullfile(folderDFL, baseFileNameDFL);
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

%Specific parsing for Quad-Plane DFL's
if(strcmpi(ArduPilotType,'Quad-Plane'))
    
    % Get the name of the input .mat file.
    fullInputMatFileNameDFL = fullfile(folderDFL, baseFileNameDFL);
    load(fullInputMatFileNameDFL,'ATT','ATT_label','BARO','BARO_label','CTUN','CTUN_label','IMU','IMU_label','GPS','GPS_label','XKF2','XKF2_label','RCOU','RCOU_label','STAT','STAT_label');
    
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
    STAT = [STAT(:,1:5)];
    STAT_label = [STAT_label(1:5)];
end

%Specific parsing for Quadcopter DFL's (EXPERIMENTAL)
if(strcmpi(ArduPilotType,'Quadcopter'))
    
    % Get the name of the input .mat file.
    fullInputMatFileNameDFL = fullfile(folderDFL, baseFileNameDFL);
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
    STAT = [STAT(:,1:5)];
    STAT_label = [STAT_label(1:5)];
end

% Get filename without the extension, used by Save Function
[~, baseNameNoExtDFL, ~] = fileparts(baseFileNameDFL);

fig1=figure('Name','Raw data from DFL. Click on graph for upper and lower bound for parsing.');

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
    y_vg(m)=GPS(find(GPS(:,2)>=x_m(m),1,'first'),8);      % Groundspeed
    y_va(m)=CTUN(find(CTUN(:,2)>=x_m(m),1,'first'),6);     % Airspeed
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

fig2=figure('Name','Preview of user-parsed DFL data.');

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

%%%%%%%%%%%%%%%%%% Start/Stop Conditions %%%%%%%%%%%%%%%%%%%%%%%%%
% Finding the applicable data range based on minimum settings above
% GPS line number of starting relavent data (used for parsing)
TO = CTUN(find(CTUN(:,2)>=x_m(1), 1, 'first'),1);
LND = CTUN(find(CTUN(:,2)>=x_m(2), 1, 'first'),1);

% Potision in each major dataset (GPS, CTUN, NKF2, RCOU) for Takeoff (TO)
% and Landing (LND)
TO_GPS = find(GPS(:,1)>TO,1,'first')-1;
LND_GPS = find(GPS(:,1)>LND,1,'first')-1;
TO_CUBE = find(CTUN(:,1)>TO,1,'first')-1;
LND_CUBE = find(CTUN(:,1)>LND,1,'first')-1;
TO_ATT = find(ATT(:,1)>TO,1,'first')-1;
LND_ATT = find(ATT(:,1)>LND,1,'first')-1;
TO_NKF = find(NKF2(:,1)>TO,1,'first')-1;
LND_NKF = find(NKF2(:,1)>LND,1,'first')-1;
TO_RCOU = find(RCOU(:,1)>TO,1,'first')-1;
LND_RCOU = find(RCOU(:,1)>LND,1,'first')-1;
TO_STAT = find(STAT(:,1)>TO,1,'first')-1;
LND_STAT = find(STAT(:,1)>LND,1,'first')-1;
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
v_a=CTUN(TO_CUBE:LND_CUBE,6);
% Max airspeed
max_v_a=max(CTUN(TO_CUBE:LND_CUBE,6));
% North winds
VWN=NKF2(TO_NKF:LND_NKF,3);
% East winds
VWE=NKF2(TO_NKF:LND_NKF,4);
% Wind vector
wind=(VWN.^2+VWE.^2).^0.5;
% Max windspeed
max_wind = max(wind);

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

% Timing length for plotting
t_plot=(1:length(x));
t_GPS = (GPS(:,2)-GPS(1,2))/1000000;

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
CTUN_LN = CTUN(TO_CUBE:LND_CUBE,1);
CTUN_time = CTUN(TO_CUBE:LND_CUBE,2);
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
NKF2_table = table(NKF_LN, NKF_time, NKF_time_out, VWN, VWE,'VariableNames',{'Line Number','Time from boot (us)','Time from parse (sec)','North Wind Vector (m/s)','East Wind Vector (m/s)'});

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

% Parsed STAT data output
STAT_LN = STAT(TO_STAT:LND_STAT,1);
STAT_time = STAT(TO_STAT:LND_STAT,2);
STAT_fly = STAT(TO_STAT:LND_STAT,3);
STAT_probFly = STAT(TO_STAT:LND_STAT,4);
STAT_armed = STAT(TO_STAT:LND_STAT,5);
STAT_time_out = (STAT_time-min(STAT_time))/1000000;
STAT = [STAT_LN, STAT_time, STAT_time_out, STAT_fly, STAT_probFly, STAT_armed];
STAT_label = {'Line No','Time since boot (us)','Time from parse (sec)','Is Aircraft Flying?','Probability of Flying','Is Aircraft Armed?'};
STAT_table = table(STAT_LN,STAT_time,STAT_time_out,STAT_fly, STAT_probFly, STAT_armed,'VariableNames',{'Line Number','Time from boot (us)','Time from parse (sec)','Is Aircraft FLying?','Probability of Flying','Is Aircraft Armed?'});

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
baseFileName = sprintf('%s_parsed.mat', baseNameNoExtDFL);
fullParsedMatFileName = fullfile(folderDFL, baseFileName);
app.LocationofOutputFilesEditField.Value = fullParsedMatFileName;
% Save file with parsed data as the original filename plus the added portion
save(fullParsedMatFileName,'ATT_table','GPS_table','CTUN_table','NKF2_table','RCOU_table','STAT_table','BARO_table','IMU_table');


%%%%%%%%%%%%%%% iMet Data Parsing and Output %%%%%%%%%%%%%%%
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
    iMetData = readtable(fullInputMatFileNameiMet);
    
    % Convert CSV data to general table to datetime array
    iMet_date_ref = iMetData(:,40);
    iMet_date_conv = table2array(iMet_date_ref);
    iMet_date = datetime(iMet_date_conv,'InputFormat','yyyy/MM/dd','Format','MMM-dd-yyyy');
    iMet_time_ref = iMetData(:,41);
    iMet_time_conv = table2array(iMet_time_ref);
    iMet_time = datetime(datevec(iMet_time_conv),'Format','HH:mm:ss');
    Pix_time = GPS(:,3);
    
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
    for i=1:length(iMet_serial)
        for j=1:length(GPS_serial)
            if(iMet_serial(i)==GPS_serial(j))
                iM_Pix(i,1)=GPS_time_out(j);
            end
        end
    end
    j=1;
    for (i=TO_iMet:LND_iMet)
        iM_time_temp(j,1) = iMet_time(i,1);
        iM_date_temp(j,1) = iMet_date(i,1);
        iM_pres_temp(j,1) = iMetData(i,37);
        iM_temp_temp(j,1) = iMetData(i,38);
        iM_humid_temp(j,1) = iMetData(i,39);
        iM_lat_temp(j,1) = iMetData(i,42);
        iM_long_temp(j,1) = iMetData(i,43);
        iM_alt_temp(j,1) = iMetData(i,44);
        iM_sat_temp(j,1) = iMetData(i,45);
        j=j+1;
    end
    
    len1 = size(iM_Pix,1);
    len2 = size(iM_time_temp,1);
    
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
        baseFileName = sprintf('%s_Parsed_iMet.csv', baseNameNoExtDFL);
        fullOutputMatFileName = fullfile(folderDFL, baseFileName);
        % Create a table with the data and variable names
        iMet_table = table(iM_Pix, iM_date, iM_time, iM_pres, iM_temp, iM_humid, iM_lat, iM_long, iM_alt, iM_sat,'VariableNames',{'Time from Arming (sec)','Date UTC','Time UTC','Barometric Pressure (hPa)','Air Temp (°C)','Relative Humidity (%)','GPS Lat','GPS Long','GPS Alt (m)','Sat Count'});
        % Write data to text file
        writetable(iMet_table, fullOutputMatFileName);
    end
end

%%%%%%%%%%%%%%% 5 Hp Data Parsing and Output %%%%%%%%%%%%%%%
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
    
    %%
    %Moving Average Calcs
    Pitot_pa_MA=movmean(Pitot_pa,500);
    Alpha_pa_MA=movmean(Alpha_pa,500);
    Beta_pa_MA=movmean(Beta_pa,500); 
    
    %Cp Averaged Calcs 
    CP_a_MA=Alpha_pa_MA./Pitot_pa_MA
    CP_b_MA=Beta_pa_MA./Pitot_pa_MA
    
    % Alpha & Beta Averaged Calcs. 
    Alpha_MA=interp1(Probe1_alpha_matrix(2,:), Probe1_alpha_matrix(1,:), CP_a_MA(i)); %just doing 1d interp for now until more speeds ran
    Beta_MA=interp1(Probe1_beta_matrix(2,:), Probe1_beta_matrix(1,:), CP_b_MA(i));
    
    %%
    
    
    %Cp Calc
    CP_a=Alpha_pa./Pitot_pa; 
    CP_b=Beta_pa./Pitot_pa; 
    
    % Converts reduced data set pitot measurements to velocity (move down
    % at some point)
    Velocity(i,1)=time;
    Velocity(i,2)=((2/rho)*(abs(Pitot_pa))) .^.5;
    Velocity(i,3)=((2/rho)*(abs(Alpha_pa))) .^.5;
    Velocity(i,4)=((2/rho)*(abs(Beta_pa))) .^.5;
    
    % calculate alpha and beta probe values
    
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
    end
    PixAv=mean(PixOff);
    GPS_av = mean(GPS_off);
    
    leapseconds_unix = 28;
    
    % Offsets between board time and Pix time
    THSense(:,2)=round((THSense(:,1)+PixAv),0);
    THSense_Unix=round((THSense(:,1)/1000)+GPS_av,1);
    MHPData(:,2)=round((MHPData(:,1)+PixAv),0);
    MHPData_Unix=round((MHPData(:,1)/1000)+GPS_av,1);
    
    TH_DateTime=datetime(THSense_Unix,'ConvertFrom','posixTime','Format','MMM-dd-yyyy HH:mm:ss.S');
    TH_Date=datestr(TH_DateTime,'mmm-dd-yyyy');
    TH_Time=datestr(TH_DateTime,'HH:MM:SS.FFF');
    
    MHP_DateTime=datetime(MHPData_Unix,'ConvertFrom','posixTime','Format','MMM-dd-yyyy HH:mm:ss.S');
    MHP_Date=datestr(MHP_DateTime,'mmm-dd-yyyy');
    MHP_Time=datestr(MHP_DateTime,'HH:MM:SS.FFF');
    
    
    % 5HP and TPH parsing
    
    if (min(TH_DateTime) < min(GPS_final))
        TO_TPH = find(TH_DateTime(:)>=min(GPS_final),1,'first');
        TO_MHP = find(MHP_DateTime(:)>=min(GPS_final),1,'first');
    else
        TO_TPH = 1;
        TO_MHP = 1;
    end
    
    if (max(TH_DateTime) > max(GPS_final))
        LND_TPH = find(TH_DateTime(:)>=max(GPS_final),1,'first');
        LND_MHP = find(MHP_DateTime(:)>=max(GPS_final),1,'first');
    else
        LND_TPH = length(TH_DateTime);
        LND_MHP = length(MHP_DateTime);
    end
    
    TPH = THSense(TO_TPH:LND_TPH,:);
    MHP = MHPData(TO_MHP:LND_MHP,:);
    TH_Date = TH_Date(TO_TPH:LND_TPH,:);
    TH_Time = TH_Time(TO_TPH:LND_TPH,:);
    MHP_Date = MHP_Date(TO_MHP:LND_MHP,:);
    MHP_Time = MHP_Time(TO_MHP:LND_MHP,:);
    TPH_time_out = (TPH(:,1)-min(TPH(:,1)))/1000;
    MHP_time_out = (MHP(:,1)-min(MHP(:,1)))/1000;
    Pix_time_out = (PixData(:,1)-min(PixData(:,1)))/1000;
    
    % Create tables with the data and variable names   
    TPH_table = table(TPH(:,1),TPH(:,2),TPH_time_out,TH_Date, TH_Time, TPH(:,3),TPH(:,4),TPH(:,5),TPH(:,6),TPH(:,7),TPH(:,8) , 'VariableNames', {'Board Time from PowerUp (msec)','Pixhawk Time from PowerUp (msec)','Pix Time from parse','UTC Date','UTC Time','Temp 1 (°C)','Temp 2 (°C)','Temp 3 (°C)','Humidity 1 (%)','Humidity 2 (%)','Humidity 3 (%)'} );
    MHP_table = table(MHP(:,1),MHP(:,2),MHP_time_out, MHP_Date, MHP_Time, MHP(:,3),MHP(:,4),MHP(:,5),MHP(:,6),MHP(:,7), 'VariableNames', {'Board Time from PowerUp (msec)','Pix Time from PowerUp (msec)','Pix time from parse','UTC Date','UTC Time','Pitot-Static (m/s)','V (m/s)','U (m/s)','Alpha(deg)','Beta(deg)'} );
    PixData_table = table(PixData(:,1),PixData(:,2),Pix_time_out,PixData(:,3),'VariableNames',{'Sensor board time (ms)','GPS Unix Time (sec)','Pix board time (sec)','Pix board time (ms)'});
    
    save(fullParsedMatFileName,'TPH_table','-append');
    save(fullParsedMatFileName,'MHP_table','-append');
    save(fullParsedMatFileName,'PixData_table','-append');
    
    if(strcmpi(MHPValue,'Yes') && strcmpi(TPHValue,'Yes'))
       %% 
        fig4=figure('Name','Parsed 5HP and TPH Data');
        set(fig4,'defaultLegendAutoUpdate','off');
        subplot(2,1,1);
        plt2 = plot(TPH(:,2)/1000,TPH(:,3),'r-',TPH(:,2)/1000,TPH(:,4),'b-',TPH(:,2)/1000,TPH(:,5),'g-',TPH(:,2)/1000,TPH(:,6),'r.',TPH(:,2)/1000,TPH(:,7),'b.',TPH(:,2)/1000,TPH(:,8),'g.');
        title('Temp and Humidity vs Time')
        legend({'Temp 1','Temp 2', 'Temp 3','Humid 1','Humid 2', 'Humid 3'},'Location','southeast')
        xlabel('Time (sec)');
        ylabel('Temp (°C) and Humidity (%)');
        xlim([(min(TPH(:,2)/1000)) (max(TPH(:,2)/1000))])
        
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
        plt1 = plot(MHP(:,2)/1000,MHP(:,3),'r', ...
            CTUN(:,2)/1000000,CTUN(:,4),'k');
        title('MHP-Pitot Raw,and Pix Airspeeds with Time')
        legend({'MHP-Pitot Raw', 'Pix Arspd'},'Location','northwest')
        ylabel('Airspeed (m/s)');
        xlim([(min(MHP(:,2)/1000)) (max(MHP(:,2)/1000))])
        
        subplot(2,1,2)
        plt1 = plot(MHP(:,2)/1000,MHP(:,3),'r',MHP(:,2)/1000,MHP(:,4),'b', ...
            MHP(:,2)/1000,MHP(:,5),'g', ...
            CTUN(:,2)/1000000,CTUN(:,4),'k');
        title('MHP-Pitot Raw,and Pix Airspeeds with Time')
        legend({'MHP-Pitot Raw', 'Pix Arspd'},'Location','northwest')
        ylabel('Airspeed (m/s)');
        xlim([(min(MHP(:,2)/1000)) (max(MHP(:,2)/1000))])
        
  %%      
        
        
    
        if(strcmpi(Sensor_out,'Yes'))
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
            baseFileName = sprintf('%s_Parsed_MHP.csv', baseNameNoExtDFL);
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
            baseFileName = sprintf('%s_Parsed_TPH.csv', baseNameNoExtDFL);
            fullOutputMatFileName = fullfile(folderDFL, baseFileName);
            % Write data to text file
            writetable(TPH_table, fullOutputMatFileName);
        end
        
    end
    
end


%%%%%%%%%%%%%%% CSV Output of GPS Data %%%%%%%%%%%%%%%%%%%%%
if (strcmpi(GPS_out,'On'))
    % Get the name of the input.mat file and save as input_GPS.csv
    baseFileName = sprintf('%s_GPS.csv', baseNameNoExtDFL);
    fullOutputMatFileName = fullfile(folderDFL, baseFileName);
    % Write data to text file
    writetable(GPS_table, fullOutputMatFileName);
end

%%%%%%%%%%% CSV Output of Aircraft Attitude Data %%%%%%%%%%%
if (strcmpi(Attitude_out,'On'))
    % Get the name of the input.mat file and save as input_GPS.csv
    baseFileName = sprintf('%s_Attitude.csv', baseNameNoExtDFL);
    fullOutputMatFileName = fullfile(folderDFL, baseFileName);
    % Write data to text file
    writetable(ATT_table, fullOutputMatFileName);
end

%%%%%%%%%%%%%%% CSV Output of IMU Data %%%%%%%%%%%%%%%%%%%%%
if (strcmpi(StateSpace,'Yes'))
    % Get the name of the input.mat file and save as input_GPS.csv
    baseFileName = sprintf('%s_IMU.csv', baseNameNoExtDFL);
    fullOutputMatFileName = fullfile(folderDFL, baseFileName);
    % Write data to text file
    writetable(IMU_table, fullOutputMatFileName);
end

% Get GPS points from parsed data file
if (strcmpi(graphToggle,'On'))
    % Converted timestamps to time (in seconds) from TO to LND
    t_GPS = GPS_time_out;
    t_cube = CTUN_time_out;
    t_NKF = NKF_time_out;
    t_RCOU = RCOU_time_out;
    t_BARO = BARO_time_out;
    t_low = min(GPS_time_out);
    t_high = max(GPS_time_out);
    
    
    
    if (strcmpi(Overlay,'Yes'))
        
        fig5=figure('Name','Data Plots from Parsed Sensor data and Autopilot DFL');
        
        if(strcmpi(MHPValue,'Yes'))
            % Groundspeed plot
            plt1 = subplot(5,1,1);
            plot(t_GPS,v_g,'k',t_cube,v_a,'b',t_NKF,wind,'r',MHP(:,2)/1000,MHP(:,3),'g')
            title('Groundspeed (black), Airspeed (blue), Windspeed (red), MHP-Pitot (green) vs Time')
            ylabel({'Velocity (m/s)'})
        else
            % Groundspeed plot
            plt1 = subplot(5,1,1);
            plot(t_GPS,v_g,'k',t_cube,v_a,'b',t_NKF,wind,'r')
            title('Groundspeed (black), Airspeed (blue), Windspeed (red) vs Time')
            ylabel({'Velocity (m/s)'})
        end
        
        if(strcmpi(iMetValue,'Yes'))
            % Barometric Pressure of Pixhawk and Sensor Packages
            plt4 = subplot(5,1,4);
            plot(t_BARO, BARO(:,4),'b-',iM_Pix(:), iM_pres(:),'r-');
            title('Pixhawk (internal) vs iMet (external) Atmospheric Pressure Measurements')
            %xticks([150:20:370])
            ylabel({'Pixhawk Pressure (blue)';'iMet Pressure (red)';'(mbar)'});
        else
            % Barometric Pressure of Pixhawk and Sensor Packages
            plt4 = subplot(5,1,4);
            plot(t_BARO,BARO(:,4),'b-');
            title('Pixhawk (internal) Atmospheric Pressure Measurements')
            %xticks([150:20:370])
            ylabel({'Pixhawk Pressure (blue)';'(mbar)'});
        end
        
        
        % Throttle Output
        plt2 = subplot(5,1,2);
        plot(t_RCOU,thr,'b')
        title('Throttle vs Time')
        ylabel({'Throttle';'(%)'})
        %xticks([150:20:370])
        ylim([0 100])
        
        % For the dotted line along x-axis of pitch plot
        zero=int8(zeros(length(pitchAC),1));
        
        % Aircraft Pitch angle: Can change ylim to something more relevant.
        % TIV uses -20 to 50 to see high AoA landing
        plt3 = subplot(5,1,3);
        plot(t_cube,pitchAC,'b',t_cube,zero,'r:')
        title('Aircraft Pitch Angle vs Time')
        ylabel({'Aircraft Pitch';'Angle (°)'})
        %xticks([150:20:370])
        ylim([-20 50])

        % Altitude plot
        plt5 = subplot(5,1,5);
        plot(t_GPS,z_AGL,'b')
        title('Altitude vs Time')
        %xticks([150:20:370])
        ylabel({'Altitude AGL';'(m)'})
        xlabel('Time (seconds)')
        
        linkaxes([plt1 plt2 plt3 plt4 plt5],'x')
        xlim([t_low t_high])
        
        fig6=figure('Name','Sensor Data Comparisons');
        
        plt1 = subplot(3,1,1);
        plot(t_cube,v_a,'k',MHP_time_out,MHP(:,3),'r',MHP_time_out,MHP(:,4),'b',MHP_time_out,MHP(:,5),'g');
        title('Pixhawk Airspeed vs 5HP Alpha, Beta, and Pitot Velocities');
        ylabel({'Velocity (m/s)'});
        
        plt2 = subplot(3,1,2);
        plot(iM_Pix(:),iM_temp(:),'k',iM_Pix(:),iM_humid,'k-',TPH_time_out,TPH(:,6),'r',TPH_time_out,TPH(:,3),'r-',TPH_time_out,TPH(:,7),'b',TPH_time_out,TPH(:,4),'b-',TPH_time_out,TPH(:,8),'g',TPH_time_out,TPH(:,5),'g-');
        title('iMet vs Sensor Package Temperature and Humidity');
        ylabel({'Temp (°C) and Humidity (%)'});
        
        plt3 = subplot(3,1,3);
        plot(BARO(:,3),BARO(:,4),'k',iM_Pix(:),iM_pres(:),'r');
        title('Pixhawk (internal) vs iMet (external) Pressure Readings');
        ylabel({'Pressure (mbar)'});
        xlabel({'Time (sec)'});
        linkaxes([plt1 plt2 plt3],'x')
        xlim([min(BARO(:,3)) max(BARO(:,3))])
        
    else
        
        fig5=figure('Name','Data Plots from Parsed Autopilot DFL');
        
        % Groundspeed plot
        plt1 = subplot(4,1,1);
        plot(t_GPS,v_g,'b-',t_cube,v_a,'r-',t_NKF,wind,'g-')
        title('Groundspeed, Airspeed, and Windspeed vs Time')
        ylabel({'Groundspeed (blue)';'Airspeed (red)';'Windspeed (green)';'(m/s)'})
        
        % Throttle Output
        plt2 = subplot(4,1,2);
        plot(t_RCOU,thr,'b')
        title('Throttle vs Time')
        ylabel({'Throttle';'(%)'})
        ylim([0 100])
        
        % For the dotted line along x-axis of pitch plot
        zero=int8(zeros(length(pitchAC),1));
        
        % Aircraft Pitch angle: Can change ylim to something more relevant.
        % TIV uses -20 to 50 to see high AoA landing
        plt3 = subplot(4,1,3);
        plot(t_cube,pitchAC,'b',t_cube,zero,'r:')
        title('Aircraft Pitch Angle vs Time')
        ylabel({'Aircraft Pitch';'Angle (°)'})
        ylim([-10 40])
        
        
        % Altitude plot
        plt4 = subplot(4,1,4);
        plot(t_GPS,z_AGL,'b')
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
        plot(t_GPS,v_g,'b-',t_cube,v_a,'r-',t_NKF,wind,'g-')
        title('Groundspeed and Airspeed vs Time')
        ylabel({'Groundspeed (blue)';'Airspeed (red)';'Windspeed (green)';'(m/s)'})
        xlim([min(t_GPS) max(t_GPS)])
        
        % Throttle Output
        subplot(4,1,5);
        plot(t_RCOU,thr,'b')
        title('Throttle vs Time')
        ylabel({'Throttle';'(%)'})
        xlim([min(t_RCOU) max(t_RCOU)])
        ylim([0 100])
        
        % For the dotted line along x-axis of pitch plot
        zero=int8(zeros(length(pitchAC),1));
        
        % Aircraft Pitch angle: Can change ylim to something more relevant.
        % TIV uses -20 to 50 to see high AoA landing
        subplot(4,1,3);
        plot(t_cube,pitchAC,'b',t_cube,zero,'r:')
        title('Aircraft Pitch Angle vs Time')
        ylabel({'Aircraft Pitch';'Angle (°)'})
        xlim([min(t_cube) max(t_cube)])
        ylim([-20 50])
        
        % Altitude plot
        subplot(4,1,4);
        plot(t_GPS,z_AGL,'b')
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
            y_n1(n)=v_g(find(t_GPS>=x_n(n),1));      % Groundspeed
            y_n2(n)=v_a(find(t_cube>=x_n(n),1));     % Airspeed
            y_n3(n)=wind(find(t_NKF>=x_n(n),1));     % Windspeed
            y_n4(n)=thr(find(t_cube>=x_n(n),1));     % Throttle Percent
            y_n5(n)=pitchAC(find(t_cube>=x_n(n),1)); % Aircraft Pitch
            y_n6(n)=z_AGL(find(t_GPS>=x_n(n),1));    % Altitude
            y_n7(n)=RCOU(find(t_cube>=x_n(n),1),3);  % Pitch PWM
            
            % Groundspeed plot
            subplot(4,1,1);
            plot(t_GPS,v_g,'b',t_cube,v_a,'r',t_NKF,wind,'g',x_n,y_n1,'kx',x_n,y_n2,'kx',x_n,y_n3,'kx')
            title('Groundspeed, Airspeed, and Windspeed vs Time')
            ylabel({'Groundspeed (blue)';'Airspeed (red)';'Windspeed (green)';'(m/s)'})
            xlim([min(t_GPS) max(t_GPS)])
            
            % Throttle Output
            subplot(4,1,5);
            plot(t_RCOU,thr,'b',x_n, y_n4,'kx')
            title('Throttle vs Time')
            ylabel({'Throttle';'(%)'})
            xlim([min(t_RCOU) max(t_RCOU)])
            ylim([0 100])
            
            % For the dotted line along x-axis of pitch plot
            zero=int8(zeros(length(pitchAC),1));
            
            % Aircraft Pitch angle: Can change ylim to something more relevant.
            % TIV uses -20 to 50 to see high AoA landing
            subplot(4,1,3);
            plot(t_cube,pitchAC,'b',t_cube,zero,'r:',x_n,y_n5,'kx');
            title('Aircraft Pitch Angle vs Time');
            ylabel({'Aircraft Pitch';'Angle (°)'});
            xlim([min(t_cube) max(t_cube)]);
            ylim([-20 50]);
            
            % Altitude plot
            subplot(4,1,4);
            plot(t_GPS,z_AGL,'b',x_n,y_n6,'kx')
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

% Animation of flight
if(strcmpi(animateToggle, 'On'))
    id = ones(length(x), 1);
    obj1 = [x, y, z_AGL, t_plot', id];
    
    %% Animation Function
    
    %function comet3n( src, varargin )
    % COMET3N plots trajectories of multiple objects in 3D
    %   comet3n(src) plots tracjectors of objects specified by MxN  matrix src.
    %   src has to be at least M * 5 in size.
    %   The first 3 columns of src must be the x, y, and z coordinates of the
    %   object at a timepoint. The 4th column is timepoint where spatial
    %   coordinates are registered. The 5th column is the ID number of the
    %   object.
    %
    %   Optinally, color can be supplied in the form rgb indexes. src in this
    %   case would be an M * 8 matrix.
    %
    %   comet3n(src) plots cells and trajectories using the color
    %   specified by the 6th to 8th column (R,G and B) of the input file, src.
    %
    %   comet3n(src,'speed',num) allows different plotting speed, ranging from
    %   1 to 10. When speed argument is not given, this function will plot at
    %   maximum speed.
    %
    %   comet3n(src,'taillength',num) allows user to specify taillength.
    %   Defauly is 20.
    %
    %   comet3n(src,'headsize',num) allows user to change the size of head.
    %   The scale is relative to default size, which is 1/100 of the x axis
    %   range.
    %
    %   comet3n(src, 'tailwidth', num) allows user to change tail width.
    %
    %   comet3n(src,'alpha',num) allows user to change alpha value of the comet
    %   head. Default is 1.
    %
    %   Version 1.3
    %   Copyright Chaoyuan Yeh, 2016
    %
    ObjList_T = cell(max(obj1(:,4)),1);
    for tt = 1:max(obj1(:,4))
        ObjList_T{tt} = obj1(obj1(:,4)==tt,5);
    end
    
    if size(obj1,2) ~= 8
        color_temp = hsv(max(obj1(:,5)));
        color_temp = color_temp(randperm(max(obj1(:,5)))',:);
        color = zeros(size(obj1,1),3);
        for ii = 1 : max(obj1(:,5))
            ind = (obj1(:,5) == ii);
            color(ind,1) = color_temp(ii,1);
            color(ind,2) = color_temp(ii,2);
            color(ind,3) = color_temp(ii,3);
        end
        obj1(:,6:8) = color;
        clearvars ind color color_temp;
    end
    
    PosList_ID = cell(max(obj1(:,5)),1);
    for ii = 1:max(obj1(:,5))
        PosList_ID{ii} = obj1(obj1(:,5)==ii,[1:4,6:8]);
    end
    
    if animateTailLength <= 0
        animateTailLength = 20;
    end
    
    if animateTailWidth <= 0
        animateTailWidth = 2;
    end
    
    if animateSpeed <=0
        animateSpeed = 10;
    end
    
    if animateHeadSize <= 0 | animateHeadSize >10
        animateHeadSize = 2;
    end
    
    xmin = min(obj1(:,1));
    xmax = max(obj1(:,1));
    ymin = min(obj1(:,2));
    ymax = max(obj1(:,2));
    zmin = min(obj1(:,3));
    zmax = max(obj1(:,3));
    yratio = (ymax-ymin)/(xmax-xmin);
    zratio = (zmax-zmin)/(xmax-xmin);
    scale =(xmax-xmin)/100;
    
    scale = scale * animateHeadSize;
    
    animateAlpha = 1;
    
    [sx,sy,sz] = sphere(15);
    figure(5);
    hold on
    axis([xmin xmax ymin ymax zmin zmax])
    ax = gca;
    ax.Color = 'k';
    grid on
    ax.GridColor = 'w';
    ax.GridAlpha = 0.5;
    view([45 45])
    camlight('right')
    xlabel('Lattitude')
    ylabel('Longitude')
    zlabel('Altitude (m, AGL)')
    
    % Setup graphics handle
    numObj = max(obj1(:,5));
    gh = struct;
    for ii = 1:numObj
        gh(ii).sh = surface(0, 'EdgeColor', 'none');
        gh(ii).ph = plot(0,'LineWidth', animateTailWidth);
    end
    
    % Update position
    for tt = 1:max(obj1(:,4))
        ObjList = ObjList_T{tt};
        
        for ii = 1:length(ObjList)
            ind_t = find(PosList_ID{ObjList(ii)}(:,4)==tt);
            
            set(gh(ObjList(ii)).sh, 'XData', scale*sx+PosList_ID{ObjList(ii)}(ind_t,1),...
                'YData', scale*yratio*sy+PosList_ID{ObjList(ii)}(ind_t,2),...
                'ZData', scale*zratio*sz+PosList_ID{ObjList(ii)}(ind_t,3),...
                'FaceAlpha', animateAlpha,...
                'FaceColor', PosList_ID{ObjList(ii)}(ind_t,5:7));
            
            if ind_t <= animateTailLength
                
                set(gh(ObjList(ii)).ph, 'XData', PosList_ID{ObjList(ii)}(1:ind_t,1),...
                    'YData', PosList_ID{ObjList(ii)}(1:ind_t,2),...
                    'ZData', PosList_ID{ObjList(ii)}(1:ind_t,3),...
                    'color',PosList_ID{ObjList(ii)}(ind_t,5:7));
            else
                
                set(gh(ObjList(ii)).ph, 'XData', PosList_ID{ObjList(ii)}(ind_t-animateTailLength:ind_t,1),...
                    'YData', PosList_ID{ObjList(ii)}(ind_t-animateTailLength:ind_t,2),...
                    'Zdata', PosList_ID{ObjList(ii)}(ind_t-animateTailLength:ind_t,3),...
                    'color', PosList_ID{ObjList(ii)}(ind_t,5:7));
            end
        end
        drawnow
        pause(1/(100*animateSpeed));
    end
end

