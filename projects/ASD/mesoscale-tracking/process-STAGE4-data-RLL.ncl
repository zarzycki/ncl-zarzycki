load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

h4filename="/glade/u/home/zarzycki/scratch/MTD-example/obs-data/STAGE4_hh-sum-20120928_090000_51--66-24--125_remapbil.nc"

h4file=addfile(h4filename,"r")
;wgtname="/glade/p/work/zarzycki/ASD2017_files/offline-remap/map_STAGE4-4km-curv-MODE_TO_0.125x0.125reg_blin.170425.nc"
wgtname="/glade/scratch/zarzycki/map_STAGE4-4km-curv-MODE_TO_0.125x0.125reg_blin.170425.nc"

PRECTasd=h4file->APCP(:,:)
;lat2d=h4file->lat
;lon2d=h4file->lon

;tfile=addfile("/glade/u/home/zarzycki/scratch/MTD-example/data_ctr_SE/SE12_hh-sum-19870708_210000_XX--YY-ZZ--AAA_remapbil-ctr.nc","r")
;lat=tfile->lat
;lon=tfile->lon


;PRECT=rcm2rgrid_Wrap(lat2d,lon2d,PRECTasd,lat,lon,0)

Opt                = True
Opt@ForceOverwrite = True
Opt@PrintTimings   = True
PRECT=ESMF_regrid_with_weights(PRECTasd,wgtname,Opt)


;lat=PRECT&lat
;lon=PRECT&lon

;lat!0="lat"
;lon!0="lon"

;lat&lat=lat
;lon&lon=lon

;lat@units = "degrees_north"
;lat@long_name = "latitude"
;lat@standard_name = "latitude"
;lon@units = "degrees_east"
;lon@long_name = "longitude"
;lon@standard_name = "longitude"



APCP = PRECT
delete(PRECT)

APCP@name="APCP"
APCP@long_name = "Total precipitation"
APCP@level = "surf"
APCP@units = "kg/m^2"
;APCP@init_time = YYYYMMDD_HHMMSS
;APCP@init_time_ut = UNIXTIME
;APCP@valid_time = YYYYMMDD_HHMMSS
;APCP@valid_time_ut = UNIXTIME
APCP@accum_time = "10000"
APCP@accum_time_sec = 3600

;outFileName="/glade/scratch/zarzycki/MTD-example/data_ctr_SE/SE12_hh-sum-"+YYYYMMDD_HHMMSS+"_XX--YY-ZZ--AAA_remapbil-ctr.nc"
outFileName="/glade/scratch/zarzycki/test.nc"

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


;ncdf->lat=lat
;ncdf->lon=lon

ncdf->APCP=APCP




end
