

while (true)

    flush(readCom,'input');
    pause(0.2);
    radarData = readline(readCom);
    radarData = split(radarData,',')
    
    nmeaMSG = [];
    
    clockTime = datetime('now','Format','HH mm ss SSS','TimeZone','Z');
    timeMid = split(sprintf("%s",clockTime),' ');
    
    name = "$GPGGA";
    time = sprintf('%s%s%s.%s',timeMid(1),timeMid(2),timeMid(3),timeMid(4));
    
    lat = radarData(1);
    latDir = radarData(2);
    lon = radarData(3);
    lonDir = radarData(4);
    alt = radarData(5);
    
    quality = "1";
    sats = "13";
    hdop = "1.0";
    altUnit = "M";
    geoSep = "0";
    geoSepUnit = "M";
    corAge = "1.0";
    corStat = "0000";
    fakeCheckSum = "*40";

    nmeaMSG = append(name,',',time,',',lat,',',latDir,',',lon,',',lonDir,',',quality,',',sats,',',hdop,',',alt,',',altUnit,',',geoSep,',',geoSepUnit,',',corAge,',',corStat,fakeCheckSum);
    
    actualCheckSum = gps_chksum(nmeaMSG);
    
    nmeaMSG = append(name,',',time,',',lat,',',latDir,',',lon,',',lonDir,',',quality,',',sats,',',hdop,',',alt,',',altUnit,',',geoSep,',',geoSepUnit,',',corAge,',',corStat,'*',actualCheckSum)
   
    
    flush(writeCom,'output');
    writeline(writeCom,nmeaMSG);

end


function chksm = gps_chksum(rawGPS)
%% This fuction calculates the checksum at the end of a line of GPS data.
%
% Val Schmidt
% Center for Coastal and Ocean Mapping
% University of New Hampshire
% 2012
gps=char(rawGPS);
names=regexp(gps,'\$(?<message>.*)\*(?<gsum>\w\w)','names');
msg=uint8(char(names.message));
%chksum=names.gsum;
chksm = uint8(msg(1));
for i=2:length(msg)
    chksm = bitxor(chksm,uint8(msg(i)));
end
chksm = dec2hex(chksm);

end
