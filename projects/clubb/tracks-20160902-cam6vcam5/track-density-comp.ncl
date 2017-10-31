;=================== Description ==================================
; This script reads in Tempeset
; tracking code and plots a track density
;==================================================================

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "/glade/u/home/zarzycki/ncl/functions/getTrajectories.ncl"
load "/glade/u/home/zarzycki/ncl/functions/trackDensity.ncl"

begin

;=================== User Settings ================================
gridsize = 8.0
out_type = "pdf"
wind_factor = 0.85

prescut = 980.0   ; only storms with pres LOWER than this are included. set to 99999.0 for all storms

;======================= Constants ================================
ms_to_kts = 1.94384449

;=================== Get traj data ================================
thefile="/glade/u/home/zarzycki/work/clubb-tracking/CAM5_ALL/trajectories.txt.CAM5"  ; trajectory file full path
ncols = 13 ; number of columns in non-header rows of trajectory file
maxLines = -1  ; set to -1 for auto-detection
traj_data = getTrajectories(thefile,ncols,maxLines)

; load in trajectory data (need to be modified if using different tempest output
xlon  = traj_data(:,1,:)
xlat  = traj_data(:,2,:)
xpres = traj_data(:,3,:)/100.
xwind = traj_data(:,5,:)*wind_factor
clat = ndtooned(xlat)
clon = ndtooned(xlon)
cwind = ndtooned(xwind)
cpres = ndtooned(xpres)

clat = where(cpres.lt.prescut,clat,clat@_FillValue)
clon = where(cpres.lt.prescut,clon,clon@_FillValue)

count1 = track_density(gridsize,0.0,clat,clon,False)
nyrs=6.
count1=count1/nyrs

delete([/xlon,xlat,xpres,xwind,clon,clat,cpres,cwind,nyrs,traj_data,maxLines,ncols,thefile/])

;=================== Get traj data ================================
thefile="/glade/u/home/zarzycki/tempest-scripts/clubb/traj.txt.CLUBB"  ; trajectory file full path
ncols = 13 ; number of columns in non-header rows of trajectory file
maxLines = -1  ; set to -1 for auto-detection
traj_data = getTrajectories(thefile,ncols,maxLines)

; load in trajectory data (need to be modified if using different tempest output
xlon  = traj_data(:,1,:)
xlat  = traj_data(:,2,:)
xpres = traj_data(:,3,:)/100.
xwind = traj_data(:,5,:)*wind_factor
clat = ndtooned(xlat)
clon = ndtooned(xlon)
cwind = ndtooned(xwind)
cpres = ndtooned(xpres)

clat = where(cpres.lt.prescut,clat,clat@_FillValue)
clon = where(cpres.lt.prescut,clon,clon@_FillValue)

count2 = track_density(gridsize,0.0,clat,clon,False)
nyrs=15.15
count2=count2/nyrs

delete([/xlon,xlat,xpres,xwind,clon,clat,cpres,cwind,nyrs,traj_data,maxLines,ncols,thefile/])

;=================== Get traj data ================================
thefile="/glade/u/home/zarzycki/work/reanalysis-monte/JRA_DZ300500/traj.ab.0105"  ; trajectory file full path
ncols = 11 ; number of columns in non-header rows of trajectory file
maxLines = -1  ; set to -1 for auto-detection
traj_data = getTrajectories(thefile,ncols,maxLines)

; load in trajectory data (need to be modified if using different tempest output
xlon  = traj_data(:,2,:)
xlat  = traj_data(:,3,:)
xpres = traj_data(:,4,:)/100.
xwind = traj_data(:,5,:)*wind_factor
clat = ndtooned(xlat)
clon = ndtooned(xlon)
cwind = ndtooned(xwind)
cpres = ndtooned(xpres)

clat = where(cpres.lt.prescut,clat,clat@_FillValue)
clon = where(cpres.lt.prescut,clon,clon@_FillValue)

count3 = track_density(gridsize,0.0,clat,clon,False)
nyrs=11.
count3=count3/nyrs

delete([/xlon,xlat,xpres,xwind,clon,clat,cpres,cwind,nyrs,traj_data,maxLines,ncols,thefile/])

;=================== Get ibtracs data ================================
ibstyr=1980
ibenyr=2009
print("Plotting iBtracks data from: "+ibstyr+" to "+ibenyr)
ibdir = "/glade/u/home/zarzycki/work/ibtracs/"
ibfilename="Allstorms.ibtracs_wmo.v03r08.nc"
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
xlat = ibfile->lat_wmo(stix:enix,:)*.01
xlon = ibfile->lon_wmo(stix:enix,:)*.01
xtype = toint(ibfile->nature_wmo(stix:enix,:))
xwind = ibfile->wind_wmo(stix:enix,:)*.1/ms_to_kts
xpres = ibfile->pres_wmo(stix:enix,:)*.1

cwind = ndtooned(xwind)
cpres = ndtooned(xpres)
clat = ndtooned(xlat)
clon = ndtooned(xlon)
ctype = ndtooned(xtype)

clon = where(clon.lt.0,clon+360.,clon)

cwind = where(ctype.ne.2,cwind,cwind@_FillValue)
cpres = where(ctype.ne.2,cpres,cpres@_FillValue)
clat = where(ctype.ne.2,clat,clat@_FillValue)
clon = where(ctype.ne.2,clon,clon@_FillValue)

clat = where(cpres.lt.prescut,clat,clat@_FillValue)
clon = where(cpres.lt.prescut,clon,clon@_FillValue)

countobs = track_density(gridsize,0.0,clat,clon,False)
nyrs=30.
countobs=countobs/nyrs

delete([/xlon,xlat,xpres,xwind,xtype,clon,clat,cpres,cwind,ctype,nyrs/])


;=================== Do diff ================================
count_diff1 = count1   ; just a trick to copy metadata
count_diff1 = count1-countobs
count_diff2 = count2   ; just a trick to copy metadata
count_diff2 = count2-countobs

;=================== change zeros to missing values ================================

countobs = where(countobs.eq.0, countobs@_FillValue,countobs)

count1 = where(count1.eq.0, count1@_FillValue,count1)
count2 = where(count2.eq.0, count2@_FillValue,count2)
count3 = where(count3.eq.0, count3@_FillValue,count3)

count_diff1 = where(count_diff1.eq.0, count_diff1@_FillValue,count_diff1)
count_diff2 = where(count_diff2.eq.0, count_diff2@_FillValue,count_diff2)


;************************************************
; create plot
;************************************************
if (prescut .lt. 1020.0) then
  plotname = "anntrackdens_lt"+prescut
else
  plotname = "anntrackdens_all"
end if
wks = gsn_open_wks(out_type,plotname)
plot = new(6,"graphic")

colorMap1="BlAqGrYeOrRe"
colorMap2="BlWhRe"

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

res@mpMinLatF             = -65.
res@mpMaxLatF             = 65.
res@mpCenterLonF          = 180.

; plot absolute data
res@cnLevelSelectionMode  = "ManualLevels"
res@cnMinLevelValF        = 0.0
res@cnMaxLevelValF        = 75.0
res@cnLevelSpacingF       = res@cnMaxLevelValF/25.
res@cnFillPalette=colorMap1
plot(0) = gsn_csm_contour_map_ce(wks,countobs(:,:),res)
plot(1) = gsn_csm_contour_map_ce(wks,count3(:,:),res)
plot(2) = gsn_csm_contour_map_ce(wks,count1(:,:),res)
plot(4) = gsn_csm_contour_map_ce(wks,count2(:,:),res)
; plot differences
res@cnLevelSelectionMode  = "ManualLevels"
res@cnMinLevelValF        = -35.0
res@cnMaxLevelValF        = 35.0
res@cnLevelSpacingF       = res@cnMaxLevelValF/20.
res@cnFillPalette=colorMap2

plot(3) = gsn_csm_contour_map_ce(wks,count_diff1(:,:),res)
plot(5) = gsn_csm_contour_map_ce(wks,count_diff2(:,:),res)

resP = True
if (prescut .lt. 1020.0) then
  resP@txString           = "Annual TC track density, < "+prescut+" mb"
else
  resP@txString           = "Annual TC track density, all storms"
end if
resP@amJust           = "TopLeft"
resP@gsnPanelFigureStringsFontHeightF = 0.014
resP@gsnPanelFigureStrings= (/"IBTRACS","JRA55","CAM5","CAM5-IBTRACS","CAM6","CAM6-OBS"/)

gsn_panel(wks,plot,(/3,2/),resP)

end
