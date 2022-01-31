
%i=0;
%while i==0
    
%     flush(readCom,'input');
%     radarData = readline(readCom);
%     radarData = split(radarData,',');
    
    nmeaMSG = [];
    
    clockTime = datetime('now','Format','HH mm ss SSS','TimeZone','Z');
    timeMid = split(sprintf("%s",clockTime),' ');
    
    name = "$GPGGA";
    time = sprintf('%s%s%s.%s',timeMid(1),timeMid(2),timeMid(3),timeMid(4));
    
%     lat = radarData(1);
%     latDir = radarData(2);
%     lon = radarData(3);
%     lonDir = radarData(4);
%     alt = radarData(5);
    
    lat = "3404.7041778";
    latDir = "N";
    lon = "07044.3966270";
    lonDir = "W";
    alt = "495.144";
    
    quality = "1";
    sats = "13";
    hdop = "1.0";
    altUnit = "M";
    geoSep = "0";
    geoSepUnit = "M";
    corAge = "1.0";
    corStat = "0000";
    checkSum = "*40";
    nmeaMSG = append(name,',',time,',',lat,',',latDir,',',lon,',',lonDir,',',quality,',',sats,',',hdop,',',alt,',',altUnit,',',geoSep,',',geoSepUnit,',',corAge,',',corStat,checkSum)
    
    %flush(writeCom,'output');
    writeline(writeCom,nmeaMSG);
    %pause(.2);

%end
