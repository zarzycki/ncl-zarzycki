;========================================================
; This file reads in a traj file produced by the TC tracker
; and produces a lat-lon plot of trajectories color-coded by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "/glade/u/home/zarzycki/ncl/functions/getTrajectories.ncl"
load "/glade/u/home/zarzycki/ncl/functions/trackDensity.ncl"

;========================================================
begin

out_type="x11"
RSIthresh=0
prescut=1000.
plot_diff_abs=True

trajfile=(/"/glade/u/home/zarzycki/snow-tracking/LES_tracking/traj/tempest.LENS.1990.ALL","/glade/u/home/zarzycki/snow-tracking/LES_tracking/traj/tempest.LENS.2071.ALL"/)
RSIfile = (/"/glade/u/home/zarzycki/scratch/LES-snow/stats/RSI.SNOW.LENS.1990.ALL.5e-9_12.csv.PRECT.tempest.csv","/glade/u/home/zarzycki/scratch/LES-snow/stats/RSI.SNOW.LENS.2071.ALL.5e-9_12.csv.PRECT.tempest.csv"/)
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

countArr = where(countArr.eq.0, countArr@_FillValue,countArr)
count_diff = where(count_diff.eq.0, count_diff@_FillValue,count_diff)

if (.not. plot_diff_abs) then
  count_diff = 100. * count_diff / countArr(0,:,:)
  count_diff = where(countArr(1,:,:) .ge. 10., count_diff, count_diff@_FillValue)
end if

;************************************************
; create plot
;************************************************

plotname = "tmp"

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
res@gsnCenterString       = ""

res@mpMinLatF             = 20.
res@mpMaxLatF             = 70.
res@mpMinLonF             = 260.
res@mpMaxLonF             = 310.
;res@mpCenterLonF          = 180.

; plot absolute data
res@cnLevelSelectionMode  = "ManualLevels"
res@cnMinLevelValF        = 0.0
res@cnMaxLevelValF        = 100.0
res@cnLevelSpacingF       = res@cnMaxLevelValF/10.

cmap = read_colormap_file("GMT_hot")
res@cnFillPalette=cmap(::-1,:)
delete(cmap)

plot(0) = gsn_csm_contour_map_ce(wks,countArr(0,:,:),res)
plot(1) = gsn_csm_contour_map_ce(wks,countArr(1,:,:),res)
; plot differences
res@cnLevelSelectionMode  = "ManualLevels"
if (plot_diff_abs) then
  res@cnMinLevelValF        = -20.0
  res@cnMaxLevelValF        = 20.0
  res@cnLevelSpacingF       = (res@cnMaxLevelValF-res@cnMinLevelValF)/10.
else
  res@cnMinLevelValF        = -50.0
  res@cnMaxLevelValF        = 50.0
  res@cnLevelSpacingF       = res@cnMaxLevelValF/10.
end if

delete(res@cnFillPalette)
res@cnFillPalette=colorMap2

plot(2) = gsn_csm_contour_map_ce(wks,count_diff(:,:),res)

resP = True
resP@txString           = ""
resP@amJust           = "TopLeft"
resP@gsnPanelFigureStringsFontHeightF = 0.014
resP@gsnPanelFigureStrings= (/"a.","b.","c."/)

gsn_panel(wks,plot,(/1,3/),resP)

end
