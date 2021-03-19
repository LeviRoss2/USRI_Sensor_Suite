# Matlab Files
This folder contains the Matlab files relevant to the 5HP system.

Ardupilog: Takes raw Pixhawk DataFlash Log files (.bin) and converts it to useable matlab data. DOES NOT SAVE DATA AUTOMATICALLY.

PixhawkParser: Takes Pixhawk DFL's converted to Matlab files (using Mission Planner) for post-processing and data splicing with Sensor Suite.

In the works: Incorporate elements of Ardupilog into PixhawkParser to auto-convert .bin files to .mat, preventing the need for Mission Planner or extra codesets.
