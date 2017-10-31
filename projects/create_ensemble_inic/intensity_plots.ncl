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

;models = (/"0001","0002","0003","0004","0005"/)
;models = (/"0005","0006","0007"/)
models = (/"9001","9002","9003","9004","9005","9006","9007","9008","9009","9010","9011","9012","9013","9014","9015","9016","9017","9018","9019","9020"/)
outstring = "katrina_phys_ens"
;figure_colors = (/"red","blue","green","orange","purple"/)
figure_colors = models 
nfiles = dimsizes(models)
figure_labels = models
figure_linethck = models

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

figure_colors(filepick) = "black"
figure_linethck(filepick) = 2.0
print("Doing file number: "+(filepick+1)+" of: "+nfiles)

all_files = "/glade/u/home/zarzycki/scratch/DART_newgulf_30_x4/run/"+thisModel+"/h0.full.nc"
in1      = addfile (all_files, "r")

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

resgen@pmLegendDisplayMode    = "Never"                      ; turn on legend

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
 
; res@lgAutoManage = False
; res@pmLegendSide           = "Bottom"                      ; Change location of 
; res@pmLegendParallelPosF   = .32                           ; move units right
; res@pmLegendOrthogonalPosF = -.40                         ; move units down
; res@pmLegendWidthF         = 0.1                          ; Change width and
; res@pmLegendHeightF        = 0.1                           ; height of legend.
; res@lgPerimOn              = False                         ; turn off box around
; res@lgLabelFontHeightF     = .015                          ; label font height

 ;res@tiMainString           = "Intensity comparison w/ refinement"
 res@tiMainFontHeightF      = 0.02
 res@tiXAxisString          = "Days"
 res@tiYAxisString          = "MSLP (hPa)"
; res@trYMinF                =  840.0 
 plot  = gsn_csm_xy (wks,time(0:deltatime-1),psminplot/100,res) ; create plot
 
resmean = res
delete(resmean@xyExplicitLegendLabels)
delete(resmean@xyLineColors)
delete(resmean@xyLineThicknesses)
resmean@xyLineColors       = "red"
resmean@xyLineThicknesses = "12.0"
psminEnsMean = dim_avg_n_Wrap(psminplot,0)
 plot2  = gsn_csm_xy (wks,time(0:deltatime-1),psminEnsMean/100,resmean) ; create plot
overlay(plot,plot2)
draw(plot)
frame(wks)
delete(resmean)
 
 draw(plot)
 frame(wks)
 
 delete(res)
 
;************************************************
; PLOT MAXIMUM WIND SPEED
;************************************************

 wks   = gsn_open_wks ("pdf","pdf/xy_windmax_"+outstring)                  ; open workstation

 res                        = resgen                          ; turn on plot resources

 res@gsnDraw    = False                         ; don't draw
 res@gsnFrame   = False                         ; don't advance frame
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
resmean = res
delete(resmean@xyExplicitLegendLabels)
delete(resmean@xyLineColors)
delete(resmean@xyLineThicknesses)
resmean@xyLineColors       = "red"
resmean@xyLineThicknesses = "12.0"
windEnsMean = dim_avg_n_Wrap(windmaxplot,0)
 plot2  = gsn_csm_xy (wks,time(0:deltatime-1),windEnsMean,resmean) ; create plot
overlay(plot,plot2)
draw(plot)
frame(wks)

 delete(res)
 
;************************************************
; PLOT TRAJECTORY
;************************************************
   wks = gsn_open_wks("pdf","pdf/xy_traj_"+outstring)               ; open workstation
   res            = resgen                          ; map resources
   res@gsnDraw    = False                         ; don't draw
   res@gsnFrame   = False                         ; don't advance frame

   res@mpMaxLatF  = 38                           ; select subregion
   res@mpMinLatF  = 22 
   res@mpMinLonF  = -96
   res@mpMaxLonF  = -78
  
   map = gsn_csm_map_ce(wks,res)                         ; create map

   draw(map)
   
;********************************

lineres=True
do i = 0,dimsizes(models)-1
  lineres@gsLineColor = figure_colors(i)
  lineres@gsLineThicknessF = figure_linethck(i)
  do k = 0,deltatime-2
    lon1=psmin_lon_loc(i,k)
    lon2=psmin_lon_loc(i,k+1)
    lat1=psmin_lat_loc(i,k)
    lat2=psmin_lat_loc(i,k+1)
    gsn_polyline(wks,map,(/lon1,lon2/),(/lat1,lat2/),lineres)
  end do
end do


;  map = gsn_csm_xy(wks,psmin_lon_loc(:,:),psmin_lat_loc(:,:),res)
;map = gsn_csm_xy(wks,vrtmax_lon_loc(:,:),vrtmax_lat_loc(:,:),res)




delete(res)
 
end

