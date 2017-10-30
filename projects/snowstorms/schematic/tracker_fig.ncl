load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin
;******************************************************
;  Open a netCDF file containing the grid and data from the HOMME
;  (High-Order Multiscale Modeling Environment) model, formerly
;  called SEAM (Spectral Element Atmosphere Model).
;******************************************************


;        27321   276.427168      31.754528       1.004685e+05    2.020864e+01    1987    1       30      0
;        28141   285.792561      38.325114       9.946578e+04    3.304421e+01    1987    1       31      0
;        28966   299.943447      43.164037       9.848248e+04    2.893638e+01    1987    2       1       0
;        30314   313.815386      51.348571       9.706304e+04    1.806870e+01    1987    2       2       0
;        30580   317.726886      54.394914       9.559576e+04    2.242173e+01    1987    2       3       0

npanels=3
wks = gsn_open_wks("pdf","tracker_panel")               ; open a ps file
plot = new(npanels,graphic)                          ; create a plot array
dum = new(npanels,"graphic")
dum2 = new(npanels,"graphic")
dum3 = new(npanels,"graphic")
do z = 0,npanels-1

if (z .eq. 0) then
  filename = "/glade/scratch/zarzycki/archive/ecsnow30x0_AMIP/atm/hist/ecsnow30x0_AMIP.cam.h4.1987-01-30-00000.nc"
  minLat=31.754528
  minLon=276.427168 
  minPSL=1.004685e+05
else if (z .eq. 1) then
  filename = "/glade/scratch/zarzycki/archive/ecsnow30x0_AMIP/atm/hist/ecsnow30x0_AMIP.cam.h4.1987-01-31-00000.nc"
  minLat=38.325114
  minLon=285.792561 
  minPSL=9.946578e+04
else if (z .eq. 2)
  filename = "/glade/scratch/zarzycki/archive/ecsnow30x0_AMIP/atm/hist/ecsnow30x0_AMIP.cam.h4.1987-02-01-00000.nc"
  minLat=43.164037
  minLon=299.943447  
  minPSL=9.848248e+04
else
  print("Too many loops")
  exit
end if
end if
end if

f    = addfile(filename,"r")  
lat1d = ndtooned(f->lat)          ; Pull off lat/lon variable and
lon1d = ndtooned(f->lon)          ; convert both to 1D.
var  = f->PSL(0,:)/100.

minPSL=minPSL/100.

;******************************************************
; create plot
;******************************************************
gsn_define_colormap(wks,"WhiteBlue")   ; choose colormap

allres                     = True         ; plot modifications desired
allres@gsnDraw=False
allres@gsnFrame=False
allres@sfXArray            = lon1d        ; Required to tell NCL where to
allres@sfYArray            = lat1d        ; overlay data on globe.

res=allres
res@lbLabelBarOn = False
res@gsnSpreadColors     = True         ; Use full colormap, but start
res@cnFillOn            = True         ; Turn on contour fill
res@cnFillMode          = "AreaFill"   ; Style of fill. You can also
res@cnLinesOn           = False        ; Turn off contour lines
res@cnLineLabelsOn      = False        ; Turn off contour line labels
res@lbLabelAutoStride   = True         ; Clean up labelbar labels.

res@gsnAddCyclic = False

res@mpMinLatF             = 27.
res@mpMaxLatF             = 47.5 
res@mpMinLonF             = 271. 
res@mpMaxLonF             = 305.5 

res@mpGeophysicalLineColor = "White"
res@mpGeophysicalLineThicknessF = 2.5

res@cnLevelSelectionMode = "ManualLevels"	; manually set the contour levels with the following 3 resources
res@cnMinLevelValF  = 985.			; set the minimum contour level
res@cnMaxLevelValF  = 1025.		; set the maximum contour level
res@cnLevelSpacingF = 3.5			; set the interval between contours

res@tmXBLabelFontHeightF = 0.015
res@tmYLLabelFontHeightF = res@tmXBLabelFontHeightF

res@mpOutlineOn                 = True

; Label bar stuff
;res@lbBoxSeparatorLinesOn = False
;res@lbTitleString = "hPa"
;res@lbTitleExtentF = 0.02
;res@lbTitlePosition  = "Right"              ; title position
;res@lbTitleFontHeightF= .015                ; make title smal;;ler
;res@lbTitleDirection = "Across"             ; title direction
;res@lbTitleExtentF = 0.01

res2=allres
res2@cnLevelSelectionMode = "ExplicitLevels"     ; set manual contour levels
res2@cnLevels    = (/ minPSL+2. /)	; set levels
res2@cnLineLabelsOn       = False
res2@cnInfoLabelOn = False 
res2@cnLineThicknessF = 4.	       ; doubles thickness of zero contour
res2@sfXArray            = lon1d        ; Required to tell NCL where to
res2@sfYArray            = lat1d        ; overlay data on globe.
plot(z) = gsn_csm_contour_map_overlay(wks,var,var,res,res2)
clat = new(100,float)
clon = new(100,float)
nggcog(minLat,minLon,4.0,clat,clon)


circleres=True
circleres@gsLineColor = "black"
circleres@gsLineThicknessF = 8.0
circleres@gsLineDashPattern = 1
dum(z) = gsn_add_polyline(wks, plot(z), clon, clat, circleres)

polyres=True
polyres@gsMarkerColor="red"
polyres@gsMarkerIndex = 16 
polyres@gsMarkerSizeF = 8 
dum2(z) = gsn_add_polymarker(wks, plot(z), minLon, minLat, polyres)

tres                      = True                ; text mods desired
tres@txFontHeightF        = 0.02               ; make smaller
tres@amJust           = "TopCenter"
dum3(z) = gsn_add_text(wks,plot(z),sprintf("%4.0f",minPSL),minLon,minLat-.5,tres)

end do

  resP                     = True                ; modify the panel plot
  ;resP@txString           = "A plot with a common label bar"
  resP@gsnPanelLabelBar    = True                ; add common colorbar
  resP@lbLabelFontHeightF  = 0.012               ; make labels smaller
  resP@lbLabelStride=2
  resP@gsnPanelFigureStrings= (/"+00 hr","+24 hr","+48 hr"/)

  gsn_panel(wks,plot,(/1,npanels/),resP)             ; now draw as one plot

end
