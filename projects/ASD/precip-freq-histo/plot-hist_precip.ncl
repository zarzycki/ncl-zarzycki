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



out_format = "x11"

xmin = (/0.0,0.0/)             ; x axis minimums
xmax = (/25.,600./)           ; x axis maximums
ymin = (/1e-4,1e-7/)                ; y minimum (both panels)
ymax = (/1e0,1e0/)                 ; y maximum (both panels)
titles = (/" "," "/)           ; titles
axis_labels = (/"fraction"," "/)               ; y axis labels
colorAll = (/"red3","blue3","pink2","skyblue2","black"/)      ; line colors

gridlist = (/"conus_30_x8","ne30","mp15a-120a-US","mp120a","cmorph"/)
physpkg = "CAM6"
nfiles = dimsizes(gridlist)
dycore_labelsAll = (/"conus_30_x8","ne30","mp15a-120a-US","mp120a","cmorph"/)
needs_regrid=True

panels1 = new(2,graphic)

do file_step=0,nfiles-1  ; dycore loop
print("      File "+file_step)

gridname = gridlist(file_step)
print("Doing grid: "+gridname)

fname="OUT_"+gridname+".nc"
f1=addfile(fname,"r")

if (file_step .eq. 0) then
  var0 = f1->hvar_small
  var01 = f1->hvar_large
  printMinMax(var0,True)
  xval0 = f1->xval_small
  xval01 = f1->xval_large
else if (file_step .eq. 1) then
  var1 = f1->hvar_small
  var11 = f1->hvar_large
  printMinMax(var1,True)
  xval1 = f1->xval_small
  xval11 = f1->xval_large
else if (file_step .eq. 2) then
  var2 = f1->hvar_small
  var21 = f1->hvar_large
  printMinMax(var2,True)
  xval2 = f1->xval_small
  xval21 = f1->xval_large
else if (file_step .eq. 3) then
  var3 = f1->hvar_small
  var31 = f1->hvar_large
  printMinMax(var3,True)
  xval3 = f1->xval_small
  xval31 = f1->xval_large
else if (file_step .eq. 4) then
  var4 = f1->hvar_small
  var41 = f1->hvar_large
  printMinMax(var4,True)
  xval4 = f1->xval_small
  xval41 = f1->xval_large
end if
end if
end if
end if
end if

delete([/ f1,fname,gridname /])

end do   ; dycore loop
;----------------
; Print sums to make sure they are close to 1
; We have to divide by 2 because we duplicate the array to draw left
; and right corners of boxes in histogram

print("1 bin sum of "+gridlist(0)+" is: "+(sum(var0)/2))
print("-------------")
print("10 bin sum of "+gridlist(0)+" is: "+(sum(var01)/2))

   wks  = gsn_open_wks(out_format,"precip_hist_all")

; First Panel ---------------------------------

  ; Truncate colors and labels arrays
  color = colorAll(0:nfiles-1)
  dycore_labels = dycore_labelsAll(0:nfiles-1)
  
  res = True
  res@tiMainString = titles(0)
  res@tiYAxisString = axis_labels(0)
  res@tiXAxisString = "mm day:S:-1:N:"
  res@gsnDraw = False
  res@gsnFrame = False
  res@trYLog = True
  res@trYMinF = ymin(0)
  res@trYMaxF = ymax(0)
  res@trXMinF = xmin(0)
  res@trXMaxF = xmax(0)
  ;res@xyLineThicknessF = 2.0
  res@xyMonoLineThickness = False
  res@xyLineThicknesses = (/3.0,3.0,2.0,2.0/)


  res@xyLineColor = color(0)  
  plot0 = gsn_csm_xy(wks,xval0,var0,res)

  res@xyLineColor = color(1)
  plot1 = gsn_csm_xy(wks,xval1,var1,res)

  res@xyLineColor = color(2)
  plot2 = gsn_csm_xy(wks,xval2,var2,res)

  res@xyLineColor = color(3)
  plot3 = gsn_csm_xy(wks,xval3,var3,res)

  res@xyLineColor = color(4)
  plot4 = gsn_csm_xy(wks,xval4,var4,res)

  overlay(plot0,plot1)
  overlay(plot0,plot2) 
  overlay(plot0,plot3)
  overlay(plot0,plot4)

  panels1(0) = plot0

; Attach a legend ------------------

  lgres                    = True
  lgres@lgLineColors       = color(::-1)    ; reverse color order in legend
  lgres@lgDashIndexes      = (/0,0,0,0/)    ; all solid lines
  lgres@lgLineThicknesses   = res@xyLineThicknesses
  lgres@lgLabelFontHeightF = .20            ; legend label font thickness
  lgres@lgBoxMinorExtentF  = 0.60          ; adjust legend size
  lgres@vpWidthF           = 0.13           ; width of legend (NDC)
  lgres@vpHeightF          = 0.10           ; height of legend (NDC)
  lgres@lgPerimThicknessF  = 2.0            ; thicken the box perimeter

  labels = dycore_labels(::-1)              ; reverse dycore order in legend
  legend = gsn_create_legend (wks, nfiles, labels,lgres)

  amres                  = True
  amres@amJust           = "BottomRight"    ; Use bottom right corner of box
                                            ; for determining its location.
  amres@amParallelPosF   = 0.5              ; Move legend to right
  amres@amOrthogonalPosF = -0.334              ; Move legend down.

  annoid = gsn_add_annotation(plot0,legend,amres)  ; add legend to plot

; Second Panel ---------------------------------

  res@tiMainString = titles(1)
  res@tiYAxisString = axis_labels(1)
  res@trXMinF = xmin(1)
  res@trXMaxF = xmax(1)
  res@trYMinF = ymin(1)
  res@trYMaxF = ymax(1)

  res@xyLineColor = color(0)
  plot0 = gsn_csm_xy(wks,xval01,var01,res)

  res@xyLineColor = color(1)
  plot1 = gsn_csm_xy(wks,xval11,var11,res)

  res@xyLineColor = color(2)
  plot2 = gsn_csm_xy(wks,xval21,var21,res)

  res@xyLineColor = color(3)
  plot3 = gsn_csm_xy(wks,xval31,var31,res)

  res@xyLineColor = color(4)
  plot4 = gsn_csm_xy(wks,xval41,var41,res)

  overlay(plot0,plot1)
  overlay(plot0,plot2)
  overlay(plot0,plot3)
  overlay(plot0,plot4)

  panels1(1) = plot0

; Attach a legend ------------------

  legend = gsn_create_legend (wks, nfiles, labels,lgres)

  annoid = gsn_add_annotation(plot0,legend,amres)  ; add legend to plot


;-------------------------


  resP = True
  resP@gsnMaximize = True
  resP@gsnPanelXF = (/-1,0.59/)
  gsn_panel(wks,panels1,(/1,2/),resP)

  end
