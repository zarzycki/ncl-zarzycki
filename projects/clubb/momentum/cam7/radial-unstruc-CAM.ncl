; NOTES

load "../../../../functions/radialAvg.ncl"

begin

; cyclone-variable
;        481926  245.374988      18.191805       9.294229e+04    6.005012e+01    7.284355e+01    0.000000e+00    2009    8       3       15
cenlat=18.191805
cenlon=245.374988
timeStep=2
filename="/glade/derecho/scratch/hannay/archive/f.e30_cam6_4_036.FMTHIST.ne120_L93.001/atm/hist/f.e30_cam6_4_036.FMTHIST.ne120_L93.001.cam.h5i.2009-08-03-21600.nc"

; static
phisfilename="/glade/work/juliob/GridFiles/Topo/ne120pg3_gmted2010_modis_bedmachine_nc3000_Laplace0025_noleak_20240326.nc"

;-------------------------------------------------------------------------------------------

outerRadius = 1000. ; outer rad of radial profiles, in km
topLev = 10.        ; top level of analysis/model data (mb)
botLev = 1100.      ; lowest level of analysis/model data (set to something like 1100+ for surface) (mb)
zlev_min = 100.     ; minimum z level for output
zlev_max = 18000.   ; maximum z level for output
zlev_npts = 180     ; number of evenly spaced points in zlevs for output
deltaMax=0.25       ; nominal resolution used for binning

; Tunable but not really
valid_points_scan_ix = outerRadius / 111.1 * 1.5   ; max distance from targeted cenlat/cenlon into memory
max_phis_allowed = 10.0 ; maximum gridcell PHIS kept in averaging
psmin_search_rad = 2.0  ; GCD to move cenlat/cenlon to true PSmin
height_for_rmw = 100.0  ; height to calc RMW (meters)

; constants
pi=3.14159
grav=9.81
P0=100000.
P0@units="Pa"

thefile = addfile(filename,"r")
phisfile = addfile(phisfilename,"r")

lat = thefile->lat(:)
lon = thefile->lon(:)
PHIS = phisfile->PHIS(:)
nearby_ix = ind((gc_latlon(cenlat,cenlon,lat,lon,2,2) .lt. valid_points_scan_ix) .and. (PHIS .lt. max_phis_allowed))
lat := thefile->lat(nearby_ix)
lon := thefile->lon(nearby_ix)
PHIS := phisfile->PHIS(nearby_ix)

; get data
lev = thefile->lev({topLev:botLev})
lev@units = "hPa"
fulllev = thefile->lev
toplevix = ind_nearest_coord (lev(0), fulllev, 0)
botlevix = ind_nearest_coord (lev((dimsizes(lev)-1)), fulllev, 0)

ncol = dimsizes(lat)
nlev = dimsizes(lev)

; Get 2-D variables
PS1 = thefile->PS(timeStep,nearby_ix)

; Get 3-D pressure field
if (isfilevar(thefile, "PMID")) then
  PRES = thefile->PMID(timeStep,{topLev:botLev},nearby_ix)
else
  hyam=thefile->hyam(toplevix:botlevix)
  hybm=thefile->hybm(toplevix:botlevix)
  hyai=thefile->hyai(toplevix+1:botlevix+1)
  hybi=thefile->hybi(toplevix+1:botlevix+1)
  PRES = pres_hybrid_ccm(PS1,P0,hyam,hybm)
end if

; Get 3-D variables
U = thefile->U(timeStep,{topLev:botLev},nearby_ix)
V = thefile->V(timeStep,{topLev:botLev},nearby_ix)
T = thefile->T(timeStep,{topLev:botLev},nearby_ix)
if (isfilevar(thefile, "Q")) then
  Q = thefile->Q(timeStep,{topLev:botLev},nearby_ix)
else
  ; we need to estimate q
  print("We do not have Q on the file, estimating assuming 85% RH")
  dumRH = T
  dumRH = 85.0
  Q = mixhum_ptrh(PRES/100., T, dumRH, 2)   ; estimate Q as 80% RH
  Q@long_name="specific humidity"
  Q@units="kg/kg"
  delete(dumRH)
end if
if (isfilevar(thefile, "OMEGA")) then
  have_omega = True
  OMEGA = thefile->OMEGA(timeStep,{topLev:botLev},nearby_ix)
  ; Calculate vertical velocity (z-coords)
  W = omega_to_w(OMEGA, PRES, T)         ; w (m/s)
else
  ; Cannot calculate W
  print("We do not have OMEGA on the file, will not print vertical velocity")
  have_omega = False
end if

; Calculate potential temperature
THETA=pot_temp(PRES,T,-1,False)

; Calculate virtual temperature
TV=T*(1.+0.61*Q)

; Find the true PS minimum of the nearby cells
print("Using surface pressure minimum to find storm center")
; Artificially restrict PS to within 2GCD of where we guessed to make sure we don't pick up another TC
tmp_PS = PS1
tmp_PS = where(gc_latlon(cenlat,cenlon,lat,lon,2,2) .lt. psmin_search_rad, PS1, 9e9)
; Find minimum of valid values
min_location  = minind(tmp_PS)
psminlat=lat(min_location)
psminlon=lon(min_location)
print("Found psmin at lat: "+psminlat+" lon: "+psminlon+" with PS: "+PS1(min_location))
print("Previous cenlat: "+cenlat+" lon: "+cenlon+" "+gc_latlon(cenlat,cenlon,psminlat,psminlon,2,2)+" degrees apart")
delete(min_location)
delete(tmp_PS)

; calculate radial components
vComps = calcWindComponents_unstruct(U,V,lat,lon,psminlat,psminlon,0,0)
v_rad = vComps[0]
v_theta = vComps[1]
delete(vComps)

; get Z from hybrid levels
; First, create new arrays to hold P and T w/ surface values appended
PPnew = new((/nlev+1,ncol/),typeof(PRES))
TVnew = new((/nlev+1,ncol/),typeof(TV))
PPnew!0="lev"
PPnew!1="ncol"
TVnew!0="lev"
TVnew!1="ncol"

; Create new arrays for hydro, flipping now to bottom->top
PPnew(0,:) = (/PS1/)
TVnew(0,:) = (/TV(nlev-1,:)/)
PPnew(1:nlev,:) = (/PRES(::-1,:)/)
TVnew(1:nlev,:) = (/TV(::-1,:)/)
PPnew = PPnew / 100. ; convert to mb

; Run hydro function, correctly ordering things. PHIS/grav = zs
Z = hydro(PPnew(ncol|:,lev|:),TVnew(ncol|:,lev|:),PHIS/grav)

; Remove zs and flip back from top->bottom
Z := Z(:,1:nlev)
Z := Z(:,::-1)
Z!0 = "ncol"
Z!1 = "lev"

; Reorder dimensions of z to match other vars
Z := Z(lev|:,ncol|:)
Z@units = "m"

; generate Zlev
Zlev = fspan(zlev_min,zlev_max,zlev_npts)
Zlev@units = "m"
Zlev!0     = "Zlev"
Zlev&Zlev = Zlev

; do vertical interpolation from model levels to equally spaced Z levels
interp_type=1
v_theta_Z  = int2p_n_Wrap(Z,v_theta,Zlev,interp_type,0)
v_rad_Z    = int2p_n_Wrap(Z,v_rad,Zlev,interp_type,0)
T_Z        = int2p_n_Wrap(Z,T,Zlev,interp_type,0)
Q_Z        = int2p_n_Wrap(Z,Q,Zlev,interp_type,0)
if (have_omega) then
  W_Z        = int2p_n_Wrap(Z,W,Zlev,interp_type,0)
end if

; do radial integrals
rad_v_theta  = radialAvg3D_unstruc(v_theta_Z,lat,lon,Zlev,deltaMax,psminlat,psminlon,outerRadius,True)
rad_v_rad    = radialAvg3D_unstruc(v_rad_Z,lat,lon,Zlev,deltaMax,psminlat,psminlon,outerRadius,True)
rad_v_rad    = -rad_v_rad  ; SWITCH TO NEGATIVE FOR CONVENTION
rad_T      = radialAvg3D_unstruc(T_Z,lat,lon,Zlev,deltaMax,psminlat,psminlon,outerRadius,True)
rad_Q      = radialAvg3D_unstruc(Q_Z,lat,lon,Zlev,deltaMax,psminlat,psminlon,outerRadius,True)
if (have_omega) then
  rad_W        = radialAvg3D_unstruc(W_Z,lat,lon,Zlev,deltaMax,psminlat,psminlon,outerRadius,True)
end if

rad_dims=dimsizes(rad_v_theta)
nlev_rad=rad_dims(0)
nrad_rad=rad_dims(1)

rad_t_anom = rad_T
;Tref = dim_avg_n_Wrap(rad_t_anom(:,nrad_rad-2:nrad_rad-1),1)
rad_t_anom = rad_T - conform(rad_T,rad_t_anom(:,nrad_rad-1),0)

rad_q_anom = rad_Q
rad_q_anom = rad_Q - conform(rad_Q,rad_q_anom(:,nrad_rad-1),0)

; find RMW
rmw = calc_vertmax_from_rad(rad_v_theta)
rmw_at_vmax = rmw({height_for_rmw})
; find height of max wind at RMW
zmax = calc_zmax_from_rad(rad_v_theta)
zmax_at_rmw = zmax({rmw_at_vmax})

; vertical profile of wind at RMW
wind_at_rmw = rad_v_theta(:,{rmw_at_vmax})
; 1-D profile of wind at surface
wind_at_sfc = rad_v_theta(0,:)

print("Found psmin at lat: "+psminlat+" lon: "+psminlon)
print("Found RMW at: "+rmw_at_vmax+" km")
print("Found zmax/RMW at: "+zmax_at_rmw+" m")

; Place any other diagnostics here
; Get surface maps of radial and tangential 2-D wind fields
v_theta_Z_sfc = v_theta_Z(0,:)
v_rad_Z_sfc = v_rad_Z(0,:)
v_theta_Z_sfc!0="ncol"
v_rad_Z_sfc!0="ncol"
ZS = Z(nlev-1,:)

;alpha = atan(rad_v_rad({height_for_rmw},{rmw_at_vmax}) / rad_v_theta({height_for_rmw},{rmw_at_vmax}))
;alpha = alpha * 180. / pi
;print("inflow angle: "+alpha)

; find surface inflow angle
; we scane down
do ii = 0,nlev_rad-1
  if(.not. ismissing(rad_v_theta(ii,{rmw_at_vmax}))) then
    sfc_inflow_ang=atan(rad_v_rad(ii,{rmw_at_vmax})/rad_v_theta(ii,{rmw_at_vmax}))*180./pi
    sfc_radial_flow=abs(rad_v_rad(ii,{2.0*rmw_at_vmax}))
    break
  else
    print("Missing value in search for lowest model level...")
  end if
  if (ii .eq. nlev_rad-1) then
    print("Uh oh, we couldn't find a surface inflow angle or radial flow, something went wrong!")
    sfc_inflow_ang = -9999.9
    sfc_radial_flow = -9999.9
  end if
end do

do ii = 0,nlev_rad-1
  if(.not. ismissing(rad_v_theta(ii,{2.0*rmw_at_vmax}))) then
    if (abs(rad_v_rad(ii,{2.0*rmw_at_vmax})) .ge. 0.1*sfc_radial_flow) then
      print("Searing for inflow depth -- at z: "+Zlev(ii)+" "+abs(rad_v_rad(ii,{2.0*rmw_at_vmax}))+" compared to: "+(0.1*sfc_radial_flow))
      inflow_depth=tofloat(Zlev(ii))
    else
      print("Breaking -- at z: "+Zlev(ii)+" "+abs(rad_v_rad(ii,{2.0*rmw_at_vmax}))+" compared to: "+(0.1*sfc_radial_flow))
      break
    end if
  else
    print("Missing value in search for inflow depth...")
  end if
  if ((ii .eq. nlev_rad-1) .or. (sfc_radial_flow .le. -9999.)) then
    print("Uh oh, we couldn't find an inflow depth, something went wrong!")
    print("sfc_radial_flow: "+sfc_radial_flow)
    inflow_depth = -9999.9
  end if
end do

inflow_depth@units=Zlev@units
inflow_depth!0="depth"
sfc_inflow_ang@units="degrees"
sfc_inflow_ang!0="angle"

print("-------------------------------------------------------------------")
print("surface inflow angle: "+abs(sfc_inflow_ang))
print("inflow depth: "+inflow_depth+" "+sfc_inflow_ang@units)
print("-------------------------------------------------------------------")

print("Writing file...")
;==================================================================================================
outDir="./netcdf/"
system("mkdir -p "+outDir)
outFile="ben"+timeStep+".nc"
system("/bin/rm -fv "+outDir+"/"+outFile)   ; remove any pre-existing file
ncdf = addfile(outDir+"/"+outFile ,"c")  ; open output netCDF file

fAtt               = True            ; assign file attributes
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes

print("Writing coordinates")
ncdf->lat = lat
ncdf->lon = lon
print("Writing 3-D radial fields")
ncdf->V_THETA  =  dble2flt(rad_v_theta)
ncdf->V_RAD  =  dble2flt(rad_v_rad)
ncdf->T  =  dble2flt(rad_T)
ncdf->Q  =  dble2flt(rad_Q)
ncdf->T_anom =  dble2flt(rad_t_anom)
ncdf->Q_anom =  dble2flt(rad_q_anom)
if (have_omega) then
  ncdf->W  =  dble2flt(rad_W)
end if
print("Writing 2-D horizontal fields")
ncdf->PS1 =  PS1
ncdf->ZS =  ZS
ncdf->v_theta_Z =  dble2flt(v_theta_Z_sfc)
ncdf->v_rad_Z =  dble2flt(v_rad_Z_sfc)
print("Writing 1-D fields")
ncdf->wind_at_rmw = dble2flt(wind_at_rmw)
ncdf->wind_at_sfc =  dble2flt(wind_at_sfc)
print("Writing scalars")
ncdf->inflow_depth = inflow_depth
ncdf->sfc_inflow_ang = dble2flt(sfc_inflow_ang)

end