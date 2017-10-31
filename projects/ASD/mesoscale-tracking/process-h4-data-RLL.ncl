load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

;h4filename="/glade/u/home/zarzycki/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.ne0conus30x8_t12.exp003/atm/hist/f.asd2017.cesm20b05.FAMIPC6CLM5.ne0conus30x8_t12.exp003.cam.h4.1990-06-05-00000.nc"
;h4filename="/glade/u/home/zarzycki/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.mp15a-120a-US_t12.exp004/atm/hist/f.asd2017.cesm20b05.FAMIPC6CLM5.mp15a-120a-US_t12.exp004.cam.h4.1988-06-25-00000.nc"
;h4filename="/glade/u/home/zarzycki/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.mp120a_g16.exp005/atm/hist/f.asd2017.cesm20b05.FAMIPC6CLM5.mp120a_g16.exp005.cam.h4.1988-06-25-00000.nc"

h4file=addfile(h4filename,"r")
;wgtname="/glade/p/work/zarzycki/ASD2017_files/offline-remap/map_conus30x8_TO_WRF4km-curv-MODE_blin.170410.nc"
wgtname="/glade/p/work/zarzycki/ASD2017_files/offline-remap/map_mp15a-120a-US_to_0.125x0.125reg_patch.nc"
;wgtname="/glade/p/work/zarzycki/ASD2017_files/offline-remap/map_mp120a_to_0.125x0.125reg_patch.nc"

do ii=0,(dimsizes(h4file->time)-1)

PRECTasd=h4file->PRECT(ii,:)
timeasd=h4file->time(ii)
utc_date = cd_calendar(timeasd, 0)

YYYY=sprinti("%0.4i", toint(utc_date(0,0)))
MM=sprinti("%0.2i", toint(utc_date(0,1)))
DD=sprinti("%0.2i", toint(utc_date(0,2)))
HH=sprinti("%0.2i", toint(utc_date(0,3)))

YYYYMMDD_HHMMSS=YYYY+MM+DD+"_"+HH+"0000"
print(YYYYMMDD_HHMMSS)

UNIXTIME=toint(systemfunc("date -u -d '"+MM+"/"+DD+"/"+YYYY+" "+HH+":00:00' \+%s"))
print(UNIXTIME)

PRECTasd = PRECTasd * 3600. * 1000.  ; convert from m/s to kg/m2 in one hour

Opt                = True
Opt@ForceOverwrite = True
Opt@PrintTimings   = True
PRECT=ESMF_regrid_with_weights(PRECTasd,wgtname,Opt)

;PRECT!0="lat"
;PRECT!1="lon"

lat=PRECT&lat
lon=PRECT&lon

lat!0="lat"
lon!0="lon"

lat&lat=lat
lon&lon=lon

lat@units = "degrees_north"
lat@long_name = "latitude"
lat@standard_name = "latitude"
lon@units = "degrees_east"
lon@long_name = "longitude"
lon@standard_name = "longitude"



APCP = PRECT
delete(PRECT)

APCP@name="APCP"
APCP@long_name = "Total precipitation"
APCP@level = "surf"
APCP@units = "kg/m^2"
APCP@init_time = YYYYMMDD_HHMMSS
APCP@init_time_ut = UNIXTIME
APCP@valid_time = YYYYMMDD_HHMMSS
APCP@valid_time_ut = UNIXTIME
APCP@accum_time = "10000"
APCP@accum_time_sec = 3600

outFileName="/glade/scratch/zarzycki/MTD-example/data_ctr_SE/SE12_hh-sum-"+YYYYMMDD_HHMMSS+"_XX--YY-ZZ--AAA_remapbil-ctr.nc"

;=====================================================================

;=====================================================================

system("/bin/rm -f "+outFileName)   ; remove any pre-existing file
ncdf = addfile(outFileName ,"c")  ; open output netCDF file

fAtt               = True            ; assign file attributes
fAtt@creation_date = systemfunc ("date")
fAtt@MET_version = "V5.0" ;
fAtt@MET_tool = "pcp_combine" ;
fAtt@Projection = "LatLon" ;

fAtt@lat_ll = "10.000000 degrees_north" ;
fAtt@lon_ll = "230.000000 degrees_east" ;
fAtt@delta_lat = "0.125000 degrees" ;
fAtt@delta_lon = "0.125000 degrees" ;
fAtt@Nlat = "361 grid_points" ;
fAtt@Nlon = "560 grid_points" ;


;fAtt@scale_lat_1 = "14" ;
;fAtt@scale_lat_2 = "14" ;
;fAtt@lat_pin = "18.25784538" ;
;fAtt@lon_pin = "-122.7158995" ;
;fAtt@x_pin = "0.000000" ;
;fAtt@y_pin = "0.000000" ;
;fAtt@lon_orient = "-105.000000" ;
;fAtt@d_km = "14 km" ;
;fAtt@r_km = "6371.200000 km" ;
;fAtt@nx = "1431" ;
;fAtt@ny = "1111" ;
;fAtt@scale_lat = "60.000000 degrees_north" ;
;fAtt@hemisphere = "N" ;
fileattdef( ncdf, fAtt )            ; copy file attributes

;filedimdef(ncdf,"time",-1,True) 


ncdf->lat=lat
ncdf->lon=lon

ncdf->APCP=APCP


end do


end
