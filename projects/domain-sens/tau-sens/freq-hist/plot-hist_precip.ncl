;================================================;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
; ================================================;
begin
;=================================================;
; open file and read in data
;=================================================;

out_format = "pdf"
var="OMEGA500_MASKI"

namesuff="def"
gridlist = (/"tau3600_"+var,"dtime900_"+var,"dtime1800_"+var/)
configs_pretty=(/"dt~B~1800~N~","dt~B~900~N~","dt~B~450~N~"/)

;namesuff="sens"
;gridlist = (/"tau3600_"+var,"tau900_"+var,"tau3600_lowdmpdz2_"+var/)
;configs_pretty=(/"dt~B~450","tau~B~900~N~","dt~B~450~N~,lowdmpdz~N~"/)

if (var .eq. "OMEGA500_MASKI")
  xmin = (/-14.0/)
  xmax = (/0.0/)          ; x axis maximums
  ymin = (/2e-6/)                ; y minimum (both panels)
  ymax = (/2e0/)                ; y maximum (both panels)
  var_units="Pa s~S~-1~N~"
  panel_frac="c."
  panel_corner="TopLeft"  ; TopLeft, TopRight
  plot_leg=False
end if
if (var .eq. "PRECL_MASKI")
  xmin = (/0./)
  xmax = (/1000./)          ; x axis maximums
  ymin = (/2e-6/)                ; y minimum (both panels)
  ymax = (/2e0/)                ; y maximum (both panels)
  var_units="mm day~S~-1~N~"
  panel_frac="b."
  panel_corner="TopRight"  ; TopLeft, TopRight
  plot_leg=False
end if
if (var .eq. "PRECC_MASKI")
  xmin = (/0./)
  xmax = (/1000./)          ; x axis maximums
  ymin = (/2e-6/)                ; y minimum (both panels)
  ymax = (/2e0/)                ; y maximum (both panels)
  var_units="mm day~S~-1~N~"
  panel_frac="a."
  panel_corner="TopRight"  ; TopLeft, TopRight
  plot_leg=True
end if

titles = (/" "," "/)           ; titles
axis_labels = (/"fraction"," "/)               ; y axis labels
colorAll = (/"red3","blue3","green4","pink2","skyblue2","darkseagreen2"/)      ; line colors




nfiles = dimsizes(gridlist)
dycore_labelsAll = gridlist
needs_regrid=True

panels1 = new(1,graphic)
plot = new(nfiles,graphic)

var0 = new((/nfiles,1000/),"double")
var01 = new((/nfiles,1000/),"double")
xval0 = new((/nfiles,1000/),"double")
xval01 = new((/nfiles,1000/),"double")

do file_step=0,nfiles-1  ; dycore loop
print("      File "+file_step)

gridname = gridlist(file_step)
print("Doing grid: "+gridname)

fname="OUT_"+gridname+".nc"
f1=addfile(fname,"r")

nlengths = dimsizes(f1->hvar_small)
nlengthl = dimsizes(f1->hvar_large)

var0(file_step,0:nlengths-1) = f1->hvar_small
var01(file_step,0:nlengthl-1) = f1->hvar_large
var0(file_step,0:nlengths-1) = where(var0(file_step,0:nlengths-1).le.0,var0@_FillValue,var0(file_step,0:nlengths-1))
var01(file_step,0:nlengthl-1) = where(var01(file_step,0:nlengthl-1).le.0,var01@_FillValue,var01(file_step,0:nlengthl-1))
xval0(file_step,0:nlengths-1) = f1->xval_small
xval01(file_step,0:nlengthl-1) = f1->xval_large

;if (file_step .eq. 0) then
;  var0 = f1->hvar_small
;  var01 = f1->hvar_large
;  var0 = where(var0.le.0,var0@_FillValue,var0)
;  var01 = where(var01.le.0,var01@_FillValue,var01)
;  printMinMax(var0,True)
;  print(""+var0@nUse)
;  print(""+var0(0:3))
;  xval0 = f1->xval_small
;  xval01 = f1->xval_large
;else if (file_step .eq. 1) then
;  var1 = f1->hvar_small
;  var1 = where(var1.le.0,var1@_FillValue,var1)
;  var11 = f1->hvar_large
;  var11 = where(var11.le.0,var11@_FillValue,var11)
;  printMinMax(var1,True)
;  print(""+var1@nUse)
;  print(""+var1(0:3))
;  xval1 = f1->xval_small
;  xval11 = f1->xval_large
;else if (file_step .eq. 2) then
;  var2 = f1->hvar_small
;  var2 = where(var2.le.0,var2@_FillValue,var2)
;  var21 = f1->hvar_large
;  var21 = where(var21.le.0,var21@_FillValue,var21)
;  printMinMax(var2,True)
;  print(""+var2@nUse)
;  print(""+var2(0:3))
;  xval2 = f1->xval_small
;  xval21 = f1->xval_large
;else if (file_step .eq. 3) then
;  var3 = f1->hvar_small
;  var3 = where(var3.le.0,var3@_FillValue,var3)
;  var31 = f1->hvar_large
;  var31 = where(var31.le.0,var31@_FillValue,var31)
;  printMinMax(var3,True)
;  print(""+var3@nUse)
;  print(""+var3(0:3))
;  xval3 = f1->xval_small
;  xval31 = f1->xval_large
;else if (file_step .eq. 4) then
;  var4 = f1->hvar_small
;  var4 = where(var4.le.0,var4@_FillValue,var4)
;  var41 = f1->hvar_large
;  var41 = where(var41.le.0,var41@_FillValue,var41)
;  printMinMax(var4,True)
;  print(""+var4@nUse)
;  print(""+var4(0:3))
;  xval4 = f1->xval_small
;  xval41 = f1->xval_large
;else if (file_step .eq. 5) then
;  var5 = f1->hvar_small
;  var5 = where(var5.le.0,var5@_FillValue,var5)
;  var51 = f1->hvar_large
;  var51 = where(var51.le.0,var51@_FillValue,var51)
;  printMinMax(var5,True)
;  print(""+var5@nUse)
;  print(""+var5(0:3))
;  xval5 = f1->xval_small
;  xval51 = f1->xval_large
;end if
;end if
;end if
;end if
;end if
;end if

delete([/ f1,fname,gridname /])

end do   ; dycore loop
;----------------
; Print sums to make sure they are close to 1
; We have to divide by 2 because we duplicate the array to draw left
; and right corners of boxes in histogram

print("1 bin sum of "+gridlist(0)+" is: "+(sum(var0)/2))
print("-------------")
print("10 bin sum of "+gridlist(0)+" is: "+(sum(var01)/2))

   wks  = gsn_open_wks(out_format,"histfreq_"+var+"_"+namesuff)

; First Panel ---------------------------------

  ; Truncate colors and labels arrays
  color = colorAll(0:nfiles-1)
  dycore_labels = dycore_labelsAll(0:nfiles-1)
  
  res = True
  res@tiMainString = titles(0)
  res@tiYAxisString = axis_labels(0)
  res@tiXAxisString = var_units
  res@gsnDraw = False
  res@gsnFrame = False
  res@trYLog = True
  res@trYMinF = ymin(0)
  res@trYMaxF = ymax(0)
  res@trXMinF = xmin(0)
  res@trXMaxF = xmax(0)
  ;res@xyLineThicknessF = 2.0
  res@xyMonoLineThickness = True
  res@xyLineThicknessF = 6.0

  res@gsnXYBarChart            = True              ; Create bar plot
  res@gsnXYBarChartOutlineOnly = True

do ii = 0,nfiles-1
  res@xyLineColor = color(ii)  
  plot(ii) = gsn_csm_xy(wks,xval0(ii,:),var0(ii,:),res)
end do

do ii = 1,nfiles-1
  overlay(plot(0),plot(ii))
end do

panels1(0) = plot(0)

; Attach a legend ------------------

if (plot_leg) then
  lgres                    = True
  lgres@lgLineColors       = color(::-1)    ; reverse color order in legend
  lgres@lgDashIndexes      = (/0,0,0,0,0,0/)    ; all solid lines
  lgres@lgLineThicknessF   = res@xyLineThicknessF
  lgres@lgLabelFontHeightF = .06           ; legend label font thickness
  lgres@lgLineDashSegLenF = 0.2
  lgres@lgItemType         = "Lines"        ; show lines only (default)
  lgres@vpWidthF           = 0.16          ; width of legend (NDC)
  lgres@vpHeightF          = 0.125           ; height of legend (NDC)
  lgres@lgPerimThicknessF  = 2.0            ; thicken the box perimeter
  lgres@lgLabelOffsetF = 0.1
  labels = configs_pretty(::-1)              ; reverse dycore order in legend

  legend = gsn_create_legend (wks, nfiles, labels,lgres)

getvalues legend
"lgLabelFontHeightF" : cmz_font
"lgLineDashSegLenF" : cmz_length
end getvalues 
print(cmz_font)
print(cmz_length)

  amres                  = True
  amres@amJust           = "BottomRight"    ; Use bottom right corner of box
                                            ; for determining its location.
  amres@amParallelPosF   = 0.48              ; Move legend to right -0.5 left, 0.5 right
  amres@amOrthogonalPosF = 0.48              ; Move legend vertically: -0.5 top, 0.5 bottom

  annoid = gsn_add_annotation(plot(0),legend,amres)  ; add legend to plot
end if

resP = True
resP@gsnMaximize = True

resP@gsnPanelFigureStringsFontHeightF = 0.06
resP@gsnPanelFigureStrings=panel_frac
resP@amJust           = panel_corner




gsn_panel(wks,panels1,(/1,1/),resP)

end
