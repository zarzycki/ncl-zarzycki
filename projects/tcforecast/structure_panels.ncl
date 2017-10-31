load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "/glade/u/home/zarzycki/ncl/functions/rainratetodbz.ncl"

begin

;maxlat = 32.5
;minlat = 17.5
;minlon = -94.5 
;maxlon = -79.5

maxlat = 34.
minlat = 21.
minlon = 291. 
maxlon = 304.

stride = 1
grid="tcforecast_60_x4"
date="2012090200"

wks = gsn_open_wks("pdf","struct_pdf/structure_"+grid+"_"+date)           ; open a ps file

;========================================================================

;/glade/u/home/zarzycki/scratch/sewx_fullforecasts/structure/uniform_60/2012_00Z/2012090200



;f1name=grid+".cam.h1.2012-08-28-00000.nc"
;f1 = addfile("/glade/u/home/zarzycki/scratch/sewx_fullforecasts/structure/"+grid+"/2012_00Z/2012082300/"+f1name,"r")

f1name=grid+".cam.h1.2012-09-06-00000.nc"
f1 = addfile("/glade/u/home/zarzycki/scratch/sewx_fullforecasts/structure/"+grid+"/2012_00Z/2012090200/"+f1name,"r")

;========================================================================

uvar = "U850"
vvar = "V850"

u_se1 = f1->$uvar$
v_se1 = f1->$vvar$
prect_se = f1->PRECT
omega_se1 = f1->OMEGA500

; Convert precipitation to dBZ
prect_se1 = rainratetodbz(prect_se,1)

if (grid .eq. "tcforecast_60_x4") then
  wgt_file1 = "/glade/u/home/zarzycki/work/maps/forecast_plot_maps/tcforecast_60_x4_to_0.125x0.125_patch.nc"
end if
if (grid .eq. "uniform_60") then
  wgt_file1 = "/glade/u/home/zarzycki/work/maps/forecast_plot_maps/uniform_60_to_0.5x0.5_patch.nc"
end if
;wgt_file2 = "/glade/u/home/zarzycki/work/maps/forecast_plot_maps/uniform_240_to_0.125x0.125_patch.nc"


print("remapping")
Opt         = True
u1  = ESMF_regrid_with_weights(u_se1,wgt_file1,Opt)
v1  = ESMF_regrid_with_weights(v_se1,wgt_file1,Opt)
prect1  = ESMF_regrid_with_weights(prect_se1,wgt_file1,Opt)
omega1  = ESMF_regrid_with_weights(omega_se1,wgt_file1,Opt)

delete(u_se1)
delete(v_se1)
delete(prect_se1)
delete(omega_se1)
;u2  = ESMF_regrid_with_weights(u_se2,wgt_file2,Opt)
;v2  = ESMF_regrid_with_weights(v_se2,wgt_file2,Opt)
;delete(u_se2)
;delete(v_se2)

print("... done remapping")

print("Begin interp")
guess     = 1                ; use zonal means
is_cyclic = True             ; cyclic [global]
nscan     = 500             ; usually much less than this
eps       = 1.e-2            ; variable dependent
relc      = 0.5              ; relaxation coefficient
opt       = 0                ; not used
poisson_grid_fill( u1, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( v1, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( prect1, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( omega1, is_cyclic, guess, nscan, eps, relc, opt)
print("... done interp.")

print("calculating wind/vort")

wind1 = u1(:,::stride,::stride)
wind1 = sqrt(u1(:,::stride,::stride)^2 + v1(:,::stride,::stride)^2)
;wind2 = u2(:,::stride,::stride)
;wind2 = sqrt(u2(:,::stride,::stride)^2 + v2(:,::stride,::stride)^2)

vort1 = uv2vrF_Wrap(u1(:,::stride,::stride),v1(:,::stride,::stride))
vort1 = vort1/1e-5
;vort2 = uv2vrF_Wrap(u2(:,::stride,::stride),v2(:,::stride,::stride))
;vort2 = vort2/1e-5

vort1@units="10~S~-5~N~ 1/s"


print("done calc wind/vort")

vortArr=new(101,"float")
do i = 0,59
  vortArr(i) = i
end do
do i = 60,90
  vortArr(i) = i*2.0
end do
do i = 91,100
  vortArr(i) = i*3.0
end do

VVpos=(/0.01,0.02,0.05,0.1,0.2,0.4,0.6,0.8,1.0,1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,6.0,7.0,8.0,9.0,10.0,12.0,15.0/)
VVsize=dimsizes(VVpos)
VVArr=new((VVsize*2)+1,"float")
VVArr=0.0
do i = 0,dimsizes(VVpos)-1
  VVArr(i)=VVpos(dimsizes(VVpos)-1-i)*-1
end do
do i = dimsizes(VVpos)+1,dimsizes(VVArr)-1
  VVArr(i)=VVpos(i-VVsize-1)
end do

print(VVArr)


numpanels=4

contour = new(numpanels,"graphic")



res                   = True
res@gsnDraw = False
res@gsnFrame = False

res@cnFillOn          = True              ; color plot desired
res@cnLineLabelsOn    = False             ; turn off contour lines

res@gsnAddCyclic = False

res@mpMaxLatF                   = maxlat           ; choose subregion
res@mpMinLatF                   = minlat
res@mpMinLonF = minlon
res@mpMaxLonF = maxlon

;res@lbLabelStride        = 4

colormaps = (/"WhViBlGrYeOrReWh","WhBlGrYeRe","rainradar","NCV_blu_red"/)


;res@gsnRightString=""
;res@gsnLeftString=""

res@gsnRightStringFontHeightF=0.026
res@gsnLeftStringFontHeightF=0.026
res@tmXBLabelFontHeightF=0.021
res@tmYLLabelFontHeightF=0.021
res@lbLabelFontHeightF=0.023
res@lbTopMarginF = .18

  res@cnLevelSelectionMode = "ExplicitLevels"    			; set explicit contour levels
  res@cnLevels    = vortArr
  res@lbBoxSeparatorLinesOn = False
  res@cnFillMode = "AreaFill"
  ;res@lbLabelStride = toint(res@cnMaxLevelValF/res@cnLevelSpacingF)
  res@cnLinesOn = False
  res@cnFillPalette = colormaps(0)  ; Assign a colormap to a contour plot
  res@gsnLeftString="850 hPa vorticity"
  ;res@gsnRightString="s-1"
  res@lbLabelStride        = 4
  contour(0) = gsn_csm_contour_map(wks,vort1(0,:,:),res)  ; create the plot
  delete(res@lbLabelStride)



  res@cnLevelSelectionMode = "ManualLevels"
  res@cnLevelSpacingF      =  3.0
  res@cnMinLevelValF       =  4.0
  res@cnMaxLevelValF       =  70.0
  res@lbLabelStride = 4
  res@lbBoxSeparatorLinesOn = False
  res@cnFillMode = "AreaFill"
  res@cnLinesOn = False
  res@cnFillPalette = colormaps(1)  ; Assign a colormap to a contour plot
  res@gsnLeftString="850 hPa wind"
  contour(1) = gsn_csm_contour_map(wks,wind1(0,:,:),res)  ; create the plot


  res@cnLevelSelectionMode = "ManualLevels"
  res@cnMinLevelValF       =  6.
  res@cnMaxLevelValF       =  50.
  res@cnLevelSpacingF      = 1.
  res@cnFillMode = "AreaFill"
  res@cnLinesOn = False
  res@cnFillPalette = colormaps(2)  ; Assign a colormap to a contour plot
  res@gsnLeftString="Radar reflectivity"
  contour(2) = gsn_csm_contour_map(wks,prect1(0,:,:),res)  ; create the plot

  res@cnLevelSelectionMode = "ExplicitLevels"    			; set explicit contour levels
  delete(res@cnLevels)
  res@cnLevels    = VVArr
  res@lbBoxSeparatorLinesOn = False
  res@cnFillMode = "AreaFill"
  res@cnLinesOn = False
  res@cnFillPalette = colormaps(3)  ; Assign a colormap to a contour plot
  res@gsnLeftString="500 hPa pressure velocity"
  contour(3) = gsn_csm_contour_map(wks,omega1(0,:,:),res)  ; create the plot




resP                     = True                ; modify the panel plot
resP@txString  = "Init: 2012090200, valid: +120h"
resP@txFontHeightF = 0.015

resP@amJust           = "TopRight"
resP@gsnPanelFigureStringsFontHeightF = 0.018
if (grid .eq. "uniform_60") then
  resP@gsnPanelFigureStrings= (/"a.","b.","c.","d."/)
end if
if (grid .eq. "tcforecast_60_x4") then
  resP@gsnPanelFigureStrings= (/"e.","f.","g.","h."/)
end if

gsn_panel(wks,contour,(/1,4/),resP)             ; now draw as one plot

end
