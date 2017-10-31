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
datatoplot = 2
; 0 = ibtracs
; 1 = CAM-SE VR
; 2 = CAM-SE 1 deg

domask = 0 ; 0 = true, 1 = false
maskbasin = 1

gridsize = 4.0

ibstyr = 1980
ibenyr = 2002

; valid values are tstorm, hurricane, or anything else for no cut
cuttype = "tstorm"

out_type = "eps"

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

print("Using windcut: "+windcut+" m/s")

;--- Create desired grid

if (datatoplot .eq. 0) then
  latS =    -90
  latN =   90
  lonW = -180
  lonE =    180
else if (datatoplot .ge. 1) then
  latS =    -90
  latN =   90
  lonW = 0
  lonE =    360
else
end if
end if

  dlat =  gridsize
  dlon =  gridsize

  nlat = toint((latN-latS)/dlat) + 1
  mlon = toint((lonE-lonW)/dlon)

  lat  = fspan(latS, latN, nlat)
  lon  = fspan(lonW, lonE-dlon, mlon)

  lat@units = "degrees_north"
  lon@units = "degrees_east"

 ;print(lat)
 ;print(lon)

  count     = new( (/nlat,mlon/), "float", 1e20) 
  count!0   = "lat"
  count!1   = "lon"
  count&lat =  lat
  count&lon =  lon

;--- Read data

count = 0

if (datatoplot .eq. 0) then
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
 
  ; pick center for wind
  center = -999
  if (maskbasin .eq. 1) then
    center = 0
  else if (maskbasin .eq. 2) then
    center = 14 ; hurdat_epac
  end if
  end if
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
  
  onedwind = where(onedwind.ge.windcut,onedwind,onedwind@_FillValue)  
  onedlat = where(onedwind.ge.windcut,onedlat,onedlat@_FillValue)
  onedlon = where(onedwind.ge.windcut,onedlon,onedlon@_FillValue)
  
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
  
  ;ibwind2 = onedtond(onedwind,dimsizes(ibwind_))
  ;iblat2 = onedtond(onedlat,dimsizes(iblat))
  ;iblon2 = onedtond(onedlon,dimsizes(iblat))
  
  ;ibdimsizes = dimsizes(iblat)
  ;ibnumstorms = ibdimsizes(0)
 
 print("Starting loop over iBtracks data")
 
  do n=0,npts-1
     if(all(ismissing(clon(n)))) then
     else
     jl = toint((clat(n)-latS)/dlat) 
     il = toint((clon(n)-lonW)/dlon)
     if (il .gt. mlon-1) then
       print(il)
       il = 0
     end if
     count(jl,il) = count(jl,il) + 1
     end if
  end do
  
  
 
;;; do ii=0,ibnumstorms-1
;;;   clat = iblat2(ii,:)
;;;   clon = iblon2(ii,:)
;;;   npts = num(.not.ismissing(clat))
;;; ;  print("Doing storm "+ii+" of "+ibnumstorms)
;;; 
;;; 
;;; ;--- Bin data
;;; 
;;;   do n=0,npts-1
;;;   ;do n=0,dimsizes(onedlat)-1
;;;      if (ibyear(ii) .ge. ibstyr .and. ibyear(ii) .le. ibenyr .and. ibtype(ii,n) .eq. 0) then
;;;        ;if (n .eq. 0 .and. mod(ii,5) .eq. 0) ; 
;;;           ;print("Binning storm # "+ii)
;;;        ;end if
;;;        if(all(ismissing(clon(n)))) then
;;;        else
;;;          jl = toint((clat(n)-latS)/dlat) 
;;;          il = toint((clon(n)-lonW)/dlon)
;;;          if (il .gt. mlon-1) then
;;;            ;print(il)
;;;            il = 0
;;;          end if
;;;          count(jl,il) = count(jl,il) + 1
;;;        end if
;;;      else
;;;      end if
;;;   end do
;;;   
;;;   delete(clat)
;;;   delete(clon)
;;; 
;;; end do
 
else if (datatoplot .ge. 1) then
  print("Plotting data from tracker")

  traj_dir = "/glade/u/home/zarzycki/tcstats/FinalJAMESPaper/"
  if (datatoplot .eq. 1) then
    traj_filename = "traj_vr"
  else if (datatoplot .eq. 2) then
    traj_filename = "traj_1deg"
  else
  end if
  end if
  traj_cleanfile = "traj_filt_clean.TMP"

  print("Removing text headers from trajectories")
  system("grep -v '^start' "+ traj_dir+traj_filename +" > "+traj_cleanfile+"")
  
  traj_ncols = numAsciiCol(traj_cleanfile)
  ; Given the # of columns, we can use readAsciiTable to read this file.
  traj_data = readAsciiTable(traj_cleanfile,traj_ncols,"float",0)
  traj_nrows = dimsizes(traj_data(:,0))    ; calculate # of rows
  
  print("'" + traj_cleanfile + "' has " + traj_nrows + " rows and " + traj_ncols + \
        " columns of data.")
  
  print("Removing temporary file:"+traj_cleanfile)
  system("rm -rf "+traj_cleanfile)
  
  

  clat = traj_data(:,1)
  clon = traj_data(:,0)
  cwind = traj_data(:,2)*wind_factor
  
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
     count(jl,il) = count(jl,il) + 1
     end if
  end do

else
end if
end if



count = where(count.eq.0, count@_FillValue,count)

tcMask = mask_tc(0,-999,-999,gridsize/2,toint(lonE))

if (domask .eq. 0)
do i = 0,nlat-1
  do j = 0,mlon-1
    if (tcMask({lat(i)},{lon(j)}) .ne. maskbasin)
      count(i,j) = count@_FillValue
    end if
  end do
end do
end if

print("count: min="+min(count)+"   max="+max(count))
print("count: sum="+sum(count))
  
;************************************************
; create plot
;************************************************

if (datatoplot .eq. 0) then
  wks = gsn_open_wks(out_type,"dens_ibtracs_"+cuttype)                ; open a ps file
else if (datatoplot .eq. 1) then
  wks = gsn_open_wks(out_type,"dens_camse_vr_"+cuttype)                ; open a ps file
else if (datatoplot .eq. 2) then
  wks = gsn_open_wks(out_type,"dens_camse_1deg_"+cuttype)                ; open a ps file
else
end if
end if
end if

  gsn_define_colormap(wks,"BlAqGrYeOrReVi200")        ; choose colormap

  res                       = True     ; plot mods desired
  res@gsnMaximize           = True
  res@gsnDraw = False
  res@gsnFrame = False
  res@gsnSpreadColors       = True     ; use full range of color map
  res@gsnAddCyclic          = False    

  res@cnFillOn              = True     ; turn on color fill
  res@cnFillMode            = "RasterFill"       ; Raster Mode
  res@cnLinesOn             = False    ; turn of contour lines
  res@cnLineLabelsOn  = False
  

  if (cuttype .eq. "tstorm")
    res@cnLevelSelectionMode  = "ManualLevels"
    res@cnMinLevelValF        = 0
    res@cnMaxLevelValF        = 80
    res@cnLevelSpacingF       = 4
  else if (cuttype .eq. "hurricane")
    res@cnLevelSelectionMode  = "ManualLevels"
    res@cnMinLevelValF        = 0
    res@cnMaxLevelValF        = 51
    res@cnLevelSpacingF       = 3
  else
    windcut = 0.01
  end if
  end if

;  res@lbTitleString = "#"
;  res@lbTitlePosition  = "Right"              ; title position
;  res@lbTitleFontHeightF= .02                ; make title smaller
;  res@lbTitleDirection = "Across"             ; title direction
;  res@lbTitleExtentF = 0.01
  
  if (datatoplot .ge. 1) then
    res@lbLabelBarOn = False
  end if
  ;res@lbLabelAutoStride     = True
  res@lbLabelStride = 2

  res@mpMinLatF             = 0
  res@mpMaxLatF             = 50
  res@mpMinLonF             = -105
  res@mpMaxLonF             = -10
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
  
  if (datatoplot .eq. 0) then
    res@gsnCenterString       = "IBTrACS Storms "+cutname
  else if (datatoplot .eq. 1) then
    res@gsnCenterString       = "CAM-SE Var-Res Storms "+cutname
  else if (datatoplot .eq. 2) then
    res@gsnCenterString       = "CAM-SE 1~S~o~N~ Storms "+cutname
  else
  end if
  end if
  end if

;  res@lbTitleOn        = True                  ; turn on title
;  res@lbTitleString    = "Total number of cyclone counts"
; res@gsnRightString        = "Count"

  plot = gsn_csm_contour_map_ce(wks,count, res)

resP = True
resP@amJust           = "TopLeft"
if (datatoplot .eq. 2 .and. cuttype .eq. "tstorm") then
  resP@gsnPanelFigureStrings= (/"a."/)
else if (datatoplot .eq. 1 .and. cuttype .eq. "tstorm") then
  resP@gsnPanelFigureStrings= (/"b."/)
else if (datatoplot .eq. 0 .and. cuttype .eq. "tstorm") then
  resP@gsnPanelFigureStrings= (/"c."/)
else if (datatoplot .eq. 2 .and. cuttype .eq. "hurricane") then
  resP@gsnPanelFigureStrings= (/"d."/)
else if (datatoplot .eq. 1 .and. cuttype .eq. "hurricane") then
  resP@gsnPanelFigureStrings= (/"e."/)
else if (datatoplot .eq. 0 .and. cuttype .eq. "hurricane") then
  resP@gsnPanelFigureStrings= (/"f."/)
else
  resP@gsnPanelFigureStrings= (/"X."/)
end if
end if
end if
end if
end if
end if
resP@gsnPanelFigureStringsFontHeightF = 0.04
gsn_panel(wks,plot,(/1,1/),resP)             ; now draw as one plot

end
