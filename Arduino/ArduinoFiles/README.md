# Primary Code
This is the main code for the Teensy to operate 3 Honeywell HSC-series differntial pressure transducers (3D wind velocity vector), 3 iMet thermocouples, 3 HYT271 Humidity sensors, and 2 MS5611 barometers.

The code cycles through based on user-prorgammed timing loops (higher TPH data rate = lower max 5HP data rate).

MavLink connection with Pixhawk allows for Pixhawk boot time and GPS UNIX time to be logged on the Teensy in 1 second intervals.

Post processing in the Matlab PixhawkParser script takes the Teensy and Pixhawk board times, converts them into UTC times, and generates tables with all Pixhawk and Sensor Suite data in the same time domain for comparisons between both systems.

All data Teensy is stored in the onboard SD card.
