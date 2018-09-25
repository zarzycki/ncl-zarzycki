;========================================================
; This file reads in a traj file produced by the TC tracker
; and produces a lat-lon plot of trajectories color-coded by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "../../../functions/getTrajectories.ncl"
load "../../../functions/trackDensity.ncl"

;========================================================
begin

out_type="pdf"
RSIthresh=3   ;0 for all ETCs
prescut=1090.  ; 1000 for AGU
plot_diff_abs=True
plotname = "pdf/etcdens-absdiff-RSIthresh_"+RSIthresh

DEG="12"
SLR="12"
PRECTSNOW="PRECT"
BASEDIR="/glade/u/home/zarzycki/scratch/LES-snow/stats/"
modelstrs=(/"1990","2071"/)
RSIfile=(/BASEDIR+"/5e-9_"+SLR+"_"+DEG+"/RSI.SNOW.LENS."+modelstrs+".ALL.5e-9_"+SLR+"_"+DEG+".csv."+PRECTSNOW+".tempest.csv"/)
trajfile=(/"/glade/u/home/zarzycki/snow-tracking/tracking/traj/tempest.LENS."+modelstrs+".ALL"/)

nyrs = (/16*35,10*35/)
nyrs = nyrs / 10   ; change normalization to "per decade"

ncols = 9                     ; assign number of columns

gridsize=4.0

delim = ","

ncases = dimsizes(trajfile)
print("Doing "+ncases+"  number of cases")

do z = 0,ncases-1


  
  maxLines = -1
  traj_data = getTrajectories(trajfile(z),ncols,maxLines)

  lines = asciiread(RSIfile(z),-1,"string")

  ;member   = str_get_field(lines,1,delim)
  ;stormID  = tointeger(str_get_field(lines,2,delim))
  ;RSIval   = tofloat(str_get_field(lines,3,delim))
  RSIcat   = tointeger(str_get_field(lines,7,delim))

  ndims = dimsizes(traj_data)
  nstorms = ndims(0)
  ncols   = ndims(1)
  ntimes  = ndims(2)

  do i = 0,nstorms-1
    if (RSIcat(i) .lt. RSIthresh)
      traj_data(i,:,:) = traj_data@_FillValue
    end if
  end do

  ;lon = traj_data(:,2,:)
  ;lat = traj_data(:,3,:)
  ;pres = traj_data(:,4,:)/100.
  ;wind = traj_data(:,5,:)*.8
  ;yyyy = traj_data(:,6,:)
  ;mm = traj_data(:,7,:)
  ;dd = traj_data(:,8,:)
  ;hh = traj_data(:,9,:)


  xlon  = traj_data(:,2,:)
  xlat  = traj_data(:,3,:)
  xpres = traj_data(:,4,:)/100.
  xmon = traj_data(:,7,:)

  ; convert to 1-D for easy where processing
  clat = ndtooned(xlat)
  clon = ndtooned(xlon)
  cpres = ndtooned(xpres)
  cmon = toint(ndtooned(xmon))

  ; filter only storms with SLP less than prescut
  clat = where(cpres.lt.prescut,clat,clat@_FillValue)
  clon = where(cpres.lt.prescut,clon,clon@_FillValue)
  cmon = where(cpres.lt.prescut,cmon,cmon@_FillValue)

  ; Calculate track density
  count1 = track_density(gridsize,0.0,clat,clon,False)

  if (z .eq. 0) then
    dims = dimsizes(count1)
    nlatdens = dims(0)
    nlondens = dims(1)
    countArr = new((/nstorms,nlatdens,nlondens/),typeof(count1))
    countArr!1 = "lat"
    countArr!2 = "lon"
    countArr&lat = count1&lat
    countArr&lon = count1&lon
  end if
  countArr(z,:,:) = count1/nyrs(z)

  delete(traj_data)
  delete(lines)
  delete(RSIcat)
  delete(nstorms)
  delete([/xlon,xlat,xpres,xmon/])
  delete([/clon,clat,cpres,cmon/])
  delete(count1)

end do



count_diff = countArr(0,:,:)
count_diff = countArr(1,:,:) - countArr(0,:,:)



if (.not. plot_diff_abs) then
  countArr = where(countArr.eq.0, countArr@_FillValue,countArr)
  count_diff = where(count_diff.eq.0, count_diff@_FillValue,count_diff)
  count_diff = 100. * count_diff / countArr(0,:,:)
  count_diff = where(countArr(1,:,:) .ge. 10., count_diff, count_diff@_FillValue)
end if

;************************************************
; create plot
;************************************************



wks = gsn_open_wks(out_type,plotname)
plot = new(3,"graphic")

;colorMap1="GMT_hot"
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
res@gsnRightString       = "decade~S~-1"

res@mpMinLatF             = 20.
res@mpMaxLatF             = 70.
res@mpMinLonF             = 260.
res@mpMaxLonF             = 310.
;res@mpCenterLonF          = 180.

; plot absolute data
print(RSIthresh)
if (RSIthresh .eq. 0) then
  res@cnLevelSelectionMode  = "ManualLevels"
  res@cnMinLevelValF        = 16.0
  res@cnMaxLevelValF        = 192.0
  res@cnLevelSpacingF       = res@cnMaxLevelValF/12.
else if (RSIthresh .eq. 1) then
  res@cnLevelSelectionMode  = "ManualLevels"
  res@cnMinLevelValF        = 12.0
  res@cnMaxLevelValF        = 144.0
  res@cnLevelSpacingF       = res@cnMaxLevelValF/12.
else
  res@cnLevelSelectionMode  = "ManualLevels"
  res@cnMinLevelValF        = 4.0
  res@cnMaxLevelValF        = 60.0
  res@cnLevelSpacingF       = res@cnMaxLevelValF/12.
end if
end if

cmap = read_colormap_file("GMT_hot")
res@cnFillPalette=cmap(::-1,:)
delete(cmap)

if (RSIthresh .eq. 0) then
  CATSTR="all ETCs"
else
  CATSTR="RPI ~F34~3~F21~ "+RSIthresh
end if

res@gsnLeftString       = "1990-05 "+CATSTR
plot(0) = gsn_csm_contour_map_ce(wks,countArr(0,:,:),res)
res@gsnLeftString       = "2071-80 "+CATSTR
plot(1) = gsn_csm_contour_map_ce(wks,countArr(1,:,:),res)
print("max countArr(0,:,:) "+max(countArr(0,:,:)))
print("max countArr(1,:,:) "+max(countArr(1,:,:)))

; plot differences
res@cnLevelSelectionMode  = "ManualLevels"
if (plot_diff_abs) then
  if (RSIthresh .eq. 0) then
    res@cnMinLevelValF        = -48.0
    res@cnMaxLevelValF        = 48.0
  else if (RSIthresh .eq. 1) then
    res@cnMinLevelValF        = -36.0
    res@cnMaxLevelValF        = 36.0
  else
    res@cnMinLevelValF        = -15.0
    res@cnMaxLevelValF        = 15.0
  end if
  end if
  res@cnLevelSpacingF       = (res@cnMaxLevelValF-res@cnMinLevelValF)/12.
else
  res@cnMinLevelValF        = -50.0
  res@cnMaxLevelValF        = 50.0
  res@cnLevelSpacingF       = res@cnMaxLevelValF/10.
end if

delete(res@cnFillPalette)
res@cnFillPalette=colorMap2

res@gsnLeftString       = "Diff. "+CATSTR
plot(2) = gsn_csm_contour_map_ce(wks,count_diff(:,:),res)
print("max count_diff(:,:) "+max(count_diff(:,:)))

resP = True
resP@txString           = ""
resP@amJust           = "TopLeft"
resP@gsnPanelFigureStringsFontHeightF = 0.02
if (RSIthresh .eq. 0) then
  resP@gsnPanelFigureStrings= (/"a.","b.","c."/)
else if (RSIthresh .eq. 1) then
  resP@gsnPanelFigureStrings= (/"d.","e.","f."/)
else
  resP@gsnPanelFigureStrings= (/"g.","h.","i."/)
end if
end if

gsn_panel(wks,plot,(/1,3/),resP)

end
