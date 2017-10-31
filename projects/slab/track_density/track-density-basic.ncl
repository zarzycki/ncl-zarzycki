;=================== Description ==================================
; This script reads in either iBTracs data or data from the GFDL
; tracking code and plots a track density plot for a specific ocean
; basin
;==================================================================

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin

;=================== User Settings ================================
plot_diff=True
trajFile1="/glade/u/home/zarzycki/ocn-tc-cooling-nhemi_30_x4/tracking/cat_traj_fixedSST_900.txt"

gridsize = 4.0

; valid values are tstorm, hurricane, or anything else for no cut
cuttype = "none"

out_type = "x11"

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

count     = new( (/nlat,mlon/), "float", 1e20) 
count!0   = "lat"
count!1   = "lon"
count&lat =  lat
count&lon =  lon

;--- Read data

count = 0
 
print("Plotting data from tracker")
traj_cleanfile = "traj_file.TMP"

traj_filename = trajFile1

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
   count(jl,il) = count(jl,il) + 1
   end if
end do

print("count: min="+min(count(:,:))+"   max="+max(count(:,:)))
print("count: sum="+sum(count(:,:)))

delete(jl)
delete(il)
delete(n)
delete(clat)
delete(clon)
delete(cwind)
delete(traj_data)
delete(traj_nrows)
delete(traj_ncols)

count = where(count.eq.0, count@_FillValue,count)

;************************************************
; create plot
;************************************************

  wks = gsn_open_wks(out_type,"dens_camse_vr_"+cuttype)
  plot = new(3,"graphic")

  colorMap1="BlAqGrYeOrRe"

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
  
  res@cnLevelSelectionMode  = "ManualLevels"
  res@cnMinLevelValF        = 0
  res@cnMaxLevelValF        = max(count)-.2*max(count)
  res@cnLevelSpacingF       = res@cnMaxLevelValF/30.


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
  

    res@gsnCenterString       = "CAM-SE Var-Res Storms "+cutname

;  res@lbTitleOn        = True                  ; turn on title
;  res@lbTitleString    = "Total number of cyclone counts"
; res@gsnRightString        = "Count"

  res@cnFillPalette=colorMap1
plot(0) = gsn_csm_contour_map_ce(wks,count(:,:),res)

resP = True
resP@amJust           = "TopLeft"



resP@gsnPanelFigureStringsFontHeightF = 0.04

  gsn_panel(wks,plot,(/1,1/),resP)

end
