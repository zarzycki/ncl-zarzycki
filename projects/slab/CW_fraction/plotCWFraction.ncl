;========================================================
; Reads 
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/glade/u/home/zarzycki/ncl/functions/mask_tc.ncl"
load "/glade/u/home/zarzycki/ncl/functions/surfaceWindCorrFactor.ncl"
;========================================================
begin

; load data
f1 = addfile("data_cat_traj_slab_08_4.7_900.txt.nc","r")
f2 = addfile("data_cat_traj_slab2_08_4.7_900.txt.nc","r")

avgArray1 = f1->avgArray 
windCuts1 = f1->windCuts 
windCutStrLocs1 = f1->windCutStrLocs

avgArray2 = f2->avgArray 
windCuts2 = f2->windCuts 
windCutStrLocs2 = f2->windCutStrLocs 

windCutStrs=(/"TD","TS","C1","C2","C3","C4","C5"/)

maxCat=5

centralXY1=avgArray1(3,:)
errorMax1=avgArray1(1,:)
errorMin1=avgArray1(4,:)

centralXY2=avgArray2(3,:)
errorMax2=avgArray2(1,:)
errorMin2=avgArray2(4,:)

print(centralXY1)
print(centralXY2)

wks = gsn_open_wks("pdf","frac_CW")

res               = True
res@gsnDraw       = False
res@gsnFrame      = False
res@gsnMaximize   = True

res@tiMainString  = "SSTA contribution from turb. parameterization"
res@tiYAxisString = "Fraction"
res@tiXAxisString = "Saffir-Simpson intensity"

res@xyLineThicknessF = 5.0
res@xyMarkLineMode = "MarkLines"    ; Markers *and* lines
res@xyMarker      = 16
res@xyMarkerColor      = "blue"
res@xyMarkerSizeF     = .005

res@tmXBMode          = "Explicit" 
res@tmXBValues        = windCutStrLocs1(0:maxCat)
res@tmXBLabels        = windCutStrs(0:maxCat)
res@trXMinF            = min(res@tmXBValues) - 0.5
res@trXMaxF            = max(res@tmXBValues) + 0.5

res@tmYMajorGrid=True

polyres                   = True                       ; marker resources
polyres@gsMarkerIndex     = 1                          ; index for circle
polyres@gsMarkerSizeF     = .1                        ; size
polyres@gsLineThicknessF = 7.0
polyres@gsLineColor = "black"

offset = 0.07
;=======================================================

res@xyLineColor      = "blue"
offsetMeanX = -offset

plot1 = gsn_csm_xy(wks,windCutStrLocs1(0:maxCat)+offsetMeanX,centralXY1(0:maxCat),res)

error_bar1 = new((/dimsizes(windCutStrLocs1)/),graphic)
do t=0,maxCat
  error_bar1(t) = gsn_add_polyline(wks,plot1,(/windCutStrLocs1(t)+offsetMeanX,windCutStrLocs1(t)+offsetMeanX/),(/errorMin1(t),errorMax1(t)/),polyres)
end do

;=======================================================

res@xyLineColor      = "red"
offsetMeanX = offset

plot2 = gsn_csm_xy(wks,windCutStrLocs2(0:maxCat)+offsetMeanX,centralXY2(0:maxCat),res)

error_bar2 = new((/dimsizes(windCutStrLocs2)/),graphic)
do t=0,maxCat
  error_bar2(t) = gsn_add_polyline(wks,plot2,(/windCutStrLocs2(t)+offsetMeanX,windCutStrLocs2(t)+offsetMeanX/),(/errorMin2(t),errorMax2(t)/),polyres)
end do



overlay(plot1,plot2)


  lgres                    = True
  lgres@lgLineColors     = (/"red","blue"/)
  lgres@lgLineThicknessF  = polyres@gsLineThicknessF
  lgres@lgItemType         = "Lines"        ; show lines only (default)
  lgres@lgLabelFontHeightF = .15            ; set the legend label font thickness
  lgres@vpWidthF           = 0.15           ; width of legend (NDC)
  lgres@vpHeightF          = 0.1            ; height of legend (NDC)
  lgres@lgPerimColor       = "black"       ; draw the box perimeter in orange
  lgres@lgPerimThicknessF  = 2.5            ; thicken the box perimeter
  lgres@lgDashIndexes = (/0,0/)
  lbid = gsn_create_legend(wks,2,(/"SLAB2","SLAB1"/),lgres)         ; create legend

  amres = True
  amres@amParallelPosF   = 0.35		    ; move legend to the right
  amres@amOrthogonalPosF = 0.39             ; move the legend down
  annoid1 = gsn_add_annotation(plot1,lbid,amres)   ; add legend to plot


draw(plot1)
frame(wks)

end
