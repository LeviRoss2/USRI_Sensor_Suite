clear all
close all
clc

%% Gather Pixhawk Data
thrMinPWM = 1100;              % Default, scales THR% plots
thrMaxPWM = 1900;
mhpValue = 'Yes';
tphValue = 'Yes';
sensorOut = 'Yes';
DFL_NewOld = 'New';

startingFolderDFL = pwd;
% Get the name of the file that the user wants to use.
defaultFileNameDFL = fullfile(startingFolderDFL,{'*.bin;*.mat'});
[baseFileNameDFL, folderDFL] = uigetfile(defaultFileNameDFL, 'Select a Pixhawk DFL file (.bin or .mat only)');
startingFolderDFL = folderDFL;
fullInputMatFileNameDFL = fullfile(folderDFL, baseFileNameDFL);
% Preserve original file name
[~, baseNameNoExtDFL, ~] = fileparts(baseFileNameDFL);

if baseFileNameDFL == 0
    % User clicked the Cancel button.
    return;
end

rawDFL = Ardupilog(fullInputMatFileNameDFL);

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
%% XKF2
XKF2(:,1) = rawDFL.XKF2.LineNo;
XKF2(:,2) = fix(rawDFL.XKF2.TimeS/rawDFL.XKF2.fieldMultipliers.TimeUS);
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

%% Process Pixhawk Data
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

%%%%%%%%% GPS Logs Parsing %%%%%%%%%
% Latitude
x=GPS(:,5);
% Longitude
y=GPS(:,6);
% Altitude
z=GPS(:,7);
z_AGL = z(:)-z(1);

%%%%%%%%% Airspeed and Windspeed Data %%%%%%%%%
% Ground speed
v_g=GPS(:,8);
% Max ground speed
max_v_g=max(GPS(:,8));
% Airspeed
v_a=CTUN(:,6);
% North winds
VWN=NKF2(:,3);
% East winds
VWE=NKF2(:,4);
% Wind vector
wind=(VWN.^2+VWE.^2).^0.5;

%%%%%%%%% Aircraft Data %%%%%%%%%
% Pitch PWM signal
pitchPWM=RCOU(:,3);
% Aircraft pitch angle
pitchAC=ATT(:,4);
% Aircraft roll angle
rollAC = ATT(:,3);
% Aircraft yaw (Earth reference, degrees)
yawAC = ATT(:,5);
% Throttle output from Pixhawk
thr=(RCOU(:,5)-thrMinPWM)/(thrMaxPWM-thrMinPWM)*100;

%% Parse All Data and Save To Respective Tables
% Parsed GPS data output
GPS_LN = GPS(:,1);
GPS_time = GPS(:,2);
GPS_ms = GPS(:,3);
GPS_wk = GPS(:,4);
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
GPS_label = {'Line No','Time since boot (us)','Time from Arming (sec)','UTC Date','UTC Time','Lattitude','Longitude','Altitude (m, MSL)','Altitude (m, AGL)','Groundspeed (m/s)'};
GPS_table = table(GPS_LN, GPS_time, GPS_time_out,tempGPS_date,tempGPS_time, x, y, z, z_AGL, v_g, 'VariableNames', {'Line Number','Time from boot (us)','Time from parse (sec)','UTC Date','UTC Time','Lat','Long','Altitude (m, MSL)','Altitude (m, AGL)','Groundspeed (m/s)'});

% Parsed Attidue data output
ATT_LN = ATT(:,1);
ATT_time = ATT(:,2);
ATT_time_out= (ATT_time-min(ATT_time))/1000000;
ATT = [ATT_LN, ATT_time, ATT_time_out, rollAC, pitchAC, yawAC];
ATT_label = {'Line No','Time since boot (us)','Time from Arming (sec)','Aircraft Roll (deg)','Aircraft Pitch (deg)','Aircraft Yaw (deg)'};
ATT_table = table(ATT_LN,ATT_time,ATT_time_out, rollAC, pitchAC, yawAC, 'VariableNames', {'Line Number','Time from boot (us)','Time from parse (sec)','Aircraft Roll (deg)','Aircraft Pitch (deg)','Aircraft Yaw (deg, magnetic)'});

% Parsed CTUN data output
CTUN_LN = CTUN(:,1);
CTUN_time = CTUN(:,2);
CTUN_time_out= (CTUN_time-min(CTUN_time))/1000000;
CTUN = [CTUN_LN, CTUN_time, CTUN_time_out, v_a];
CTUN_label = {'Line No','Time since boot (us)','Time from Arming (sec)','Airspeed (m/s)'};
CTUN_table = table(CTUN_LN,CTUN_time,CTUN_time_out,v_a,'VariableNames',{'Line Number','Time from boot (us)','Time from parse (sec)','Airspeed (m/s)'});

% Parsed NKF2 data output
NKF_LN = NKF2(:,1);
NKF_time = NKF2(:,2);
NKF_time_out= (NKF_time-min(NKF_time))/1000000;
NKF2 = [NKF_LN, NKF_time, NKF_time_out, VWN, VWE];
NKF2_label = {'Line No','Time since boot (us)','Time from Arming (sec)','North Wind Vector (m/s)','East Wind Vector (m/s)'};
NKF2_table = table(NKF_LN, NKF_time, NKF_time_out, VWN, VWE, wind,'VariableNames',{'Line Number','Time from boot (us)','Time from parse (sec)','North Wind Vector (m/s)','East Wind Vector (m/s)','Wind Speed (m/s)'});

% Parsed RCOU data output
RCOU_LN = RCOU(:,1);
RCOU_time = RCOU(:,2);
RCOU_pitch = RCOU(:,3);
RCOU_roll = RCOU(:,4);
RCOU_thr = RCOU(:,5);
RCOU_yaw = RCOU(:,6);
RCOU_time_out = (RCOU_time-min(RCOU_time))/1000000;
RCOU = [RCOU_LN, RCOU_time, RCOU_time_out, RCOU_pitch, RCOU_roll, RCOU_thr, RCOU_yaw];
RCOU_label = {'Line No','Time since boot (us)','Time from Arming (sec)','C1 - Pitch PWM',' C2 - Roll PWM','C3 - Throttle PWM','C4 - Yaw PWM'};
RCOU_table = table(RCOU_LN, RCOU_time, RCOU_time_out, RCOU_pitch, RCOU_roll, thr,RCOU_thr, RCOU_yaw, 'VariableNames',{'Line Number','Time from boot (us)','Time from parse (sec)','Pitch PWM','Roll PWM','Throttle (%)','Throttle PWM','Yaw PWM'});

% Parsed IMU data output
IMU_LN = IMU(:,1);
IMU_time = IMU(:,2);
IMU_GyrX = IMU(:,3);
IMU_GyrY = IMU(:,4);
IMU_GyrZ = IMU(:,5);
IMU_AccX = IMU(:,6);
IMU_AccY = IMU(:,7);
IMU_AccZ = IMU(:,8);
IMU_time_out = (IMU_time-min(IMU_time))/1000000;
IMU = [IMU_LN, IMU_time, IMU_time_out, IMU_GyrX, IMU_GyrY, IMU_GyrZ, IMU_AccX, IMU_AccY, IMU_AccZ];
IMU_label = {'Line No','Time since boot (us)','Time from parse (sec)','X Gyro rotation (°/sec)','Y Gyro rotation (°/sec)','Z Gyro rotation (°/sec)','X Acceleration (°/sec/sec)','Y Acceleration (°/sec/sec)','Z Acceleration (°/sec/sec)'};
IMU_table = table(IMU_LN,IMU_time,IMU_time_out,IMU_GyrX, IMU_GyrY, IMU_GyrZ, IMU_AccX, IMU_AccY, IMU_AccZ,'VariableNames',{'Line Number','Time from boot (us)','Time from parse (sec)','X Gyro rotation (°/sec)','Y Gyro rotation (°/sec)','Z Gyro rotation (°/sec)','X Acceleration (°/sec/sec)','Y Acceleration (°/sec/sec)','Z Acceleration (°/sec/sec)'});

% Parsed Pixhawk barometric data
BARO_LN = BARO(:,1);
BARO_time = BARO(:,2);
BARO_time_out = (BARO_time-min(BARO_time))/1000000;
BARO_alt = BARO(:,3);
BARO_press = BARO(:,4)/100;
BARO = [BARO_LN, BARO_time, BARO_time_out, BARO_press, BARO_alt];
BARO_label = {'Line No','Time since boot (us)','Time from parse (sec)','Barometric pressure (mbar)','Barometric Altitude (m, AGL)'};
BARO_table = table(BARO_LN,BARO_time,BARO_time_out,BARO_press, BARO_alt,'VariableNames',{'Line Number','Time from boot (us)','Time from parse (sec)','Barometric pressure (mbar)','Barometric Altitude (m, AGL)'});

[~, baseNameNoExtDFL, ~] = fileparts(baseFileNameDFL);

baseFileName = sprintf('%s_Parsed.mat', baseNameNoExtDFL);
fullParsedMatFileName = fullfile(folderDFL, baseFileName);
save(fullParsedMatFileName,'ATT_table','GPS_table','CTUN_table','NKF2_table','RCOU_table','BARO_table','IMU_table');
%% 5HP Data Parsing and Output
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
    Temp = T1(i);
    
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

%Time in microseconds converted to milliseconds
tempPixTime = GPS(:,2)/1000;
%Time in tenths of a second
serialGPS = posixtime(GPS_final);

count = 0;
lastVal = 1;
for i=1:length(data(:,1))
    number = data(i,1)/1000;
    integ = fix(number);
    fract = fix(abs(number - integ)*10);
    if(fract == 0 | fract == 2 | fract == 4 | fract == 6 | fract == 8)
        if(fract ~= lastVal)
            count=count+1;
            lastVal = fract;
            sensorTime(count,1) = data(i,1);
        end
    end
end

if(length(sensorTime) > length(tempPixTime))
    offset = length(sensorTime) - length(tempPixTime);
    sensorTime(1:offset,:) = [];
else
    offset = length(tempPixTime) - length(sensorTime);
    tempPixTime((end-offset+1):end,:) = [];
    serialGPS((end-offset+1):end,:) = [];
end


timeCompare(:,1) = sensorTime(:,1); % Teensy board time data (ms)
timeCompare(:,2) = tempPixTime(:,1); % Pix board time data (ms)
timeCompare(:,3) = serialGPS(:,1);  % Pix GPS time data (sec)

% Offsets between board time and Pix time
MHPData(:,2)= interp1(timeCompare(:,1),timeCompare(:,2),MHPData(:,1));
MHPData_Unix= interp1(timeCompare(:,1),timeCompare(:,3),MHPData(:,1));

for i=fliplr(1:length(MHPData(:,2)))
    if(isnan(MHPData(i,2)))
        MHPData(i,:)=[];
        MHPData_Unix(i,:) = [];
    end
end


MHP_DateTime=datetime(MHPData_Unix,'ConvertFrom','posixTime','Format','MMM-dd-yyyy HH:mm:ss.S');
MHP_Date=datestr(MHP_DateTime,'mmm-dd-yyyy');
MHP_Time=datestr(MHP_DateTime,'HH:MM:SS.FFF');

if(exist('THSense','var'))
    THSense(:,2)=interp1(timeCompare(:,1),timeCompare(:,2),THSense(:,1));
    THSense_Unix=interp1(timeCompare(:,1),timeCompare(:,3),THSense(:,1));
    
    for i=fliplr(1:length(THSense(:,2)))
        if(isnan(THSense(i,2)))
            THSense(i,:)=[];
            THSense_Unix(i,:) = [];
        end
    end
    
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
    TPH_time_out = (TPH_entry(:,2)-min(TPH_entry(:,2)))/1000+TPH_entry(1,1)/1000-tempPixTime(1,1)/1000;
end

MHP_entry = MHPData(TO_MHP:LND_MHP,:);
MHP_Date = MHP_Date(TO_MHP:LND_MHP,:);
MHP_Time = MHP_Time(TO_MHP:LND_MHP,:);
MHP_time_out = (MHP_entry(:,2)-min(MHP_entry(:,2)))/1000+MHP_entry(1,1)/1000-tempPixTime(1,1)/1000;

Pix_time_out = (tempPixTime(:,1)-min(tempPixTime(:,1)))/1000;

% Create tables with the data and variable names
MHP_table = table(MHP_entry(:,1),MHP_entry(:,2),MHP_time_out, MHP_Date, MHP_Time,MHP_entry(:,3),MHP_entry(:,4),MHP_entry(:,5),MHP_entry(:,6),MHP_entry(:,7),MHP_entry(:,8),MHP_entry(:,9),MHP_entry(:,10),MHP_entry(:,11),MHP_entry(:,12),MHP_entry(:,13),MHP_entry(:,14),'VariableNames', {'Board Time from PowerUp (msec)','Pix Time from PowerUp (msec)','Pix time from parse','UTC Date','UTC Time','U (m/s)','V (m/s)','W (m/s)','Alpha(deg)','Beta(deg)','Alpha Mean Aver.','Beta Mean Aver.','Total Velocity (m/s)','TBD','TBD2','TBD3','TBD4'} );
save(fullParsedMatFileName,'MHP_table','-append');

PixData_table = table(timeCompare(:,1),timeCompare(:,3),Pix_time_out,timeCompare(:,2),'VariableNames',{'Sensor board time (ms)','GPS Unix Time (sec)','Pix boot time (sec)','Pix board time (ms)'});
save(fullParsedMatFileName,'PixData_table','-append');

if(exist('THSense','var'))
    TPH_table = table(TPH_entry(:,1),TPH_entry(:,2),TPH_time_out,TH_Date, TH_Time, TPH_entry(:,3),TPH_entry(:,4),TPH_entry(:,5),TPH_entry(:,6),TPH_entry(:,7),TPH_entry(:,8) , 'VariableNames', {'Board Time from PowerUp (msec)','Pixhawk Time from PowerUp (msec)','Pix Time from parse','UTC Date','UTC Time','Temp 1 (°C)','Temp 2 (°C)','Temp 3 (°C)','Humidity 1 (%)','Humidity 2 (%)','Humidity 3 (%)'} );
    save(fullParsedMatFileName,'TPH_table','-append');
end

if(exist('TPH_table','var'))
    TPH = [table2array(TPH_table(:,1:3)) table2array(TPH_table(:,6:end))];
end
if(exist('MHP_table','var'))
    MHP = [table2array(MHP_table(:,1:3)) table2array(MHP_table(:,6:end))];
    CTUN = table2array(CTUN_table);
end

if(strcmpi(mhpValue,'Yes') && strcmpi(tphValue,'Yes') && exist('TPH','var'))
    
    fig4=figure(4);
    fig4.Name = 'Parsed 5HP and TPH Data';
    set(fig4,'defaultLegendAutoUpdate','off');
    subplot(2,1,1);
    %plt2 = plot(TPH(:,3),TPH(:,4),'r-',TPH(:,3),TPH(:,5),'b-',TPH(:,3),TPH(:,6),'g-',TPH(:,3),TPH(:,7),'r.',TPH(:,3),TPH(:,8),'b.',TPH(:,3),TPH(:,9),'g.');
    plt2 = plot(TPH(:,3),TPH(:,4),'r-',TPH(:,3),TPH(:,5),'b-',TPH(:,3),TPH(:,6),'g-',TPH(:,3),TPH(:,9),'g.');
    
    title('Temp and Humidity vs Time')
    legend({'Temp 1','Temp 2', 'Temp 3','Humid 1','Humid 2', 'Humid 3'},'Location','southeast')
    xlabel('Time (sec)');
    ylabel('Temp (°C) and Humidity (%)');
    xlim([min(TPH(:,3)) max(TPH(:,3))])
    
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
    plt2 = plot(MHP(:,3),MHP(:,4),'r',MHP(:,3),MHP(:,5),'b',MHP(:,3),MHP(:,6),'g',CTUN(:,2)/1000000,CTUN(:,4),'k');
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
    
elseif(strcmpi(mhpValue,'Yes') && (strcmpi(tphValue,'No') | ~exist('TPH','var')))
    
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
    plt1 = plot(MHP(:,3),MHP(:,4),'r',CTUN(:,2),CTUN(:,4),'k');
    title('MHP Pitot and Pix Airspeeds with Time')
    legend({'MHP Pitot', 'Pix Arspd'},'Location','northwest')
    ylabel('Airspeed (m/s)');
    xlim([(min(MHP(:,3))) (max(MHP(:,3)))])
    
    subplot(2,1,2)
    plt2 = plot(MHP(:,3),MHP(:,4),'r',MHP(:,3),MHP(:,5),'b',MHP(:,3),MHP(:,6),'g',CTUN(:,2)/1000000,CTUN(:,4),'k');
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
    
    
elseif(strcmpi(mhpValue,'No') && strcmpi(tphValue,'Yes') && exist('TPH','var'))
    
    fig4=figure(4);
    fig4.Name = 'Parsed TPH Data';
    plt2 = plot(TPH(:,3),TPH(:,4),'r-',TPH(:,3),TPH(:,5),'b-',TPH(:,3),TPH(:,6),'g-',TPH(:,3),TPH(:,7),'r.',TPH(:,3),TPH(:,8),'b.',TPH(:,3),TPH(:,9),'g.');
    title('Temp and Humidity vs Time')
    legend({'Temp 1','Temp 2', 'Temp 3','Humid 1','Humid 2', 'Humid 3'},'Location','southeast')
    xlabel('Time (sec)');
    ylabel('Temp (°C) and Humidity (%)');
    xlim([(min(TPH(:,3))) (max(TPH(:,3)))])
    
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