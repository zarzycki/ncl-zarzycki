;=================== Description ==================================
; This script reads in Tempeset
; tracking code and plots a track density
;==================================================================

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "../../functions/getTrajectoriesGeneric.ncl"
load "../../functions/trackDensity.ncl"
load "../../functions/mask_tc.ncl"

begin

;=================== User Settings ================================
gridsize = 8.0
out_type = "pdf"
wind_factor = 0.85
do_genesis = False
prescut = 99999.0   ; only storms with pres LOWER than this are included. set to 99999.0 for all storms
;======================= Constants ================================
ms_to_kts = 1.94384449

;======================= Masking ================================

basin=1
maskspacing=1.0
tcMask = mask_tc(0,-999,-999,maskspacing,360)

;=================== Get traj data ================================
thefile="ibtracs-1998-2008-GLOB.txt"  ; trajectory file full path
ncols = 11 ; number of columns in non-header rows of trajectory file
maxLines = -1  ; set to -1 for auto-detection
traj_data = getTrajectoriesGeneric(thefile,ncols,maxLines,"start","tab",False,False)

; load in trajectory data (need to be modified if using different tempest output
xlon  = traj_data(:,2,:)
xlat  = traj_data(:,3,:)
xpres  = traj_data(:,4,:)/100.
xwind  = traj_data(:,5,:)
dims=dimsizes(xlon)
nstorms=dims(0)
ntimes=dims(1)

do ii = 0,nstorms-1
  orilat=xlat(ii,0)
  orilon=xlon(ii,0)
  if (orilon .gt. 360.0-maskspacing) then
    orilon=360.0-maskspacing
    print("    original lon: "+xlon(ii,0)+"   modified lon: "+orilon)
  end if
  if (tcMask({orilat},{orilon}) .ne. basin)
    xlon(ii,:)=xlon@_FillValue
    xlat(ii,:)=xlat@_FillValue
    xpres(ii,:)=xpres@_FillValue
    xwind(ii,:)=xwind@_FillValue
  end if
end do

xlon=where(xwind.gt.35/ms_to_kts,xlon,xlon@_FillValue)
xlat=where(xwind.gt.35/ms_to_kts,xlat,xlat@_FillValue)
xpres=where(xwind.gt.35/ms_to_kts,xpres,xpres@_FillValue)
xwind=where(xwind.gt.35/ms_to_kts,xwind,xwind@_FillValue)

xlon=where(xpres.lt.850.,xlon@_FillValue,xlon)
xlat=where(xpres.lt.850.,xlat@_FillValue,xlat)
xpres=where(xpres.lt.850.,xpres@_FillValue,xpres)
xwind=where(xpres.lt.850.,xwind@_FillValue,xwind)

if (do_genesis) then
  xlon  := xlon(:,0)
  xlat  := xlat(:,0)
  xpres  := dim_min_n(xpres,1)
  xwind  := dim_max_n(xwind,1)
end if

;do zz = 0,nstorms-1
;  print(zz+" "+(1.0e-4*sum((xwind(zz,:)*ms_to_kts)^2.)))
;end do

clat = ndtooned(xlat)
clon = ndtooned(xlon)
cpres = ndtooned(xpres)
cwind = ndtooned(xwind)

clat = where(cpres.lt.prescut,clat,clat@_FillValue)
clon = where(cpres.lt.prescut,clon,clon@_FillValue)
cwind = where(cpres.lt.prescut,cwind,cwind@_FillValue)
cpres = where(cpres.lt.prescut,cpres,cpres@_FillValue)

trackdens1 = track_density(gridsize,0.0,clat,clon,False)
minpres1 = track_minmax(gridsize,0.0,clat,clon,cpres,"min",20)
maxwind1 = track_minmax(gridsize,0.0,clat,clon,cwind,"max",20)

nyrs=11.
trackdens1=trackdens1/nyrs

tcdays=tofloat(num(cwind .gt. 17.5))/nyrs
ACE=(1.0e-4*sum((cwind*ms_to_kts)^2.))/nyrs

print("TCDays: "+tcdays)
print("ACE: "+ACE)

delete([/xlon,xlat,xpres,xwind,clon,clat,cpres,cwind,nyrs,traj_data,maxLines,ncols,thefile/])

;=================== Get traj data ================================
thefile="trajectories.txt.CFSR"  ; trajectory file full path
ncols = 11 ; number of columns in non-header rows of trajectory file
maxLines = -1  ; set to -1 for auto-detection
traj_data = getTrajectoriesGeneric(thefile,ncols,maxLines,"start","tab",False,False)

; load in trajectory data (need to be modified if using different tempest output
xlon  = traj_data(:,2,:)
xlat  = traj_data(:,3,:)
xpres  = traj_data(:,4,:)/100.
xwind  = traj_data(:,5,:)
dims=dimsizes(xlon)
nstorms=dims(0)
ntimes=dims(1)

if (min(xlon).lt.0.0) then
  xlon = where(xlon.lt.0.0,xlon+360.,xlon)
end if

do ii = 0,nstorms-1
  orilat=xlat(ii,0)
  orilon=xlon(ii,0)
  if (orilon .gt. 360.0-maskspacing) then
    orilon=360.0-maskspacing
    print("    original lon: "+xlon(ii,0)+"   modified lon: "+orilon)
  end if
  if (tcMask({orilat},{orilon}) .ne. basin)
    xlon(ii,:)=xlon@_FillValue
    xlat(ii,:)=xlat@_FillValue
    xpres(ii,:)=xpres@_FillValue
    xwind(ii,:)=xwind@_FillValue
  end if
end do

if (do_genesis) then
  xlon  := xlon(:,0)
  xlat  := xlat(:,0)
  xpres  := dim_min_n(xpres,1)
  xwind  := dim_max_n(xwind,1)
end if

clat = ndtooned(xlat)
clon = ndtooned(xlon)
cpres = ndtooned(xpres)
cwind = ndtooned(xwind)

clat = where(cpres.lt.prescut,clat,clat@_FillValue)
clon = where(cpres.lt.prescut,clon,clon@_FillValue)
cwind = where(cpres.lt.prescut,cwind,cwind@_FillValue)
cpres = where(cpres.lt.prescut,cpres,cpres@_FillValue)

trackdens2 = track_density(gridsize,0.0,clat,clon,False)
minpres2 = track_minmax(gridsize,0.0,clat,clon,cpres,"min",20)
maxwind2 = track_minmax(gridsize,0.0,clat,clon,cwind,"max",20)

nyrs=11.
trackdens2=trackdens2/nyrs

tcdays=tofloat(num(cwind .gt. 17.5))/nyrs
ACE=(1.0e-4*sum((cwind*ms_to_kts)^2.))/nyrs

print("TCDays: "+tcdays)
print("ACE: "+ACE)

delete([/xlon,xlat,xpres,xwind,clon,clat,cpres,cwind,nyrs,traj_data,maxLines,ncols,thefile/])


minpres_diff = minpres1   ; just a trick to copy metadata
minpres_diff = minpres1-minpres2

patterncorr = pattern_cor(trackdens1,trackdens2,1.,1)
print(patterncorr)

;************************************************
; create plot
;************************************************
if (prescut .lt. 1020.0) then
  plotname = "anntrackdens_lt"+prescut
else
  plotname = "anntrackdens_all"
end if
wks = gsn_open_wks(out_type,plotname)
plot = new(3,"graphic")

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
;res@mpMinLatF             = -60.
;res@mpMaxLatF             = 60.
;res@mpMinLonF             = 0.
;res@mpMaxLonF             = 360.
res@mpCenterLonF          = (res@mpMinLonF + res@mpMaxLonF)/2

; plot absolute data
res@cnLevelSelectionMode  = "ManualLevels"
; 0-120
res@cnMinLevelValF        = 900.0
res@cnMaxLevelValF        = 1015.0
res@cnLevelSpacingF       = (res@cnMaxLevelValF - res@cnMinLevelValF) / 15.
res@cnFillPalette=colorMap1
print("min: "+min(minpres1({res@mpMinLatF:res@mpMaxLatF},{res@mpMinLonF:res@mpMaxLonF}))+"   max: "+max(minpres1({res@mpMinLatF:res@mpMaxLatF},{res@mpMinLonF:res@mpMaxLonF})))
plot(1) = gsn_csm_contour_map_ce(wks,minpres1(:,:),res)
plot(0) = gsn_csm_contour_map_ce(wks,minpres2(:,:),res)
; plot differences
res@cnLevelSelectionMode  = "ManualLevels"
; -40-40
res@cnMinLevelValF        = -60.
res@cnMaxLevelValF        = -res@cnMinLevelValF
res@cnLevelSpacingF       = res@cnMaxLevelValF/15.
res@cnFillPalette=colorMap2

print("min: "+min(minpres_diff({res@mpMinLatF:res@mpMaxLatF},{res@mpMinLonF:res@mpMaxLonF}))+"   max: "+max(minpres_diff({res@mpMinLatF:res@mpMaxLatF},{res@mpMinLonF:res@mpMaxLonF})))
plot(2) = gsn_csm_contour_map_ce(wks,minpres_diff(:,:),res)

resP = True
if (prescut .lt. 1020.0) then
  resP@txString           = "Annual TC track density, < "+prescut+" mb"
else
  resP@txString           = "Annual TC track density, all storms"
end if
resP@amJust           = "TopLeft"
resP@gsnPanelFigureStringsFontHeightF = 0.014
resP@gsnPanelFigureStrings= (/"MODEL","OBS","M-O"/)

gsn_panel(wks,plot,(/3,1/),resP)

end