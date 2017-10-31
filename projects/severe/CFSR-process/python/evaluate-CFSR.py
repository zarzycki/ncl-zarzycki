# Analysis.
import numpy as np
import pandas as pd
import netCDF4
from netCDF4 import Dataset
import matplotlib

# Misc.
from datetime import datetime, timedelta
import time

########## FUNCTIONS

def nearest(items, pivot):
    return min(items, key=lambda x: abs(x - pivot))

def geo_idx(dd, dd_array):
   """
     search for nearest decimal degree in an array of decimal degrees and return the index.
     np.argmin returns the indices of minium value along an axis.
     so subtract dd from all values in dd_array, take absolute value and find index of minium.
    """
   geo_idx = (np.abs(dd_array - dd)).argmin()
   return geo_idx

def find(lst, a):
    return [i for i, x in enumerate(lst) if x==a]

from math import radians, cos, sin, asin, sqrt
def greatCircleDist(lon1, lat1, lon2, lat2):
    """
    Calculate the great circle distance (km) between two points 
    on the earth (specified in decimal degrees)
    """
    # convert decimal degrees to radians 
    lon1, lat1, lon2, lat2 = map(radians, [lon1, lat1, lon2, lat2])
    # haversine formula 
    dlon = lon2 - lon1 
    dlat = lat2 - lat1 
    a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
    c = 2 * asin(sqrt(a)) 
    km = 6367 * c
    return km

############### USER OPTIONS

debug=False    # Print a few debug statements in the loops

# Severe var to use and thresholds
severe_var="SCP"
severe_thresh=3.0   # severe indice threshold
precip_thresh=0.1   # precip rate thresh (mm/day)

# Offset for tor hit/miss ("grid cells")
space_offset=1  # 50km
time_offset=1   # 6 hours

# Dist threshold for gridded cell hit/false alarm
dist_thresh_km=250.

# Year to test
YYYY=2006

########################################## nc and csv files for each year

if YYYY == 2006:
  nc_file = '/glade/u/home/zarzycki/scratch/CFSR/CFSR-SEVERE/single-file/cfsr-2006.nc'
  csv_file = "./StormEvents/StormEvents_details-ftp_v1.0_d2006_c20170717.csv"
if YYYY == 2007:
  nc_file = '/glade/u/home/zarzycki/scratch/CFSR/CFSR-SEVERE/single-file/cfsr-2007.nc'
  csv_file = "./StormEvents/StormEvents_details-ftp_v1.0_d2007_c20170717.csv"
if YYYY == 2008:
  nc_file = '/glade/u/home/zarzycki/scratch/CFSR/CFSR-SEVERE/single-file/cfsr-2008.nc'
  csv_file = "./StormEvents/StormEvents_details-ftp_v1.0_d2008_c20170718.csv"
if YYYY == 2009:
  nc_file = '/glade/u/home/zarzycki/scratch/CFSR/CFSR-SEVERE/single-file/cfsr-2009.nc'
  csv_file = "./StormEvents/StormEvents_details-ftp_v1.0_d2009_c20170816.csv"

print("-------------------------------------------------------------------")
print(nc_file)
print(csv_file)
print "Severe var: %s   with threshold: %.1f    and precip threshold %.1f mm/d" % (severe_var , severe_thresh , precip_thresh)
print "space_offset: %d   time_offset: %d    dist_thresh_km %d" % (space_offset , time_offset , dist_thresh_km)

scriptStartTime = datetime.now()

# Read Storm Events CSV

raw_df = pd.read_csv(csv_file,parse_dates=["BEGIN_DATE_TIME"])

df = raw_df[[ "EVENT_TYPE","BEGIN_DATE_TIME","TOR_F_SCALE","BEGIN_LAT","BEGIN_LON","MAGNITUDE"]]

#filt_df = df.loc[(df['TOR_F_SCALE'] == 'EF2') | (df['TOR_F_SCALE'] == 'EF3') | (df['TOR_F_SCALE'] == 'EF4') | (df['TOR_F_SCALE'] == 'EF5') ]
#filt_df = df.loc[(df['TOR_F_SCALE'] == 'F2') | (df['TOR_F_SCALE'] == 'F3') | (df['TOR_F_SCALE'] == 'F4') | (df['TOR_F_SCALE'] == 'F5') ]
#filt_df = df.loc[(df['TOR_F_SCALE'] == 'F3') | (df['TOR_F_SCALE'] == 'F4') | (df['TOR_F_SCALE'] == 'F5') ]

# Filter by tornados > F1
df_tor = df.loc[(df['TOR_F_SCALE'] == 'F1') | (df['TOR_F_SCALE'] == 'F2') | (df['TOR_F_SCALE'] == 'F3') | (df['TOR_F_SCALE'] == 'F4') | (df['TOR_F_SCALE'] == 'F5') | (df['TOR_F_SCALE'] == 'EF1') | (df['TOR_F_SCALE'] == 'EF2') | (df['TOR_F_SCALE'] == 'EF3') | (df['TOR_F_SCALE'] == 'EF4') | (df['TOR_F_SCALE'] == 'EF5') ]

# Filter by all severe phenomena (used to check if gridded proxy has a nearby "severe" storm report
df_sev = df.loc[(df['EVENT_TYPE'] == 'Tornado') | (df['EVENT_TYPE'] == 'Funnel Cloud') | ((df['EVENT_TYPE'] == 'Hail') & (df['MAGNITUDE'] >= 1.0)) | ((df['EVENT_TYPE'] == 'Thunderstorm Wind') & (df['MAGNITUDE'] >= 58)) ]

# To list-ify
tor_obstimes=df_tor["BEGIN_DATE_TIME"].tolist()
tor_obslats =df_tor["BEGIN_LAT"].tolist()
tor_obslons =df_tor["BEGIN_LON"].tolist()
tor_fscale  =df_tor["TOR_F_SCALE"].tolist()
tor_numRecs =len(tor_obstimes)
sev_obstimes=df_sev["BEGIN_DATE_TIME"].tolist()
sev_obslats =df_sev["BEGIN_LAT"].tolist()
sev_obslons =df_sev["BEGIN_LON"].tolist()
sev_numRecs =len(sev_obstimes)

# Load/open CFSR NetCDF file
fh = Dataset(nc_file, mode='r')
lons = fh.variables['lon'][:]
lats = fh.variables['lat'][:]
times = netCDF4.num2date(fh.variables['time'][:],fh.variables['time'].units,fh.variables['time'].calendar)
nlons=len(lons)
nlats=len(lats)
ntimes=len(times)
modeltimes=pd.to_datetime(times)

# Process netCDF vars
severe = fh.variables[severe_var][:]
precip = fh.variables['PRECT'][:]
precip = precip/1.15741e-8/1000.
# Filter/mask where either severe or precip don't reach threshold
severe[np.where(severe<severe_thresh)] = 0.
precip[np.where(precip<precip_thresh)] = 0.

# Close netcdf file
fh.close()

# Initialize hits/misses arrays to 0
tor_hit=0
tor_miss=0
# Create total hit and miss bins for each EF category (1-5)
f_hit=[0] * 5
f_miss=[0] * 5
# Loop over all tornados in record
for ii, zz in enumerate(range(tor_numRecs-1)):
  # What time/lat/lon was this tornado observed at?
  obstime=tor_obstimes[ii]
  obslat=tor_obslats[ii]
  obslon=tor_obslons[ii]+360.
  # Find the nearest model time
  modeltime=nearest(modeltimes,obstime)
  # Find indices for nearest time, lat, lon in gridded data...
  latix=geo_idx(lats,obslat)
  lonix=geo_idx(lons,obslon)
  timeix=geo_idx(modeltimes,modeltime)

  # proxy is the multiplier of the severe index threshold + precip flag that have been masked out above.
  # if 0, it means one or both criteria WERE NOT MET at a particular grid cell
  # if >0, it means that both the index and precip values at that gridbox in time satisfy user-specified threshold
  proxy=severe[timeix-time_offset:timeix+time_offset+1,latix-space_offset:latix+space_offset+1,lonix-space_offset:lonix+space_offset+1] * precip[timeix-time_offset:timeix+time_offset+1,latix-space_offset:latix+space_offset+1,lonix-space_offset:lonix+space_offset+1]

  if debug:
    print('---------------------------------')
    print(modeltime,'    ',obstime)
    #print(obslat,'    ',obslon)
    #print(latix,'    ',lonix,'    ',timeix)
    #print(lats[latix],'  ',lons[lonix],'   ',modeltimes[timeix])
    #print('---------------------------------')
    print(proxy)

  # If any proxy > 0, means our criteria has matched a storm event tornado + environmental conditions for tornado
  # If no proxy cells > 0, means tornado there in record, but no environmental proxy found close enough in space and/or time
  if (proxy.any() > 0.):
    if debug:
      print("     TRUE")
    tor_hit += 1
    if (tor_fscale[ii] == "F1" or tor_fscale[ii] == "EF1"):
      f_hit[0] += 1
    elif (tor_fscale[ii] == "F2" or tor_fscale[ii] == "EF2"):
      f_hit[1] += 1
    elif (tor_fscale[ii] == "F3" or tor_fscale[ii] == "EF3"):
      f_hit[2] += 1
    elif (tor_fscale[ii] == "F4" or tor_fscale[ii] == "EF4"):
      f_hit[3] += 1
    elif (tor_fscale[ii] == "F5" or tor_fscale[ii] == "EF5"):
      f_hit[4] += 1
  else:
    if debug:
      print("     FALSE")
    tor_miss += 1
    if (tor_fscale[ii] == "F1" or tor_fscale[ii] == "EF1"):
      f_miss[0] += 1
    elif (tor_fscale[ii] == "F2" or tor_fscale[ii] == "EF2"):
      f_miss[1] += 1
    elif (tor_fscale[ii] == "F3" or tor_fscale[ii] == "EF3"):
      f_miss[2] += 1
    elif (tor_fscale[ii] == "F4" or tor_fscale[ii] == "EF4"):
      f_miss[3] += 1
    elif (tor_fscale[ii] == "F5" or tor_fscale[ii] == "EF5"):
      f_miss[4] += 1

print(f_hit)
print(f_miss)
print "Number of >EF1 tornados found by algorithm: %d" % tor_hit
print "Number of >EF1 tornados missed by algorithm: %d" % tor_miss

## Now we look to see if cells flagged as severe in gridded data have nearby storm report
cell_hit=0
cell_fa=0
tot_cells=0
for ii, zz in enumerate(range(ntimes-1)):
  modeltime=modeltimes[ii]
  timeearly=modeltime + timedelta(hours=6)
  timelate=modeltime - timedelta(hours=6)
  # Get datetime of severe weather reports
  theseobs=pd.to_datetime(sev_obstimes)
  # Find any obs times that match the window of this time
  matchingobstimes=theseobs[(theseobs <= timeearly) & (theseobs >= timelate)].tolist()
  if debug:
    print(modeltime)
    print("------")

  for jj, yy in enumerate(range(nlats-1)):
    for kk, xx in enumerate(range(nlons-1)):
      proxyCell=severe[ii,jj,kk]*precip[ii,jj,kk]
      if (proxyCell > 0.):
        tot_cells += 1
        # Assume false alarm for now
        cell_fa += 1
        # If there are no matchingobstimes, no reason to do anything...
        if matchingobstimes:
          found_match=False  # Initialize match found
          modellat=lats[jj]
          modellon=lons[kk]
          for possible in matchingobstimes:
            if not found_match:
              arrix=find(theseobs,possible)
              for storms in arrix:
                obslat=sev_obslats[storms]
                obslon=sev_obslons[storms]
                dist=greatCircleDist(modellon, modellat, obslon, obslat)
                if dist < dist_thresh_km:
                  found_match=True   # Found a match at this time
                  cell_hit += 1      # Add one to the hit column
                  cell_fa -= 1       # Undo the false alarm assumption
                  break              # Break out of "for storms" loop, found_match breaks "for possible", sends us back to for kk,xx loop

print "Number of severe cells with a severe weather report within %d km: %d" % (dist_thresh_km , cell_hit)
print "Number of severe cells with no report within %d km: %d" % (dist_thresh_km , cell_fa)

if (cell_hit + cell_fa) != tot_cells:
  print "uh oh! hit FA does NOT equal tot_cells!"
  print "hit: %d    fa: %d    tot_cells: %d" % (cell_hit , cell_fa, tot_cells)

# Print how long script took
print datetime.now() - scriptStartTime

