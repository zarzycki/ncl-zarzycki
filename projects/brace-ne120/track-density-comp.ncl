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
gridsize = 4.0
out_type = "pdf"
wind_factor = 0.85

prescut = 920.0   ; only storms with pres LOWER than this are included. set to 99999.0 for all storms

;======================= Constants ================================
ms_to_kts = 1.94384449

;=================== Get traj data ================================
thefile="/glade/u/home/zarzycki/tempest-scripts/nan-ne120/trajectories.txt.TEST.NE120.1979_2012.ALL"  ; trajectory file full path
ncols = 10 ; number of columns in non-header rows of trajectory file
maxLines = -1  ; set to -1 for auto-detection
traj_data = getTrajectories(thefile,ncols,maxLines)

; load in trajectory data (need to be modified if using different tempest output
xlon  = traj_data(:,1,:)
xlat  = traj_data(:,2,:)
xpres = traj_data(:,3,:)/100.
xwind = traj_data(:,4,:)*wind_factor
clat = ndtooned(xlat)
clon = ndtooned(xlon)
cwind = ndtooned(xwind)
cpres = ndtooned(xpres)

clat = where(cpres.lt.prescut,clat,clat@_FillValue)
clon = where(cpres.lt.prescut,clon,clon@_FillValue)

count1 = track_density(gridsize,0.0,clat,clon,False)
nyrs=90.
count1=count1/nyrs

delete([/xlon,xlat,xpres,xwind,clon,clat,cpres,cwind,nyrs,traj_data,maxLines,ncols,thefile/])

;=================== Get traj data ================================
thefile="/glade/u/home/zarzycki/tempest-scripts/nan-ne120/trajectories.txt.TEST.NE120.RCP85_2070_2099.ALL"  ; trajectory file full path
ncols = 10 ; number of columns in non-header rows of trajectory file
maxLines = -1  ; set to -1 for auto-detection
traj_data = getTrajectories(thefile,ncols,maxLines)

; load in trajectory data (need to be modified if using different tempest output
xlon  = traj_data(:,1,:)
xlat  = traj_data(:,2,:)
xpres = traj_data(:,3,:)/100.
xwind = traj_data(:,4,:)*wind_factor
clat = ndtooned(xlat)
clon = ndtooned(xlon)
cwind = ndtooned(xwind)
cpres = ndtooned(xpres)

clat = where(cpres.lt.prescut,clat,clat@_FillValue)
clon = where(cpres.lt.prescut,clon,clon@_FillValue)

count2 = track_density(gridsize,0.0,clat,clon,False)
nyrs=90.
count2=count2/nyrs

delete([/xlon,xlat,xpres,xwind,clon,clat,cpres,cwind,nyrs,traj_data,maxLines,ncols,thefile/])


;=================== Do storm diffs ================================
count_diff1 = count1   ; just a trick to copy metadata
count_diff1 = count1-count2

;=================== change zeros to missing values ================================

;countobs = where(countobs.eq.0, countobs@_FillValue,countobs)

count1 = where(count1.eq.0, count1@_FillValue,count1)
count2 = where(count2.eq.0, count2@_FillValue,count2)

;count_diff1 = where(count_diff1.eq.0, count_diff1@_FillValue,count_diff1)


;************************************************
; create plot
;************************************************
if (prescut .lt. 1020.0) then
  plotname = "anntrackdens_lt"+prescut
else
  plotname = "anntrackdens_all"
end if
wks = gsn_open_wks(out_type,plotname)
plot = new(12,"graphic")

colorMap1="BlAqGrYeOrRe"
colorMap2="BlWhRe"

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
res@mpMaxLatF             = 60.
res@mpMinLonF             = -120.
res@mpMaxLonF             = -10.
;res@mpCenterLonF          = 180.

; plot absolute data
res@cnLevelSelectionMode  = "ManualLevels"
; 0-120
res@cnMinLevelValF        = 0.0
res@cnMaxLevelValF        = 1.0
res@cnLevelSpacingF       = res@cnMaxLevelValF/20.
res@cnFillPalette=colorMap1
print("min: "+min(count1(:,:))+"   max: "+max(count1(:,:)))
print("min: "+min(count2(:,:))+"   max: "+max(count2(:,:)))
plot(4) = gsn_csm_contour_map_ce(wks,count1(:,:),res)
plot(7) = gsn_csm_contour_map_ce(wks,count2(:,:),res)
; plot differences
res@cnLevelSelectionMode  = "ManualLevels"
; -40-40
res@cnMinLevelValF        = -0.3
res@cnMaxLevelValF        = 0.3
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
;print("min: "+count3(:,:)+"   max: "+count3(:,:))
plot(5) = gsn_csm_contour_map_ce(wks,count_diff1(:,:),res)
;plot(11) = gsn_csm_contour_map_ce(wks,count_diff3(:,:),res)

resP = True
if (prescut .lt. 1020.0) then
  resP@txString           = "Annual TC track density, < "+prescut+" mb"
else
  resP@txString           = "Annual TC track density, all storms"
end if
resP@amJust           = "TopLeft"
resP@gsnPanelFigureStringsFontHeightF = 0.014
resP@gsnPanelFigureStrings= (/"OBS","","","WAT-OBS","WAT","WAT-EXT","REF-OBS","REF","REF-EXT","EXT-OBS","EXT",""/)

gsn_panel(wks,plot,(/4,3/),resP)

end
