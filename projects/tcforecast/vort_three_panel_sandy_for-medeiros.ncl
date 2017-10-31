; Inputs
; iniyear (1999)
; inimon (12)
; iniday (25)
; inisec (24000)
; filename

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "plot_outline_tcforecast.ncl"

begin

do_ne60=True
var="vort"
level="500"
out_type = "pdf"

maxlat = 65.     
minlat = -5
minlon = -170.
maxlon = -30.

stride = 1

;sandy
date="2012102500"


wks = gsn_open_wks(out_type,"panel_vort_pdf/"+var+"_panel_sandy")           ; open a ps file

;all_files = systemfunc ("ls /glade/scratch/zarzycki/_UNIFORM240/"+date+"/*h1*nc")
;print(all_files)
;nfiles = dimsizes(all_files)

;23 - 3 days
;31 - 4 days
;39 - 5 days
;47 - 6 days
;55 - 7 days
do z = 23,23
;do z = 0,nfiles-1

;strs = str_split(all_files(z),".")
;datestr = strs(3)
datestr="2012-10-28-00000"
;print("Doing: "+z+" of "+nfiles+"   DATE: "+datestr)
print("   ")

;========================================================================

f1name="tcforecast_60_x4.cam.h1."+datestr+".nc"
f1 = addfile("/glade/p/work/zarzycki/tcforecast_paper/vort_plots/"+f1name,"r")

f2name="uniform_240.cam.h1."+datestr+".nc"
f2 = addfile("/glade/p/work/zarzycki/tcforecast_paper/vort_plots/"+f2name,"r")

if (do_ne60) then
  f3name="uniform_60.cam.h1."+datestr+".nc"
  f3 = addfile("/glade/p/work/zarzycki/tcforecast_paper/vort_plots/"+f3name,"r")
end if
;========================================================================

uvar = "U"+level
vvar = "V"+level

u_se1 = f1->$uvar$
v_se1 = f1->$vvar$
u_se2 = f2->$uvar$
v_se2 = f2->$vvar$

if (do_ne60) then
  u_se3 = f3->$uvar$
  v_se3 = f3->$vvar$
end if

wgt_file1 = "/glade/u/home/zarzycki/work/maps/forecast_plot_maps/tcforecast_60_x4_to_0.125x0.125_patch.nc"
wgt_file2 = "/glade/u/home/zarzycki/work/maps/forecast_plot_maps/uniform_240_to_0.125x0.125_patch.nc"
wgt_file3 = "/glade/u/home/zarzycki/work/maps/forecast_plot_maps/uniform_60_to_0.5x0.5_patch.nc"

print("remapping")
Opt         = True
u1  = ESMF_regrid_with_weights(u_se1,wgt_file1,Opt)
v1  = ESMF_regrid_with_weights(v_se1,wgt_file1,Opt)
delete(u_se1)
delete(v_se1)
u2  = ESMF_regrid_with_weights(u_se2,wgt_file2,Opt)
v2  = ESMF_regrid_with_weights(v_se2,wgt_file2,Opt)
delete(u_se2)
delete(v_se2)
if (do_ne60) then
  u3  = ESMF_regrid_with_weights(u_se3,wgt_file3,Opt)
  v3  = ESMF_regrid_with_weights(v_se3,wgt_file3,Opt)
  delete(u_se3)
  delete(v_se3)
end if
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
poisson_grid_fill( u2, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( v2, is_cyclic, guess, nscan, eps, relc, opt)
if (do_ne60) then
  poisson_grid_fill( u3, is_cyclic, guess, nscan, eps, relc, opt)
  poisson_grid_fill( v3, is_cyclic, guess, nscan, eps, relc, opt)
end if
print("... done interp.")

print("calculating wind/vort")
ne60stride=1 ;unlikely to change

if (var .eq. "wind") then
  wind1 = u1(:,::stride,::stride)
  wind1 = sqrt(u1(:,::stride,::stride)^2 + v1(:,::stride,::stride)^2)
  wind2 = u2(:,::stride,::stride)
  wind2 = sqrt(u2(:,::stride,::stride)^2 + v2(:,::stride,::stride)^2)
  if (do_ne60) then
    wind3 = u3(:,::ne60stride,::ne60stride)
    wind3 = sqrt(u3(:,::ne60stride,::ne60stride)^2 + v3(:,::ne60stride,::ne60stride)^2)
  end if
end if

if (var .eq. "vort") then
  vort1 = uv2vrF_Wrap(u1(:,::stride,::stride),v1(:,::stride,::stride))
  vort1 = vort1/1e-5
  vort2 = uv2vrF_Wrap(u2(:,::stride,::stride),v2(:,::stride,::stride))
  vort2 = vort2/1e-5
  if (do_ne60) then
    vort3 = uv2vrF_Wrap(u3(:,::ne60stride,::ne60stride),v3(:,::ne60stride,::ne60stride))
    vort3 = vort3/1e-5
  end if
end if


print("done calc wind/vort")

if (do_ne60) then
  numpanels = 3
else
  numpanels = 2
end if

contour = new(numpanels,"graphic")



res                   = True
res@gsnDraw = False
res@gsnFrame = False

res@cnFillOn          = True              ; color plot desired
res@cnLineLabelsOn    = False             ; turn off contour lines

res@gsnAddCyclic = False

res@gsnSpreadColors     = True            ; use full range of color map

res@mpMaxLatF                   = maxlat           ; choose subregion
res@mpMinLatF                   = minlat
res@mpMinLonF = minlon
res@mpMaxLonF = maxlon

res@gsnSpreadColors      = True              ; use full colormap
res@lbLabelStride        = 4

  res@lbLabelBarOn        = False

if (var .eq. "vort") then
  gsn_define_colormap(wks,"BlueRed")          ; choose colormap
  res@cnLevelSelectionMode = "ManualLevels"
  res@cnMinLevelValF       =  -30.
  res@cnMaxLevelValF       =  30.
  res@cnLevelSpacingF      =  2.
  res@lbBoxSeparatorLinesOn = False
  res@cnFillMode = "RasterFill"
  res@lbLabelStride = toint(res@cnMaxLevelValF/res@cnLevelSpacingF)
  res@cnLinesOn = False
end if

if (var .eq. "wind") then
  gsn_define_colormap(wks,"WhBlGrYeRe")
  res@cnLevelSelectionMode = "ManualLevels"
  res@cnLevelSpacingF      =  2.0
  res@cnMinLevelValF       =  4.0
  res@cnMaxLevelValF       =  56.0
  res@lbLabelStride = 4
  res@lbBoxSeparatorLinesOn = False
  res@cnFillMode = "RasterFill"
  res@cnLinesOn = False
end if

res@gsnRightString=level+"hPa "+var
res@gsnLeftString=""


if (var .eq. "wind") then
  res@gsnLeftString="55km->14km (V-R CAM)"
  contour(0) = gsn_csm_contour_map(wks,wind1(0,:,:),res)  ; create the plot
  res@gsnLeftString="Uni. 14km (CAM-UNI14)"
  contour(1) = gsn_csm_contour_map(wks,wind2(0,:,:),res)  ; create the plot
  if (do_ne60) then
    res@gsnLeftString="Uni. 55km (CAM-UNI55)"
    contour(2) = gsn_csm_contour_map(wks,wind3(0,:,:),res)  ; create the plot
  end if
end if

if (var .eq. "vort") then
  res@gsnLeftString="55km->14km (V-R CAM)"
  contour(0) = gsn_csm_contour_map(wks,vort1(0,:,:),res)  ; create the plot
  contour(0) = plot_outline_fcn(wks,contour(0),"black",5.0)
  res@gsnLeftString="Uni. 14km (CAM-UNI14)"
  contour(1) = gsn_csm_contour_map(wks,vort2(0,:,:),res)  ; create the plot
  if (do_ne60) then
    res@gsnLeftString="Uni. 55km (CAM-UNI55)"
    contour(2) = gsn_csm_contour_map(wks,vort3(0,:,:),res)  ; create the plot
  end if
end if

resP                     = True                ; modify the panel plot
resP@txString            = "Init: "+date+", valid: +72h"
resP@gsnPanelLabelBar    = True      
resP@lbBoxSeparatorLinesOn = False          ; add common colorbar
resP@lbTitleString = "10~S~-5~N~ s~S~-1"
resP@lbTitleExtentF = 0.02
resP@lbTitlePosition  = "Right"              ; title position
resP@lbTitleFontHeightF= .015                ; make title smaller
resP@lbTitleDirection = "Across"             ; title direction
resP@lbTitleExtentF = 0.01

resP@amJust           = "BottomLeft"
resP@gsnPanelFigureStringsFontHeightF = 0.021
resP@gsnPanelFigureStrings= (/"a.","b.","c."/)

gsn_panel(wks,contour,(/numpanels,1/),resP)             ; now draw as one plot

delete([/u1,u2,v1,v2/])
if (do_ne60) then
  delete([/u3,v3/])
end if

if (var .eq. "wind") then
  delete([/wind1,wind2/])
  if (do_ne60) then
    delete([/wind3/])
  end if
end if

if (var .eq. "vort") then
  delete([/vort1,vort2/])
  if (do_ne60) then
    delete([/vort3/])
  end if
end if

end do

end
