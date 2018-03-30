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
prescut=1090.  ; 1000 for AGU
plot_diff_abs=False
plotname = "x11"

trajfile=(/"/glade/u/home/zarzycki/scratch/tmp-slab/ocn-tc-cooling-nhemi_30_x4/tracking/cat_traj_fixedSST_900.txt","/glade/u/home/zarzycki/scratch/tmp-slab/ocn-tc-cooling-nhemi_30_x4/tracking/cat_traj_slab_08_4.7_900.txt"/)

ncols = 12                     ; assign number of columns

gridsize=8.0

delim = ","

ncases = dimsizes(trajfile)
print("Doing "+ncases+"  number of cases")

do z = 0,ncases-1


  
  maxLines = -1
  traj_data = getTrajectories(trajfile(z),ncols,maxLines)

  ndims = dimsizes(traj_data)
  nstorms = ndims(0)
  ncols   = ndims(1)
  ntimes  = ndims(2)

  xlon  = traj_data(:,3,:)
  xlat  = traj_data(:,4,:)
  xpres = traj_data(:,7,:)/100.

  ; convert to 1-D for easy where processing
  clat = ndtooned(xlat)
  clon = ndtooned(xlon)
  cpres = ndtooned(xpres)

  ; filter only storms with SLP less than prescut
  clat = where(cpres.lt.prescut,clat,clat@_FillValue)
  clon = where(cpres.lt.prescut,clon,clon@_FillValue)

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
  countArr(z,:,:) = count1

  delete(traj_data)
  delete(nstorms)
  delete([/xlon,xlat,xpres/])
  delete([/clon,clat,cpres/])
  delete(count1)

end do



count_diff = countArr(0,:,:)
count_diff = countArr(1,:,:) - countArr(0,:,:)



if (.not. plot_diff_abs) then
  countArr = where(countArr.eq.0, countArr@_FillValue,countArr)
  count_diff = where(count_diff.eq.0, count_diff@_FillValue,count_diff)
  count_diff = 100. * count_diff / countArr(0,:,:)
  count_diff = where(countArr(1,:,:) .ge. 48., count_diff, count_diff@_FillValue)
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
res@gsnRightString       = "per gridbox"

; plot absolute data

  res@cnLevelSelectionMode  = "ManualLevels"
  res@cnMinLevelValF        = 48.0
  res@cnMaxLevelValF        = 720.0
  res@cnLevelSpacingF       = res@cnMaxLevelValF/24.


cmap = read_colormap_file("GMT_hot")
res@cnFillPalette=cmap(::-1,:)
delete(cmap)

  CATSTR="all ETCs"


res@gsnLeftString       = "FixedSST"
plot(0) = gsn_csm_contour_map_ce(wks,countArr(0,:,:),res)
res@gsnLeftString       = "SLAB2"
plot(1) = gsn_csm_contour_map_ce(wks,countArr(1,:,:),res)
print("max countArr(0,:,:) "+max(countArr(0,:,:)))
print("max countArr(1,:,:) "+max(countArr(1,:,:)))

; plot differences
res@cnLevelSelectionMode  = "ManualLevels"
if (plot_diff_abs) then
  res@cnMinLevelValF        = -48.0
  res@cnMaxLevelValF        = 48.0
  res@cnLevelSpacingF       = (res@cnMaxLevelValF-res@cnMinLevelValF)/12.
else
  res@cnMinLevelValF        = -100.0
  res@cnMaxLevelValF        = 100.0
  res@cnLevelSpacingF       = res@cnMaxLevelValF/10.
end if

delete(res@cnFillPalette)
res@cnFillPalette=colorMap2

res@gsnLeftString       = "Diff."
plot(2) = gsn_csm_contour_map_ce(wks,count_diff(:,:),res)
print("max count_diff(:,:) "+max(count_diff(:,:)))

resP = True
resP@txString           = ""
resP@amJust           = "TopLeft"
resP@gsnPanelFigureStringsFontHeightF = 0.02
  resP@gsnPanelFigureStrings= (/"a.","b.","c."/)


gsn_panel(wks,plot,(/3,1/),resP)

end
