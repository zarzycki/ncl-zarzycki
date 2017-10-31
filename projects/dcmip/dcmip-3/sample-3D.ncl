;*************************************************
; tdpack_2.ncl
;************************************************
;
; This file is loaded by default in NCL V6.2.0 and newer
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"

begin

;x = R * cos(lat) * cos(lon)
;y = R * cos(lat) * sin(lon)
;z = R * sin(lat)

resol="r200"

w_data_file  = "/glade/p/vetssg/data/DCMIP_2016/mpas/publish/mpas.163."+resol+".L40.latlon.nonhydro.nc"
qr_data_file = "/glade/p/vetssg/data/DCMIP_2016/mpas/publish/mpas.163."+resol+".L40.latlon.nonhydro.nc"
correctLon=False
conv_qr_units=True ; do we need to conv from kg/kg to g/kg?
w_data = addfile(w_data_file,"r")
qr_data = addfile(qr_data_file,"r")
; CMZ -- still need to interpolate since 5000 falls between two levels in output
lev=w_data->Z(0:39,0,0)

minlat=0.
maxlat=30.
minlon=-30.
maxlon=10.

print(lev)   ;5000 is the 10th index


w = w_data->W((/12/),:,:,:)
qr = qr_data->QR((/12/),:,:,:)
w = lonFlip(w)
qr = lonFlip(qr)

lat=qr&lat
lon=qr&lon

lat!0="lat"
lat&lat=lat
lon!0="lon"
lon&lon=lon

latsub=lat({minlat:maxlat})
lonsub=lon({minlon:maxlon})
qrsub=qr(:,{minlat:maxlat},{minlon:maxlon})

;x=lon
;y=lat
;z=lev
qrsub_reorder = qrsub(lon|:,lat|:,lev|:)
printVarSummary(qrsub_reorder)
print(lonsub)
print(latsub)
print(lev)

latsub=latsub*.1
lonsub=lonsub*.1
lev=lev*.0001

print(qrsub_reorder)
;
; Open workstation, draw isosurface, and advance frame.
;
  wks = gsn_open_wks("x11","tdpack")  ; send graphics to PNG file
  thresh=0.0001
  tdez3d(wks,lonsub,latsub,lev,qrsub_reorder,thresh,1.8,-55.,70.,-2)
  frame(wks)
end
