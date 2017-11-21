;*************************************************
; NCL Graphics: polar_1.ncl
;
; Concepts illustrated:
;   - Drawing black-and-white contours over a polar stereographic map
;   - Drawing the northern hemisphere of a polar stereographic map
;
;************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl" 
;************************************************
begin
;************************************************
; read in netCDF file
;************************************************
  a = addfile("CFSR.h1.2007032500.nc","r")
;************************************************
; read in zonal winds
;************************************************
  var=a->PSL(0,:,:)                                ; read July zonal winds
  lat=a->lat
  lon=a->lon
;**************************************************
; calc min extrema : note already in anomaly form
;**************************************************
  locmin = local_min(var,True,100.)
  x=lon(locmin@xi)                ; get lat/lon points of minima
  y=lat(locmin@yi)

;************************************************
; create plot
;************************************************
  wks = gsn_open_wks("x11" ,"polar")              ; open a ps file
  res            = True                          ; plot mods desired
  res@gsnPolar   = "NH"                          ; specify the hemisphere

  res@cnFillOn          = True                  ; color fill
;  res@cnLevelSpacingF   = 3.                    ; interval spacing
  res@cnLinesOn         = False                 ; no contour lines
  res@gsnFrame             = False

  plot = gsn_csm_contour_map_ce(wks,var,res)    ; create the plot

;*****************************************
; plot min extrema over original data
;*****************************************
  polyres               = True          ; poly marker mods desired 
  polyres@gsMarkerIndex = 16            ; choose circle as polymarker
  polyres@gsMarkerSizeF = 5.0           ; select size to avoid streaking
  polyres@gsMarkerColor = (/"black"/)   ; choose color
  gsn_polymarker(wks,plot,x,y,polyres)  ; draw polymarkers
  frame(wks)

end
