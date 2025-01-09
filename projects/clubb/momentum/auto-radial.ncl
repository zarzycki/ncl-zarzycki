; NOTES

load "../../../functions/radialAvg.ncl"

begin

;EXP="901"
config="RCE.QPC6.ne0np4tcfplane.ne15x16.exp"+EXP+".001"
dayofsim="02"
FILEDIR="/glade/scratch/zarzycki/"+config+"/run/"
filename = FILEDIR+"/"+config+".cam.h2.0001-01-"+dayofsim+"-00000.nc"
vars = (/"MPCLDM","MPLCLDM","MPICLDM","CLOUD","CLDLIQ","CLDICE","MPDT","MPDQ","MPDLIQ","MPDICE","MPDNLIQ","MPDNICE","AWNC","AWNI","AREL","AREI","FREQL","FREQI","FREQM","FREQSL","FREQSLM","NCAL","NCAI","AQRAIN","AQSNOW","ANRAIN","ANSNOW","ADRAIN","ADSNOW","FREQR","FREQS","REFL","UMR","UMS","CLOUDFRAC_CLUBB","TTEND_TOT","RELHUM"/)


stride = 1          ; how many cells to skip (set to 1 for all)
topLev = 1.        ; top level of analysis
botLev = 1050.      ; lowest level of analysis (set to something like 1050+ for surface)
outerRadius = 1500. ; km
maxLat=-25.         ; lat bound to extract
minLat=25.          ; lat bound to extract
timeStep=0          ; what timestep of file (set to 0 for single indexed files)

zlev_min = 100.
zlev_max = 20000.
zlev_npts = 100

; constants
pi=3.14159

thefile = addfile(filename,"r")

do_interp=True
if (do_interp) then
  Opt         = True
  wgt_file="/glade/u/home/zarzycki/work/maps/clubb-TC-test-VR/map_ne0np4tcfplane.ne15x16_to_0.25x0.25_REG.nc"
  U  = ESMF_regrid_with_weights(thefile->U,wgt_file,Opt)
  V  = ESMF_regrid_with_weights(thefile->V,wgt_file,Opt)
  T  = ESMF_regrid_with_weights(thefile->T,wgt_file,Opt)
  Q  = ESMF_regrid_with_weights(thefile->Q,wgt_file,Opt)
  OMEGA  = ESMF_regrid_with_weights(thefile->OMEGA,wgt_file,Opt)
  PS1  = ESMF_regrid_with_weights(thefile->PS,wgt_file,Opt)
  lat = U&lat
  lon = U&lon
  lat!0 = "lat"
  lat&lat = lat
  lon!0 = "lon"
  lon&lon = lon
  lat := lat({maxLat:minLat:stride})
  lon := lon(::stride)
else
  lat = thefile->lat({maxLat:minLat:stride})
  lon = thefile->lon(::stride)
end if

; get data
lev = thefile->lev({topLev:botLev})
lev@units = "hPa"
fulllev = thefile->lev
toplevix = ind_nearest_coord (lev(0), fulllev, 0)
botlevix = ind_nearest_coord (lev((dimsizes(lev)-1)), fulllev, 0)
hyam=thefile->hyam(toplevix:botlevix)
hybm=thefile->hybm(toplevix:botlevix)
hyai=thefile->hyai(toplevix+1:botlevix+1)
hybi=thefile->hybi(toplevix+1:botlevix+1)

; get P0 needed for hybrid conversion, generally set to 1000 hPa (or 100000 Pa)
;P0=thefile->P0
P0=100000.
P0@units="Pa"

nlat = dimsizes(lat)
nlon = dimsizes(lon)
nlev = dimsizes(lev)

if (do_interp) then
  U := U(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
  V := V(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
  T := T(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
  Q := Q(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
  OMEGA := OMEGA(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
  PS1 := PS1(timeStep,{maxLat:minLat:stride},::stride)
else
  U = thefile->U(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
  V = thefile->V(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
  T = thefile->T(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
  Q = thefile->Q(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
  OMEGA = thefile->OMEGA(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
  PS1 = thefile->PS(timeStep,{maxLat:minLat:stride},::stride)
end if

PRES = pres_hybrid_ccm(PS1,P0,hyam,hybm)

THETA=pot_temp(PRES,T,-1,False)

W = omega_to_w(OMEGA, PRES, T)         ; w (m/s)

;---FIND LOCATIONS OF PSMIN and WINDMAX
a = new((/nlat,nlon/),float)
a(:,:) = PS1(:,:)
a1D      = ndtooned(a)
dsizes_a = dimsizes(a)
a_indices  = ind_resolve(minind(a1D),dsizes_a)
psminlat = lat(a_indices(0,0))
psminlon = lon(a_indices(0,1))

; calculate radial stuff
vComps = calcWindComponents(U,V,lat,lon,psminlat,psminlon,0,0)
v_rad = vComps[0]
v_theta = vComps[1]
delete(vComps)

; get Z from hybrid levels
TV=T*(1.+0.61*Q)
PHIS=PS1
PHIS=0.0
Z = cz2ccm(PS1,PHIS,TV,P0,hyam(::-1),hybm(::-1),hyai(::-1),hybi(::-1))
Z@units="m"

; generate Zlev
Zlev = fspan(zlev_min,zlev_max,zlev_npts)
Zlev@units = "m"
Zlev!0     = "Zlev"
Zlev&Zlev = Zlev

; do vertical interpolation from model levels to equally spaced Z levels
interp_type=1
v_theta_Z  = int2p_n_Wrap(Z,v_theta,Zlev,interp_type,0)
v_rad_Z    = int2p_n_Wrap(Z,v_rad,Zlev,interp_type,0)
W_Z        = int2p_n_Wrap(Z,W,Zlev,interp_type,0)
T_Z      = int2p_n_Wrap(Z,T,Zlev,interp_type,0)
Q_Z      = int2p_n_Wrap(Z,Q,Zlev,interp_type,0)

; do radial integrals
rad_v_theta  = radialAvg3D(v_theta_Z,lat,lon,Zlev,psminlat,psminlon,outerRadius,True)
rad_v_rad    = radialAvg3D(v_rad_Z,lat,lon,Zlev,psminlat,psminlon,outerRadius,True)
rad_v_rad    = -rad_v_rad  ; SWITCH TO NEGATIVE FOR CONVENTION
rad_W        = radialAvg3D(W_Z,lat,lon,Zlev,psminlat,psminlon,outerRadius,True)
rad_T      = radialAvg3D(T_Z,lat,lon,Zlev,psminlat,psminlon,outerRadius,True)
rad_Q      = radialAvg3D(Q_Z,lat,lon,Zlev,psminlat,psminlon,outerRadius,True)

rad_dims=dimsizes(rad_v_theta)
nlev_rad=rad_dims(0)
nrad_rad=rad_dims(1)

rad_t_anom = rad_T
;Tref = dim_avg_n_Wrap(rad_t_anom(:,nrad_rad-2:nrad_rad-1),1)
rad_t_anom = rad_T - conform(rad_T,rad_t_anom(:,nrad_rad-1),0)

rad_q_anom = rad_Q
rad_q_anom = rad_Q - conform(rad_Q,rad_q_anom(:,nrad_rad-1),0)

print("Writing file...")
;==================================================================================================
outDir="./netcdf/"
system("mkdir -p "+outDir)
outFile=config+"_"+dayofsim+".nc"
system("/bin/rm -fv "+outDir+"/"+outFile)   ; remove any pre-existing file
ncdf = addfile(outDir+"/"+outFile ,"c")  ; open output netCDF file

;===================================================================
; create global attributes of the file (optional)
;===================================================================
fAtt               = True            ; assign file attributes
fAtt@title         = "NCL Simple Approach to netCDF Creation"
fAtt@source_file   =  "original-file.nc"
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes

;===================================================================
; make time an UNLIMITED dimension; recommended  for most applications
;===================================================================
filedimdef(ncdf,"time",-1,True)

;===================================================================
; output variables directly; NCL will call appropriate functions
; to write the meta data associated with each variable
;===================================================================
ncdf->V_THETA  = rad_v_theta
ncdf->V_RAD  = rad_v_rad
ncdf->W  = rad_W
ncdf->T  = rad_T
ncdf->Q  = rad_Q
ncdf->T_anom = rad_t_anom
ncdf->Q_anom = rad_q_anom

var_in   = getfilevarnames( thefile )
nvar_in  = dimsizes(var_in)
var_in_exclude = (/"U","V","T","Q","lat", "lon", "area","time_bnds", "date_written", "time_written"/)
var_out        = "All_Variables"     ; to be regridded

do nv=0,nvar_in-1
   ;print("** "+var_in(nv))
   if (.not.any(var_in(nv).eq.var_in_exclude)) then
       rank_in = dimsizes(getfilevardimsizes(thefile, var_in(nv)))

       if (rank_in.eq.1) then
           ;rgrd_nc->$var_in(nv)$ = sfile->$var_in(nv)$
           print(var_in(nv)+" 1D")
       else
           if (rank_in.eq.2 .and. (var_out(0).eq."All_Variables" .or. any(var_in(nv).eq.var_out))) then
               print(var_in(nv)+" 2D")
               fullvar := thefile->$var_in(nv)$
               fullvar := ESMF_regrid_with_weights(fullvar,wgt_file,Opt)
               fullvar := fullvar(timeStep,{maxLat:minLat:stride},::stride)
               tmp := radialAvg2D(fullvar,lat,lon,psminlat,psminlon,outerRadius,True)
               rad_var = tmp(0,:)
               var_var = tmp(1,:)
               ncdf->$var_in(nv)$ = rad_var
               delete([/rad_var, var_var, tmp, fullvar/])
           else if (rank_in.eq.3 .and. (var_out(0).eq."All_Variables" .or. any(var_in(nv).eq.var_out))) then
               print(var_in(nv)+" 3D")
              fullvar := thefile->$var_in(nv)$
              fullvar := ESMF_regrid_with_weights(fullvar,wgt_file,Opt)
              fullvar := fullvar(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
              tmpdims1 := dimsizes(fullvar)
              tmpdims2 := dimsizes(Z)
              if (tmpdims1(0) .eq. tmpdims2(0)) then
                var_Z   = int2p_n_Wrap(Z,fullvar,Zlev,interp_type,0)
                rad_var = radialAvg3D(var_Z,lat,lon,Zlev,psminlat,psminlon,outerRadius,True)
                ncdf->$var_in(nv)$ = rad_var
                delete([/rad_var, var_Z/])
              end if
              delete(fullvar)
           else
             print("NAH")
           end if
           end if
       end if
   end if
end do


exit

do ii = 0,dimsizes(vars)-1
  loopvar = vars(ii)
  print(""+loopvar)
  if (do_interp) then
    fullvar := thefile->$loopvar$
    fullvar := ESMF_regrid_with_weights(fullvar,wgt_file,Opt)
    fullvar := fullvar(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
  else
    fullvar := thefile->$loopvar$(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
  end if
  var_Z   = int2p_n_Wrap(Z,fullvar,Zlev,interp_type,0)
  rad_var = radialAvg3D(var_Z,lat,lon,Zlev,psminlat,psminlon,outerRadius,True)
  ncdf->$loopvar$ = rad_var
end do

;==================================================================================================

end

