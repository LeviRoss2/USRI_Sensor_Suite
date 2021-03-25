# Sensor Suite Repository
This repo is for all code sets supporting the 5 Hole Pitot Probe (5HP) and integrated atmospheric sensing suite (Temp, Pressure, Humidity) developed by the Unmanned Systems Research Institute at Oklahoma State University. The Arduino folder contains all libraries and files relating to the microcontroller setup (currently Teensy 3.6, switching to Teensy 4.1). The Matlab folder contains the parsing main code sets supporting 5 Hole Pitot Probe (5HP) data acquisition, analysis, parsing, and reporting.

###Prerequisites for running:###
1) Download Pixhawk DataFlash log using Mission Planner. Steps can be found here: https://ardupilot.org/copter/docs/common-downloading-and-analyzing-data-logs-in-mission-planner.html
2) Convert Pixhawk DFL (.bin or .txt) to a matlab file using Mission Planner. 
   1) In Mission Planner, on "Data" page, select "DataFlash Logs" tab below the artificial horizon.
   2) Select "Create Matlab File"
   3) Choose the DFL from your computer you wish to run through Matlab script. *Note: this can take a few minutes.*
3) Rename the file into something relevant. Common format includes Aircraft_Flight#_Month_Day_Year (ex: Hera_Flight1_08_04_2020)
4) Move file into conventient location. Whereever this file resides, so will the outputs from the Matlab parser.
5) Move any supporting files to the same location (iMet, 5HP/TPH, etc.)

###How to use Matlab script (dev version):###
1) Choose which flags you would like to enable/disable
2) Click Run
   1) If an animation is chosen, the Command Window will prompt you to enter a plot title.
3) First file requested will be a converted DataFlash log from a Pixhawk Autopilot. This is the file from Prerequisite Step 2 above.
4) A plot figure with 4 plots will appear. Using the mouse, select the "start" and "stop" points for the parser. Note: mouse cursor will turn into a crosshair, and selecing a point on any of the 4 graphs will work, as the parser is using that x-value to parse with.
5) If iMet data is chosen, next file asked for will be iMet data logged from the an XQ (small) or XQ2 (large).
6) If 5HP or TPH data is chosen, next file asked for will be MHP/TPH data logged from the teensy. This file will be vehicleName###.csv for example HERA002.csv.
7) Thats it! Output data will be inputFileName_Parsed.mat for the converted Pixhawk file, the TPH and iMet data will be inputFileName_Parsed_Sensor (ex: Sensor can be TPH, MHP, iMet, GPS, etc.)
