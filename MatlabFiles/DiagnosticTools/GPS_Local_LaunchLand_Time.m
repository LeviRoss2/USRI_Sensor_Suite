clear all
clc

startingFolderDFL = pwd;
% Get the name of the file that the user wants to use.
defaultFileNameDFL = fullfile(startingFolderDFL,{'*.mat'});
[baseFileNameDFL, folderDFL] = uigetfile(defaultFileNameDFL, 'Select a Pixhawk DFL file (.bin or .mat only)');
startingFolderDFL = folderDFL;
if baseFileNameDFL == 0
    % User clicked the Cancel button.
    return;
end

fullInputMatFileNameDFL = fullfile(folderDFL, baseFileNameDFL);
load(fullInputMatFileNameDFL,'GPS','GPS_label','CTUN','CTUN_label');

cutGPS = find(GPS(:,10) ~= -17,1,'first');
GPS(1:cutGPS,:) = [];

TO_loc = find(CTUN(:,7)>=5,1,'first');
TO_ln = CTUN(TO_loc,1);
TO_gps = find(GPS(:,1)>=TO_ln,1,'first');
TO_wk = GPS(TO_gps,5);
TO_ms = GPS(TO_gps,4);

LND_loc = find(CTUN(:,7)>=5,1,'last');
LND_ln = CTUN(LND_loc,1);
LND_gps = find(GPS(:,1)>=LND_ln,1,'first');
LND_wk = GPS(LND_gps,5);
LND_ms = GPS(LND_gps,4);

GPS_wk = [TO_wk LND_wk];
GPS_ms = [TO_ms LND_ms];

% Convert GPS timestamps to UTC time
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
GPS_utc = datetime(tempGPS_comb,'TimeZone','UTC','Format','MMM-dd-yyyy HH:mm:ss.S');
GPS_stw = datetime(GPS_utc,'TimeZone','America/Chicago');

R = 6371000;  % Earths mean radius in meters
LAT = deg2rad(GPS(:,8));
LON = deg2rad(GPS(:,9));
delLat = LAT(:,1)-LAT(1,1);
delLon = LON(:,1)-LON(1,1);

d=zeros(length(GPS(:,1)),1);

for i=1:length(GPS(:,1));
    a = sin(delLat(i)/2).^2 + cos(LAT(i,1))*cos(LAT(1,1))*sin(delLon(i)/2).^2;
    c = 2*atan2(sqrt(a),sqrt(1-a));
    d(i,1) = R * c;
end

dispAlt = sprintf('Max Alt:\n   %d m\n   %d ft',round(max(GPS(:,10))-min(GPS(:,10)),0),round(unitsratio('feet','meters')*(max(GPS(:,10))-min(GPS(:,10))),0));
dispDist = sprintf('Max Distance:\n   %d m\n   %d ft',round(max(d),0),round(unitsratio('feet','meters')*max(d),0));
dispTO = sprintf('Takeoff Time:\n   %s',GPS_stw(1));
dispLND = sprintf('Land Time:\n   %s',GPS_stw(2));

disp(dispTO);
disp(dispLND);
disp(dispAlt);
disp(dispDist);
