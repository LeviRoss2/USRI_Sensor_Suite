
i=0;
while i>(-1)

    i=i+1;
    nmeaMSG = [];
    
    spoof = sprintf('%d',i);
    
    lat = "3604.3966270";
    latDir = "N";
    lon = "07244.3966270";
    lonDir = "W";
    alt = append("500.",spoof);
    
    nmeaMSG = append(lat,',',latDir,',',lon,',',lonDir,',',alt)
    
    writeline(writeCom,nmeaMSG);
    
    pause(.2);
    
end
