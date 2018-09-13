;========================================================
; This file reads in a traj file produced by the TC tracker
; and produces a lat-lon plot of trajectories color-coded by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;========================================================
begin

var="PRECBSN_FREQ_PRECT"
fileDir="/glade/scratch/zarzycki/LENS-snow/"
configArr=(/"B20TRC5CNBDRD","BRCP85C5CNBDRD","BRCP85C5CNBDRD"/)
yearsArr=(/"1990010100Z-2005123118Z","2026010100Z-2035123118Z","2071010100Z-2080123118Z"/)

out_type="x11"
out_name="spatdiff-"+var

nconfigs=dimsizes(configArr)

do ii = 0,nconfigs-1
  all_files = systemfunc("ls "+fileDir+"/b.e11."+configArr(ii)+".f09_g16.*.cam.h2."+var+"."+yearsArr(ii)+".nc") 
  fall = addfiles (all_files, "r")
  ListSetType (fall, "join")
  ensallvar=fall[:]->$var$
  tmp=dim_avg_n_Wrap(ensallvar,0)
  if (ii .eq. 0)
    ndims=dimsizes(tmp)
    nlat=ndims(0)
    nlon=ndims(1)
    ensavg=new((/nconfigs,nlat,nlon/),typeof(tmp))
    ensavg!1="lat"
    ensavg!2="lon"
    ensavg&lat=tmp&lat
    ensavg&lon=tmp&lon
    ;delete([/nlat,nlon,ndims/])
  end if
  ensavg(ii,:,:)=tmp
  delete([/tmp,ensallvar,fall,all_files/])
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

ensavgdiff = ensavg(0,:,:)

; CMZ - need to mask

wks = gsn_open_wks(out_type,out_name)               ; open workstation
nplots=6
map = new(nplots,graphic)

res                     = True         ; plot modifications desired

res@gsnDraw=False
res@gsnFrame=False

res@cnFillOn            = True         ; Turn on contour fill
res@cnLinesOn           = False        ; Turn off contour lines
res@cnLineLabelsOn      = False        ; Turn off contour line labels
res@lbLabelAutoStride   = True         ; Clean up labelbar labels.

res@lbLabelBarOn        = False           ; turn off individual cb's


cmap = read_colormap_file("precip_11lev") 
res@cnFillPalette       = cmap
res@cnLevelSelectionMode = "ManualLevels"
if (var .eq. "PRECBSN_FREQ_PRECT")
  res@cnLevelSpacingF      =  2.0
  res@cnMinLevelValF       =  2.0
  res@cnMaxLevelValF       =  24.0
else
  res@cnLevelSpacingF      =  10.0
  res@cnMinLevelValF       =  10.0
  res@cnMaxLevelValF       =  110.0
end if

;res@cnFillMode          = "RasterFill"
res@gsnAddCyclic = False

res@mpMinLatF             = 37.
res@mpMaxLatF             = 47.75
res@mpMinLonF             = 279.
res@mpMaxLonF             = 293.25
res@mpCenterLonF = 286.


res@mpOutlineOn                 = True

res@mpUSStateLineThicknessF     = 1.0  ; 2-1/2 times as thick.
res@mpGeophysicalLineThicknessF = 1.0
res@mpOutlineBoundarySets       = "GeophysicalAndUSStates"
res@mpOutlineSpecifiers         = (/"Land","Conterminous US:states"/)


res@gsnRightString="days/year"
res@gsnLeftString="Bourgoin snow freq."
res@tiMainString="Present day (1990-2005)"
map(0) = gsn_csm_contour_map_ce(wks,ensavg(0,:,:),res)
res@tiMainString="Mid-century (2026-2035)"
map(1) = gsn_csm_contour_map_ce(wks,ensavg(1,:,:),res)
res@tiMainString="End-of-century (2071-2080)"
map(2) = gsn_csm_contour_map_ce(wks,ensavg(2,:,:),res)

delete(cmap)
delete(res@cnFillPalette)
cmap = read_colormap_file("sunshine_9lev") 
res@cnFillPalette       = cmap(::-1,:)
if (var .eq. "PRECBSN_FREQ_PRECT")
  res@cnLevelSpacingF      =  1.0
  res@cnMinLevelValF       =  -6.0
  res@cnMaxLevelValF       =  0.0
else
  res@cnLevelSpacingF      =  4.0
  res@cnMinLevelValF       =  -28.0
  res@cnMaxLevelValF       =  0.0
end if

ensavgdiff = ensavg(1,:,:) - ensavg(0,:,:)
res@tiMainString="(2026-2035) - (1990-2005)"
map(4) = gsn_csm_contour_map_ce(wks,ensavgdiff(:,:),res)
ensavgdiff = ensavg(2,:,:) - ensavg(1,:,:)
res@tiMainString="(2071-2080) - (1990-2005)"
map(5) = gsn_csm_contour_map_ce(wks,ensavgdiff(:,:),res)

;;;;;;;;;
res_outline=True
res_outline@gsnDraw=False
res_outline@gsnFrame=False
res_outline@cnLevelSelectionMode = "ExplicitLevels"     ; set manual contour levels
res_outline@cnLevels    = (/ 0.95 /)      ; set levels
res_outline@cnLineLabelsOn       = False
res_outline@cnInfoLabelOn = False
res_outline@cnLineColor="black"
res_outline@cnLineThicknessF = 3.             ; doubles thickness of zero contour
plotzeroline = new(nplots,graphic)

plotzeroline(0) = gsn_csm_contour(wks,RSIOUT,res_outline)
overlay(map(0),plotzeroline(0))
plotzeroline(1) = gsn_csm_contour(wks,RSIOUT,res_outline)
overlay(map(1),plotzeroline(1))
plotzeroline(2) = gsn_csm_contour(wks,RSIOUT,res_outline)
overlay(map(2),plotzeroline(2))
plotzeroline(4) = gsn_csm_contour(wks,RSIOUT,res_outline)
overlay(map(4),plotzeroline(4))
plotzeroline(5) = gsn_csm_contour(wks,RSIOUT,res_outline)
overlay(map(5),plotzeroline(5))

;************************************************
; create panel
;************************************************
  pres                  = True
  pres@gsnMaximize      = True
  pres@gsnFrame         = False
  pres@gsnPanelLabelBar = True
  pres@pmLabelBarWidthF = 0.8
pres@lbLabelStride = 1
;
; Panel the first set of plots without drawing them, so we
; can retrieve the bounding boxes and calculate the height.
;
  pres@gsnDraw = False
;
; "gsn_panel_return" is an unadvertised function. It behaves
; the same as "gsn_panel", except it returns all the objects 
; being paneled, including the labelbar if there is one.
;
  pplots = gsn_panel_return(wks,map(0:2),(/1,3/),pres)
;
; Retrieve bounding boxes of all objects created by gsn_panel call.
;
; max(bb(:,0)) is the topmost location of all combined objects,
; and min(bb(:,1)) is the bottommost.
;
  bb     = NhlGetBB(pplots)
  height = max(bb(:,0)) - min(bb(:,1))

;---Using height value, now we can panel all sets of plots.
  pres@gsnDraw                          = True
  pres@gsnPanelTop                      = 0.9   ; leave room for title
  pres@gsnPanelBottom                   = pres@gsnPanelTop - height

;---figure string resources
  pres@gsnPanelFigureStringsPerimOn     = True
  pres@gsnPanelFigureStringsFontHeightF = 0.015
  pres@amJust                           = "TopLeft"

;---Main title, only on first set of plots
  pres@txString = "LENS ensemble mean days/year supporting snow"

  fig_strs = (/"a","b","c","X","d","e"/) + "."
  do n=0,nplots-1,3
    pres@gsnPanelFigureStrings = fig_strs(n:n+2)
    gsn_panel(wks,map(n:n+2),(/1,3/),pres)

;---Set for the next panel call.
    pres@txString = ""
    pres@gsnPanelTop    = pres@gsnPanelBottom
    pres@gsnPanelBottom = pres@gsnPanelTop-height
  end do
  frame(wks)


end
