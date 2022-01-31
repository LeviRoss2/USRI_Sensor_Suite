clear all
clc

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
load(fullInputMatFileNameDFL,'GPS','GPS_label');

cutGPS = find(GPS(:,10) ~= -17,1,'first');
GPS(1:cutGPS,:) = [];

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

disp(dispAlt);
disp(dispDist);