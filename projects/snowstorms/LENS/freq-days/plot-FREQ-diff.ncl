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

var="PRECBSN_FREQ"
fileDir="/glade/u/home/zarzycki/ncl/projects/snowstorms/LENS/freq-days/"
configArr=(/"B20TRC5CNBDRD","BRCP85C5CNBDRD","BRCP85C5CNBDRD"/)
yearsArr=(/"1990010100Z-2005123118Z","2026010100Z-2035123118Z","2071010100Z-2080123118Z"/)

nconfigs=dimsizes(configArr)

do ii = 0,nconfigs-1
  all_files = systemfunc("ls "+fileDir+"/b.e11."+configArr(ii)+".f09_g16.*.cam.h2."+var+"."+yearsArr(ii)+".nc") 
  fall = addfiles (all_files, "r")
  ListSetType (fall, "join")
  ensallvar=fall[:]->PTYPE
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

ensavgdiff = ensavg(0,:,:)
ensavgdiff = ensavg(2,:,:) - ensavg(0,:,:)

; CMZ - need to mask

wks = gsn_open_wks("x11","./base_"+var)               ; open workstation

res                     = True         ; plot modifications desired

res@cnFillOn            = True         ; Turn on contour fill
res@cnLinesOn           = False        ; Turn off contour lines
res@cnLineLabelsOn      = False        ; Turn off contour line labels
res@lbLabelAutoStride   = True         ; Clean up labelbar labels.

cmap = read_colormap_file("WhViBlGrYeOrRe") 
res@cnFillPalette       = cmap
res@cnLevelSelectionMode = "ManualLevels"
res@cnLevelSpacingF      =  10.0
res@cnMinLevelValF       =  0.0
res@cnMaxLevelValF       =  140.0

;res@cnFillMode          = "RasterFill"
res@gsnAddCyclic = False

res@mpMinLatF             = 30.
res@mpMaxLatF             = 50.
res@mpMinLonF             = 270.
res@mpMaxLonF             = 300.

res@mpOutlineOn                 = True

res@mpUSStateLineThicknessF     = 1  ; 2-1/2 times as thick.
res@mpGeophysicalLineThicknessF = 1

res@mpOutlineBoundarySets       = "GeophysicalAndUSStates"
res@mpOutlineSpecifiers         = (/"Land","Conterminous US:states"/)

res@tiMainString="LENS AVG SN POSS (2015-1990)"
res@gsnRightString="days/year"
res@gsnLeftString="Bourgoin scheme"

map = gsn_csm_contour_map_ce(wks,ensavg(0,:,:),res)

;wks = gsn_open_wks("x11","./diff_"+var)               ; open workstation
;
;res                     = True         ; plot modifications desired
;
;res@cnFillOn            = True         ; Turn on contour fill
;res@cnLinesOn           = False        ; Turn off contour lines
;res@cnLineLabelsOn      = False        ; Turn off contour line labels
;res@lbLabelAutoStride   = True         ; Clean up labelbar labels.
;
;cmap = read_colormap_file("temp_19lev") 
;cmap = cmap(::-1,:)
;res@cnFillPalette       = cmap
;res@cnLevelSelectionMode = "ManualLevels"
;res@cnLevelSpacingF      =  10.0
;res@cnMinLevelValF       =  -50.0
;res@cnMaxLevelValF       =  50.0
;
;;res@cnFillMode          = "RasterFill"
;res@gsnAddCyclic = False
;
;res@mpMinLatF             = 30.
;res@mpMaxLatF             = 50.
;res@mpMinLonF             = 270.
;res@mpMaxLonF             = 300.
;
;res@mpOutlineOn                 = True
;
;res@mpUSStateLineThicknessF     = 1  ; 2-1/2 times as thick.
;res@mpGeophysicalLineThicknessF = 1
;
;res@mpOutlineBoundarySets       = "GeophysicalAndUSStates"
;res@mpOutlineSpecifiers         = (/"Land","Conterminous US:states"/)
;
;res@tiMainString="LENS AVG SN POSS (2071-80 MINUS 2015-1990)"
;res@gsnRightString="days/year"
;res@gsnLeftString="Bourgoin scheme"
;
;map = gsn_csm_contour_map_ce(wks,ensavgdiff(:,:),res)


end
