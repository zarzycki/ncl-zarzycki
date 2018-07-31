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
do_genesis = False
prescut = 1000.0   ; only storms with pres LOWER than this are included. set to 99999.0 for all storms

;======================= Constants ================================
ms_to_kts = 1.94384449

;=================== Get traj data ================================
thefile="/global/homes/c/czarzyck/tempest-scripts/hyperion/trajectories.txt.CHEY.VR28.NATL.WAT.CAM5.4CLM5.0.dtime900.ALL"  ; trajectory file full path
ncols = 10 ; number of columns in non-header rows of trajectory file
maxLines = -1  ; set to -1 for auto-detection
traj_data = getTrajectories(thefile,ncols,maxLines)

; load in trajectory data (need to be modified if using different tempest output
if (do_genesis) then
  xlon  = traj_data(:,1,0)
  xlat  = traj_data(:,2,0)
  xpres  = dim_min_n((traj_data(:,3,:)/100.),1)
  xwind  = dim_max_n((traj_data(:,4,:)),1)
else
  xlon  = traj_data(:,1,:)
  xlat  = traj_data(:,2,:)
  xpres  = traj_data(:,3,:)/100.
  xwind  = traj_data(:,4,:)
end if

clat = ndtooned(xlat)
clon = ndtooned(xlon)
cpres = ndtooned(xpres)
cwind = ndtooned(xwind)

clat = where(cpres.lt.prescut,clat,clat@_FillValue)
clon = where(cpres.lt.prescut,clon,clon@_FillValue)

count1 = track_density(gridsize,0.0,clat,clon,False)
nyrs=60.
count1=count1/nyrs

delete([/xlon,xlat,xpres,xwind,clon,clat,cpres,cwind,nyrs,traj_data,maxLines,ncols,thefile/])

;=================== Get traj data ================================
thefile="/global/homes/c/czarzyck/tempest-scripts/hyperion/trajectories.txt.CHEY.VR28.NATL.REF.CAM5.4CLM5.0.dtime900.ALL"  ; trajectory file full path
ncols = 10 ; number of columns in non-header rows of trajectory file
maxLines = -1  ; set to -1 for auto-detection
traj_data = getTrajectories(thefile,ncols,maxLines)

; load in trajectory data (need to be modified if using different tempest output
if (do_genesis) then
  xlon  = traj_data(:,1,0)
  xlat  = traj_data(:,2,0)
  xpres  = dim_min_n((traj_data(:,3,:)/100.),1)
  xwind  = dim_max_n((traj_data(:,4,:)),1)
else
  xlon  = traj_data(:,1,:)
  xlat  = traj_data(:,2,:)
  xpres  = traj_data(:,3,:)/100.
  xwind  = traj_data(:,4,:)
end if

clat = ndtooned(xlat)
clon = ndtooned(xlon)
cpres = ndtooned(xpres)
cwind = ndtooned(xwind)

clat = where(cpres.lt.prescut,clat,clat@_FillValue)
clon = where(cpres.lt.prescut,clon,clon@_FillValue)

count2 = track_density(gridsize,0.0,clat,clon,False)
nyrs=60.
count2=count2/nyrs

delete([/xlon,xlat,xpres,xwind,clon,clat,cpres,cwind,nyrs,traj_data,maxLines,ncols,thefile/])

;=================== Get traj data ================================
thefile="/global/homes/c/czarzyck/tempest-scripts/hyperion/trajectories.txt.CHEY.VR28.NATL.EXT.CAM5.4CLM5.0.dtime900.ALL"  ; trajectory file full path
ncols = 10 ; number of columns in non-header rows of trajectory file
maxLines = -1  ; set to -1 for auto-detection
traj_data = getTrajectories(thefile,ncols,maxLines)

; load in trajectory data (need to be modified if using different tempest output
if (do_genesis) then
  xlon  = traj_data(:,1,0)
  xlat  = traj_data(:,2,0)
  xpres  = dim_min_n((traj_data(:,3,:)/100.),1)
  xwind  = dim_max_n((traj_data(:,4,:)),1)
else
  xlon  = traj_data(:,1,:)
  xlat  = traj_data(:,2,:)
  xpres  = traj_data(:,3,:)/100.
  xwind  = traj_data(:,4,:)
end if

clat = ndtooned(xlat)
clon = ndtooned(xlon)
cpres = ndtooned(xpres)
cwind = ndtooned(xwind)

clat = where(cpres.lt.prescut,clat,clat@_FillValue)
clon = where(cpres.lt.prescut,clon,clon@_FillValue)

count3 = track_density(gridsize,0.0,clat,clon,False)
nyrs=60.
count3=count3/nyrs

delete([/xlon,xlat,xpres,xwind,clon,clat,cpres,cwind,nyrs,traj_data,maxLines,ncols,thefile/])

;=================== Get ibtracs data ================================
ibstyr=1984
ibenyr=2014
print("Plotting iBtracks data from: "+ibstyr+" to "+ibenyr)
ibdir="/global/homes/c/czarzyck/ncl-zarzycki/files/"
ibfilename="Allstorms.ibtracs_wmo.v03r10.nc"
ibfile = addfile(ibdir+ibfilename,"r")
;=============================================================================
; Here we'll find the storm # bounds so we don't have to load full dataset
;=============================================================================
ibyear = toint(ibfile->season)
print("num storms "+dimsizes(ibyear))
print("Figuring out what storms we need to take")
ibyear = where(ibyear .lt. ibstyr,-1,ibyear)
ibyear = where(ibyear .gt. ibenyr,-1,ibyear)
; loop forwards to find first instance of valid year
do i = 0,dimsizes(ibyear)-1
  if(ibyear(i).gt.0) then
    stix = i
    break
  end if
end do
; loop backwards to find last instance of valid year
do i = dimsizes(ibyear)-1,0,1
  if(ibyear(i).gt.0) then
    enix = i
    break
  end if
end do
print("Starting index: "+stix+"     end index: "+enix)
delete(ibyear)
;=============================================================================

if (do_genesis) then
  xlat = ibfile->lat_wmo(stix:enix,0)*.01
  xlon = ibfile->lon_wmo(stix:enix,0)*.01
  xwind = dim_min_n((ibfile->wind_wmo(stix:enix,:)*.1/ms_to_kts),1)
  xpres = dim_min_n((ibfile->pres_wmo(stix:enix,:)*.1),1)
else
  xlat = ibfile->lat_wmo(stix:enix,:)*.01
  xlon = ibfile->lon_wmo(stix:enix,:)*.01
  xwind = ibfile->wind_wmo(stix:enix,:)*.1/ms_to_kts
  xpres = ibfile->pres_wmo(stix:enix,:)*.1
  xtype = toint(ibfile->nature_wmo(stix:enix,:))
end if

cwind = ndtooned(xwind)
cpres = ndtooned(xpres)
clat = ndtooned(xlat)
clon = ndtooned(xlon)

clon = where(clon.lt.0,clon+360.,clon)

if (do_genesis) then
  ; do nothing
else
  ctype = ndtooned(xtype)
  ;cwind = where(ctype.ne.2,cwind,cwind@_FillValue)
  ;cpres = where(ctype.ne.2,cpres,cpres@_FillValue)
  ;clat = where(ctype.ne.2,clat,clat@_FillValue)
  ;clon = where(ctype.ne.2,clon,clon@_FillValue)
end if

clat = where(cpres.lt.prescut,clat,clat@_FillValue)
clon = where(cpres.lt.prescut,clon,clon@_FillValue)

countobs = track_density(gridsize,0.0,clat,clon,False)
nyrs=31.
countobs=countobs/nyrs

delete([/xlon,xlat,xpres,xwind,clon,clat,cpres,cwind,nyrs/])


;=================== Do storm diffs ================================
count_diff1 = count1   ; just a trick to copy metadata
count_diff1 = count1-count3
count_diff2 = count2   ; just a trick to copy metadata
count_diff2 = count2-count3
count_diff3 = count3   ; just a trick to copy metadata
count_diff3 = count3-count3

;=================== Do storm diffs ================================
count_obsdiff1 = count1   ; just a trick to copy metadata
count_obsdiff1 = count1-countobs
count_obsdiff2 = count2   ; just a trick to copy metadata
count_obsdiff2 = count2-countobs
count_obsdiff3 = count3   ; just a trick to copy metadata
count_obsdiff3 = count3-countobs

;=================== change zeros to missing values ================================

countobs = where(countobs.eq.0, countobs@_FillValue,countobs)

count1 = where(count1.eq.0, count1@_FillValue,count1)
count2 = where(count2.eq.0, count2@_FillValue,count2)
count3 = where(count3.eq.0, count3@_FillValue,count3)

count_diff1 = where(count_diff1.eq.0, count_diff1@_FillValue,count_diff1)
count_diff2 = where(count_diff2.eq.0, count_diff2@_FillValue,count_diff2)
count_diff3 = where(count_diff3.eq.0, count_diff3@_FillValue,count_diff3)

count_obsdiff1 = where(count_obsdiff1.eq.0, count_obsdiff1@_FillValue,count_obsdiff1)
count_obsdiff2 = where(count_obsdiff2.eq.0, count_obsdiff2@_FillValue,count_obsdiff2)
count_obsdiff3 = where(count_obsdiff3.eq.0, count_obsdiff3@_FillValue,count_obsdiff3)

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

colorMap1="WhiteBlueGreenYellowRed"
colorMap2="BlueWhiteOrangeRed"

res                       = True     ; plot mods desired
res@gsnDraw = False
res@gsnFrame = False
res@gsnAddCyclic          = False    

res@cnFillOn              = True     ; turn on color fill
res@cnFillMode            = "RasterFill"       ; Raster Mode
res@cnLinesOn             = False    ; turn of contour lines
res@cnLineLabelsOn  = False
res@lbLabelStride = 2
res@gsnCenterString       = ""

res@mpMinLatF             = 5.
res@mpMaxLatF             = 55.
res@mpMinLonF             = 260.
res@mpMaxLonF             = 350.
res@mpCenterLonF          = (res@mpMinLonF + res@mpMaxLonF)/2

; plot absolute data
res@cnLevelSelectionMode  = "ManualLevels"
; 0-120
res@cnMinLevelValF        = 0.0
res@cnMaxLevelValF        = 10.
res@cnLevelSpacingF       = res@cnMaxLevelValF/20.
res@cnFillPalette=colorMap1
print("min: "+min(count1({res@mpMinLatF:res@mpMaxLatF},{res@mpMinLonF:res@mpMaxLonF}))+"   max: "+max(count1({res@mpMinLatF:res@mpMaxLatF},{res@mpMinLonF:res@mpMaxLonF})))
print("min: "+min(count2({res@mpMinLatF:res@mpMaxLatF},{res@mpMinLonF:res@mpMaxLonF}))+"   max: "+max(count2({res@mpMinLatF:res@mpMaxLatF},{res@mpMinLonF:res@mpMaxLonF})))
print("min: "+min(count3({res@mpMinLatF:res@mpMaxLatF},{res@mpMinLonF:res@mpMaxLonF}))+"   max: "+max(count3({res@mpMinLatF:res@mpMaxLatF},{res@mpMinLonF:res@mpMaxLonF})))
plot(0) = gsn_csm_contour_map_ce(wks,countobs(:,:),res)
plot(4) = gsn_csm_contour_map_ce(wks,count1(:,:),res)
plot(7) = gsn_csm_contour_map_ce(wks,count2(:,:),res)
plot(10) = gsn_csm_contour_map_ce(wks,count3(:,:),res)
; plot differences
res@cnLevelSelectionMode  = "ManualLevels"
; -40-40
res@cnMinLevelValF        = -8.
res@cnMaxLevelValF        = -res@cnMinLevelValF
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

print("min: "+min(count_diff1({res@mpMinLatF:res@mpMaxLatF},{res@mpMinLonF:res@mpMaxLonF}))+"   max: "+max(count_diff1({res@mpMinLatF:res@mpMaxLatF},{res@mpMinLonF:res@mpMaxLonF})))
print("min: "+min(count_diff2({res@mpMinLatF:res@mpMaxLatF},{res@mpMinLonF:res@mpMaxLonF}))+"   max: "+max(count_diff2({res@mpMinLatF:res@mpMaxLatF},{res@mpMinLonF:res@mpMaxLonF})))
;print("min: "+count3(:,:)+"   max: "+count3(:,:))
plot(5) = gsn_csm_contour_map_ce(wks,count_diff1(:,:),res)
plot(8) = gsn_csm_contour_map_ce(wks,count_diff2(:,:),res)
;plot(11) = gsn_csm_contour_map_ce(wks,count_diff3(:,:),res)

plot(3) = gsn_csm_contour_map_ce(wks,count_obsdiff1(:,:),res)
plot(6) = gsn_csm_contour_map_ce(wks,count_obsdiff2(:,:),res)
plot(9) = gsn_csm_contour_map_ce(wks,count_obsdiff3(:,:),res)

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
