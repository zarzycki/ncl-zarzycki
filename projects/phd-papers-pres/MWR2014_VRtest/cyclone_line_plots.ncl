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
;========================================================
; USER OPTIONS
;========================================================

 plot_type  = "ps"   ; plot types: ps,x11
 plot_name  = "control_high"
;========================================================
; Define Constants
;========================================================
 pi    = 4.d0*atan(1.d0)
 con   = pi/180.d0
; a     = 6371220.d0
 omega = 7.292115d-5
 p0    = 101500.d0
 p00   = 100000.d0
 g     = 9.80616d0
 Rd    = 287.04d0
 Rv    = 461.5d0
 Lv    = 2501000.d0
 cp    = 1004.64d0
 f     = 2.d0*omega*sin(10.d0*pi/180.d0)
 constq = 0.608d0
 Ts    = 302.15d0

;timefile = addfile("/ptmp/zarzycki/cam5_work/lowtohighnorth_15_x8/data_output/camrun.cam.h0.0000-09-01-00000.nc","r")
timefile = addfile("/glade/p/work/zarzycki/cam5_work/hightolowvert_15_x8_adia/data_output/camrun.cam.h0.full.nc","r")
;gdir = "/Users/zarzycki/Research/data_files/HOMME/"

nfiles = 4
numchop = 20
deltatime = getfilevardimsizes(timefile, "time" ) - numchop

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

print("Doing file number: "+(filepick+1)+" of: "+nfiles)

;do filepick = 2,2

if( filepick .eq. 0 ) then 
	in1 = addfile("/glade/p/work/zarzycki/cam5_work/hightolowvert_15_x8_adia/data_output/camrun.cam.h0.full.nc","r")
;    in1 = addfile("/ptmp/zarzycki/cam5_work/hightolowvert_15_x8_adia/data_output/hightolowvert_15_x8_dry.30.nc","r")
else
end if

if( filepick .eq. 1 ) then 
	in1 = addfile("/glade/p/work/zarzycki/cam5_work/lowtohighvert_15_x8_adia/data_output/camrun.cam.h0.full.nc","r")
;    in1 = addfile("/ptmp/zarzycki/cam5_work/lowtohighvert_15_x8_adia/data_output/lowtohighvert_15_x8_dry.30.nc","r")
else
end if

if( filepick .eq. 2 ) then 
;	in1 = addfile("/glade/p/work/zarzycki/cam5_work/uniform_15_adia/data_output/camrun.cam.h0.full.nc","r")
	in1 = addfile("/glade/p/work/zarzycki/cam5_work/uniform_15_adia/data_output/camrun.cam.h0.full.nc","r")
;    in1 = addfile("/ptmp/zarzycki/cam5_work/uniform_15_adia/data_output/uniform_15_dry.30.nc","r")
else
end if

if( filepick .eq. 3 ) then 
	in1 = addfile("/glade/p/work/zarzycki/cam5_work/uniform_120_adia/data_output/camrun.cam.h0.full.nc","r")
;	in1 = addfile("/ptmp/zarzycki/cam5_work/equator_15_x8_adia/data_output/equator_15_x8_dry.30.nc","r")
else
end if

;=== EARLY FIGURE STUFF

figure_labels = (/"HTL","LTH","Low","High"/)
figure_colors = (/"red","red4","blue","blue4"/)
figure_linethck = (/9.0,9.0,12.0,12.0/)


;==========Read in data=============

latband = 18
lonst = 230
lonend = 310
startday = 0
endday = 6
plev = 50000d0

multilevels = 0 ; 0 if true, 1 if false

lat = in1->lat({-latband:latband})
lon = in1->lon({lonst:lonend})
lev  = in1->lev
ilev = in1->ilev
time = in1->time({startday:endday})

lvlspace = lev
do i = 0,dimsizes(lev) - 1
  lvlspace(i) = ilev(i+1) - ilev(i)
end do

PS1  = in1->PS({startday:endday},{-latband:latband},{lonst:lonend})


nlat = dimsizes(lat)
nlon = dimsizes(lon)

;toplev = dimsizes(lev) - 6
toplev = dimsizes(lev) - 12
;toplev = 0
botlev = dimsizes(lev) - 1

nlev = botlev - toplev + 1

if (multilevels .eq. 1) then
  U = in1->U({startday:endday},{500},{-latband:latband},{lonst:lonend})
  V = in1->V({startday:endday},{500},{-latband:latband},{lonst:lonend})
  T = in1->T({startday:endday},{500},{-latband:latband},{lonst:lonend})
else
  U = in1->U({startday:endday},{500:1050},{-latband:latband},{lonst:lonend})
  V = in1->V({startday:endday},{500:1050},{-latband:latband},{lonst:lonend})
;  T = in1->T({startday:endday},toplev:botlev,{-latband:latband},{lonst:lonend})
  ilevsub = in1->ilev(toplev:botlev+1)
end if

U = U+10

wind  = sqrt(U^2+V^2)

delete(U)
delete(V)

;************************************************
; calculate vorticity on a Fixed Grid
; scale for visual convenience
;************************************************

;vr = U(:,:,:)
;vr = uv2dv_cfd(U(:,:,:),V(:,:,:),tofloat(lat),tofloat(lon),3)*10^5
;print(max(vr))
;print(min(vr))

;vr = U(:,0,:,:)
;vr = uv2dv_cfd(U(:,0,:,:),V(:,0,:,:),tofloat(lat),tofloat(lon),3)*10^5
;print(max(vr))
;print(min(vr))


;vr@long_name = "vorticity"
;vr@units     = "scaled"

;============Find max/min value=====================

psmin = new (deltatime,float)
windmax = new(deltatime,float)
;vortmax = new(deltatime,float)
psminlat = new (deltatime,double)
psminlon = new (deltatime,double)
windmaxlat = new (deltatime,double)
windmaxlon = new (deltatime,double)
;vrtmaxlat = new(deltatime,double)
;vrtmaxlon = new(deltatime,double)
rmw = new (deltatime,double)
ike = new (deltatime,double)

cellarea = calc_area(lat,lon)
 
do j = 0,deltatime-1

psmin(j) = min(PS1(j,:,:))

if (multilevels .eq. 1) then
  windmax(j) = max(wind(j,:,:))
else
  windmax(j) = max(wind(j,:,:,:))
end if
    
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
    
    if (multilevels .eq. 1) then
      b = new((/nlat,nlon/),float)
      b(:,:) = wind(j,:,:)
      b1D      = ndtooned(b)
      dsizes_b = dimsizes(b)
      b_indices  = ind_resolve(maxind(b1D),dsizes_b)
      windmaxlat(j) = lat(b_indices(0,0))
      windmaxlon(j) = lon(b_indices(0,1))
    else
      b = new((/nlev,nlat,nlon/),float)
      b(:,:,:) = wind(j,:,:,:)
      b1D      = ndtooned(b)
      dsizes_b = dimsizes(b)
      b_indices  = ind_resolve(maxind(b1D),dsizes_b)
      windmaxlat(j) = lat(b_indices(0,1))
      windmaxlon(j) = lon(b_indices(0,2))
    end if
    
;    cc = new((/nlat,nlon/),float)
;    cc(:,:) = vr(j,:,:)
;    cc1D     = ndtooned(cc)   
;    dsizes_cc = dimsizes(cc)
;    cc_indices =  ind_resolve(maxind(cc1D),dsizes_cc)
;    vrtmaxlat(j) =  lat(cc_indices(0,0))
;    vrtmaxlon(j) =  lon(cc_indices(0,1))

    
    ; Find the RMW by searching distance from psmin to windmax by GC
    rmw(j) = gc_latlon(psminlat(j),psminlon(j),windmaxlat(j),windmaxlon(j),2,4)
            
     ;============Calc integrated kinetic energy==========================    
    ikerun = 1e-18      ; Initialize some small value
    windthresh = 0       ; Wind speed threshold (set equal to zero to negate criteria)
    distthresh = 1500  ; Distance threshold (km)
    stride = 1        ; How many elements to subsample in horizontal
    
;    print("Vort max lat/lon "+vrtmaxlat(j)+" "+vrtmaxlon(j)+" AND Psmin lat/lon "+psminlat(j)+" "+psminlon(j))
    do aa = 0,nlat-1,stride
        do bb = 0,nlon-1,stride
            ; Print statement to see where in loop we are -- print every 100 elements
            if ( (mod(aa,10).eq.0) .and. (bb.eq.0) ) then
                print ("Lat index number "+aa+"/"+nlat)
            end if
    
            ; Now calculate IKE if looped cell within distthresh of center
            ; and wind speed over threshold 
            
    if (multilevels .eq. 1) then
            if ((gc_latlon(psminlat(j),psminlon(j),lat(aa),lon(bb),2,4) .lt. distthresh) .and. wind(j,aa,bb) .ge. windthresh)
                ikerun = tofloat(plev/T(j,aa,bb)/Rd) * wind(j,aa,bb)*wind(j,aa,bb)*tofloat(cellarea(aa,bb)) + ikerun
            end if
    else
            if ((gc_latlon(psminlat(j),psminlon(j),lat(aa),lon(bb),2,4) .lt. distthresh) .and. wind(j,0,aa,bb) .ge. windthresh)
            ;if (lat(aa) .gt. -20 .AND. lat(aa) .lt. 20)
                do h = 0,nlev-1
                    ;ikerun = tofloat(Rd*T(j,h,aa,bb)*log(ilev(h)/ilev(h+1))/g)*tofloat(plev/T(j,h,aa,bb)/Rd) * wind(j,h,aa,bb)*wind(j,h,aa,bb)*tofloat(cellarea(aa,bb)) + ikerun
                    ikerun = wind(j,h,aa,bb)*wind(j,h,aa,bb)*tofloat(cellarea(aa,bb)) + ikerun
                end do
            end if
    end if            
            
              

        end do
    end do
            
    ike(j) = ikerun     ; Put IKE in time-specific array
    
    ;============Clean up==========================
    delete(a1D)
    delete(b1D)
;    delete(cc1D)
    delete(dsizes_a)
    delete(dsizes_b)
;    delete(dsizes_cc)
    delete(a_indices)
    delete(b_indices)
;    delete(cc_indices)
         
end do

;============Rewrite value per resolution==========================
 
 psminplot(filepick,:) = psmin
 windmaxplot(filepick,:) = windmax
 psmin_lat_loc(filepick,:) = psminlat
 psmin_lon_loc(filepick,:) = psminlon
 windmax_lat_loc(filepick,:) = windmaxlat
 windmax_lon_loc(filepick,:) = windmaxlon
; vrtmax_lat_loc(filepick,:) = vrtmaxlat
; vrtmax_lon_loc(filepick,:) = vrtmaxlon
 rmw_plot(filepick,:) = rmw
 ike_plot(filepick,:) = ike
 
 ike_plot(filepick,:) = ike / ike(0)
 
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
 delete(rmw)
 delete(lat)
 delete(lon)
 delete(nlat)
 delete(nlon)
 delete(ike)
 delete(b)
 delete(a)
 delete(cellarea)
 
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
 wks   = gsn_open_wks ("eps","xy_sfcpres")                  ; open workstation
 
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

 res@tiMainString           = "Intensity comparison w/ refinement"
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

 wks   = gsn_open_wks ("eps","xy_windmax")                  ; open workstation

 res                        = resgen                          ; turn on plot resources

 res@lgAutoManage = True
 res@pmLegendSide           = "Bottom"                      ; Change location of 
 res@pmLegendParallelPosF   = .20                           ; move units right
 res@pmLegendOrthogonalPosF = -1.15                         ; move units down
 res@pmLegendWidthF         = 0.15                          ; Change width and
 res@pmLegendHeightF        = 0.1                           ; height of legend.
 res@lgPerimOn              = False                         ; turn off box around
 res@lgLabelFontHeightF     = .02                           ; label font height

 res@tiMainString           = "Maximum Wind - Hemi_15_x4"
 res@tiXAxisString          = "Days"
 res@tiYAxisString          = "Wind (m/s)"

 plot  = gsn_csm_xy (wks,time(0:deltatime-1),windmaxplot,res) ; create plot

 delete(res)
 
;************************************************
; PLOT RADIUS OF MAXIMUM WIND
;************************************************

 wks   = gsn_open_wks ("eps","xy_rmw")                  ; open workstation

 res                        = resgen                          ; turn on plot resources

 res@lgAutoManage = True
 res@pmLegendSide           = "Bottom"                      ; Change location of 
 res@pmLegendParallelPosF   = .20                           ; move units right
 res@pmLegendOrthogonalPosF = -1.15                         ; move units down
 res@pmLegendWidthF         = 0.15                          ; Change width and
 res@pmLegendHeightF        = 0.1                           ; height of legend.
 res@lgPerimOn              = False                         ; turn off box around
 res@lgLabelFontHeightF     = .02                           ; label font height

 res@tiMainString           = "Radius of Maximum Wind"
 res@tiXAxisString          = "Days"
 res@tiYAxisString          = "RMW (km)"

 plot  = gsn_csm_xy (wks,time(0:deltatime-1),rmw_plot,res) ; create plot

 delete(res)
 
;************************************************
; PLOT INTEGRATED KINETIC ENERGY
;************************************************

 wks   = gsn_open_wks ("eps","xy_ike")                  ; open workstation

 res                        = resgen                          ; turn on plot resources

 res@lgAutoManage = False
 res@pmLegendSide           = "Bottom"                      ; Change location of 
 res@pmLegendParallelPosF   = .16                           ; move units right
 res@pmLegendOrthogonalPosF = -0.43                         ; move units down
 res@pmLegendWidthF         = 0.15                          ; Change width and
 res@pmLegendHeightF        = 0.15                           ; height of legend.
 res@lgPerimOn              = False                         ; turn off box around
 res@lgLabelFontHeightF     = .02                          ; label font height
 res@trYMinF                = 0.15
 res@trYMaxF                = 1.05

 
 res@lgLabelFontAspectF = 1.4

 res@tiMainString           = "Vortex Integrated Kinetic Energy"
 res@tiXAxisString          = "Days"
 res@tiYAxisString          = "IKE (normalized)"

 plot  = gsn_csm_xy (wks,time(0:deltatime-1),ike_plot,res) ; create plot

 delete(res)
 
;************************************************
; PLOT TRAJECTORY
;************************************************
   wks = gsn_open_wks("eps","xy_traj")               ; open workstation
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

