;========================================================
; This file reads in a traj file produced by the TC tracker
; and produces a lat-lon plot of trajectories color-coded by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "/glade/u/home/zarzycki/ncl/functions/surfaceWindCorrFactor.ncl"
load "/glade/u/home/zarzycki/ncl/functions/getTrajectories.ncl"
;========================================================
begin

wcStrt     = systemfunc("date")

fileDir="/glade/u/home/zarzycki/scratch/LES-snow/storm-files/5e-9_12_12/"
config="tempest"
yearsArr=(/"1990","2026","2071"/)
ncases=dimsizes(yearsArr)

do ii = 0,ncases-1
  f1=addfile(fileDir+"/frac."+config+".LENS."+yearsArr(ii)+".ALL.nc","r")
  STORMFRAC=f1->STORMFRAC
  STORMFRAC=STORMFRAC*100.  
  if (ii .eq. 0)
    ndims=dimsizes(STORMFRAC)
    nlat=ndims(0)
    nlon=ndims(1)
    ensavg=new((/ncases,nlat,nlon/),typeof(STORMFRAC))
    ensavg!1="lat"
    ensavg!2="lon"
    ensavg&lat=STORMFRAC&lat
    ensavg&lon=STORMFRAC&lon
    ;delete([/nlat,nlon,ndims/])
  end if
  ensavg(ii,:,:)=STORMFRAC
  delete([/STORMFRAC,f1/])
end do

maskfile=addfile("/glade/u/home/zarzycki/snow-tracking/calc_RSI/NEmask.nc","r")
RSIOUT=maskfile->MASK
printVarSummary(RSIOUT)
MASKNATIVE=linint2_Wrap(RSIOUT&lon+360.,RSIOUT&lat,RSIOUT,False,ensavg&lon,ensavg&lat, 0)
ENSAVG_MASK=linint2_Wrap(ensavg&lon,ensavg&lat,ensavg,False,RSIOUT&lon+360.,RSIOUT&lat, 0)
delete(ensavg)
ENSAVG_MASK!1="lat"
ENSAVG_MASK!2="lon"
thislon=RSIOUT&lon+360.
thislon@units="degrees_east"
ENSAVG_MASK&lon=thislon

do jj = 0,2
  ENSAVG_MASK(jj,:,:)=where(RSIOUT.gt.0.5,ENSAVG_MASK(jj,:,:),ENSAVG_MASK@_FillValue)
end do
ensavg=ENSAVG_MASK





; PLOT FRAC
nplots=3

wks = gsn_open_wks("pdf","pl_seasonal_frac")               ; open workstation
map = new(nplots,"graphic")

res                     = True         ; plot modifications desired
res@gsnDraw=False
res@gsnFrame=False

res@cnFillOn            = True         ; Turn on contour fill
res@cnLinesOn           = False        ; Turn off contour lines
res@cnLineLabelsOn      = False        ; Turn off contour line labels
res@lbLabelAutoStride   = True         ; Clean up labelbar labels.

;res@mpOceanFillColor = "White"
;res@cnFillDrawOrder             = "PreDraw"
;res@cnLineDrawOrder             = "PreDraw"
;res@mpFillAreaSpecifiers        = (/"Land"/)
;res@mpSpecifiedFillColors       = (/"transparent"/)
;res@mpOutlineDrawOrder = "Draw"

res@cnFillPalette        = "BkBlAqGrYeOrReViWh200"              ; choose colormap
res@cnSpanFillPalette=True

;res@cnFillMode          = "RasterFill"
res@gsnAddCyclic = False

res@mpMinLatF             = 38.
res@mpMaxLatF             = 48.
res@mpMinLonF             = 279.
res@mpMaxLonF             = 293.
res@mpCenterLonF = 286.

res@lbLabelBarOn        = False 

res@mpOutlineOn                 = True

res@mpUSStateLineThicknessF     = 1.0  ; 2-1/2 times as thick.
res@mpGeophysicalLineThicknessF = 1.0
res@mpOutlineBoundarySets       = "GeophysicalAndUSStates"
res@mpOutlineSpecifiers         = (/"Land","Conterminous US:states"/)

res@gsnStringFontHeightF=0.027

res@cnLevelSelectionMode = "ManualLevels"	; manually set the contour levels with the following 3 resources
res@cnMinLevelValF  = 50.			; set the minimum contour level
res@cnMaxLevelValF  = 100.			; set the maximum contour level
res@cnLevelSpacingF = 5.0			; set the interval between contours

res@lbLabelStride = 2

resavg=res



resavg@gsnRightString="%"
resavg@gsnLeftString="Snow due to ETCs"
resavg@tiMainString="Present day (1990-2005)"
map(0) = gsn_csm_contour_map_ce(wks,ensavg(0,:,:),resavg)
resavg@tiMainString="Mid-century (2026-2035)"
map(1) = gsn_csm_contour_map_ce(wks,ensavg(1,:,:),resavg)
resavg@tiMainString="End-of-century (2071-2080)"
map(2) = gsn_csm_contour_map_ce(wks,ensavg(2,:,:),resavg)

res_outline=True
res_outline@gsnDraw=False
res_outline@gsnFrame=False
res_outline@cnLevelSelectionMode = "ExplicitLevels"     ; set manual contour levels
res_outline@cnLevels    = (/ 0.95 /)      ; set levels
res_outline@cnLineLabelsOn       = False
res_outline@cnInfoLabelOn = False
res_outline@cnLineColor="black"
res_outline@cnLineThicknessF = 5.             ; doubles thickness of zero contour
plotzeroline = new(nplots,graphic)

plotzeroline(0) = gsn_csm_contour(wks,RSIOUT,res_outline)
overlay(map(0),plotzeroline(0))
plotzeroline(1) = gsn_csm_contour(wks,RSIOUT,res_outline)
overlay(map(1),plotzeroline(1))
plotzeroline(2) = gsn_csm_contour(wks,RSIOUT,res_outline)
overlay(map(2),plotzeroline(2))


;************************************************
; create panel
;************************************************
pres                  = True
pres@gsnMaximize      = True
pres@gsnFrame         = False
pres@gsnPanelLabelBar = True
pres@pmLabelBarWidthF = 0.8
pres@lbLabelStride = 2

;---figure string resources
  pres@gsnPanelFigureStringsPerimOn     = True
  pres@gsnPanelFigureStringsFontHeightF = 0.015
  pres@amJust                           = "TopLeft"

fig_strs = (/"d","e","f"/) + "."

pres@gsnPanelFigureStrings = fig_strs
  
gsn_panel(wks,map,(/1,3/),pres)

frame(wks)

end
