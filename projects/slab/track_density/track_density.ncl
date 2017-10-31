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
load "/glade/u/home/zarzycki/ncl/functions/plot_outline_fcn.ncl"
;load "calc_area.ncl"  

begin

;=================== User Settings ================================
plot_diff=False
panelStr="c."
;trajFile1="/glade/u/home/zarzycki/ocn-tc-cooling-nhemi_30_x4/tracking/cat_traj_fixedSST_900.txt"
;trajFile1="/glade/u/home/zarzycki/ocn-tc-cooling-nhemi_30_x4/tracking/cat_traj_slab_08_4.7_900.txt"
trajFile1="/glade/u/home/zarzycki/ocn-tc-cooling-nhemi_30_x4/tracking/cat_traj_slab2_08_4.7_900.txt"

domask = 1 ; 0 = true, 1 = false
maskbasin = 1

gridsize = 5.0

; valid values are tstorm, hurricane, or anything else for no cut
cuttype = "tstorm"

out_type = "pdf"

wind_factor = 0.85

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

onedwind = where(onedlat.gt.0.0.and.onedlat.lt.55.0,onedwind,onedwind@_FillValue)
onedlat  = where(onedlat.gt.0.0.and.onedlat.lt.55.0,onedlat,onedlat@_FillValue)
onedlon  = where(onedlat.gt.0.0.and.onedlat.lt.55.0,onedlon,onedlon@_FillValue)

onedwind = where(onedlon.gt.100.0.and.onedlon.lt.359.0,onedwind,onedwind@_FillValue)
onedlat  = where(onedlon.gt.100.0.and.onedlon.lt.359.0,onedlat,onedlat@_FillValue)
onedlon  = where(onedlon.gt.100.0.and.onedlon.lt.359.0,onedlon,onedlon@_FillValue)

onedwind = where(onedmonth.lt.6 .or. onedmonth.gt.11 , onedwind@_FillValue, onedwind) 
onedlat  = where(onedmonth.lt.6 .or. onedmonth.gt.11 , onedlat@_FillValue, onedlat) 
onedlon  = where(onedmonth.lt.6 .or. onedmonth.gt.11 , onedlon@_FillValue, onedlon) 

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

delete(clon)
delete(clat)
delete(jl)
delete(il)
delete(n)

;--- Read data

count = 0

do z = 0,nfiles-1
 
print("Plotting data from tracker")
traj_cleanfile = "traj_file.TMP"

traj_filename = trajFile1
if (plot_diff .and. z .gt. 0) then
  traj_filename = trajFile2
end if

print("Removing text headers from trajectories")
system("grep -v '^start' "+traj_filename +" > "+traj_cleanfile+"")

traj_ncols = numAsciiCol(traj_cleanfile)
; Given the # of columns, we can use readAsciiTable to read this file.
traj_data = readAsciiTable(traj_cleanfile,traj_ncols,"float",0)
traj_nrows = dimsizes(traj_data(:,0))    ; calculate # of rows

print("'" + traj_cleanfile + "' has " + traj_nrows + " rows and " + traj_ncols + \
      " columns of data.")

print("Removing temporary file:"+traj_cleanfile)
system("rm -rf "+traj_cleanfile)

clat = traj_data(:,4)
clon = traj_data(:,3)
cwind = traj_data(:,5)*wind_factor

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

print("count: min="+min(count(z,:,:))+"   max="+max(count(z,:,:)))
print("count: sum="+sum(count(z,:,:)))

delete(jl)
delete(il)
delete(n)
delete(clat)
delete(clon)
delete(cwind)
delete(traj_data)
delete(traj_nrows)
delete(traj_ncols)

end do

count_obs = where(count_obs.eq.0, count_obs@_FillValue,count_obs)
count = where(count.eq.0, count@_FillValue,count)

if (0 .eq. 1) then
  count_obs=count_obs/(sum(count_obs))
  do i = 0,ncount-1
    count(i,:,:)=count(i,:,:)/(sum(count(i,:,:)))
  end do
  print(max(count_obs))
end if

;count_obs=count_obs/26.
;do i = 0,ncount-1
;  count(i,:,:)=count(i,:,:)/25.
;end do
;print(max(count_obs))


count_diff=count
do i = 0,ncount-1
  count_diff(i,:,:) = count(i,:,:)-count_obs(:,:)
  print(sum(abs(count_diff(i,:,:))))
end do
print(max(abs(count_diff)))

if (plot_diff)
  gauwgts = cos(0.01745329*lat)
  ra = pattern_cor(count(0,:,:), count(1,:,:), gauwgts, 1)
  print("Uncentered "+ra)
  ra = pattern_cor(count(0,:,:), count(1,:,:), gauwgts, 0)
  print("Centered "+ra)
end if

tcMask = mask_tc(0,-999,-999,gridsize/2,toint(lonE))

if (domask .eq. 0)
do i = 0,nlat-1
do j = 0,mlon-1
  if (tcMask({lat(i)},{lon(j)}) .ne. maskbasin)
    count(:,i,j) = count@_FillValue
  end if
end do
end do
end if

;************************************************
; create plot
;************************************************

  wks = gsn_open_wks(out_type,"dens_camse_vr_"+cuttype)
  plot = new(3,"graphic")

  colorMap1="BlAqGrYeOrRe"
  colorMap2="temp_diff_18lev"
;   colors = read_colormap_file(colorMap1)
;   numColors1=dimsizes(colors(:,0))
;   print(numColors1)
;   delete(colors)
;   colors = read_colormap_file(colorMap2)
;   numColors2=dimsizes(colors(:,0))
;   print(numColors2)
;   delete(colors) 
;   stcolor1=2
;   encolor1=numColors1+1
;   stcolor2=numColors1+2
;   encolor2=numColors1+numColors2+1



  res                       = True     ; plot mods desired
  res@gsnMaximize           = True
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

    res@cnLevelSelectionMode  = "ManualLevels"
    res@cnMinLevelValF        = 0.0
    res@cnMaxLevelValF        = 400.0
    res@cnLevelSpacingF       = res@cnMaxLevelValF/20.

;  res@lbTitleString = "#"
;  res@lbTitlePosition  = "Right"              ; title position
;  res@lbTitleFontHeightF= .02                ; make title smaller
;  res@lbTitleDirection = "Across"             ; title direction
;  res@lbTitleExtentF = 0.01
  

    ;res@lbLabelBarOn = False
  ;res@lbLabelAutoStride     = True
  res@lbLabelStride = 2

  res@mpMinLatF             = 0
  res@mpMaxLatF             = 60
  res@mpMinLonF             = 95
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
  

    res@gsnCenterString       = "CAM-SE TCs "+cutname

;  res@lbTitleOn        = True                  ; turn on title
;  res@lbTitleString    = "Total number of cyclone counts"
; res@gsnRightString        = "Count"

  res@cnFillPalette=colorMap1
plot(0) = gsn_csm_contour_map_ce(wks,count(0,:,:),res)
;plot(0) = gsn_csm_contour_map_ce(wks,count_obs(:,:),res)

if (plot_diff)
    res@cnFillPalette=colorMap2
    res@cnLevelSelectionMode  = "ManualLevels"
    res@cnMinLevelValF        = -25.0
    res@cnMaxLevelValF        =  25.0
    res@cnLevelSpacingF       =  2.5
  plot(1) = gsn_csm_contour_map_ce(wks,count_diff(0,:,:),res)
  plot(2) = gsn_csm_contour_map_ce(wks,count_diff(1,:,:),res)
end if

resP = True
resP@amJust           = "TopLeft"



resP@gsnPanelFigureStringsFontHeightF = 0.04
if (plot_diff) then
  resP@gsnPanelFigureStrings= (/"a.","b.","c."/)
  gsn_panel(wks,plot,(/3,1/),resP)
else
  resP@gsnPanelFigureStrings= (/panelStr/)
  gsn_panel(wks,plot,(/1,1/),resP)
end if

end
