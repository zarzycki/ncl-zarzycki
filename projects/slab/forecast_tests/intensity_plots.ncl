;========================================================
; TC_cross_and_latlon.ncl:   plots the PS, U, V, and T.
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "../../functions/calc_area.ncl"
;========================================================
begin

models = (/"slab","noslab"/)
outstring = "clubb"
figure_colors = models
nfiles = dimsizes(models)
figure_labels = models
figure_linethck = (/9.0,9.0,9.0,9.0,9.0/)

deltatime = 21

psminplot = new((/nfiles,deltatime/),float)
windmaxplot = new((/nfiles,deltatime/),float)
psmin_lat_loc = new((/nfiles,deltatime/),double)
psmin_lon_loc = new((/nfiles,deltatime/),double)
windmax_lat_loc = new((/nfiles,deltatime/),double)
windmax_lon_loc = new((/nfiles,deltatime/),double)
vrtmax_lat_loc = new((/nfiles,deltatime/),double)
vrtmax_lon_loc = new((/nfiles,deltatime/),double)
rmw_plot = new((/nfiles,deltatime/),double)
ike_plot = new((/nfiles,deltatime/),double)

do filepick = 0,nfiles-1
thisModel = models(filepick)

print("Doing file number: "+(filepick+1)+" of: "+nfiles)

if( thisModel .eq. "slab" ) then 
  all_files = "DART_katrina_2005082600_yes_slab.nc"
  in1      = addfile (all_files, "r")
  figure_colors(filepick) = "red"
end if
if( thisModel .eq. "noslab" ) then 
  all_files = "DART_katrina_2005082600_no_slab.nc"
  in1      = addfile (all_files, "r")
  figure_colors(filepick) = "blue"
end if


;==========Read in data=============


lat = in1->lat
lon = in1->lon
time = in1->time

PS1  = in1->PSL

nlat = dimsizes(lat)
nlon = dimsizes(lon)

wind = in1->U10

psmin = new(deltatime,float)
windmax = new(deltatime,float)
psminlat = new (deltatime,double)
psminlon = new (deltatime,double)
windmaxlat = new (deltatime,double)
windmaxlon = new (deltatime,double)
 
do j = 0,deltatime-1

psmin(j) = min(PS1(j,:,:))

windmax(j) = max(wind(j,:,:))

    
    ;---FIND LOCATIONS OF PSMIN and WINDMAX
    ;---Convert to 1D
    a = new((/nlat,nlon/),float)
    a(:,:) = PS1(j,:,:)
    a1D      = ndtooned(a)
    dsizes_a = dimsizes(a)
    ;---Resolve the 1D indices back to their original 3D array.
    a_indices  = ind_resolve(minind(a1D),dsizes_a)  
    ;---Convert index to lat/lon points
    psminlat(j) = lat(a_indices(0,0))
    psminlon(j) = lon(a_indices(0,1))
    

      b = new((/nlat,nlon/),float)
      b(:,:) = wind(j,:,:)
      b1D      = ndtooned(b)
      dsizes_b = dimsizes(b)
      b_indices  = ind_resolve(maxind(b1D),dsizes_b)
      windmaxlat(j) = lat(b_indices(0,0))
      windmaxlon(j) = lon(b_indices(0,1))
 
    
    ;============Clean up==========================
    delete(a1D)
    delete(b1D)
    delete(dsizes_a)
    delete(dsizes_b)
    delete(a_indices)
    delete(b_indices)

         
end do

;============Rewrite value per resolution==========================
 
 psminplot(filepick,:) = psmin
 windmaxplot(filepick,:) = windmax
 psmin_lat_loc(filepick,:) = psminlat
 psmin_lon_loc(filepick,:) = psminlon
 windmax_lat_loc(filepick,:) = windmaxlat
 windmax_lon_loc(filepick,:) = windmaxlon

 delete(PS1)
 delete(psmin)
; delete(T)
 delete(wind)
; delete(vr)
 delete(windmax)
 delete(psminlat)
 delete(psminlon)
 delete(windmaxlat)
 delete(windmaxlon)
; delete(vrtmaxlat)
; delete(vrtmaxlon)

 delete(lat)
 delete(lon)
 delete(nlat)
 delete(nlon)

 delete(b)
 delete(a)
 
 ;list_vars()
 
 end do
 
;**************
; GENERAL RESOLUTION PARAMETERS
;**************

resgen = True

resgen@xyExplicitLegendLabels = figure_labels ; create explicit labels 
resgen@xyLineColors       = figure_colors  ; 4 different color
resgen@xyLineThicknesses  = figure_linethck               ; change line thickness

resgen@pmLegendDisplayMode    = "Always"                      ; turn on legend

resgen@tmXBMajorOutwardLengthF = 0.0                          ; draw tickmarks inward
resgen@tmXBMinorOutwardLengthF = 0.0                          ; draw minor ticsk inward
resgen@tmYLMajorOutwardLengthF = 0.0                          ; draw tickmarks inward
resgen@tmYLMinorOutwardLengthF = 0.0                          ; draw minor ticsk inward
resgen@lgLabelFontHeightF     = .02  

resgen@tiXAxisString           = ""                           ; turn off axis label
resgen@tiYAxisString           = ""                           ; turn off axis label

resgen@xyMonoLineThickness = True
resgen@xyLineThicknessF = 3

;************************************************
; PLOT MINIMUM SURFACE PRESSURE
;************************************************
 wks   = gsn_open_wks ("pdf","pdf/xy_sfcpres_"+outstring)                  ; open workstation
 
 res                        = resgen                          ; turn on plot resources

res@gsnDraw          = False
res@gsnFrame         = False
 
 res@lgAutoManage = False
 res@pmLegendSide           = "Bottom"                      ; Change location of 
 res@pmLegendParallelPosF   = .32                           ; move units right
 res@pmLegendOrthogonalPosF = -.40                         ; move units down
 res@pmLegendWidthF         = 0.1                          ; Change width and
 res@pmLegendHeightF        = 0.1                           ; height of legend.
 res@lgPerimOn              = False                         ; turn off box around
 res@lgLabelFontHeightF     = .015                          ; label font height

 ;res@tiMainString           = "Intensity comparison w/ refinement"
 res@tiMainFontHeightF      = 0.02
 res@tiXAxisString          = "Days"
 res@tiYAxisString          = "MSLP (hPa)"
; res@trYMinF                =  840.0 
 plot  = gsn_csm_xy (wks,time(0:deltatime-1),psminplot/100,res) ; create plot
 
 ;res2                        = True
 ;res2@gsnDraw          = False
 ;res2@gsnFrame         = False
 ;res2@xyLineColors       = "red"
 ;res2@xyDashPattern          = 0                             ; Make curves all solid
 ;plot1  = gsn_csm_xy (wks,time,pstopbnd/100,res2) ; create plot
 ;plot2  = gsn_csm_xy (wks,time,psbotbnd/100,res2) ; create plot
 
; 
; res3                        = True
; gray = NhlNewColor(wks,0.8,0.8,0.8)       ; add color to colormap
; res3@gsnDraw          = False
; res3@gsnFrame         = False
; res3@gsnXYFillColors = gray
; res3@xyLineColor     = -1                           ; We don't want the line, so make it transparent.
; plot3  = gsn_csm_xy (wks,time,psbnd/100,res3)  ; Create filled XY plot.
; 
; overlay(plot,plot3)
; 
; delete(res3)
 
 draw(plot)
 frame(wks)
 
 delete(res)
 
;************************************************
; PLOT MAXIMUM WIND SPEED
;************************************************

 wks   = gsn_open_wks ("pdf","pdf/xy_windmax_"+outstring)                  ; open workstation

 res                        = resgen                          ; turn on plot resources

 res@lgAutoManage = True
 res@pmLegendSide           = "Bottom"                      ; Change location of 
 res@pmLegendParallelPosF   = .20                           ; move units right
 res@pmLegendOrthogonalPosF = -1.15                         ; move units down
 res@pmLegendWidthF         = 0.15                          ; Change width and
 res@pmLegendHeightF        = 0.1                           ; height of legend.
 res@lgPerimOn              = False                         ; turn off box around
 res@lgLabelFontHeightF     = .02                           ; label font height

 ;res@tiMainString           = ""
 res@tiXAxisString          = "Days"
 res@tiYAxisString          = "Wind (m/s)"

 plot  = gsn_csm_xy (wks,time(0:deltatime-1),windmaxplot,res) ; create plot

 delete(res)
 
;************************************************
; PLOT TRAJECTORY
;************************************************
   wks = gsn_open_wks("pdf","pdf/xy_traj_"+outstring)               ; open workstation
   res            = resgen                          ; map resources
   res@gsnDraw    = False                         ; don't draw
   res@gsnFrame   = False                         ; don't advance frame

   res@tiMainString    = "Example of a trajectory plot"  ; title
;   res@gsnCenterString = "markers every 4th time step"   ; center string
  
;   map = gsn_csm_map(wks,res)                  ; create map
   
   
  map = gsn_csm_xy(wks,psmin_lon_loc(:,:),psmin_lat_loc(:,:),res)
;map = gsn_csm_xy(wks,vrtmax_lon_loc(:,:),vrtmax_lat_loc(:,:),res)

   mres  = True                               ; marker resources
   first = True                               ; start of traj resources

; add markers to the trajectories

;      mres@gsMarkerIndex  = 16           ; marker style (circle)
;      mres@gsMarkerSizeF  = 4.0          ; marker size
;      mres@gsMarkerColor  = "red"      ; maker color
;      gsn_polymarker(wks,map,psmin_lon_loc(::4),psmin_lat_loc(::4),mres) ; draw every 4th marker

; create a unique marker to indicate the start of the trajectory

      first@gsMarkerSizeF  = 8.0         ; marker size
      first@gsMarkerColor  = "red"     ; marker color

      gsn_polymarker(wks,map,psmin_lon_loc(:,0),psmin_lat_loc(:,0),first) ; draw start of traj
      delete(first@gsMarkerColor)
      delete(first@gsMarkerSizeF)            

   draw(map)

delete(res)
 
end

