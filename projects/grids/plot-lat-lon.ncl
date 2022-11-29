;================================================;
;  Popgrid_1.ncl
;================================================;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   
; ================================================;
begin

;f         = addfile("/glade/p/cesmdata/inputdata/atm/cam/inic/fv/cami_0000-01-01_4x5_L30_c090108.nc","r")
;f         = addfile("/glade/p/cesmdata/inputdata/atm/cam/inic/fv/chem_mam3_2000-01-01_0.9x1.25_L30_c150624.nc","r")
f         = addfile("/glade/p/cesmdata/inputdata/atm/cam/inic/fv/chem_mam3_2000-01-01_1.9x2.5_L30_c120222.nc","r")

T       = f->T(0,0,:,:)
lat     = f->lat
lon     = f->lon
nlat=dimsizes(lat)
nlon=dimsizes(lon)

lat2d=conform_dims((/nlon,nlat/),lat,1)
lon2d=conform_dims((/nlon,nlat/),lon,0)
lat2d!1="lat"
lat2d!0="lon"
lat2d&lat=lat
lat2d&lon=lon
lon2d!1="lat"
lon2d!0="lon"
lon2d&lat=lat
lon2d&lon=lon

print(lat2d(0,:))
;=================================================;
; Create plot
;=================================================;
wks  = gsn_open_wks("pdf","global-latlon-grid")             ; open a ps file

res = True
res@gsnDraw  = False       ; don't draw the plots now
res@gsnFrame = False       ; or advance the frame

res@mpProjection      = "Orthographic"
res@mpCenterLatF      =  39.
res@mpCenterLonF      =  262.

        res@vpXF      = 0.05
        res@vpYF      = 0.9
        res@vpWidthF  = 0.9
        res@vpHeightF = 0.8

res@mpOutlineOn            = True
res@mpPerimOn              = False
res@mpLandFillColor        = "tan"
res@mpOceanFillColor       = "LightBlue"
res@mpInlandWaterFillColor = "Blue"
res@mpGreatCircleLinesOn = True

plot = gsn_csm_map(wks,res)
;---Call function to draw lat/lon lines.
pres                   = True
pres@gsnCoordsAsLines  = True        ; Default is points
gsn_coordinates(wks,plot,T,pres)

end

