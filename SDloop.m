myDir = uigetdir; %gets directory
myFiles = dir(fullfile(myDir,'*.bin'));
iter = 0;

for k = 1:length(myFiles)
    baseFileName = myFiles(k).name;
    fullFileName = fullfile(myDir, baseFileName);
    try
        rawDFL{k,1} = Ardupilog(fullFileName);
    catch
        display('No GPS connection, assume no flight.');
        continue
    end
    
    nextLog = rawDFL{k}.MSG;
    
    % Initialize check for ArduPilot Type
    Rover = 0;
    Copter = 0;
    QuadPlane = 0;
    Plane = 0;
    
    % Scan message log to determine what ArduPilot type it is
    for i=1:length(nextLog.LineNo);
        if(contains(nextLog.Message(i,1:length(nextLog.Message(1,:))),'ArduCopter'))
            Copter = 1;
        elseif(contains(nextLog.Message(i,1:length(nextLog.Message(1,:))),'QuadPlane'))
            QuadPlane = 1;
        elseif(contains(nextLog.Message(i,1:length(nextLog.Message(1,:))),'ArduRover'))
            Rover = 1;
        elseif(contains(nextLog.Message(i,1:length(nextLog.Message(1,:))),'ArduPlane'))
            Plane = 1;
        end
    end
    
    % Depending on what values were found, set ArduPilot type
    % This structure prevents false analysis as more than 1 can be present
    if(Rover == 1)
        %arduPilotType = 'ArduRover';
    elseif(Copter == 1)
        %arduPilotType = 'ArduCopter';
        throttleOn = find(rawDFL{k}.CTUN.ThO >= 0.05);
        
        j = 0;
        new = 1;
        for i=1:length(throttleOn)-1
            if((throttleOn(i+1) - throttleOn(i))>1)
                j = j + 1;
                throttleBreak{j,1} = throttleOn(new:i,1);
                throttleBreak{j,2} = throttleOn(i)-throttleOn(new);
                new = i;
            end
        end
        
        if (new == 1)
            TO_time =  rawDFL{k}.CTUN.TimeUS(throttleOn(1));
            LND_time = rawDFL{k}.CTUN.TimeUS(throttleOn(end));
            
            flightTime = LND_time - TO_time;
        else
            flightTime = 0;
            
            allBreaks = [throttleBreak{:,2}]';
            targInd = find(allBreaks == max(allBreaks));
        end
        
        %if(rawDFL{k}.CTUN.TimeUS(throttleBreak
       
        
        
        if(flightTime >= 60000000)
            
            iter = iter+1;
            outputMSG{iter,1} = rawDFL{k}.MSG.DatenumUTC;
            outputMSG{iter,2} = datetime(rawDFL{k}.MSG.DatenumUTC,'ConvertFrom','datenum','Format','MMM-dd-yyy');
            outputMSG{iter,3} = datetime(rawDFL{k}.MSG.DatenumUTC,'ConvertFrom','datenum','Format','hh:mm:ss.SSS');
            outputMSG{iter,4} = rawDFL{k}.MSG.Message;
            outputGPS{iter,1} = rawDFL{k}.GPS.DatenumUTC;
            outputGPS{iter,2} = datetime(rawDFL{k}.GPS.DatenumUTC,'ConvertFrom','datenum','Format','MMM-dd-yyy');
            outputGPS{iter,3} = datetime(rawDFL{k}.GPS.DatenumUTC,'ConvertFrom','datenum','Format','hh:mm:ss.SSS');
            outputGPS{iter,4} = rawDFL{k}.GPS.NSats;
            outputGPS{iter,5} = rawDFL{k}.GPS.HDop;
            outputGPS{iter,6} = rawDFL{k}.GPS.Lat;
            outputGPS{iter,7} = rawDFL{k}.GPS.Lng;
            outputGPS{iter,8} = rawDFL{k}.GPS.Alt;
            outputGPS{iter,9} = rawDFL{k}.GPS.Spd;
            outputGPS{iter,10} = rawDFL{k}.GPS.GCrs;
            outputGPS{iter,11} = rawDFL{k}.GPS.VZ;
            for j = 1:length(rawDFL{k}.PARM.Name)
                if(contains(string(rawDFL{k}.PARM.Name(j,:)),"THISMAV"))
                    sysID{iter,1} = rawDFL{k}.PARM.Value(j,1);
                    break
                end
            end
            
            TO_DateUTC = datetime(rawDFL{k}.MSG.DatenumUTC(1),'ConvertFrom','datenum','Format','yyyy-MM-dd');
            TO_TimeUTC = datetime(rawDFL{k}.MSG.DatenumUTC(1),'ConvertFrom','datenum','Format','hh-mm-ss');
            
            exportMSG = [];
            exportMSG = table(outputMSG{iter,:},'VariableNames',{'PosixTime',...
                'DateUTC','TimeUTC','Messages'});
            
            exportGPS = [];
            exportGPS = table(outputGPS{iter,:},'VariableNames',{'Posix Time',...
                'DateUTC','TimeUTC','NumberSats','HDop(m)','Lat','Long',...
                'Alt(m)','GroundSpeed(m/s)','Heading','VerticalSpeed(m/s)'});

            % Save tabele for user review           
            table2saveCSV(TO_DateUTC,TO_TimeUTC,sysID{iter,1},"MSG",exportMSG,myDir);
            table2saveCSV(TO_DateUTC,TO_TimeUTC,sysID{iter,1},"GPS",exportGPS,myDir);
            
        end
        
    elseif(QuadPlane == 1)
        %arduPilotType = 'QuadPlane';
        flying = rawDFL{k}.STAT.isFlying;
        
        TO = find(flying,1,'first');
        LND = find(flying,1,'last');
        
        TO_time = rawDFL{k}.STAT.TimeUS(TO);
        LND_time = rawDFL{k}.STAT.TimeUS(LND);
        flightTime = LND_time - TO_time;
        
        if(flightTime >= 60000000)
            
            TO_DateUTC = datetime(rawDFL{k}.STAT.DatenumUTC(TO),'ConvertFrom','datenum','Format','yyyy-MM-dd');
            TO_TimeUTC = datetime(rawDFL{k}.STAT.DatenumUTC(TO),'ConvertFrom','datenum','Format','hh-mm-ss');
            
            iter = iter+1;
            outputMSG{iter,1} = rawDFL{k}.MSG.DatenumUTC;
            outputMSG{iter,2} = datetime(rawDFL{k}.MSG.DatenumUTC,'ConvertFrom','datenum','Format','MMM-dd-yyy');
            outputMSG{iter,3} = datetime(rawDFL{k}.MSG.DatenumUTC,'ConvertFrom','datenum','Format','hh:mm:ss.SSS');
            outputMSG{iter,4} = rawDFL{k}.MSG.Message;
            outputGPS{iter,1} = rawDFL{k}.GPS.DatenumUTC;
            outputGPS{iter,2} = datetime(rawDFL{k}.GPS.DatenumUTC,'ConvertFrom','datenum','Format','MMM-dd-yyy');
            outputGPS{iter,3} = datetime(rawDFL{k}.GPS.DatenumUTC,'ConvertFrom','datenum','Format','hh:mm:ss.SSS');
            outputGPS{iter,4} = rawDFL{k}.GPS.NSats;
            outputGPS{iter,5} = rawDFL{k}.GPS.HDop;
            outputGPS{iter,6} = rawDFL{k}.GPS.Lat;
            outputGPS{iter,7} = rawDFL{k}.GPS.Lng;
            outputGPS{iter,8} = rawDFL{k}.GPS.Alt;
            outputGPS{iter,9} = rawDFL{k}.GPS.Spd;
            outputGPS{iter,10} = rawDFL{k}.GPS.GCrs;
            outputGPS{iter,11} = rawDFL{k}.GPS.VZ;
            for j = 1:length(rawDFL{k}.PARM.Name)
                if(contains(string(rawDFL{k}.PARM.Name(j,:)),"THISMAV"))
                    sysID{iter,1} = rawDFL{k}.PARM.Value(j,1);
                    break
                end
            end
            
            exportMSG = [];
            exportMSG = table(outputMSG{iter,:},'VariableNames',{'PosixTime',...
                'DateUTC','TimeUTC','Messages'});
            
            exportGPS = [];
            exportGPS = table(outputGPS{iter,:},'VariableNames',{'Posix Time',...
                'DateUTC','TimeUTC','NumberSats','HDop(m)','Lat','Long',...
                'Alt(m)','GroundSpeed(m/s)','Heading','VerticalSpeed(m/s)'});

            % Save tabele for user review           
            table2saveCSV(TO_DateUTC,TO_TimeUTC,sysID{iter,1},"MSG",exportMSG,myDir);
            table2saveCSV(TO_DateUTC,TO_TimeUTC,sysID{iter,1},"GPS",exportGPS,myDir);
            
        end
        
        
    elseif(Plane == 1)
        %arduPilotType = 'FixedWing';
        flying = rawDFL{k}.STAT.isFlying;
        
        TO = find(flying,1,'first');
        LND = find(flying,1,'last');
        
        TO_time = rawDFL{k}.STAT.TimeUS(TO);
        LND_time = rawDFL{k}.STAT.TimeUS(LND);
        flightTime = LND_time - TO_time;
        
        if(flightTime >= 60000000)
            
            TO_DateUTC = datetime(rawDFL{k}.STAT.DatenumUTC(TO),'ConvertFrom','datenum','Format','yyyy-MM-dd');
            TO_TimeUTC = datetime(rawDFL{k}.STAT.DatenumUTC(TO),'ConvertFrom','datenum','Format','hh-mm-ss');
            
            iter = iter+1;
            outputMSG{iter,1} = rawDFL{k}.MSG.DatenumUTC;
            outputMSG{iter,2} = datetime(rawDFL{k}.MSG.DatenumUTC,'ConvertFrom','datenum','Format','MMM-dd-yyy');
            outputMSG{iter,3} = datetime(rawDFL{k}.MSG.DatenumUTC,'ConvertFrom','datenum','Format','hh:mm:ss.SSS');
            outputMSG{iter,4} = rawDFL{k}.MSG.Message;
            outputGPS{iter,1} = rawDFL{k}.GPS.DatenumUTC;
            outputGPS{iter,2} = datetime(rawDFL{k}.GPS.DatenumUTC,'ConvertFrom','datenum','Format','MMM-dd-yyy');
            outputGPS{iter,3} = datetime(rawDFL{k}.GPS.DatenumUTC,'ConvertFrom','datenum','Format','hh:mm:ss.SSS');
            outputGPS{iter,4} = rawDFL{k}.GPS.NSats;
            outputGPS{iter,5} = rawDFL{k}.GPS.HDop;
            outputGPS{iter,6} = rawDFL{k}.GPS.Lat;
            outputGPS{iter,7} = rawDFL{k}.GPS.Lng;
            outputGPS{iter,8} = rawDFL{k}.GPS.Alt;
            outputGPS{iter,9} = rawDFL{k}.GPS.Spd;
            outputGPS{iter,10} = rawDFL{k}.GPS.GCrs;
            outputGPS{iter,11} = rawDFL{k}.GPS.VZ;
            for j = 1:length(rawDFL{k}.PARM.Name)
                if(contains(string(rawDFL{k}.PARM.Name(j,:)),"THISMAV"))
                    sysID{iter,1} = rawDFL{k}.PARM.Value(j,1);
                    break
                end
            end

            exportMSG = [];
            exportMSG = table(outputMSG{iter,:},'VariableNames',{'PosixTime',...
                'DateUTC','TimeUTC','Messages'});
            
            exportGPS = [];
            exportGPS = table(outputGPS{iter,:},'VariableNames',{'Posix Time',...
                'DateUTC','TimeUTC','NumberSats','HDop(m)','Lat','Long',...
                'Alt(m)','GroundSpeed(m/s)','Heading','VerticalSpeed(m/s)'});

            % Save tabele for user review           
            table2saveCSV(TO_DateUTC,TO_TimeUTC,sysID{iter,1},"MSG",exportMSG,myDir);
            table2saveCSV(TO_DateUTC,TO_TimeUTC,sysID{iter,1},"GPS",exportGPS,myDir);
        end
    end
    
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
function table2saveCSV(TO_Date, TO_time,AC_ID, varName, varData, folder)

% Save file as "PixhawkDFLname_VARNAME.csv"
% VARNAME can be undefinedVar if description is not set
baseFileName = sprintf('%s_%s_%s-%d_%s.csv',TO_Date,TO_time,'ID',AC_ID,varName);
fullOutputFileName = fullfile(folder, baseFileName);
% Write data to .csv file
writetable(varData, fullOutputFileName);

end


