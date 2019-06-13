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
load "./taylor_diagram.ncl"

begin

;=================== User Settings ================================
out_type = "pdf"
wind_factor = 0.85
prescut = 99999.0   ; only storms with pres LOWER than this are included. set to 99999.0 for all storms
do_genesis=True
gridsize = 8.0

;======================= Constants ================================
ms_to_kts = 1.94384449

;======================= Masking ================================

basin=1
maskspacing=1.0
tcMask = mask_tc(0,-999,-999,maskspacing,360)

;=================== Get traj data ================================
filename = "tracker_configs.csv"
lines = asciiread(filename,-1,"string")
delim = ","
files  =           str_get_field(lines,1,delim)
strs = str_get_field(lines,2,delim)
isUnstructStr   = str_get_field(lines,3,delim)
ensmembers= toint(str_get_field(lines,4,delim))
yearspermember= toint(str_get_field(lines,5,delim))
windcorrs = tofloat(str_get_field(lines,6,delim))

isUnstruct = where(isUnstructStr.eq."True",True,False)
;==========================================================

nfiles=dimsizes(files)

nmonths=12

do zz = 0,nfiles-1
  nyears=ensmembers(zz)*yearspermember(zz)

  thefile=str_right_strip(files(zz))
  ncols = 11 ; number of columns in non-header rows of trajectory file
  maxLines = -1  ; set to -1 for auto-detection
  if (isUnstruct(zz)) then
    ncols = ncols-1
  end if
  traj_data = getTrajectoriesGeneric(thefile,ncols,maxLines,"start","tab",isUnstruct(zz),False)

  wind_factor = windcorrs(zz)
  print("corr wind: "+wind_factor)

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

  trackdens = track_density(gridsize,0.0,clat,clon,False)
  trackdens = trackdens/nyears
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
    trackdens = track_density(gridsize,0.0,clat,clon,False)
    trackdens = trackdens/nyears
    fullgen(zz,:,:)=trackdens(:,:)
  end if

  delete([/xlon,xlat,xpres,xwind,clon,clat,cpres,cwind/])
  delete([/traj_data,maxLines,ncols,thefile/])
  delete([/trackdens,minpres,maxwind/])

end do

taylor_cco=new((/2,nfiles-1/),"float")
taylor_rat=new((/2,nfiles-1/),"float")

delim=","
OPT=0
print("PATTERN")
do mm = 1,nfiles-1
  tmprefr=fulldens(0,:,:)
  tmptest=fulldens(mm,:,:)
  tmprefr=where(fulldens(0,:,:) .eq. 0 .and. fulldens(mm,:,:) .eq. 0,tmprefr@_FillValue,tmprefr)
  tmptest=where(fulldens(0,:,:) .eq. 0 .and. fulldens(mm,:,:) .eq. 0,tmptest@_FillValue,tmptest)
  tm2refr=fullgen(0,:,:)
  tm2test=fullgen(mm,:,:)
  tm2refr=where(fullgen(0,:,:) .eq. 0 .and. fullgen(mm,:,:) .eq. 0,tm2refr@_FillValue,tm2refr)
  tm2test=where(fullgen(0,:,:) .eq. 0 .and. fullgen(mm,:,:) .eq. 0,tm2test@_FillValue,tm2test)
  print(strs(mm)+delim+pattern_cor(tmprefr,tmptest,1.,OPT)+delim+ \
    pattern_cor(fullpres(0,:,:),fullpres(mm,:,:),1.,OPT)+delim+ \
    pattern_cor(fullwind(0,:,:),fullwind(mm,:,:),1.,OPT)+delim+ \
    pattern_cor(tm2refr,tm2test,1.,OPT) )
  taylorVals=taylor_stats(tmptest,tmprefr,1.,0)
  taylor_cco(0,mm-1)=taylorVals(0)
  taylor_rat(0,mm-1)=taylorVals(1)
  ;taylorVals=taylor_stats(tm2test,tm2refr,1.,0)
  ;taylor_cco(1,mm-1)=taylorVals(0)
  ;taylor_rat(1,mm-1)=taylorVals(1)
end do
print("RMSE")
do mm = 1,nfiles-1
  tmprefr=fulldens(0,:,:)
  tmptest=fulldens(mm,:,:)
  tmprefr=where(fulldens(0,:,:) .eq. 0 .and. fulldens(mm,:,:) .eq. 0,tmprefr@_FillValue,tmprefr)
  tmptest=where(fulldens(0,:,:) .eq. 0 .and. fulldens(mm,:,:) .eq. 0,tmptest@_FillValue,tmptest)

  ;rmean   = avg(tmprefr)            ; area weighted means
  ;tmean   = avg(tmptest)
  ;tmprefr=tmprefr-rmean
  ;tmptest=tmptest-tmean
  ;print(sqrt(sum(tmptest^2)/sum(tmprefr^2)))

  tm2refr=fullgen(0,:,:)
  tm2test=fullgen(mm,:,:)
  tm2refr=where(fullgen(0,:,:) .eq. 0 .and. fullgen(mm,:,:) .eq. 0,tm2refr@_FillValue,tm2refr)
  tm2test=where(fullgen(0,:,:) .eq. 0 .and. fullgen(mm,:,:) .eq. 0,tm2test@_FillValue,tm2test)
  print(strs(mm)+delim+dim_rmsd_n(tmprefr,tmptest,(/0,1/))+delim+ \
    dim_rmsd_n(fullpres(0,:,:),fullpres(mm,:,:),(/0,1/))+delim+ \
    dim_rmsd_n(fullwind(0,:,:),fullwind(mm,:,:),(/0,1/))+delim+ \
    dim_rmsd_n(tm2refr,tm2test,(/0,1/)) )
end do

print(taylor_cco+" "+taylor_rat)

wks   = gsn_open_wks("pdf","taylor")      ; send graphics to PNG file
res   = True
res@Markers = (/16,4/)
res@txFontHeightF = 0.02
res@markerTxYOffset = 0.02
;res@varLabels = strs(1:nfiles-1)  ; don't include obs
plot  = taylor_diagram(wks, taylor_rat, taylor_cco, res)
exit

plots = (/0,5,9,10/)

wks = gsn_open_wks("pdf","test")
plot = new(4,"graphic")

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
res@cnMaxLevelValF        = 15.0
res@cnLevelSpacingF       = (res@cnMaxLevelValF - res@cnMinLevelValF) / 15.
res@cnFillPalette=colorMap1
plot(0) = gsn_csm_contour_map_ce(wks,fulldens(plots(0),:,:),res)
plot(1) = gsn_csm_contour_map_ce(wks,fulldens(plots(1),:,:),res)
plot(2) = gsn_csm_contour_map_ce(wks,fulldens(plots(2),:,:),res)
plot(3) = gsn_csm_contour_map_ce(wks,fulldens(plots(3),:,:),res)

resP=True
resP@txString           = "Annual TC track density, all storms"
resP@amJust           = "TopLeft"
resP@gsnPanelFigureStringsFontHeightF = 0.014
resP@gsnPanelFigureStrings= strs(plots)

gsn_panel(wks,plot,(/2,2/),resP)




end
