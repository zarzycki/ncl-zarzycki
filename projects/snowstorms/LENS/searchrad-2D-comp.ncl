;========================================================
; This file reads in a traj file produced by the TC tracker
; and produces a lat-lon plot of trajectories color-coded by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "../../../functions/getTrajectories.ncl"
;========================================================
begin

f=addfile("/glade/scratch/zarzycki/flxf06.gdas.1993031318.grb2","r")
var=f->ULWRF_P8_L8_GGA0_avg
printVarSummary(var)

wks = gsn_open_wks("pdf","2D-rad-sens-ex")          ; send graphics to PNG file

res                   = True
res@gsnDraw=False
res@gsnFrame=False

res@mpPerimOn         = False             ; turn off box around plot
res@mpFillOn          = False

res@cnFillOn          = True              ; color plot desired
res@cnFillPalette     = "gsltod"     ; set color map
res@cnLineLabelsOn    = False             ; turn off contour lines
res@cnLinesOn         = False             ; turn off contour lines

res@cnLevelSelectionMode = "ManualLevels"	; manually set the contour levels with the following 3 resources
res@cnMinLevelValF  = 120.			; set the minimum contour level
res@cnMaxLevelValF  = 270.			; set the maximum contour level
res@cnLevelSpacingF = 10.			; set the interval between contours
res@mpGeophysicalLineColor="green"
res@mpGeophysicalLineThicknessF=3.0

res@lbLabelFontHeightF  = 0.015           ; label bar font height

res@gsnLeftString="Outgoing Longwave Radiation"
res@gsnRightString="W m~S~-2~"

;res@tiMainString       = "Example of Mollweide Projection"  ; add a title
;res@tiMainFontHeightF  = .018                               ; font height

;from JRA/tempest
;        505     229     284.062897      39.032703       9.631846e+04    1993    3       14      0
minLat=39.032703
minLon=284.062897
deltaDeg=32.
res@mpMinLatF=minLat-deltaDeg
res@mpMaxLatF=minLat+deltaDeg
res@mpMinLonF=minLon-deltaDeg
res@mpMaxLonF=minLon+deltaDeg
res@mpCenterLonF = minLon

contour = gsn_csm_contour_map(wks,var,res)  ; create the plot

rads=(/5.,10.,12.,15.,20./)
colors=(/"yellow","yellow","red","yellow","yellow"/)
nrads = dimsizes(rads)

circleres=True

circleres@gsLineThicknessF = 4.0
circleres@gsLineDashPattern = 5

txres               = True                            
txres@amJust = "CenterCenter"
txres@txPerimOn             = True
txres@txBackgroundFillColor = "Yellow"
txres@txFontHeightF         = 0.012

clat = new(100,float)
clon = new(100,float)

dum = new(nrads,"graphic")
text = new(nrads,"graphic")

do ii = 0,nrads-1
  circleres@gsLineColor = colors(ii)
  txres@txBackgroundFillColor = colors(ii)
  thisRad=rads(ii)
  nggcog(minLat,minLon,thisRad,clat,clon)
  dum(ii) = gsn_add_polyline(wks, contour, clon, clat, circleres)
  label = tostring(toint(thisRad))+"~S~o~N~"
  if (colors(ii) .eq. "red") then
    text(ii) = gsn_add_text(wks,contour,label,minLon,minLat-thisRad,txres)
  else
    text(ii) = gsn_add_text(wks,contour,label,minLon,minLat+thisRad,txres)
  end if
end do

draw(contour)
frame(wks)

end


