;=================== Description ==================================
; This script reads in Tempeset
; tracking code and plots a track density
;==================================================================

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "../../functions/getTrajectories.ncl"
load "../../functions/trackDensity.ncl"

begin

;=================== User Settings ================================
gridsize = 8.0
out_type = "pdf"
wind_factor = 0.85

prescut = 99999.0   ; only storms with pres LOWER than this are included. set to 99999.0 for all storms

;======================= Constants ================================
ms_to_kts = 1.94384449

;=================== Get traj data ================================
thefile="/global/homes/c/czarzyck/tempest-scripts/hyperion/AEW/trajectories.txt.CHEY.VR28.NATL.WAT.CAM5.4CLM5.0.dtime900"  ; trajectory file full path
ncols = 9 ; number of columns in non-header rows of trajectory file
maxLines = -1  ; set to -1 for auto-detection
traj_data = getTrajectories(thefile,ncols,maxLines)

; load in trajectory data (need to be modified if using different tempest output
xlon  = traj_data(:,2,:)
xlat  = traj_data(:,3,:)
clat = ndtooned(xlat)
clon = ndtooned(xlon)

count1 = track_density(gridsize,-180.0,clat,clon,False)
nyrs=30.
count1=count1/nyrs

delete([/xlon,xlat,clon,clat,nyrs,traj_data,maxLines,ncols,thefile/])

;=================== Get traj data ================================
thefile="/global/homes/c/czarzyck/tempest-scripts/hyperion/AEW/trajectories.txt.CHEY.VR28.NATL.REF.CAM5.4CLM5.0.dtime900"  ; trajectory file full path
ncols = 9 ; number of columns in non-header rows of trajectory file
maxLines = -1  ; set to -1 for auto-detection
traj_data = getTrajectories(thefile,ncols,maxLines)

; load in trajectory data (need to be modified if using different tempest output
xlon  = traj_data(:,2,:)
xlat  = traj_data(:,3,:)
clat = ndtooned(xlat)
clon = ndtooned(xlon)

count2 = track_density(gridsize,-180.0,clat,clon,False)
nyrs=30.
count2=count2/nyrs

delete([/xlon,xlat,clon,clat,nyrs,traj_data,maxLines,ncols,thefile/])

;=================== Get traj data ================================
thefile="/global/homes/c/czarzyck/tempest-scripts/hyperion/AEW/trajectories.txt.CHEY.VR28.NATL.EXT.CAM5.4CLM5.0.dtime900"  ; trajectory file full path
ncols = 9 ; number of columns in non-header rows of trajectory file
maxLines = -1  ; set to -1 for auto-detection
traj_data = getTrajectories(thefile,ncols,maxLines)

; load in trajectory data (need to be modified if using different tempest output
xlon  = traj_data(:,2,:)
xlat  = traj_data(:,3,:)
clat = ndtooned(xlat)
clon = ndtooned(xlon)

count3 = track_density(gridsize,-180.0,clat,clon,False)
nyrs=30.
count3=count3/nyrs

delete([/xlon,xlat,clon,clat,nyrs,traj_data,maxLines,ncols,thefile/])


;=================== Do storm diffs ================================
count_diff1 = count1   ; just a trick to copy metadata
count_diff1 = count1-count3
count_diff2 = count2   ; just a trick to copy metadata
count_diff2 = count2-count3
count_diff3 = count3   ; just a trick to copy metadata
count_diff3 = count3-count3

;=================== change zeros to missing values ================================

;countobs = where(countobs.eq.0, countobs@_FillValue,countobs)

count1 = where(count1.eq.0, count1@_FillValue,count1)
count2 = where(count2.eq.0, count2@_FillValue,count2)
count3 = where(count3.eq.0, count3@_FillValue,count3)

count_diff1 = where(count_diff1.eq.0, count_diff1@_FillValue,count_diff1)
count_diff2 = where(count_diff2.eq.0, count_diff2@_FillValue,count_diff2)
count_diff3 = where(count_diff3.eq.0, count_diff3@_FillValue,count_diff3)


;************************************************
; create plot
;************************************************
if (prescut .lt. 1020.0) then
  plotname = "anntrackdens_aew_lt"+prescut
else
  plotname = "anntrackdens_aew_all"
end if
wks = gsn_open_wks(out_type,plotname)
plot = new(6,"graphic")

colorMap1="WhiteBlueGreenYellowRed"
colorMap2="BlueWhiteOrangeRed"

res                       = True     ; plot mods desired
res@gsnDraw = False
res@gsnFrame = False
res@gsnAddCyclic          = False    

res@cnFillOn              = True     ; turn on color fill
;res@cnFillMode            = "RasterFill"       ; Raster Mode
res@cnLinesOn             = False    ; turn of contour lines
res@cnLineLabelsOn  = False
res@lbLabelStride = 2
res@gsnCenterString       = ""

res@mpMinLatF             = 0.
res@mpMaxLatF             = 40.
res@mpMinLonF             = -100.
res@mpMaxLonF             = 60.
;res@mpCenterLonF          = 180.

; plot absolute data
res@cnLevelSelectionMode  = "ManualLevels"
; 0-120
res@cnMinLevelValF        = 0.0
res@cnMaxLevelValF        = 260.0
res@cnLevelSpacingF       = res@cnMaxLevelValF/20.
res@cnFillPalette=colorMap1
print("min: "+min(count1(:,:))+"   max: "+max(count1(:,:)))
print("min: "+min(count2(:,:))+"   max: "+max(count2(:,:)))
print("min: "+min(count3(:,:))+"   max: "+max(count3(:,:)))
plot(0) = gsn_csm_contour_map_ce(wks,count1(:,:),res)
plot(2) = gsn_csm_contour_map_ce(wks,count2(:,:),res)
plot(4) = gsn_csm_contour_map_ce(wks,count3(:,:),res)
; plot differences
res@cnLevelSelectionMode  = "ManualLevels"
; -40-40
res@cnMinLevelValF        = -60.0
res@cnMaxLevelValF        = 60.0
res@cnLevelSpacingF       = res@cnMaxLevelValF/20.
res@cnFillPalette=colorMap2

; with 1e-6
;(0)	count: min=0   max=10930
;(0)	count: sum=1.73084e+06
;(0)	min: 5   max: 369.333
;(0)	min: 5.7   max: 362.8
;(0)	min: 5.86667   max: 364.333
;(0)	min: -47.6   max: 44.9667
;(0)	min: -39   max: 33.6

print("min: "+min(count_diff1(:,:))+"   max: "+max(count_diff1(:,:)))
print("min: "+min(count_diff2(:,:))+"   max: "+max(count_diff2(:,:)))
;print("min: "+count3(:,:)+"   max: "+count3(:,:))
plot(1) = gsn_csm_contour_map_ce(wks,count_diff1(:,:),res)
plot(3) = gsn_csm_contour_map_ce(wks,count_diff2(:,:),res)
;plot(11) = gsn_csm_contour_map_ce(wks,count_diff3(:,:),res)

resP = True
if (prescut .lt. 1020.0) then
  resP@txString           = "Annual 600mb AEW track density, < "+prescut+" mb"
else
  resP@txString           = "Annual 600mb AEW track density, all storms"
end if
resP@amJust           = "TopLeft"
resP@gsnPanelFigureStringsFontHeightF = 0.014
resP@gsnPanelFigureStrings= (/"WAT","WAT-EXT","REF","REF-EXT","EXT",""/)

gsn_panel(wks,plot,(/3,2/),resP)

end
