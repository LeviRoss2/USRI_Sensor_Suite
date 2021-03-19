# Sensor Suite Repository
This repo is for all code sets supporting the 5 Hole Pitot Probe (5HP) and integrated atmospheric sensing suite (Temp, Pressure, Humidity) developed by the Unmanned Systems Research Institute at Oklahoma State University. The Arduino folder contains all libraries and files relating to the microcontroller setup (currently Teenmsy 3.6, switching to Teensy 4.1). The Matlab folder contains the parsing 
Main code sets supporting 5 Hole Pitot Probe (5HP) data acquisition, analysis, parsing, and reporting.

How to use (early draft)

  Click run
  First File requested will be a .dfl converted to a .mat for more info review https://ardupilot.org/copter/docs/common-downloading-and-analyzing-data-logs-in-mission-planner.html
  Second file will be MHP/TPH data logged from the teensy. This file will be vehicle_name###.csv for example HERA002.csv
