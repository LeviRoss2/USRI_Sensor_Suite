% Trisonica parser - Base file 
% Created by: Kyle Hickman | kthickm@okstate.edu
% Modified by: James Brenner | jcbrenn@okstate.edu
% Unmanned Systems Research Institute 
% Creation Date - 4/19/2021
% Last Modified - 4/21/2021

% Features:

% General Updates:

% Bug Fixes:

% Unresolved Bugs/ Needed Work:
% - Need to convert data from string to numbers 
% - properly format the data (remove [] from number arrays) 
% - create plots of the data 
% - Convert the gps/unix time to useful data (see Levi's master sensor
% suite)

% Fig Count:
%    * Single: 0
%    * Multi: 0

%% Clear All Data
close all
clear all
clc

Y92AnemNumber = 1;


%% Load and Parse Anemometer data

[file, path] = uigetfile('*.*', 'Select Young 92000 Log File'); %Data File to parse
filename =fullfile(path, file);

dataRaw = readmatrix(filename);
data = dataRaw(2:end,:);

for(i=1:(length(data(1,:))-2))
    data(any(isnan(data(:,i)), 2), :) = [];
end

data(isnan(data)) = -1;

boardTime = data(:,1);
unixTime = data(:,7);
pixTime = data(:,8);

externTime = pixTime;

% Backfill Pixhawk BOOT and UNIX times via linear interpolation
if(max(pixTime) > 0)
    filledPixT(:,1)=timeInterpolation(boardTime(:,1),pixTime(:,1));
    
    if(max(unixTime)>0)
        filledUnixT(:,1)=timeInterpolation(boardTime(:,1),unixTime(:,1));
    else
        warning('Pixhawk GPS data not in file. Unix time cannot be parsed.');
    end
else
   warning('Pixhawk data not sent. Times cannot be parsed.'); 
end

anemTimeOut = (boardTime(:,1) - boardTime(1,1))./1000;

% Create external table for user view
% ADD DATE AND TIME (UTC) AS ENTRIES
Y92_tableExternal = table(boardTime(:,1),filledPixT(:,1),anemTimeOut,...
    data(:,2),data(:,3),data(:,4),data(:,5),data(:,6),...
    'VariableNames', {'Board Time from PowerUp (msec)',...
    'Pix Time from PowerUp (msec)','Time from parse (sec)',...
    'Wind Speed (m/s)','Wind Direction (deg)','Temperature (°C)',...
    'Humidity (%)','Pressure (mbar)'});
Y92_tableExternal.Properties.Description = sprintf('Y92Anem%d',Y92AnemNumber);
% Output table to user workspace
assignin('base',sprintf('Y92Anem_table%d',Y92AnemNumber),Y92_tableExternal);
% Save tabele for user review
%table2saveCSV(baseNameNoExt, folder, Y92_tableExternal)

% Generate internal-use table that uses DatenumUTC
% ADD DATENUME AS ENTRY
Y92_tableInternal = table(boardTime(:,1),filledPixT(:,1),anemTimeOut,...
    data(:,2),data(:,3),data(:,4),data(:,5),data(:,6),...
    'VariableNames', {'Board Time from PowerUp (msec)',...
    'Pix Time from PowerUp (msec)','Time from parse (sec)',...
    'Wind Speed (m/s)','Wind Direction (deg)','Temperature (°C)',...
    'Humidity (%)','Pressure (mbar)'});
Y92_tableInternal.Properties.Description = sprintf('Y92Aenm%d',Y92AnemNumber);
% Ouput internally-used table
outputY92 = Y92_tableInternal;

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

function outputArray = timeInterpolation(boardTime,externTime)

% Initialize the counter for output array
interpCount=0;

% Interpolation BuildUp
for i=1:length(boardTime(:,1))
    boardTimeInt = boardTime(i);   % Logger time (Teensy, Arduino, etc.)
    externTimeInt = externTime(i); % External time (Pix, Unix, GPS, etc.)
    
    % If valid timing value, add to interpolation array
    if(externTimeInt~=-1)
        interpCount=interpCount+1;
        interpData(interpCount,1)=boardTimeInt;   % Sensor board time
        interpData(interpCount,2)=externTimeInt;  % External Time        
    end
end

% Remove Duplicate External Time interpolation points
newVals=unique(interpData(:,2));
% Concatenate data based on unique datapoints only
for i=1:length(newVals(:,1))
    tempVal = find(interpData(:,2)==newVals(i,1),1,'first');
    conCat(i,1) = interpData(tempVal,1);
    conCat(i,2) = newVals(i,1);
end

% Backfill gaps in full dataset
for j = 1:length(boardTime(:,1))
    if(externTime(j,1) == -1)
        externTime(j,1) = interp1(conCat(:,1),conCat(:,2),boardTime(j,1),'linear');
    end
end

% Output the interpolated External Time array
interpolatedArray = externTime;

firstExtern = find((externTime(:,1)>0),1,'first');
lastExtern = find((externTime(:,1)>0),1,'last');

for(i=1:(firstExtern-1))
   
    beginning(i,1) = externTime(firstExtern,1) - (boardTime(firstExtern,1)-boardTime(i,1));
    
end

for(i=1:length(externTime)-lastExtern)
   
    ending(i,1) = externTime(lastExtern,1) + (boardTime(lastExtern+i,1)-boardTime(lastExtern,1));
    
end

outputArray = round([beginning; interpolatedArray(firstExtern:lastExtern,1); ending]);

end
