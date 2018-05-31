These CSV files contain timeseries of atmospheric state variables at ne120 grid cells
nearest to corresponding stations in CESM high-resolution model data output.
For information about simulations, contact Nan Rosenbloom (nanr@ucar.edu)
for information about data processing/tropical cyclones, contact Colin Zarzycki (zarzycki@ucar.edu)

NAME:

station.KTLH.1980_2009.001.csv

station - Station-level data
KTLH - Tallahassee ICAO code
1980 - Start year
2009 - End year
001  - Ensemble member #1 (of 3)



DATA FORMAT:

KMIA, 25.8, -80.2, 2071093000, 25.8, 1004.8, 69.4, 10.6, 31.6, TRUE, 27.1, 280.5, 962.2, 43.6

KMIA       - Station identifier
25.8       - Station latitude
-80.2      - Station longitude
2071093000 - YYYYMMDDHH (00Z on Sept. 30th, 2071)
25.8       - 6-hourly accumulated precipitation (in mm) ending at YYYYMMDDHH
1004.8     - Station pressure corrected to sea level
69.4       - Total precipitable water (mm)
10.6       - Station 10m wind
31.6       - Surface radiative temperature (K)
TRUE       - TRUE means tropical cyclone detected within 500km of station at time (FALSE = no storm)
27.1       - Latitude of cyclone center, if TRUE. Otherwise, -999.0 if FALSE
280.5      - Longitude of cyclone center, if TRUE. Otherwise, -999.0 if FALSE
962.2      - Sea level pressure at cyclone center, if TRUE. Otherwise, -999.0 if FALSE
43.6       - Maximum 10m wind speed of cyclone, if TRUE. Otherwise, -999.0 if FALSE
