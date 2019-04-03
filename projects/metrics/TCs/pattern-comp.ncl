;=================== Description ==================================
; This script reads in Tempeset
; tracking code and plots a track density
;==================================================================

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "../../../functions/getTrajectoriesGeneric.ncl"
load "../../../functions/trackDensity.ncl"
load "../../../functions/mask_tc.ncl"

begin

;=================== User Settings ================================
out_type = "pdf"
wind_factor = 0.85
prescut = 99999.0   ; only storms with pres LOWER than this are included. set to 99999.0 for all storms
do_genesis=True
gridsize = 8.0

;======================= Constants ================================
ms_to_kts = 1.94384449

styr=2003
enyr=2015
nyears=enyr-styr+1
yearArr=ispan(styr,enyr,1)

stmon=1
enmon=12
nmonths=enmon-stmon+1
monArr=ispan(stmon,enmon,1)

;======================= Masking ================================

basin=1
maskspacing=1.0
tcMask = mask_tc(0,-999,-999,maskspacing,360)

;=================== Get traj data ================================
files=(/"ibtracs-2003-2015-GLOB.txt", \
"trajectories.txt.CFSR", \
"trajectories.txt.JRA", \
"trajectories.txt.MERRA", \
"trajectories.txt.MERRA2", \
"trajectories.txt.ERA5", \
"trajectories.txt.ERAI", \
"trajectories.txt.VR28.NATL.WAT.CAM5.4CLM5.0.dtime900.ALL", \
"trajectories.txt.VR28.NATL.REF.CAM5.4CLM5.0.dtime900.ALL", \
"trajectories.txt.VR28.NATL.EXT.CAM5.4CLM5.0.dtime900.ALL", \
"trajectories.txt.VR28.NATL.ALL.CAM5.4CLM5.0.dtime900.ALL"/)

strs=(/"IBTrACS","CFSR","JRA","MERRA","MERRA2","ERA5","ERAI","CAMWAT","CAMREF","CAMEXT","CAMALL"/)
isUnstruct=(/False,False,False,False,False,False,False,True,True,True,True/)
ensmembers=(/1,1,1,1,1,1,1,3,3,3,9/)

nfiles=dimsizes(files)

nmonths=12

stormsByYear=new((/nfiles,nyears/),"float")
aceByYear=new((/nfiles,nyears/),"float")
tcdByYear=new((/nfiles,nyears/),"float")

stormsByMonth=new((/nfiles,12/),"float")
aceByMonth=new((/nfiles,12/),"float")
tcdByMonth=new((/nfiles,12/),"float")

do zz = 0,nfiles-1

  thefile=files(zz)
  ncols = 11 ; number of columns in non-header rows of trajectory file
  maxLines = -1  ; set to -1 for auto-detection
  if (isUnstruct(zz)) then
    ncols = ncols-1
  end if
  traj_data = getTrajectoriesGeneric(thefile,ncols,maxLines,"start","tab",isUnstruct(zz),False)

  if (zz .ne. 0) then
    wind_factor = 0.85
  else
    wind_factor = 1.0
  end if

  ; load in trajectory data (need to be modified if using different tempest output
  xlon  = traj_data(:,2,:)
  xlat  = traj_data(:,3,:)
  xpres  = traj_data(:,4,:)/100.
  xwind  = traj_data(:,5,:)*wind_factor

  dims=dimsizes(xlon)
  nstorms=dims(0)
  ntimes=dims(1)

;  if (zz.eq.3 .or. zz.eq.4) then
;    xlon = where(xlon.lt.0,xlon+360.,xlon)
;  end if

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

if (zz.eq.0)
  xlon=where(xwind.gt.35/ms_to_kts,xlon,xlon@_FillValue)
  xlat=where(xwind.gt.35/ms_to_kts,xlat,xlat@_FillValue)
  xpres=where(xwind.gt.35/ms_to_kts,xpres,xpres@_FillValue)
  xwind=where(xwind.gt.35/ms_to_kts,xwind,xwind@_FillValue)

  xlon=where(xpres.lt.850.,xlon@_FillValue,xlon)
  xlat=where(xpres.lt.850.,xlat@_FillValue,xlat)
  xpres=where(xpres.lt.850.,xpres@_FillValue,xpres)
  xwind=where(xpres.lt.850.,xwind@_FillValue,xwind)
end if
  
  clat = ndtooned(xlat)
  clon = ndtooned(xlon)
  cpres = ndtooned(xpres)
  cwind = ndtooned(xwind)

  clat = where(cpres.lt.prescut,clat,clat@_FillValue)
  clon = where(cpres.lt.prescut,clon,clon@_FillValue)
  cwind = where(cpres.lt.prescut,cwind,cwind@_FillValue)
  cpres = where(cpres.lt.prescut,cpres,cpres@_FillValue)

  trackdens = track_density(gridsize,0.0,clat,clon,True)
  trackdens = trackdens/nyears/ensmembers(zz)
  minpres = track_minmax(gridsize,0.0,clat,clon,cpres,"min",20)
  maxwind = track_minmax(gridsize,0.0,clat,clon,cwind,"max",20)
  printVarSummary(trackdens)

  if (zz.eq.0) then
    tmpdims=dimsizes(trackdens)
    fulldens=new((/nfiles,tmpdims(0),tmpdims(1)/),typeof(trackdens))
    fulldens!1="lat"
    fulldens!2="lon"
    fulldens&lat=trackdens&lat
    fulldens&lon=trackdens&lon
    fullpres=fulldens
    fullwind=fulldens
    fullgen=fulldens
    delete(tmpdims)
  end if
  
  fulldens(zz,:,:)=trackdens(:,:)
  fullpres(zz,:,:)=minpres(:,:)
  fullwind(zz,:,:)=maxwind(:,:)

  if (do_genesis) then
    delete(trackdens)
    do kk = 0,nstorms-1
      xlontmp=ind(.not.ismissing(xlon(kk,:)))
      if (.not.all(ismissing(xlontmp)))
        xlon(kk,0)=xlon(kk,xlontmp(0))
        xlat(kk,0)=xlat(kk,xlontmp(0))
      end if
      delete(xlontmp)
    end do
    clat := ndtooned(xlat(:,0))
    clon := ndtooned(xlon(:,0))
    cpres := ndtooned(dim_min_n(xpres,1))
    cwind := ndtooned(dim_max_n(xwind,1))
    trackdens = track_density(gridsize,0.0,clat,clon,True)
    trackdens = trackdens/nyears/ensmembers(zz)
    fullgen(zz,:,:)=trackdens(:,:)
  end if

  delete([/xlon,xlat,xpres,xwind,clon,clat,cpres,cwind/])
  delete([/traj_data,maxLines,ncols,thefile/])
  delete([/trackdens,minpres,maxwind/])

end do

delim=","
OPT=0
print("MEAN CLIMO")
do mm = 1,nfiles-1
  print(strs(mm)+delim+pattern_cor(fulldens(0,:,:),fulldens(mm,:,:),1.,OPT)+delim+ \
    pattern_cor(fullpres(0,:,:),fullpres(mm,:,:),1.,OPT)+delim+ \
    pattern_cor(fullwind(0,:,:),fullwind(mm,:,:),1.,OPT)+delim+ \
    pattern_cor(fullgen(0,:,:),fullgen(mm,:,:),1.,OPT) )
end do






wks = gsn_open_wks("x11","test")
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
res@cnMinLevelValF        = 0.
res@cnMaxLevelValF        = 1.0
res@cnLevelSpacingF       = (res@cnMaxLevelValF - res@cnMinLevelValF) / 15.
res@cnFillPalette=colorMap1
plot(0) = gsn_csm_contour_map_ce(wks,fullgen(7,:,:),res)
plot(1) = gsn_csm_contour_map_ce(wks,fullgen(8,:,:),res)
plot(2) = gsn_csm_contour_map_ce(wks,fullgen(9,:,:),res)

resP=True
resP@txString           = "Annual TC track density, all storms"
resP@amJust           = "TopLeft"
resP@gsnPanelFigureStringsFontHeightF = 0.014
resP@gsnPanelFigureStrings= (/"MODEL","OBS","M-O"/)

gsn_panel(wks,plot,(/3,1/),resP)




end
