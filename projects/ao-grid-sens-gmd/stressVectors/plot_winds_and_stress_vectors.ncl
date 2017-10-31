;========================================================
; TC_cross_and_latlon.ncl:   plots the PS, U, V, and T.
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;load "../radial_plots/radialAvg.ncl"
load "~/ncl/functions/psminsolver.ncl"
;========================================================
begin

wks = gsn_open_wks("x11","fig_compareStress")         ; open a workstation
plot = new(6,graphic)                          ; create a plot array
plotStorm = "LESLIE"

do thisfile = 0,2

if (plotStorm .eq. "LESLIE") then
  if thisfile .eq. 0 then
    f=addfile("/glade/p/work/zarzycki/atm-ocn-coupling/forecast_allconserve/tcforecast_60_x4.cam.h1.2012-09-05-00000.nc_regrid.nc","r")
    titleStr="ne240_gx1v6"
  else if thisfile .eq. 1 then
    f=addfile("/glade/p/work/zarzycki/atm-ocn-coupling/forecast_allconserve/ocn_tcforecast_60_x4.cam.h1.2012-09-05-00000.nc_regrid.nc","r")
    titleStr="ne240_ne240"
  else
    f=addfile("/glade/p/work/zarzycki/atm-ocn-coupling/forecast_allconserve/atm_tcforecast_60_x4.cam.h1.2012-09-05-00000.nc_regrid.nc","r")
    titleStr="ne240_gx1v6_reverse"
  end if
  end if
else
  if thisfile .eq. 0 then
    f=addfile("/glade/p/work/zarzycki/atm-ocn-coupling/forecast_allconserve/tcforecast_60_x4.cam.h1.2012-08-28-43200.nc_regrid.nc","r")
    titleStr="ne240_gx1v6"
  else
    f=addfile("/glade/p/work/zarzycki/atm-ocn-coupling/forecast_allconserve/ocn_tcforecast_60_x4.cam.h1.2012-08-28-43200.nc_regrid.nc","r")
    titleStr="ne240_ne240"
  end if
end if

stride=2

lat=f->lat
lon=f->lon
lev=f->lev
nlat=dimsizes(lat)
nlon=dimsizes(lon)
nlev=dimsizes(lev)

PSL=f->PSL(0,:,:)
UBOT=f->U(0,nlev-1,:,:)
VBOT=f->V(0,nlev-1,:,:)
TAUX=f->TAUX(0,:,:)
TAUY=f->TAUY(0,:,:)
PSL=f->PSL(0,:,:)
PSL = PSL/100
SHFLX = f->SHFLX(0,:,:)
LHFLX = f->LHFLX(0,:,:)
FLUX=SHFLX
FLUX=SHFLX+LHFLX

stormCent=psminsolver(lat,lon,PSL)
print(stormCent)

UBOT&lat@units="degrees_north"
UBOT&lon@units="degrees_east"
VBOT&lat@units="degrees_north"
VBOT&lon@units="degrees_east"

TAUX&lat@units="degrees_north"
TAUX&lon@units="degrees_east"
TAUY&lat@units="degrees_north"
TAUY&lon@units="degrees_east"

PSL&lat@units="degrees_north"
PSL&lon@units="degrees_east"

FLUX&lat@units="degrees_north"
FLUX&lon@units="degrees_east"

printVarSummary(UBOT)

DIV = uv2dv_cfd (UBOT,VBOT,lat,lon,2)
copy_VarMeta(UBOT,DIV)

WIND=UBOT
WIND=sqrt(UBOT^2+VBOT^2)

print(max(WIND({28:34},{295:300})))
print(min(PSL({28:34},{295:300})))

DOTPROD = UBOT
DOTPROD = UBOT*TAUX+VBOT*TAUY

searchRad=1.5
print("DOTPROD "+avg(DOTPROD( {stormCent(0)-searchRad:stormCent(0)+searchRad},{stormCent(1)-searchRad:stormCent(1)+searchRad})))
print("FLUX "+avg(FLUX({stormCent(0)-searchRad:stormCent(0)+searchRad},{stormCent(1)-searchRad:stormCent(1)+searchRad})))

;************************************************
; create plot
;************************************************

  gsn_define_colormap(wks,"gui_default")    ; choose colormap
  res                   =  True              ; plot mods desired

  res@gsnDraw = False
  res@gsnFrame = False

  ;res@mpMinLatF             = 28
  ;res@mpMaxLatF             = 34
  ;res@mpMinLonF             = 295
  ;res@mpMaxLonF             = 300


;if (thisfile .eq. 1 .or. thisfile .eq. 2) then
;  res@tmYLLabelsOn=False
;end if




if (plotStorm .eq. "LESLIE") then
  ;res@mpMinLatF             = 30.
  ;res@mpMaxLatF             = 32.
  ;res@mpMinLonF             = 296.5
  ;res@mpMaxLonF             = 298.5
  lengthOver2 = 0.7
  res@mpMinLatF             = stormCent(0)-lengthOver2
  res@mpMaxLatF             = stormCent(0)+lengthOver2
  res@mpMinLonF             = stormCent(1)-lengthOver2
  res@mpMaxLonF             = stormCent(1)+lengthOver2
else
  res@mpMinLatF             = 23.
  res@mpMaxLatF             = 25.
  res@mpMinLonF             = 272.
  res@mpMaxLonF             = 274.
end if

  ;res@pmTickMarkDisplayMode = "Always"
  res@mpFillOn              =  False          ; turn off map fill

  res@gsnAddCyclic            = False            ; regional data 
if (plotStorm .eq. "LESLIE") then
  res@vcRefMagnitudeF         = 30.0             ; define vector ref mag
else
  res@vcRefMagnitudeF         = 16.0             ; define vector ref mag
end if
  res@vcRefLengthF            = 0.05            ; define length of vec ref
  res@vcMinDistanceF          = 0.015
  res@vcLineArrowThicknessF   = 3.0 

  res@gsnRightString     = ""

  res@vcRefAnnoSide = "Bottom"
  res@vcRefAnnoParallelPosF = 1.0
  res@vcRefAnnoJust="TopRight"
  res@vcRefAnnoString1=tostring(res@vcRefMagnitudeF)
  res@vcRefAnnoString2=""
  res@vcRefAnnoFontHeightF = 0.02
  res@vcRefAnnoString1=sprintf("%4.4g", res@vcRefMagnitudeF )+" m/s"

  res@gsnLeftString     = "Sfc. wind (black), sfc. stress (red)"

  res@tiMainOn = True
  res@tiMainString    = titleStr   ; add titles

  res@gsnMajorLatSpacing = 1
  res@gsnMajorLonSpacing = 1

  plot(thisfile) = gsn_csm_vector_map(wks,UBOT(::stride,::stride),VBOT(::stride,::stride),res)


  res@gsnLeftString     = ""


if (plotStorm .eq. "LESLIE") then
  res@vcRefMagnitudeF         = 1.8            ; define vector ref mag
else
  res@vcRefMagnitudeF         = 0.8             ; define vector ref mag
end if
  res@vcRefLengthF            = 0.05            ; define length of vec ref
  res@vcMinDistanceF          = 0.015
  res@vcLineArrowColor        = "red"           ; change vector color
  res@vcLineArrowThicknessF   = 2.0 
  res@vcRefAnnoSide = "Bottom"
  res@vcRefAnnoParallelPosF = 0.0
  res@vcRefAnnoOrthogonalPosF = -0.13
  res@vcRefAnnoJust="TopLeft"
  res@vcRefAnnoString1=sprintf("%3.3g", res@vcRefMagnitudeF )+" N/m2"
  res@vcRefAnnoString2=""
  res@vcRefAnnoFontHeightF = 0.02


;  res@tmXBLabelFontHeightF=0.015
;  res@tmYLLabelFontHeightF=0.015
  plot_stress = gsn_csm_vector(wks,TAUX(::stride,::stride),TAUY(::stride,::stride),res)



  overlay(plot(thisfile),plot_stress)

  res@tiMainOn = False



  res@gsnLeftString     = "MSLP"
  res@gsnRightString     = "hPa"

   res@cnLinesOn       = False
   res@cnFillOn        = True               ; color plot desired
   res@cnLineLabelsOn  = False              ; turn off contour lines
  res@cnLevelSelectionMode =  "ManualLevels"   
  res@cnMinLevelValF       = 955. ;955 for LESLIE
  res@cnMaxLevelValF       = 1010.
  res@cnLevelSpacingF      =   4. 

  ;plot(thisfile+2) = gsn_csm_contour_map(wks,PSL,res)

if (plotStorm .eq. "LESLIE") then
  ;res@mpMinLatF             = 28.0
  ;res@mpMaxLatF             = 34.0
  ;res@mpMinLonF             = 294.5
  ;res@mpMaxLonF             = 300.5
  lengthOver2 = 3.5
  res@mpMinLatF             = stormCent(0)-lengthOver2
  res@mpMaxLatF             = stormCent(0)+lengthOver2
  res@mpMinLonF             = stormCent(1)-lengthOver2
  res@mpMaxLonF             = stormCent(1)+lengthOver2
else
  res@mpMinLatF             = 22.5
  res@mpMaxLatF             = 26.5
  res@mpMinLonF             = 271
  res@mpMaxLonF             = 275
end if

  res@gsnLeftString     = "LH + SH flx"
  res@gsnRightString     = "W/m2"

  res@cnLevelSelectionMode =  "ManualLevels"   
  res@cnMinLevelValF       = 200.
  res@cnMaxLevelValF       = 1400.
  res@cnLevelSpacingF      =   100.
  res@cnFillMode = "RasterFill"

  plot(thisfile+3) = gsn_csm_contour_map(wks,FLUX,res)

;delete([/PSL,TAUX,TAUY,lat,lon,lev,UBOT,VBOT,FLUX,LHFLX,SHFLX,res,plot_stress/])
delete([/PSL,DOTPROD,WIND,DIV,PSL,TAUX,TAUY,lat,lon,lev,UBOT,VBOT,FLUX,LHFLX,SHFLX,res/])

end do

; Modify panel plots and whatnot
resP                     = True      ; modify the panel plot
resP@amJust = "TopRight"
resP@gsnPanelFigureStrings= (/"a.","b.","c.","d.","e.","f."/)
resP@gsnPanelScalePlotIndex = 2

gsn_panel(wks,plot,(/2,3/),resP)             ; now draw as one plot

end

