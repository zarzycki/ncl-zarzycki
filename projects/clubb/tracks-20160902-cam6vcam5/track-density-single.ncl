;=================== Description ==================================
; This script reads in Tempeset
; tracking code and plots a track density
;==================================================================

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "/glade/u/home/zarzycki/ncl/functions/getTrajectories.ncl"
load "/glade/u/home/zarzycki/ncl/functions/trackDensity.ncl"

begin

;=================== User Settings ================================
gridsize = 8.0
out_type = "pdf"
wind_factor = 0.85

; EXAMPLE OF FILTER THRESHOLD
prescut = 99999.0   ; only storms with pres LOWER than this are included. set to 99999.0 for all storms

;======================= Constants ================================
ms_to_kts = 1.94384449

;=================== Get traj data ================================
thefile="trajectories.txt.CAM5"  ; trajectory file full path
ncols = 9 ; number of columns in non-header rows of trajectory file
maxLines = -1  ; set to -1 for auto-detection
traj_data = getTrajectories(thefile,ncols,maxLines)

; load in trajectory data (need to be modified if using different tempest output
xlon  = traj_data(:,1,:)
xlat  = traj_data(:,2,:)
xpres = traj_data(:,3,:)/100.
xwind = traj_data(:,5,:)*wind_factor

; load traj data into 1-D arrays
clat = ndtooned(xlat)
clon = ndtooned(xlon)
cwind = ndtooned(xwind)
cpres = ndtooned(xpres)

; EXAMPLE OF HOW TO FILTER LAT/LON PAIRS BY THRESHOLD
clat = where(cpres.lt.prescut,clat,clat@_FillValue)
clon = where(cpres.lt.prescut,clon,clon@_FillValue)


count = track_density(gridsize,0.0,clat,clon)
nyrs=6.
count = count/nyrs



;************************************************
; create plot
;************************************************

wks = gsn_open_wks(out_type,"out-track-density")
plot = new(1,"graphic")

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

res@lbLabelStride = 2

;res@mpMinLatF             = 0
;res@mpMaxLatF             = 60
;res@mpMinLonF             = 95
;res@mpMaxLonF             = 355
res@mpCenterLonF          = 180.
res@mpGridAndLimbOn       = False  
res@mpGridLineDashPattern = 2             ; Dashed lines
res@mpGridLatSpacingF     = 5.0
res@mpGridLonSpacingF     = 10.0

res@gsnCenterString       = "Storm track density"

res@cnFillPalette=colorMap1
plot(0) = gsn_csm_contour_map_ce(wks,count(:,:),res)

resP = True
resP@amJust           = "TopLeft"

resP@gsnPanelFigureStringsFontHeightF = 0.04

gsn_panel(wks,plot,(/1,1/),resP)

end
