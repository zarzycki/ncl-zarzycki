# Analysis.
import numpy as np
import pandas as pd
import Ngl as ncl
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

###############

scriptStartTime = datetime.now()

YYYY="ALL"

if YYYY == 2006:
  csv_file = "./StormEvents_details-ftp_v1.0_d2006_c20170717.csv"
if YYYY == 2007:
  csv_file = "./StormEvents_details-ftp_v1.0_d2007_c20170717.csv"
if YYYY == 2008:
  csv_file = "./StormEvents_details-ftp_v1.0_d2008_c20170718.csv"
if YYYY == 2009:
  csv_file = "./StormEvents_details-ftp_v1.0_d2009_c20170816.csv"
else:
  csv_file = "./StormEvents_details-ftp_v1.0_dALL.csv"

raw_df = pd.read_csv(csv_file,parse_dates=["BEGIN_DATE_TIME"])

df = raw_df[[ "EVENT_TYPE","BEGIN_DATE_TIME","TOR_F_SCALE","BEGIN_LAT","BEGIN_LON","MAGNITUDE"]]

# Filter by tornados > F3
df_tor = df.loc[(df['TOR_F_SCALE'] == 'F1') | (df['TOR_F_SCALE'] == 'F2') | (df['TOR_F_SCALE'] == 'F3') | (df['TOR_F_SCALE'] == 'F4') | (df['TOR_F_SCALE'] == 'F5') | (df['TOR_F_SCALE'] == 'EF1') | (df['TOR_F_SCALE'] == 'EF2') | (df['TOR_F_SCALE'] == 'EF3') | (df['TOR_F_SCALE'] == 'EF4') | (df['TOR_F_SCALE'] == 'EF5') ]

# Filter by all severe phenomena
#df_sev = df.loc[(df['TOR_F_SCALE'] == 'F3') | (df['TOR_F_SCALE'] == 'F4') | (df['TOR_F_SCALE'] == 'F5') | (df['TOR_F_SCALE'] == 'EF3') | (df['TOR_F_SCALE'] == 'EF4') | (df['TOR_F_SCALE'] == 'EF5') ]
#df_sev = df.loc[(df['EVENT_TYPE'] == 'Tornado') | (df['EVENT_TYPE'] == 'Funnel Cloud') | ((df['EVENT_TYPE'] == 'Hail') & (df['MAGNITUDE'] >= 1.0)) | ((df['EVENT_TYPE'] == 'Thunderstorm Wind') & (df['MAGNITUDE'] >= 58)) ]
df_sev = df.loc[(df['EVENT_TYPE'] == 'Tornado') ]

# To list-ify
tor_obstimes=df_tor["BEGIN_DATE_TIME"].tolist()
tor_obslats =df_tor["BEGIN_LAT"].tolist()
tor_obslons =df_tor["BEGIN_LON"].tolist()
tor_fscale  =df_tor["TOR_F_SCALE"].tolist()
tor_numRecs =len(tor_obstimes)
sev_obstimes=df_sev["BEGIN_DATE_TIME"].tolist()
sev_obslats =df_sev["BEGIN_LAT"].tolist()
sev_obslons =df_sev["BEGIN_LON"].tolist()
sev_obstype =df_sev["EVENT_TYPE"].tolist()
sev_numRecs =len(sev_obstimes)

### NCL PLOT
wks_type = "png"
wks = ncl.open_wks(wks_type,"map2")

mpres = ncl.Resources()

mpres.nglFrame     = False         # Don't advance frame after plot is drawn.
mpres.nglDraw      = False         # Don't draw plot just yet.

mpres.mpFillOn   = True              # turn off gray continents
mpres.mpLandFillColor = "Tan"
mpres.mpOceanFillColor = "LightBlue1"
mpres.mpOutlineOn = True
mpres.mpInlandWaterFillColor = mpres.mpOceanFillColor

mpres.mpLimitMode       = "LatLon"
mpres.mpMinLatF         =  25
mpres.mpMaxLatF         =  50.
mpres.mpMinLonF         =  -125.
mpres.mpMaxLonF         =  -65.
mpres.mpGridAndLimbOn   = False

mpres.mpOutlineBoundarySets     = "geophysicalandusstates"
mpres.mpDataBaseVersion         = "mediumres"
mpres.mpDataSetName             = "Earth..2"

map = ncl.map(wks,mpres)         # Create map.

colors = [ "red" , "blue", "green3" ]
mkres = ncl.Resources()    # Marker options desired
mkres.gsMarkerIndex = 1
mkres.gsMarkerColor = "Blue"
mkres.gsMarkerSizeF = 0.002   # Make 3 times larger; default is 0.01.

dum=[]
for ii, zz in enumerate(range(sev_numRecs-1)):
  print "%d of %d" % (ii, sev_numRecs)
  lat=sev_obslats[ii]
  lon=sev_obslons[ii]
  type=sev_obstype[ii]
  if (type == "Tornado" or type == "Funnel Cloud"):
    mkres.gsMarkerColor=colors[0]
  elif (type == "Thunderstorm Wind"):
    mkres.gsMarkerColor=colors[1]
  elif (type == "Hail"):
    mkres.gsMarkerColor=colors[2]
  else:
    mkres.gsMarkerColor="black"
  dum.append(ncl.add_polymarker(wks,map,lon,lat,mkres))

ncl.draw(map)                         # Now draw the map and 
ncl.frame(wks)                        # advance the frame.

ncl.end()

# Print how long script took
print datetime.now() - scriptStartTime

