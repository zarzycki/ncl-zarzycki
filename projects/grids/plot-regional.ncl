;================================================;
;  Popgrid_1.ncl
;================================================;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   
; ================================================;
begin


    sfile        = addfile("uwnd.10m.mon.ltm.nc","r")    
    lat2d        = sfile->lat             ; (gridx_221, gridy_221) => (277,349)
    lon2d        = sfile->lon           

    var          = sfile->uwnd
    dimvar       = dimsizes(var)
    nlat         = dimvar(1)
    mlon         = dimvar(2)
print(nlat)
print(mlon)

stride=5
maxLat=toint(stride*floor(nlat/stride))
maxLon=toint(stride*floor(mlon/stride))
print(maxLat)

;LLcorner_lat=lat2d(0,0)
;ULcorner_lat=lat2d(maxLat,0)
;LRcorner_lat=lat2d(0,maxLon)
;URcorner_lat=lat2d(maxLat,maxLon)
;LLcorner_lon=lon2d(0,0)
;ULcorner_lon=lon2d(maxLat,0)
;LRcorner_lon=lon2d(0,maxLon)
;URcorner_lon=lon2d(maxLat,maxLon)


;********************************************
;   Draw map background
;********************************************

   wks = gsn_open_wks("pdf", "regional-grid")       ; open workstation
   gsn_define_colormap(wks,"default")
   res            = True                          ; map resources
  ;res@gsnDraw    = False                         ; don't draw
   res@gsnFrame   = False                         ; don't advance frame
res@mpProjection      = "Orthographic"
res@mpCenterLatF      =  50.
res@mpCenterLonF      =  253.

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
   pres                  = True                   ; polyline resources
   pres@gsLineThicknessF = 2.0                    ; line thickness
   pres@tfPolyDrawOrder  = "PostDraw"

   map = gsn_csm_map(wks,res)                     ; create map
 
;********************************************
; draw outline of the NARR grid
;********************************************
   pres@gsLineColor = "black"

do i = 0,maxLon,stride
   gsn_polyline(wks,map,lon2d(0:maxLat-1,   i     ),lat2d(0:maxLat-1,    i    ),pres)   ; leftmost grid boundary
end do
do i = 0,maxLat,stride
   gsn_polyline(wks,map,lon2d(i,   0:maxLon-1     ),lat2d(i,   0:maxLon-1    ),pres)   ; leftmost grid boundary
end do


   frame(wks)  

end

