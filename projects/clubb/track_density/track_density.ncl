;=================== Description ==================================
; This script reads in either iBTracs data or data from the GFDL
; tracking code and plots a track density plot for a specific ocean
; basin
;==================================================================

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "/glade/u/home/zarzycki/ncl/functions/mask_tc.ncl"
load "/glade/u/home/zarzycki/ncl/functions/getTrajectories.ncl"
load "/glade/u/home/zarzycki/ncl/functions/surfaceWindCorrFactor.ncl"
;load "calc_area.ncl"  

begin

;=================== User Settings ================================
plot_diff=True

traj_dir = (/"/glade/scratch/zarzycki/clubb-tracking/CAM5_ALL/","/glade/scratch/zarzycki/clubb-tracking/CLUBB/"/)
traj_filename = (/"trajectories.txt.CAM5","trajectories.txt.CLUBB"/)
traj_name=(/"CAM5","CLUBB"/)
traj_numyrs=(/7,2/)

gridsize = 8.0

; valid values are tstorm, hurricane, or anything else for no cut
cuttype = "tstorm"

out_type = "pdf"

;-----------------Calc wind speed correction----------------

factor = surfaceWindCorrFactor(-1,-1,"log")

;===================================================================
ms_to_kts = 1.94384449

if (cuttype .eq. "tstorm")
  windcut = 17.01
else if (cuttype .eq. "hurricane")
  windcut = 33.01
else
  windcut = 0.01
end if
end if

;===================================================================

print("Using windcut: "+windcut+" m/s")

;--- Create desired grid

latS = -90
latN = 90
lonW = 0
lonE = 360

dlat =  gridsize
dlon =  gridsize

nlat = toint((latN-latS)/dlat) + 1
mlon = toint((lonE-lonW)/dlon)

lat  = fspan(latS, latN, nlat)
lon  = fspan(lonW, lonE-dlon, mlon)

lat@units = "degrees_north"
lon@units = "degrees_east"

if (plot_diff) then
  nfiles=2
  ncount=3
else
  nfiles=1
  ncount=1
end if
count     = new( (/ncount,nlat,mlon/), "float", 1e20) 
count!1   = "lat"
count!2   = "lon"
count&lat =  lat
count&lon =  lon

count_obs = count(0,:,:)

;------------------------------------------------ GET IBTRACS

ibstyr=1980
ibenyr=2005
ibyrstot=ibenyr-ibstyr+1

print("Plotting iBtracks data from: "+ibstyr+" to "+ibenyr)

; READ IBTRACS
print("Loading data, this may take awhile.")
ibdir = "/glade/u/home/zarzycki/work/ibtracs/"
ibfilename="Allstorms.ibtracs_all.v03r04.nc.nc"

ibfile = addfile(ibdir+ibfilename,"r")
iblat = ibfile->lat_for_mapping*.01
iblon = ibfile->lon_for_mapping*.01
ibyear = toint(ibfile->season)
ibtype = toint(ibfile->nature_for_mapping)
ibwind = ibfile->source_wind(:,:,:)*.1/ms_to_kts
ibtime = ibfile->source_time

; pick center for wind
center = -999
if (center .ge. 0) then
  print("We are only using center number "+center+" from ibTracs data")
else
  print("We are using all centers available for a particular storm. Use with CAUTION")
end if
if (center .lt. 0) then
  ; average over available values since we aren't sure which center
  ; from ibtracs to use
  ibwind_ = dim_avg_n_Wrap(ibwind,2)
else
  ; we have specified the center we would like to use
  ibwind_ = ibwind(:,:,center)
end if

onedwind = ndtooned(ibwind_)
onedlat = ndtooned(iblat)
onedlon = ndtooned(iblon)
onedtype = ndtooned(ibtype)
onedyear = ndtooned(conform_dims(dimsizes(iblat),ibyear,0))
onedtime = ndtooned(ibtime)
onedtime@units=ibtime@units
utc_date = cd_calendar(onedtime, 0)
onedmonth = utc_date(:,1)

onedlon = where(onedlon.lt.0,onedlon+360.,onedlon)

onedwind = where(onedwind.ge.windcut,onedwind,onedwind@_FillValue)  
onedlat  = where(onedwind.ge.windcut,onedlat,onedlat@_FillValue)
onedlon  = where(onedwind.ge.windcut,onedlon,onedlon@_FillValue)

onedwind = where(onedtype.eq.0,onedwind,onedwind@_FillValue)
onedlat = where(onedtype.eq.0,onedlat,onedlat@_FillValue)
onedlon = where(onedtype.eq.0,onedlon,onedlon@_FillValue)

onedwind = where(onedyear.lt.ibstyr,onedwind@_FillValue,onedwind)
onedlat = where(onedyear.lt.ibstyr,onedlat@_FillValue,onedlat)
onedlon = where(onedyear.lt.ibstyr,onedlon@_FillValue,onedlon)

onedwind = where(onedyear.gt.ibenyr,onedwind@_FillValue,onedwind)
onedlat = where(onedyear.gt.ibenyr,onedlat@_FillValue,onedlat)
onedlon = where(onedyear.gt.ibenyr,onedlon@_FillValue,onedlon)

npts = dimsizes(onedwind)

clon = onedlon
clat = onedlat

print("Starting loop over iBtracks data")

count_obs=0
do n=0,npts-1
   if(all(ismissing(clon(n)))) then
   else
   jl = toint((clat(n)-latS)/dlat) 
   il = toint((clon(n)-lonW)/dlon)
   if (il .gt. mlon-1) then
     print(il)
     il = 0
   end if
   count_obs(jl,il) = count_obs(jl,il) + 1
   end if
end do


  print("Normalizing ibyears")
  count_obs=tofloat(count_obs)/tofloat(ibyrstot)

print("count_obs: min="+min(count_obs)+"   max="+max(count_obs))
print("count_obs: sum="+sum(count_obs))


delete(clon)
delete(clat)
delete(jl)
delete(il)
delete(n)

;--- Read data

count = 0

do z = 0,nfiles-1

  print("Read in TC locations from CAM")
  ncols = 12                     ; assign number of columns
  maxLines = -1

  traj_data = getTrajectories(traj_dir(z)+"/"+traj_filename(z),ncols,maxLines)
  traj_lon = traj_data(:,1,:)
  traj_lat = traj_data(:,2,:)
  traj_wind = traj_data(:,5,:)*factor

  clat=ndtooned(traj_lat)
  clon=ndtooned(traj_lon)
  cwind=ndtooned(traj_wind)

  clat = where(cwind.ge.windcut,clat,clat@_FillValue)
  clon = where(cwind.ge.windcut,clon,clon@_FillValue)

  npts = dimsizes(clat)

  do n=0,npts-1
     if(all(ismissing(clon(n)))) then
     else
     jl = toint((clat(n)-latS)/dlat) 
     il = toint((clon(n)-lonW)/dlon)
     if (il .gt. mlon-1) then
       print(il)
       il = 0
     end if
     count(z,jl,il) = count(z,jl,il) + 1
     end if
  end do

count(z,:,:)=count(z,:,:)/tofloat(traj_numyrs(z))

print("count: min="+min(count(z,:,:))+"   max="+max(count(z,:,:)))
print("count: sum="+sum(count(z,:,:)))

delete(jl)
delete(il)
delete(n)
delete(clat)
delete(clon)
delete(cwind)
delete(traj_data)
delete(traj_lon)
delete(traj_lat)
delete(traj_wind)
delete(maxLines)
delete(ncols)

end do

count_obs = where(count_obs.eq.0, count_obs@_FillValue,count_obs)
count = where(count.eq.0, count@_FillValue,count)

;count_obs=count_obs/(sum(count_obs))
;do i = 0,ncount-1
;  count(i,:,:)=count(i,:,:)/(sum(count(i,:,:)))
;end do
;print(max(count_obs))
;
;count_diff=count
;do i = 0,ncount-1
;  count_diff(i,:,:) = count(i,:,:)-count_obs(:,:)
;  print(sum(abs(count_diff(i,:,:))))
;end do
;print(max(abs(count_diff)))

;************************************************
; create plot
;************************************************

  wks = gsn_open_wks(out_type,"dens_camse_vr_"+cuttype)
  plot = new(3,"graphic")

  colorMap1="BlAqGrYeOrRe"
  colorMap2="temp_diff_18lev"




  res                       = True     ; plot mods desired
  res@gsnDraw = False
  res@gsnFrame = False
  ;res@gsnSpreadColors       = True     ; use full range of color map
  res@gsnAddCyclic          = False    

  res@cnFillOn              = True     ; turn on color fill
  res@cnFillMode            = "RasterFill"       ; Raster Mode
  res@cnLinesOn             = False    ; turn of contour lines
  res@cnLineLabelsOn  = False
  

  if (cuttype .eq. "tstorm")
    ;res@cnLevelSelectionMode  = "ManualLevels"
    ;res@cnMinLevelValF        = 0
    ;res@cnMaxLevelValF        = 80
    ;res@cnLevelSpacingF       = 4
  else if (cuttype .eq. "hurricane")
    ;res@cnLevelSelectionMode  = "ManualLevels"
    ;res@cnMinLevelValF        = 0
    ;res@cnMaxLevelValF        = 51
    ;res@cnLevelSpacingF       = 3
  else
    res@cnLevelSelectionMode  = "ManualLevels"
    res@cnMinLevelValF        = 0
    res@cnMaxLevelValF        = max(count)-.2*max(count)
    res@cnLevelSpacingF       = res@cnMaxLevelValF/20.
  end if
  end if

    res@cnLevelSelectionMode  = "ManualLevels"
    res@cnMinLevelValF        = 0.0
    res@cnMaxLevelValF        = max(count_obs)-.2*max(count_obs)
    res@cnLevelSpacingF       = res@cnMaxLevelValF/20.

;  res@lbTitleString = "#"
;  res@lbTitlePosition  = "Right"              ; title position
;  res@lbTitleFontHeightF= .02                ; make title smaller
;  res@lbTitleDirection = "Across"             ; title direction
;  res@lbTitleExtentF = 0.01
  

    ;res@lbLabelBarOn = False
  ;res@lbLabelAutoStride     = True
  res@lbLabelStride = 2

  res@mpMinLatF             = -50
  res@mpMaxLatF             = 50
  res@mpMinLonF             = 35
  res@mpMaxLonF             = 355
  res@mpCenterLonF          = (lonE+lonW)*0.5
  res@mpGridAndLimbOn       = False  
  res@mpGridLineDashPattern = 2             ; Dashed lines
  res@mpGridLatSpacingF     = 5.0
  res@mpGridLonSpacingF     = 10.0
  
 ;res@gsnLeftString         = "..."
  if (cuttype .eq. "tstorm")
    cutname = "> 17 m/s"
  else if (cuttype .eq. "hurricane")
    cutname = "> 33 m/s"
  else
    cutname = "> 0 m/s"
  end if
  end if
  

res@gsnCenterString       = "TCs "+cutname

;  res@lbTitleOn        = True                  ; turn on title
;  res@lbTitleString    = "Total number of cyclone counts"
; res@gsnRightString        = "Count"

res@cnLevelSelectionMode  = "ManualLevels"
res@cnMinLevelValF        =  0.0
res@cnMaxLevelValF        =  50.0
res@cnLevelSpacingF       =  2.0

res@cnFillPalette=colorMap1
plot(0) = gsn_csm_contour_map_ce(wks,count_obs(:,:),res)
if (plot_diff)

  plot(1) = gsn_csm_contour_map_ce(wks,count(0,:,:),res)
  plot(2) = gsn_csm_contour_map_ce(wks,count(1,:,:),res)
end if

resP = True
resP@amJust           = "TopLeft"



resP@gsnPanelFigureStringsFontHeightF = 0.02
if (plot_diff) then
  resP@gsnPanelFigureStrings= (/"OBS","CAM5","CAM5.5"/)
  gsn_panel(wks,plot,(/3,1/),resP)
else
  gsn_panel(wks,plot,(/1,1/),resP)
end if

end
