;========================================================
; This script reads in the four files produced in the AMIP simulations
; (h0-h4) and produces a panel plot of the cyclone at the specified time
; that includes 850 mb wind, simulated radar reflectivity (or precip), 
; cross-section of wind, vertical temperature anomaly.
;
; Colin Zarzycki, June 2013, zarzycki@umich.edu
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "/glade/u/home/zarzycki/ncl/functions/rainratetodbz.ncl"
;========================================================

begin

do_remap = 0
; 0 = files are already interpolated 1 means files need to be interpolated

cyclone = 3
; 1 = August 1985 Cat 5 storm in Gulf of Mexico
; 2 = October 1982 storm in WPAC for comparison
; 3 = August 1989 storm from 1 deg run
if (cyclone .eq. 1) then
  gdir = "/glade/scratch/zarzycki/AMIP_casestorms/1985/"
  setlatmin = 25.
  setlonmin = 275.
  parsetime = 2143.75
  pdfname = "atl_cat5_fourpanel"
else if (cyclone .eq. 2) then
  gdir = "/glade/scratch/zarzycki/AMIP_casestorms/1982/"
  setlatmin = 22.
  setlonmin = 130.
  parsetime = 993.75
  pdfname = "wpac_fourpanel"
else if (cyclone .eq. 3) then
  gdir = "/glade/scratch/zarzycki/AMIP_casestorms/1989/"
  setlatmin = 34.00
  setlonmin = 287.25
  parsetime = 3616.25
  pdfname = "atl_1deg_fourpanel"
else
  print("Wrong cyclone ID")
  exit
end if
end if
end if

out_type = "pdf"
wks = gsn_open_wks(out_type,pdfname)
plot2 = new(4,graphic)    

do parsetime = parsetime,parsetime,0.25

;************************************************
; read in netCDF file
;************************************************

; These are ncrcat'ed daily files from the AMIP simulation.
; Address the time directly (days since 1979-10-01 00:00:00)
in0 = addfile(gdir+"h0.nc","r")
in1 = addfile(gdir+"h1.nc","r")
in2 = addfile(gdir+"h2.nc","r")
in3 = addfile(gdir+"h3.nc","r")

if (do_remap .eq. 1) then
  wgt_file = "/glade/p/work/zarzycki/maps/plotmaps/map_cyc_15_x8_TO_0.25x0.25_patc.130225.nc"
  u_se = in1->U(parsetime:parsetime+1,:,:)            ; time (1) x nlev x ncol
  v_se = in1->V(parsetime:parsetime+1,:,:)            ; time (1) x nlev x ncol
  t_se = in1->T(parsetime:parsetime+1,:,:)            ; time (1) x nlev x ncol
  q_se = in1->Q(parsetime:parsetime+1,:,:)            ; time (1) x nlev x ncol
  ps_se = in1->PSL(parsetime:parsetime+1,:)            ; time (1) x ncol
  
  Opt         = True
  ;Pct  = ESMF_regrid_with_weights(Pct_se,wgt_file,Opt)
  u = ESMF_regrid_with_weights(u_se,wgt_file,Opt)
  v = ESMF_regrid_with_weights(v_se,wgt_file,Opt)
  t = ESMF_regrid_with_weights(t_se,wgt_file,Opt)
  q = ESMF_regrid_with_weights(q_se,wgt_file,Opt)
  PS1 = ESMF_regrid_with_weights(ps_se,wgt_file,Opt)
else
  u = in3->U({parsetime},:,:,:)            ; time (1) x nlev x ncol
  v = in3->V({parsetime},:,:,:)            ; time (1) x nlev x ncol
  t = in3->T({parsetime},:,:,:)            ; time (1) x nlev x ncol
  q = in3->Q({parsetime},:,:,:)            ; time (1) x nlev x ncol
  PS1 = in1->PSL({parsetime},:,:)            ; time (1) x ncol
  Pct = in2->PRECT({parsetime},:,:)
end if

if (cyclone .eq. 3) then
  u_int = linint2_Wrap(u&lon,u&lat,u,True,PS1&lon,PS1&lat,0)
  delete(u)
  u = u_int
  delete(u_int)
  
  v_int = linint2_Wrap(v&lon,v&lat,v,True,PS1&lon,PS1&lat,0)
  delete(v)
  v = v_int
  delete(v_int)
  
  t_int = linint2_Wrap(t&lon,t&lat,t,True,PS1&lon,PS1&lat,0)
  delete(t)
  t = t_int
  delete(t_int)
  
  q_int = linint2_Wrap(q&lon,q&lat,q,True,PS1&lon,PS1&lat,0)
  delete(q)
  q = q_int
  delete(q_int)
  
  Pct_int = linint2_Wrap(Pct&lon,Pct&lat,Pct,True,PS1&lon,PS1&lat,0)
  delete(Pct)
  Pct = Pct_int
  delete(Pct_int)
end if

; Get lev from any file that has lev
lev  = in0->lev
hyam = in0->hyam
hybm = in0->hybm 

mod_lat = u&lat
mod_lon = u&lon
mod_lat!0 = "lat"
mod_lon!0 = "lon"
mod_lat&lat = mod_lat
mod_lon&lon = mod_lon

;mod_lat2 = in2->lat
;mod_lon2 = in2->lon

mod_nlat = dimsizes(mod_lat)
mod_nlon = dimsizes(mod_lon)
;mod_nlat2 = dimsizes(mod_lat2)
;mod_nlon2 = dimsizes(mod_lon2)
 
; Convert precipitation to dBZ
temp = Pct*3.6d6
temp@units = "mm/hr"
temp!0 = "lat"
temp!1 = "lon"
temp&lat = mod_lat
temp&lon = mod_lon
temp@long_name = "Total Precip. Rate"

print("Begin interp")
guess     = 1                ; use zonal means
is_cyclic = True             ; cyclic [global]
nscan     = 500             ; usually much less than this
eps       = 1.e-2            ; variable dependent
relc      = 0.5              ; relaxation coefficient
opt       = 0                ; not used
poisson_grid_fill( temp, is_cyclic, guess, nscan, eps, relc, opt)
dbz = rainratetodbz(temp,0)
poisson_grid_fill( dbz, is_cyclic, guess, nscan, eps, relc, opt)

; Convert u and v to horizontal wind speed
wind = sqrt(u^2+v^2)
wind@units = "m/s"
wind!0 = "lev"
wind!1 = "lat"
wind!2 = "lon"
wind&lev = lev
wind&lat = mod_lat
wind&lon = mod_lon
wind@long_name = "850 hPa wind speed"
  
;************************************************
; PS min solver
;************************************************

;---FIND LOCATIONS OF PSMIN and WINDMAX
;---Convert to 1D
deg_tolerance = 30.
latcyc = mod_lat({setlatmin-deg_tolerance:setlatmin+deg_tolerance})
loncyc = mod_lon({setlonmin-deg_tolerance:setlonmin+deg_tolerance})
PScyc = PS1({setlatmin-deg_tolerance:setlatmin+deg_tolerance},{setlonmin-deg_tolerance:setlonmin+deg_tolerance})
mod_nlatcyc = dimsizes(latcyc)
mod_nloncyc = dimsizes(loncyc)
	    
b = new((/mod_nlatcyc,mod_nloncyc/),float)

printVarSummary(b)
printVarSummary(PScyc)

b(:,:) = PScyc(:,:)
b1D      = ndtooned(b)
dsizes_b = dimsizes(b)

;---Resolve the 1D indices back to their original 3D array.
b_indices  = ind_resolve(minind(b1D),dsizes_b)
  
;---Convert index to lat/lon points
psminlat = latcyc(b_indices(0,0))
psminlon = loncyc(b_indices(0,1))
		
print("PS min was found to be at lat: "+psminlat+" and lon: "+psminlon)
		
;************************************************


qint = 25
pcount = 1  ; 1 if aqua 4 is simple



 psmin = new ( (/1,1/) , double )
 psxi  = new ( (/1,1/) , integer )
 psyi  = new ( (/1,1/) , integer )

;========================================================
; Define Constants
;========================================================
 pi    = 4.d0*atan(1.d0)
 con   = pi/180.d0
 a     = 6371220.d0
 omega = 7.292115d-5
 p0    = 101500.d0
 p00   = 100000.d0
 g     = 9.80616d0
 Rd    = 287.04d0
 Rv    = 461.5d0
 Lv    = 2501000.d0
 cp    = 1004.64d0
; f_cor     = 2.d0*omega*sin(10.d0*pi/180.d0)
  constq = 0.608d0

 Ts    = 302.15d0
 
 nmin = local_min(PS1(:,:), True, 0.0)
 wind2 = ind(nmin@minval.eq.min(nmin@minval))
 psmin = nmin@minval(wind2)
 psxi  = nmin@xi(wind2)
 psyi  = nmin@yi(wind2)
 

 
 ;psxi(0,0) = closest_val(setlonmin,mod_lon)
 ;psyi(0,0) = closest_val(setlatmin,mod_lat)

 psxi(0,0) = closest_val(psminlon,mod_lon)
 psyi(0,0) = closest_val(psminlat,mod_lat)

; print(psxi)
; print(psyi)
 
 lat_x  = mod_lat( (psyi(0,0)-qint) : (psyi(0,0)+qint) )                ; get lat
 lon_x  = mod_lon( (psxi(0,0)-qint) : (psxi(0,0)+qint) )                ; get lon

 
 d2r = 4.d0*atan(1.d0)/180.d0 
 r = new ( (/2*qint+1/) , double )
       do i = 0,qint-1
          r(i) = -a/1000.d0*(acos(sin(d2r*lat_x(qint))*sin(d2r*lat_x(qint))+cos(d2r*lat_x(qint))*cos(d2r*lat_x(qint))*cos(d2r*lon_x(qint)-d2r*lon_x(i))))
       end do
       do i = qint,2*qint
          r(i) =  a/1000.d0*(acos(sin(d2r*lat_x(qint))*sin(d2r*lat_x(qint))+cos(d2r*lat_x(qint))*cos(d2r*lat_x(qint))*cos(d2r*lon_x(qint)-d2r*lon_x(i))))
       end do

 PS = PS1((psyi(0,0)-qint):(psyi(0,0)+qint),(psxi(0,0)-qint):(psxi(0,0)+qint))
 
 Pm = pres_hybrid_ccm(PS(:,:),p00,hyam,hybm)

 Ti = new ( (/dimsizes(lev)+1,dimsizes(lat_x),dimsizes(lon_x)/) , double )
 T  = t(:,(psyi(0,0)-qint):(psyi(0,0)+qint),(psxi(0,0)-qint):(psxi(0,0)+qint))
 Q  = q(:,(psyi(0,0)-qint):(psyi(0,0)+qint),(psxi(0,0)-qint):(psxi(0,0)+qint))
 
       do k = 1,(dimsizes(lev)-1)
          Ti(k,:,:) = (T(k,:,:)*(1.d0+constq*Q(k,:,:))+T(k-1,:,:)*(1.d0+constq*Q(k,:,:)))/2.d0
       end do
       Ti(dimsizes(lev),:,:) = Ts*((1.d0+constq*Q(dimsizes(lev)-1,:,:)))

 z = new ( (/dimsizes(lev),dimsizes(lat_x),dimsizes(lon_x)/) , double )      
       z(dimsizes(lev)-1,:,:) = -(Rd/(g*1000.d0))*(Ti(dimsizes(lev),:,:)+T(dimsizes(lev)-1,:,:)*(1.d0+constq*Q(dimsizes(lev)-1,:,:)))/2.d0*log(Pm(dimsizes(lev)-1,:,:)/PS(:,:))
       do k =(dimsizes(lev)-2),1,1
          z(k,:,:) =z(k+1,:,:)-(Rd/(g*1000.d0))*Ti(k+1,:,:)*log(Pm(k,:,:)/Pm(k+1,:,:))
       end do
 z(0,:,:) = z(1,:,:)+1.d0

 U  = u(:,(psyi(0,0)-qint):(psyi(0,0)+qint),(psxi(0,0)-qint):(psxi(0,0)+qint))           ; read in data (time,lev,lat,lon)
 V  = v(:,(psyi(0,0)-qint):(psyi(0,0)+qint),(psxi(0,0)-qint):(psxi(0,0)+qint))           ; read in data (time,lev,lat,lon)
  
 ;U  = in1->U(time,:,:,:)         ; read in data (time,lat,lon)
 ;V  = in1->V(time,:,:,:)         ; read in data (time,lat,lon)

 M = sqrt(U^2.d0+V^2.d0)
 
do cxloopindx = 0,1
 
if (cxloopindx .eq. 1) then

M = T
Tref = T(:,qint/2,0)
 
do j = 0,dimsizes(lat_x)-1
do k = 0,dimsizes(lon_x)-1
   M(:,j,k) = T(:,j,k) - Tref(:)
end do
end do

end if


 
; UU = u(time,level,:,:)
; VV = v(time,level,:,:)
; Pt = in1->PRECT(time,:,:)
; prect = Pt*3.6d6
 
; latdum = in1->lat
; londum = in1->lon
 
; totwind = sqrt(UU^2.d0+VV^2.d0)
 
; totwind@units = "m/s"
; totwind!0 = "lat"
; totwind!1 = "lon"
; totwind&lat = latdum
; totwind&lon = londum
; totwind@long_name = "Wind speed"
 
; prect@units = "mm/hr"
; prect!0 = "lat"
; prect!1 = "lon"
; prect&lat = latdum
; prect&lon = londum
; prect@long_name = "Total Precipitation"
  
 M!0 = "lev"
 M!1 = "lat"
 M!2 = "lon"
 M&lev = lev
 M&lat = lat_x
 M&lon = lon_x
 
 z!0 = "lev"
 z!1 = "lat"
 z!2 = "lon"
 z&lev = lev
 z&lat = lat_x
 z&lon = lon_x
 
 znew = (/ 16.d0, 15.d0, 14.d0, 13.d0, 12.d0, 11.d0, 10.d0, 9.d0, 8.d0, 7.d0, 6.d0, 5.d0, 4.d0, 3.d0, 2.d0, 1.5d0, 1.d0, .5d0, .25d0, .2d0, .15d0, 0.1d0/)
 zint = z(lat|:,lon|:,lev|:)
 Mint = M(lat|:,lon|:,lev|:)

 Mtest = linint1(zint, Mint, False, znew, 0)
  
 znew@units = "km"
 Mtest!2 = "znew"
 Mtest!0 = "lat"
 Mtest!1 = "lon"
 Mtest&znew = znew
 Mtest&lat = lat_x
 Mtest&lon = lon_x

 Mn = Mtest(znew|:,lat|:,lon|:) 

 Mn@units = "m/s"
 Mn!0 = "znew"
 Mn!1 = "lat"
 Mn!2 = "lon"
 Mn&znew = znew
 Mn&lat = lat_x
 Mn&lon = lon_x
  
 Ma  = (/Mn(:,qint,:)/)  

 r(qint) = 0.d0
 znew@units = "km"
 r@units = "km"
 Ma@units = "m/s"
 Ma!0 = "znew"
 Ma!1 = "r"
 Ma&znew = znew
 Ma&r   = r
 
if (cxloopindx .eq. 0) then
 Mwind = Ma
 delete(Ma)
end if

end do

 plev = dimsizes(znew)-pcount
 

  ii  = ispan(0,216,1)
  iis = sprinti("%0.4i",ii)   ; "000", "001", ... "100"
  
; THIS OUTPUT IS USED FOR CREATING ANIMATIONS
;	wks = gsn_open_wks(out_type,"./pdfs/"+iis(time))
;	wks = gsn_open_wks(out_type,"./pdfs/grid")
;	wks = gsn_open_wks(out_type,"./pdfs/grid")

;************************************************
; Plot underlying field
;************************************************

resmain = True
resmain@tiMainString = ""

resmain@gsnDraw = False
resmain@gsnFrame = False

resmain@lbLabelBarOn         = True              ; turn off indiv. label bars
resmain@lbBoxLinesOn         = False
;	resmain@lbOrientation = "vertical"

resmain@cnFillOn		  = True

resmain@gsnAddCyclic = False

resmain@trYMaxF      = psminlat + 10
resmain@trYMinF      = psminlat - 10
resmain@trXMaxF      = psminlon + 10
resmain@trXMinF      = psminlon - 10

resmain@cnLinesOn   = False		   				; turn off the contour lines

resmain@vpWidthF     = 1
resmain@vpHeightF    = 1

resprecip = resmain
reswind = resmain


whichrainplot = 1 ; 0 = rain rate, 1 = dbz

if whichrainplot .eq. 0 then
  gsn_define_colormap(wks,"BlAqGrYeOrReVi200")
end if

if whichrainplot .eq. 1 then
  gsn_merge_colormaps(wks,"BlAqGrYeOrReVi200","rainsnowradar")
end if
 
   
 
 
 
 reswind@cnLineLabelsOn       = False             ; turn off line labels
 reswind@gsnSpreadColors      = True              ; use full colormap
 reswind@gsnSpreadColorStart = 2
 reswind@gsnSpreadColorEnd = 201 
 reswind@lbLabelStride        = 4
 reswind@cnLevelSelectionMode = "ManualLevels"    ; set contour intervals
 reswind@cnLevelSpacingF      =  2.5                ;
 reswind@cnMinLevelValF       =  0.0           ;
 reswind@cnMaxLevelValF       =  80.0 ; Use 80.0 -> 60 for this


;res2@tmXBLabelFontHeightF = 0.02
;res2@tmYLLabelFontHeightF = 0.02

;res2@tiXAxisFontHeightF = 0.02
;res2@tiYAxisFontHeightF = 0.02

plot2(0) = gsn_csm_contour(wks,wind({850},:,:),reswind)


if whichrainplot .eq. 0 then
; gsn_define_colormap(wks,"BlAqGrYeOrReVi200")          ; choose colormap
 resprecip@cnLevelSelectionMode = "ExplicitLevels"
 resprecip@cnLineLabelsOn       = False             ; turn off line labels
 resprecip@gsnSpreadColors      = True              ; use full colormap
 resprecip@gsnSpreadColorStart = 2
 resprecip@gsnSpreadColorEnd = 201 
 resprecip@lbLabelStride        = 3
 resprecip@cnInfoLabelOn        = False             ; turn off info label bar
 ;res2@cnLevels                =(/0.02, 0.1, 0.2, 0.4, 0.6, 0.8, 1.0, 2.0, 4.0, 6.0, 8.0, 10., 15., 20., 25., 30., 35., 40., 60., 80., 100., 120./)
; resprecip@cnLevels                =(/0.2, 0.4, 0.6, 0.8, 1.0, 2.0, 4.0, 6.0, 8.0, 10., 15., 20., 25., 30., 35., 40., 60., 80./)
; resprecip@cnLevels                =(/0.02, 0.1, 0.2, 0.4, 0.6, 0.8, 1.0, 2.0, 4.0, 6.0, 8.0, 10., 15., 20., 25., 30., 35., 40., 60., 80., 100., 120./)
 resprecip@cnLevels                =(/0.002, 0.01, 0.05, 0.1, 0.2, 0.5, 1.0, 2.0, 4.0, 6.0, 8.0, 10., 15., 20., 25., 30., 35., 40., 60., 80., 100., 120./)
 	plot2(1) = gsn_csm_contour(wks,temp(:,:),resprecip)
end if

if whichrainplot .eq. 1 then
   resprecip@gsnSpreadColors      = False              ; use full colormap
 resprecip@cnFillColors = (/1,218,219,220,221,222,223,224,225,226,227,228,229,230,231,232/)
  resprecip@cnLevelSelectionMode = "ExplicitLevels"                      ; set explicit contour levels
  resprecip@cnLevels    = (/0,5,10,15,20,25,30,35,40,45,50,55,60,65,70/) ; set levels
; resprecip@gsnSpreadColors      = True              ; use full colormap
; resprecip@gsnSpreadColorStart = 218
; resprecip@gsnSpreadColorEnd = 232 
   resprecip@lbLabelStride        = 3
     resprecip@tiMainString = ""
  resprecip@gsnLeftString = "Simulated Reflectivity"
  resprecip@gsnRightString = "dBZ"
	plot2(1) = gsn_csm_contour(wks,dbz(:,:),resprecip)
end if







 cxmain                      = True              ; turn on contour resources
 cxmain@gsnDraw              = False             ; don't draw plot
 cxmain@gsnFrame             = False             ; don't advance frame

 cxmain@cnFillOn             = True              ; turn on color
 cxmain@cnLinesOn            = False             ; turn off contour lines
 cxmain@cnLineLabelsOn       = False             ; turn off line labels
 cxmain@gsnSpreadColors      = True              ; use full colormap
  cxmain@gsnSpreadColorStart = 2
 cxmain@gsnSpreadColorEnd = 201
 cxmain@lbLabelBarOn         = True              ; turn off indiv. label bars
; cxmain@lbOrientation = "vertical"
 cxmain@lbBoxLinesOn         = False
 cxmain@cnInfoLabelOn        = False             ; turn off info label bar
 
; cxmain@pmLabelBarOrthogonalPosF = .05           ; move whole thing down
 
  cxmain@vpWidthF     = 1
 cxmain@vpHeightF    = 1

 cxmain@gsnYAxisIrregular2Linear  = True 

 cxmain@trXMinF      = -300
 cxmain@trXMaxF      = 300
 

 

    
 cxmain@lbTitleFontHeightF= .045

;cxmain@tiXAxisFontHeightF = 0.025
 cxmain@tiYAxisFontHeightF = 0.045
 

 cxwind = cxmain
 cxtemp = cxmain
 
 cxwind@cnLevelSelectionMode = "manualLevels"    ; set contour intervals
 cxwind@cnLevelSpacingF      =  2.5                ;
 cxwind@cnMinLevelValF       =  0.0           ;
 cxwind@cnMaxLevelValF       =  80.0 ;
 cxwind@lbLabelStride              = 4 
 cxwind@gsnLeftString = "Wind speed"
 cxwind@gsnRightString = "m/s"
; cxwind@tiXAxisString        = "Radius (km)"
 cxwind@tiYAxisString        = "Height (km)"
 cxwind@lbTitleString    = "Radius (km)"

 cxtemp@cnLevelSelectionMode = "manualLevels"    ; set contour intervals
 cxtemp@cnLevelSpacingF      =  1                ;
; cxtemp@cnMinLevelValF       =  -4           ;
; cxtemp@cnMaxLevelValF       =  14 ;
  cxtemp@cnMinLevelValF       =  -4           ;
 cxtemp@cnMaxLevelValF       =  18 ;
 cxtemp@lbLabelStride              = 2 
 cxtemp@gsnLeftString = "Temp. anomaly"
 cxtemp@gsnRightString = "K"
; cxtemp@tiXAxisString        = "Radius (km)"
 cxtemp@lbTitleString    = "Radius (km)"




 plot2(2) = gsn_csm_contour(wks,Mwind(:,:),cxwind)
 plot2(3) = gsn_csm_contour(wks,Ma(:,:),cxtemp)









  resP                     = True                ; modify the panel plot
  
  resP@amJust           = "TopLeft"
  resP@gsnPanelFigureStrings= (/"a.","b.","c.","d."/)
  resP@gsnPanelFigureStringsFontHeightF = 0.018
  
  gsn_panel(wks,plot2,(/2,2/),resP)
  
  
; here is where we clear a bunch of crap
;list_vars()
;delete([/Mint,znew,iis,Ti,mod_nlatcyc,pcount,qint,PScyc/])


  
end do
	
;************************************************


end
