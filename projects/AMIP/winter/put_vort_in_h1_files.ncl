;======================================================================
; ESMF_regrid_18.ncl
;======================================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

;filename = "/glade/u/home/zarzycki/scratch/h1files/atl30x4/1992/TEST/atl_30_x4_refine_nochem.cam.h1.1992-09-10-00000.nc"

debug = True

thefile = addfile(filename,"w")   ; note the "s" of addfile

vr850 = thefile->VR850
lon = thefile->lon
lat = thefile->lat

;;;;;; ===================================================================
; Regrid VR850, VR500, VR200 for Hodges tracker
latS =    -90
latN =   90
;  lonW = -180
;  lonE =    180
lonW = 0
lonE =    360

dlat =  1.875
dlon =  1.875
T63_nlat = toint((latN-latS)/dlat) + 1
T63_mlon = toint((lonE-lonW)/dlon)
T63_lat  = fspan(latS, latN, T63_nlat)
T63_lon  = fspan(lonW, lonE-dlon, T63_mlon)
T63_lat@units = "degrees_north"
T63_lon@units = "degrees_east"

dlat = 2.5
dlon = 2.5
T42_nlat = toint((latN-latS)/dlat) + 1
T42_mlon = toint((lonE-lonW)/dlon)
T42_lat  = fspan(latS, latN, T42_nlat)
T42_lon  = fspan(lonW, lonE-dlon, T42_mlon)
T42_lat@units = "degrees_north"
T42_lon@units = "degrees_east"

VR850_T42_nat  = area_hi2lores_Wrap(vr850&lon,vr850&lat,vr850,True,1,T42_lon,T42_lat,False)    
VR850_T63_nat  = area_hi2lores_Wrap(vr850&lon,vr850&lat,vr850,True,1,T63_lon,T63_lat,False)

VR850_T42 = linint2_Wrap(T42_lon,T42_lat,VR850_T42_nat,True,lon,lat,0)
VR850_T63 = linint2_Wrap(T63_lon,T63_lat,VR850_T63_nat,True,lon,lat,0)

copy_VarMeta(vr850,VR850_T42)
copy_VarMeta(vr850,VR850_T63)

thefile->VR850_T42  = VR850_T42
thefile->VR850_T63  = VR850_T63

end

