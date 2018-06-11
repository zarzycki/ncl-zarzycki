;========================================================
; TC_cross_and_latlon.ncl:   plots the PS, U, V, and T.
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;========================================================
begin

plotRuns="compare_RCP"    ; base, pert_only, compare_configs, compare_MIROC, compare_RCP

; 10xx = present day runs ----red
; 20xx = full world that wasn't ----blue
; 30xx = + world that wasn't SSTs ----green
; 40xx = + world that wasn't SSTs ----yellow
; 50xx = world that wasn't PS, U, V + world that wasn't SSTs ----purple
; 60xx = T, Q + world that wasn't SSTs ----orange
; 70xx = RCP ATM + RCP SSTs ----tomato
; 800x = RCP ATM + present day SSTs ----magenta
; 825x = RCP ATM (SFC CORR) + present day SSTs ----wheat

if (plotRuns .eq. "control_only")
  nruns=2
  models = (/"1001","1002","1003","1004","1005","1006","1007","1008","1009","1010","2001","2002","2003","2004","2005","2006","2007","2008","2009","2010"/)
  outstring = "haiyan_phys_ens"
  figure_colors = (/"pink","pink","pink","pink","pink","pink","pink","pink","pink","pink","lightblue","lightblue","lightblue","lightblue","lightblue","lightblue","lightblue","lightblue","lightblue","lightblue"/)
  overcolors=(/"red","blue"/)
  labels=(/"All-Hist (Control)","Nat-Hist"/)
end if

if (plotRuns .eq. "base")
  nruns=4
  models = (/"1001","1002","1003","1004","1005","1006","1007","1008","1009","1010","2001","2002","2003","2004","2005","2006","2007","2008","2009","2010","3001","3002","3003","3004","3005","3006","3007","3008","3009","3010","4001","4002","4003","4004","4005","4006","4007","4008","4009","4010"/)
  outstring = "haiyan_phys_ens"
  figure_colors = (/"pink","pink","pink","pink","pink","pink","pink","pink","pink","pink","lightblue","lightblue","lightblue","lightblue","lightblue","lightblue","lightblue","lightblue","lightblue","lightblue","palegreen","palegreen","palegreen","palegreen","palegreen","palegreen","palegreen","palegreen","palegreen","palegreen","lightgoldenrod1","lightgoldenrod1","lightgoldenrod1","lightgoldenrod1","lightgoldenrod1","lightgoldenrod1","lightgoldenrod1","lightgoldenrod1","lightgoldenrod1","lightgoldenrod1"/)
  overcolors=(/"red","blue","green","goldenrod"/)
  labels=(/"All-Hist (Control)","Nat-Hist","Nat-Hist SST only","Nat-Hist ATM only"/)
end if

if (plotRuns .eq. "pert_only")
  nruns=3
  models = (/"2001","2002","2003","2004","2005","2006","2007","2008","2009","2010","5001","5002","5003","5004","5005","5006","5007","5008","5009","5010"  ,"6001","6002","6003","6004","6005","6006","6007","6008","6009","6010"/)
  outstring = "haiyan_phys_ens"
  figure_colors = (/"lightblue","lightblue","lightblue","lightblue","lightblue","lightblue","lightblue","lightblue","lightblue","lightblue","purple","purple","purple","purple","purple","purple","purple","purple","purple","purple",   "orange","orange","orange","orange","orange","orange","orange","orange","orange","orange"/)
  overcolors=(/"blue","purple","orange"/)
  labels=(/"Nat-Hist","Nat-Hist PS,U,V only","Nat-Hist T,Q only"/)
end if

if (plotRuns .eq. "compare_configs")
  nruns=3
  models = (/"1001","1002","1003","1004","1005","1006","1007","1008","1009","1010","2001","2002","2003","2004","2005","2006","2007","2008","2009","2010","2101","2102","2103","2104","2105","2106","2107","2108","2109","2110"/)
  outstring = "haiyan_phys_ens"
  figure_colors = (/"pink","pink","pink","pink","pink","pink","pink","pink","pink","pink","lightblue","lightblue","lightblue","lightblue","lightblue","lightblue","lightblue","lightblue","lightblue","lightblue","palegreen","palegreen","palegreen","palegreen","palegreen","palegreen","palegreen","palegreen","palegreen","palegreen"/)
  overcolors=(/"red","blue","green"/)
  labels=(/"All-Hist (CAM5)","Nat-Hist (CAM5)","Nat-Hist (MIROC)"/)
end if

if (plotRuns .eq. "compare_MIROC")
  nruns=4
  models = (/"1001","1002","1003","1004","1005","1006","1007","1008","1009","1010","2101","2102","2103","2104","2105","2106","2107","2108","2109","2110","3001","3002","3003","3004","3005","3006","3007","3008","3009","3010","4101","4102","4103","4104","4105","4106","4107","4108","4109","4110"/)
  outstring = "haiyan_phys_ens"
  figure_colors = (/"pink","pink","pink","pink","pink","pink","pink","pink","pink","pink","lightblue","lightblue","lightblue","lightblue","lightblue","lightblue","lightblue","lightblue","lightblue","lightblue","palegreen","palegreen","palegreen","palegreen","palegreen","palegreen","palegreen","palegreen","palegreen","palegreen","lightgoldenrod1","lightgoldenrod1","lightgoldenrod1","lightgoldenrod1","lightgoldenrod1","lightgoldenrod1","lightgoldenrod1","lightgoldenrod1","lightgoldenrod1","lightgoldenrod1"/)
  overcolors=(/"red","blue","green","goldenrod"/)
  labels=(/"All-Hist (CAM5)","Nat-Hist (CAM5)","Nat-Hist SST only","Nat-Hist MIROC ATM"/)
end if

if (plotRuns .eq. "compare_RCP")
  nruns=5
  models = (/"1001","1002","1003","1004","1005","1006","1007","1008","1009","1010","7201","7202","7203","7204","7205","7206","7207","7208","7209","7210","8201","8202","8203","8204","8205","8206","8207","8208","8209","8210","8251","8252","8253","8254","8255","8256","8257","8258","8259","8260","3201","3202","3203","3204","3205","3206","3207","3208","3209","3210"/)
  outstring = "haiyan_phys_ens"
  figure_colors = (/"pink","pink","pink","pink","pink","pink","pink","pink","pink","pink","tomato","tomato","tomato","tomato","tomato","tomato","tomato","tomato","tomato","tomato","violet","violet","violet","violet","violet","violet","violet","violet","violet","violet", "wheat","wheat","wheat","wheat","wheat","wheat","wheat","wheat","wheat","wheat","green","green","green","green","green","green","green","green","green","green"/)
  overcolors=(/"red","tomato3","magenta","wheat3","green"/)
  labels=(/"All-Hist (Control)","RCP85","RCP85 ATM only","RCP85 ATM_CORR only"/)
end if

if (plotRuns .eq. "check_hist")
  nruns=4
  models = (/"1001","1002","1003","1004","1005","1006","1007","1008","1009","1010","2001","2002","2003","2004","2005","2006","2007","2008","2009","2010","4051","4052","4053","4054","4055","4056","4057","4058","4059","4060","4001","4002","4003","4004","4005","4006","4007","4008","4009","4010"/)
  outstring = "haiyan_phys_ens"
  figure_colors = (/"pink","pink","pink","pink","pink","pink","pink","pink","pink","pink","lightblue","lightblue","lightblue","lightblue","lightblue","lightblue","lightblue","lightblue","lightblue","lightblue","palegreen","palegreen","palegreen","palegreen","palegreen","palegreen","palegreen","palegreen","palegreen","palegreen","lightgoldenrod1","lightgoldenrod1","lightgoldenrod1","lightgoldenrod1","lightgoldenrod1","lightgoldenrod1","lightgoldenrod1","lightgoldenrod1","lightgoldenrod1","lightgoldenrod1"/)
  overcolors=(/"red","blue","green","goldenrod"/)
  labels=(/"All-Hist (Control)","Nat-Hist","Nat-Hist ATM sfc corr","Nat-Hist ATM only"/)
end if

;figure_colors = models 
nfiles = dimsizes(models)
figure_labels = models
figure_linethck = models

deltatime = 41

minLon=108.
maxLon=153.
minLat=5.
maxLat=18.

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

ibfile=addfile("/global/homes/c/czarzyck/ibtracs/Allstorms.ibtracs_wmo.v03r08.nc","r")
ibyear = toint(ibfile->season(:))
ibnamechar = ibfile->name(:,:)
ibname = new(dimsizes(ibyear),"string")
do i = 0,dimsizes(ibyear)-1
  ibname(i)=oneDtostring(ibnamechar(i,:))
  ibname(i)=str_sub_str(ibname(i),",","")
end do

thisStr="HAIYAN"
thisYear=2013
do i = 0,dimsizes(ibname)-1
  if (thisStr .eq. ibname(i) .and. thisYear .eq. ibyear(i)) then
    print("Hello "+thisStr+"   "+ibyear(i)+"   index "+i)
    thisIndex=i
  end if
end do

obs_lat=short2flt(ibfile->lat_wmo(thisIndex,:))
obs_lon=short2flt(ibfile->lon_wmo(thisIndex,:))
obs_wind=short2flt(ibfile->wind_wmo(thisIndex,:))
obs_wind=0.514444*obs_wind ; convert to m/s
obs_pres=short2flt(ibfile->pres_wmo(thisIndex,:))


obs_time=ibfile->time_wmo(thisIndex,:)
print(obs_time)
obs_time_conv = cd_calendar(obs_time,3)
print(obs_time_conv)
obs_time = obs_time - 56600.5000000005
print(obs_time)



do filepick = 0,nfiles-1
thisModel = models(filepick)

figure_linethck(filepick) = 1.1
print("Doing file number: "+(filepick+1)+" of: "+nfiles)

;all_files = systemfunc ("ls /global/homes/c/czarzyck/scratch/haiyan48x8_FC5_v122_"+thisModel+"/run/*h0*.nc")
all_files = systemfunc ("ls /global/cscratch1/sd/czarzyck/archive/haiyan48x8_FC5_v122_"+thisModel+"/atm/hist/*h0*.nc")
;all_files = "/glade/u/home/zarzycki/scratch/DART_newgulf_30_x4/run/"+thisModel+"/h0.full.nc"
in1      = addfiles (all_files, "r")

;==========Read in data=============


lat = in1[0]->lat({minLat:maxLat})
lon = in1[0]->lon({minLon:maxLon})
time = in1[:]->time
time = time + (3./24.)

PS1  = in1[:]->PSL(:,{minLat:maxLat},{minLon:maxLon})

nlat = dimsizes(lat)
nlon = dimsizes(lon)

;ubot = in1[:]->UBOT(:,{minLat:maxLat},{minLon:maxLon})
;vbot = in1[:]->VBOT(:,{minLat:maxLat},{minLon:maxLon})

;wind = ubot
;wind = (ubot^2+vbot^2)^0.5
;wind = wind*.80

wind = in1[:]->U10(:,{minLat:maxLat},{minLon:maxLon})

print("... Done loading file number: "+(filepick+1)+" of: "+nfiles)

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
; LEGEND
;**************

lgres                    = True
lgres@lgAutoManage       = False
lgres@vpWidthF           = 0.24       ; was 0.08        ; width of legend (NDC)
lgres@vpHeightF          = 0.18       ; was 0.08        ; height of legend (NDC)

lgres@lgPerimFill        = 0                     ; Use solid fill (0) instead of the default hollow fill
lgres@lgPerimFillColor   = "Background"

;lgres@lgOrientation = "Horizontal"

; lgres@lgBoxMajorExtentF  = 0.4
lgres@lgBoxMinorExtentF  = 0.2  ; controls how wide the box holding the legend items (lines and markers) can be in relation to legend

; lgres@lgBoxBackground    = "PaleTurquoise3"

lgres@lgMonoItemType        = False                 ; indicates that we wish to set the item types individually
lgres@lgMonoMarkerIndex     = False
lgres@lgMonoLineThickness   = False
lgres@lgMonoMarkerThickness = False
lgres@lgMonoMarkerSize      = False

;lgres@lgLabelFont             = 0
lgres@lgLabelFontHeightF      = 0.10
lgres@lgLabelFontAspectF      = 1.2
lgres@lgLabelConstantSpacingF = 0.0

legendType = "Markers"
markerSize = .008
markerIndex = 16

lgres@lgItemCount        = dimsizes(labels)
lgres@lgItemTypes        = (/legendType,legendType,legendType,legendType,legendType/)
lgres@lgMarkerIndexes    = (/markerIndex,markerIndex,markerIndex,markerIndex,markerIndex/)
lgres@lgMarkerThicknesses  = (/    markerSize,    markerSize,    markerSize,    markerSize,    markerSize/)
lgres@lgMarkerColors       = overcolors
legend_labels = labels

 
;**************
; GENERAL RESOLUTION PARAMETERS
;**************

resgen = True

resgen@xyExplicitLegendLabels = figure_labels ; create explicit labels 
resgen@xyLineColors       = figure_colors  ; 4 different color
resgen@xyLineThicknesses  = tofloat(figure_linethck)               ; change line thickness

resgen@pmLegendDisplayMode    = "Never"                      ; turn on legend

resgen@tmXBMajorOutwardLengthF = 0.0                          ; draw tickmarks inward
resgen@tmXBMinorOutwardLengthF = 0.0                          ; draw minor ticsk inward
resgen@tmYLMajorOutwardLengthF = 0.0                          ; draw tickmarks inward
resgen@tmYLMinorOutwardLengthF = 0.0                          ; draw minor ticsk inward

resgen@tiXAxisString           = ""                           ; turn off axis label
resgen@tiYAxisString           = ""                           ; turn off axis label

resgen@xyMonoLineThickness = False 
resgen@xyLineThicknessF = 0.5



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
 res@trXMinF = 0.0
 res@trXMaxF = 5.0
 res@trYMinF = 860.0 
 res@trYMaxF = 1000.0
 plot  = gsn_csm_xy (wks,time(0:deltatime-1),psminplot/100,res) ; create plot
 
resmean = res
delete(resmean@xyExplicitLegendLabels)
delete(resmean@xyLineColors)
delete(resmean@xyLineThicknesses)
resmean@xyLineThicknesses = 6.0

overplot=new(nruns,"graphic")

do ii = 0,nruns-1
  resmean@xyLineColors  =overcolors(ii)
  psminEnsMean = dim_avg_n_Wrap(psminplot(ii*10:((ii+1)*10)-1,:),0)
  overplot(ii)  = gsn_csm_xy (wks,time(0:deltatime-1),psminEnsMean/100,resmean) ; create plot
  overlay(plot,overplot(ii))
end do

if (0 .eq. 1) then
  resmean@xyLineColors  = "red"
  psminEnsMean = dim_avg_n_Wrap(psminplot(0:9,:),0)
  plot2  = gsn_csm_xy (wks,time(0:deltatime-1),psminEnsMean/100,resmean) ; create plot
  overlay(plot,plot2)

  resmean@xyLineColors  = "blue"
  psminEnsMean = dim_avg_n_Wrap(psminplot(10:19,:),0)
  plot3  = gsn_csm_xy (wks,time(0:deltatime-1),psminEnsMean/100,resmean) ; create plot
  overlay(plot,plot3)

  resmean@xyLineColors  = "green"
  psminEnsMean = dim_avg_n_Wrap(psminplot(20:29,:),0)
  plot4  = gsn_csm_xy (wks,time(0:deltatime-1),psminEnsMean/100,resmean) ; create plot
  overlay(plot,plot4)

  resmean@xyLineColors  = "goldenrod"
  psminEnsMean = dim_avg_n_Wrap(psminplot(30:39,:),0)
  plot5  = gsn_csm_xy (wks,time(0:deltatime-1),psminEnsMean/100,resmean) ; create plot
  overlay(plot,plot5)

  resmean@xyLineColors  = "purple"
  psminEnsMean = dim_avg_n_Wrap(psminplot(40:49,:),0)
  plot5  = gsn_csm_xy (wks,time(0:deltatime-1),psminEnsMean/100,resmean) ; create plot
  overlay(plot,plot5)
end if

resobs = res
delete(resobs@xyExplicitLegendLabels)
delete(resobs@xyLineColors)
delete(resobs@xyLineThicknesses)
resobs@xyLineThicknesses = 6.0
resobs@xyLineColors="Black"


plot6  = gsn_csm_xy (wks,obs_time,obs_pres,resobs) ; create plot
overlay(plot,plot6)


legend = gsn_create_legend(wks,lgres@lgItemCount,legend_labels,lgres)
amres = True
amres@amParallelPosF   = -0.31               ; move legend to the right
amres@amOrthogonalPosF = .32             ; move the legend down
annoid1 = gsn_add_annotation(plot,legend,amres)   ; add legend to plot

draw(plot)
frame(wks)
delete(resmean)
delete(resobs)
delete(res)
delete(overplot)
 
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

 res@trXMinF = 0.0
 res@trXMaxF = 5.0
 res@trYMinF = 20.0 
 res@trYMaxF = 85.0

 plot  = gsn_csm_xy (wks,time(0:deltatime-1),windmaxplot,res) ; create plot
resmean = res
delete(resmean@xyExplicitLegendLabels)
delete(resmean@xyLineColors)
delete(resmean@xyLineThicknesses)
resmean@xyLineThicknesses = 6.0

overplot=new(nruns,"graphic")
do ii = 0,nruns-1
  resmean@xyLineColors  =overcolors(ii)
  windEnsMean = dim_avg_n_Wrap(windmaxplot(ii*10:((ii+1)*10)-1,:),0)
  overplot(ii)  = gsn_csm_xy (wks,time(0:deltatime-1),windEnsMean,resmean) ; create plot
  overlay(plot,overplot(ii))
end do

if (0 .eq. 1) then
  resmean@xyLineColors = "red"
  windEnsMean = dim_avg_n_Wrap((windmaxplot(0:9,:)),0)
  plot2  = gsn_csm_xy (wks,time(0:deltatime-1),windEnsMean,resmean) ; create plot
  overlay(plot,plot2)

  resmean@xyLineColors = "blue"
  windEnsMean = dim_avg_n_Wrap((windmaxplot(10:19,:)),0)
  plot3  = gsn_csm_xy (wks,time(0:deltatime-1),windEnsMean,resmean) ; create plot
  overlay(plot,plot3)

  resmean@xyLineColors = "green"
  windEnsMean = dim_avg_n_Wrap((windmaxplot(20:29,:)),0)
  plot4  = gsn_csm_xy (wks,time(0:deltatime-1),windEnsMean,resmean) ; create plot
  overlay(plot,plot4)

  resmean@xyLineColors = "goldenrod"
  windEnsMean = dim_avg_n_Wrap((windmaxplot(30:39,:)),0)
  plot5  = gsn_csm_xy (wks,time(0:deltatime-1),windEnsMean,resmean) ; create plot
  overlay(plot,plot5)

  resmean@xyLineColors = "purple"
  windEnsMean = dim_avg_n_Wrap((windmaxplot(40:49,:)),0)
  plot5  = gsn_csm_xy (wks,time(0:deltatime-1),windEnsMean,resmean) ; create plot
  overlay(plot,plot5)
end if

resobs = res
delete(resobs@xyExplicitLegendLabels)
delete(resobs@xyLineColors)
delete(resobs@xyLineThicknesses)
resobs@xyLineThicknesses = 6.0
resobs@xyLineColors="Black"
plot6  = gsn_csm_xy (wks,obs_time,obs_wind,resobs) ; create plot
overlay(plot,plot6)

legend = gsn_create_legend(wks,lgres@lgItemCount,legend_labels,lgres)
amres = True
amres@amParallelPosF   = -0.31               ; move legend to the right
amres@amOrthogonalPosF = -.32             ; move the legend down
annoid1 = gsn_add_annotation(plot,legend,amres)   ; add legend to plot

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

   res@mpMaxLatF  = maxLat
   res@mpMinLatF  = minLat 
   res@mpMinLonF  = minLon
   res@mpMaxLonF  = maxLon
  
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

delete(lat1)
delete(lon1)
delete(lat2)
delete(lon2)

lineres@gsLineColor = "black"
lineres@gsLineThicknessF = 2.0
do k = 0,dimsizes(obs_lat)-2
  if(.not. ismissing(obs_lon(k+1))) then
    lon1=obs_lon(k)
    lon2=obs_lon(k+1)
    lat1=obs_lat(k)
    lat2=obs_lat(k+1)
  end if
  gsn_polyline(wks,map,(/lon1,lon2/),(/lat1,lat2/),lineres)
end do

;map = gsn_csm_xy(wks,psmin_lon_loc(:,:),psmin_lat_loc(:,:),res)
;map = gsn_csm_xy(wks,vrtmax_lon_loc(:,:),vrtmax_lat_loc(:,:),res)




delete(res)
 
end

