;   Example script to produce plots for a WRF real-data run,
;   with the ARW coordinate dynamics option.
;   Interpolating to specified pressure levels

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "/glade/u/home/ckruse/git/ncl/kruse.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"

begin

  datadir = "/glade/scratch/ckruse/archive/ndgnotllj/atm/hist/"
  allfiles = systemfunc("ls "+datadir+"ndgnotllj.cam.h2.2010-0[567]*.nc")
  files = allfiles
  nf = dimsizes(files)
  a = addfile(files(0),"r")

  b = addfile("/glade/p/cesmdata/cseg/inputdata/atm/cam/topo/fv_0.9x1.25_nc3000_Nsw042_Nrs008_Co060_Fi001_ZR_sgh30_24km_GRNL_c170103.nc","r")
  lat = a->lat_37n
  lon = a->lon_97w
  lats = b->lat
  lons = b->lon
  lati = minind(abs(lats-lat))
  loni = minind(abs(lons-lon))
  thgt = b->PHIS(lati-2:lati+2,loni-2:loni+2)/9.81
  thgtyavg = dim_avg_n(thgt,(/0/))
  xlons = lons(loni-2:loni+2)
  re = 6371000.
  relat = re*cos(lat*3.14159/180)
  Ceq = 2*3.14159*re
  Clat = 2*3.14159*relat
  dxdlon = Ceq/360.
  dxdlonlat = Clat/360.
  dx = (xlons(1)-xlons(0))*dxdlon
  dxlat = (xlons(1)-xlons(0))*dxdlonlat
  x = ispan(0,4,1)*dxlat
  reg = regline(x,thgtyavg)

print(x + " " + thgtyavg)
print(lat)
print(reg)
print(reg*100000)
  
end
