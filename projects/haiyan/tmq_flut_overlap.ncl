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

begin


f1 = addfile("/home/zarzycki/tcforecast_60_x4_2/run/2012082200/tcforecast_60_x4_2.cam.h1.2012-08-28-00000.nc","r")
wgt_file = "/home/zarzycki/ncl/maps/map_tcforecast_60_x4_TO_0.25x0.25_patc.nc"

flut_se = f1->FLUT(0,:)
tmq_se  = f1->TMQ(0,:)

Opt         = True
flut  = ESMF_regrid_with_weights(flut_se,wgt_file,Opt)
tmq   = ESMF_regrid_with_weights(tmq_se,wgt_file,Opt)

print("Begin interp")
guess     = 1                ; use zonal means
is_cyclic = True             ; cyclic [global]
nscan     = 500             ; usually much less than this
eps       = 1.e-2            ; variable dependent
relc      = 0.5              ; relaxation coefficient
opt       = 0                ; not used

poisson_grid_fill( flut, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( tmq , is_cyclic, guess, nscan, eps, relc, opt)

flut = where(flut.ge.245,flut@_FillValue,flut)

wks   = gsn_open_wks ("x11", "haiyan_flut_2013_11_08_00Z")       ; open ps file
contour = new(1,"graphic")

gsn_merge_colormaps(wks,"matlab_jet","MPL_gist_yarg") ; merge two color maps
;gsn_draw_colormap(wks)   
;exit
  
res                   = True
res@gsnDraw = False
res@gsnFrame = False

res@cnFillOn          = True              ; color plot desired
res@cnLineLabelsOn    = False             ; turn off contour lines

res@gsnAddCyclic = False

res@gsnSpreadColors     = True            ; use full range of color map

  res@gsnSpreadColorStart = 2        ; start at 2 (the default)
  res@gsnSpreadColorEnd   = 65       ; end at 16

res@gsnSpreadColors      = True              ; use full colormap
res@lbLabelStride        = 4

res@lbLabelBarOn        = False

;res@gsnRightString=""
;res@gsnLeftString=""

res@mpMaxLatF                   = 55           ; choose subregion
res@mpMinLatF                   = -30
res@mpMinLonF = -150
res@mpMaxLonF = 40

res@mpOceanFillColor       = "black"
res@mpLandFillColor        = "darkgreen"
res@mpInlandWaterFillColor = "black"

res@lbLabelStride = 4
res@lbBoxSeparatorLinesOn = False

res@cnFillMode = "RasterFill"

res@cnLinesOn = False

res@cnLevelSelectionMode = "ManualLevels"
res@cnLevelSpacingF      =  1.0
res@cnMinLevelValF       =  15.0
res@cnMaxLevelValF       =  65.0

res@gsnAddCyclic=True

theunderlay = gsn_csm_contour_map(wks,tmq,res) 

;res@cnFillMode = "AreaFill"

  res@gsnSpreadColorStart = 66        ; start at 2 (the default)
  res@gsnSpreadColorEnd   = 140 ;193 max       ; end at 16
  
res@cnLevelSelectionMode = "ManualLevels"
res@cnLevelSpacingF      =  2.0
res@cnMinLevelValF       =  140.0
res@cnMaxLevelValF       =  240.0

res@cnFillOpacityF = 0.8

theoverlay = gsn_csm_contour(wks,flut,res)  ; create the plot

overlay(theunderlay,theoverlay)

resP                     = True                ; modify the panel plot
resP@gsnPanelLabelBar    = True      
resP@lbBoxSeparatorLinesOn = False          ; add common colorbar
gsn_panel(wks,theunderlay,(/1,1/),resP)             ; now draw as one plot

end
