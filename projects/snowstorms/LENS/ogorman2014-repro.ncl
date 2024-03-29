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

output_type="x11"

configArr=(/"B20TRC5CNBDRD","BRCP85C5CNBDRD","BRCP85C5CNBDRD"/)
yearsArr=(/"1990010100Z-2005123118Z","2026010100Z-2035123118Z","2071010100Z-2080123118Z"/)
;f1990=addfile("/glade/u/home/zarzycki/scratch/LENS-snow/climo/b.e11.B20TRC5CNBDRD.f09_g16.ENS.cam.h2.PRECT_SNOW.1990010100Z-2005123118Z_AVG.nc","r")
;f2026=addfile("/glade/u/home/zarzycki/scratch/LENS-snow/climo/b.e11.BRCP85C5CNBDRD.f09_g16.ENS.cam.h2.PRECT_SNOW.2026010100Z-2035123118Z_AVG.nc","r")
;f2071=addfile("","r")

SWE=12.
do_mask=False
do_percent=True   ; do percent decrease instead of ratio aka O'Gorman
plot_regional=True ; plot NEUS, if false plot NH aka O'gorman
fileDir="/glade/u/home/zarzycki/scratch/LENS-snow/climo/"
snowVarName="PRECT_SNOW"

ncases=dimsizes(yearsArr)
do ii = 0,ncases-1
  f1=addfile(fileDir+"/b.e11."+configArr(ii)+".f09_g16.ENS.cam.h2."+snowVarName+"."+yearsArr(ii)+"_AVG.nc","r")
  SNOW=f1->$snowVarName$(0,:,:)
  SNOW = SNOW*3.402e+6  ; now inches per day
  SNOW = SNOW*365. ; now inches per year
  SNOW = SNOW*SWE  ; now inches SNOW per year
  if (ii .eq. 0)
    ndims=dimsizes(SNOW)
    nlat=ndims(0)
    nlon=ndims(1)
    ensavg=new((/ncases,nlat,nlon/),typeof(SNOW))
    ensavg!1="lat"
    ensavg!2="lon"
    ensavg&lat=SNOW&lat
    ensavg&lon=SNOW&lon
    ;delete([/nlat,nlon,ndims/])
  end if
  ensavg(ii,:,:)=SNOW
  delete([/SNOW,f1/])
end do



;SNOW1990=f1990->PRECT_SNOW(0,:,:)
;SNOW1990 = SNOW1990*3.402e+6  ; now inches per day
;SNOW1990 = SNOW1990*365. ; now inches per year
;SNOW1990 = SNOW1990*SWE  ; now inches SNOW1990 per year;

;SNOW2026=f2026->PRECT_SNOW(0,:,:)
;SNOW2026 = SNOW2026*3.402e+6  ; now inches per day
;SNOW2026 = SNOW2026*365. ; now inches per year
;SNOW2026 = SNOW2026*SWE  ; now inches SNOW2026 per year

;SNOW2071=f2071->PRECT_SNOW(0,:,:)
;SNOW2071 = SNOW2071*3.402e+6  ; now inches per day
;SNOW2071 = SNOW2071*365. ; now inches per year
;SNOW2071 = SNOW2071*SWE  ; now inches SNOW2071 per year

;SNOW2071DIFF=SNOW2071
;SNOW2071DIFF=SNOW2071-SNOW1990
;SNOW2026DIFF=SNOW2026
;SNOW2026DIFF=SNOW2026-SNOW1990

if (do_mask) then
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

end if

ensavg(0,:,:)=where(ensavg(0,:,:).le.2.0,ensavg@_FillValue,ensavg(0,:,:))

if (do_percent) then
  SNOW2071DIFF=ensavg(2,:,:)
  SNOW2071DIFF=100.*(ensavg(0,:,:) - ensavg(2,:,:)) / ensavg(0,:,:)
  SNOW2026DIFF=ensavg(1,:,:)
  SNOW2026DIFF=100.*(ensavg(0,:,:) - ensavg(1,:,:)) / ensavg(0,:,:)
else
  SNOW2071DIFF=ensavg(2,:,:)
  SNOW2071DIFF=ensavg(2,:,:)/ensavg(0,:,:)
  SNOW2026DIFF=ensavg(1,:,:)
  SNOW2026DIFF=ensavg(1,:,:)/ensavg(0,:,:)
end if

wks = gsn_open_wks(output_type,"./pdf/ogorman14_repro")               ; open workstation
nplots=2
map = new(nplots,"graphic")

res                     = True         ; plot modifications desired
res@gsnDraw=False
res@gsnFrame=False
res@cnFillOn            = True         ; Turn on contour fill
res@cnLinesOn           = True        ; Turn off contour lines
res@cnLineLabelsOn      = False        ; Turn off contour line labels
res@lbLabelAutoStride   = True         ; Clean up labelbar labels.

;res@mpOceanFillColor = "White"
;res@cnFillDrawOrder             = "PreDraw"
;res@cnLineDrawOrder             = "PreDraw"
;res@mpFillAreaSpecifiers        = (/"Land"/)
;res@mpSpecifiedFillColors       = (/"transparent"/)
;res@mpOutlineDrawOrder = "Draw"


;res@cnFillMode          = "RasterFill"
res@gsnAddCyclic = False

if (plot_regional) then
res@mpMinLatF             = 30.
res@mpMaxLatF             = 50.
res@mpMinLonF             = 280.
res@mpMaxLonF             = 300.
else
res@mpMinLatF             = 10.
res@mpMaxLatF             = 90.
res@mpMinLonF             = 0.
res@mpMaxLonF             = 360.
end if
;res@mpCenterLonF = 286.

res@lbLabelBarOn        = False           ; turn off individual cb's


res@mpOutlineOn                 = True

res@mpUSStateLineThicknessF     = 2.5  ; 2-1/2 times as thick.
res@mpGeophysicalLineThicknessF = 2.5

res@gsnStringFontHeightF=0.012

resdiff=res

cmap = read_colormap_file("cosam12")
resdiff@cnFillPalette = cmap
resdiff@cnSpanFillPalette = True
delete(cmap)
resdiff@cnLevelSelectionMode = "ManualLevels"
if (do_percent) then
resdiff@cnLevelSpacingF      =  10.
resdiff@cnMinLevelValF       =  0.
resdiff@cnMaxLevelValF       =  100.
else
resdiff@cnLevelSpacingF      =  0.2
resdiff@cnMinLevelValF       =  0.3
resdiff@cnMaxLevelValF       =  1.5
end if

resdiff@gsnRightString="in. snow/yr"

resdiff@gsnLeftString="Ratio of mean snowfall: 2026-2035"
map(0) = gsn_csm_contour_map_ce(wks,SNOW2026DIFF,resdiff)
resdiff@gsnLeftString="Ratio of mean snowfall: 2071-2080"
map(1) = gsn_csm_contour_map_ce(wks,SNOW2071DIFF,resdiff)


if (do_mask) then
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
end if
;************************************************
; create panel
;************************************************
  pres                  = True
  pres@gsnPanelLabelBar = True
  pres@pmLabelBarWidthF = 0.8
  pres@lbLabelStride = 1

;---figure string resources
  pres@gsnPanelFigureStringsPerimOn     = True
  pres@gsnPanelFigureStringsFontHeightF = 0.018
  pres@amJust                           = "TopLeft"

;---Main title, only on first set of plots
  ;pres@txString = "LENS ensemble mean annual snowfall"

  fig_strs = (/"a","b"/) + "."

  pres@lbLabelFontHeightF = 0.012

  pres@gsnDraw                          = True
  pres@gsnPanelFigureStrings = fig_strs
  gsn_panel(wks,map,(/2,1/),pres)

end


