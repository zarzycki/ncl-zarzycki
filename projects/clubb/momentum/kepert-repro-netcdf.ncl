; NOTES

load "../../../functions/radialAvg.ncl"

begin

config="RCE.QPC6.ne0np4tcfplane.ne15x8.expS1002.L51.001"
dayofsim="09"
cam5=False

k10=0.5

if(cam5) then
  FILEDIR="/gpfs/scratch/kmn182/output/"+config+"/run/"
  filename = FILEDIR+"/"+config+".cam.h1.0001-01-"+dayofsim+"-00000.nc_regrid.nc"
  f2= FILEDIR+"/"+config+".cam.h3.0001-01-"+dayofsim+"-00000.nc_regrid.nc"
  kvmvar="UW_kvm"
  tkevar="UW_tke"
  lengthvar="UW_leng"
else
  FILEDIR="/gpfs/scratch/kmn182/output/"+config+"/run/"
  filename = FILEDIR+"/"+config+".cam.h1.0001-01-"+dayofsim+"-00000.nc_regrid.nc"
  f2= FILEDIR+"/"+config+".cam.h3.0001-01-"+dayofsim+"-00000.nc_regrid.nc"
  kvmvar="KVH"
;  kvmvar="DTCOND"
  tkevar="em"
;  tkevar="DTCOND"
  lengthvar="Lscale"
;  lengthvar="DTCOND"
end if

thefile = addfile(filename,"r")
tf2 = addfile(f2,"r")

stride = 1        ; how many cells to skip (set to 1 for all)
topLev = 500.     ; top level of analysis
botLev = 1050.    ; lowest level of analysis (set to something like 1050+ for surface)
maxLat=-25.       ; lat bound to extract
minLat=25.        ; lat bound to extract
timeStep=0        ; what timestep of file (set to 0 for single indexed files)

; constants
pi=3.14159

; get data
lat = thefile->lat({maxLat:minLat:stride})
lon = thefile->lon(::stride)
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

U = thefile->U(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
V = thefile->V(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
PS1 = thefile->PS(timeStep,{maxLat:minLat:stride},::stride)
T = thefile->T(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
Q = thefile->Q(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
OMEGA = thefile->OMEGA(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
CLDLIQ = thefile->CLDLIQ(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)

; +++ new code
U10 = tf2->U10(timeStep,{maxLat:minLat:stride},::stride)
; --- new code

KVM_CLUBB_int = tf2->$kvmvar$(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
if (.not.cam5) then
  KVM_CLUBB_int = KVM_CLUBB_int*k10
end if
KVM_CLUBB = hyi2hyo_Wrap(P0,hyai,hybi,PS1,KVM_CLUBB_int,hyam,hybm,1)

TKE_CLUBB_int = tf2->$tkevar$(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
TKE_CLUBB = hyi2hyo_Wrap(P0,hyai,hybi,PS1,TKE_CLUBB_int,hyam,hybm,1)

LSCALE_CLUBB_int = tf2->$lengthvar$(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)
LSCALE_CLUBB = hyi2hyo_Wrap(P0,hyai,hybi,PS1,LSCALE_CLUBB_int,hyam,hybm,1)

CME = tf2->CME(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)

DTCOND = tf2->DTCOND(timeStep,{topLev:botLev},{maxLat:minLat:stride},::stride)


PRES = pres_hybrid_ccm(PS1,P0,hyam,hybm)

THETA=pot_temp(PRES,T,-1,False)

CLDLIQ = CLDLIQ*1000.

; CME is kg/kg/s
CME = CME * 1000. * 86400.  ; g/kg/d

DTCOND = DTCOND * 86400. ; K/d

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
Zlev = fspan(10.,3000.,250)
Zlev@units = "m"
Zlev!0     = "Zlev"
Zlev&Zlev = Zlev

; do vertical interpolation from model levels to equally spaced Z levels
interp_type=1
v_theta_Z  = int2p_n_Wrap(Z,v_theta,Zlev,interp_type,0)
v_rad_Z    = int2p_n_Wrap(Z,v_rad,Zlev,interp_type,0)
W_Z        = int2p_n_Wrap(Z,W,Zlev,interp_type,0)
KVM_Z      = int2p_n_Wrap(Z,KVM_CLUBB,Zlev,interp_type,0)  
TKE_Z      = int2p_n_Wrap(Z,TKE_CLUBB,Zlev,interp_type,0)  
LSCALE_Z      = int2p_n_Wrap(Z,LSCALE_CLUBB,Zlev,interp_type,0)  
THETA_Z      = int2p_n_Wrap(Z,THETA,Zlev,interp_type,0)  
T_Z      = int2p_n_Wrap(Z,T,Zlev,interp_type,0)  
Q_Z      = int2p_n_Wrap(Z,Q,Zlev,interp_type,0)  
CLDLIQ_Z      = int2p_n_Wrap(Z,CLDLIQ,Zlev,interp_type,0)  
CME_Z      = int2p_n_Wrap(Z,CME,Zlev,interp_type,0)  
DTCOND_Z      = int2p_n_Wrap(Z,DTCOND,Zlev,interp_type,0)  

; do radial integrals
rad_v_theta  = radialAvg3D(v_theta_Z,lat,lon,Zlev,psminlat,psminlon,500.,True)
rad_v_rad    = radialAvg3D(v_rad_Z,lat,lon,Zlev,psminlat,psminlon,500.,True)
rad_v_rad    = -rad_v_rad  ; SWITCH TO NEGATIVE FOR CONVENTION
rad_W        = radialAvg3D(W_Z,lat,lon,Zlev,psminlat,psminlon,500.,True)
rad_KVM      = radialAvg3D(KVM_Z,lat,lon,Zlev,psminlat,psminlon,500.,True)
rad_TKE      = radialAvg3D(TKE_Z,lat,lon,Zlev,psminlat,psminlon,500.,True)
rad_LSCALE      = radialAvg3D(LSCALE_Z,lat,lon,Zlev,psminlat,psminlon,500.,True)
rad_THETA      = radialAvg3D(THETA_Z,lat,lon,Zlev,psminlat,psminlon,500.,True)
rad_T      = radialAvg3D(T_Z,lat,lon,Zlev,psminlat,psminlon,500.,True)
rad_Q      = radialAvg3D(Q_Z,lat,lon,Zlev,psminlat,psminlon,500.,True)
rad_CLDLIQ      = radialAvg3D(CLDLIQ_Z,lat,lon,Zlev,psminlat,psminlon,500.,True)
rad_CME      = radialAvg3D(CME_Z,lat,lon,Zlev,psminlat,psminlon,500.,True)
rad_DTCOND      = radialAvg3D(DTCOND_Z,lat,lon,Zlev,psminlat,psminlon,500.,True)

; +++ new code
tmp = radialAvg2D(U10(:,:),lat,lon,psminlat,psminlon,500.,True)
;tmp = radialAvg2D(v_theta(0,:,:),lat,lon,psminlat,psminlon,500.,True)
rad_v_theta_bot = tmp(0,:)
var_v_theta_bot = tmp(1,:)
; --- new code

rad_dims=dimsizes(rad_v_theta)
nlev_rad=rad_dims(0)
nrad_rad=rad_dims(1)

; Calculate derived rad quantities
L_v = 2264.76*1000.    ; J/kg
c_p = 1005.7 ; J/kg/K
g = 9.81
; q is kg/kg, 
rad_MSE = rad_T
rad_MSE = c_p * rad_T + g * conform(rad_MSE,Zlev,0) + L_v * rad_Q

; +++ new code
; find RMW
rad_sfc_v_theta=rad_v_theta({70.},:)
inds = maxind(rad_sfc_v_theta)
rad_max = rad_sfc_v_theta&radius(inds)   ; insert the longitude index into the lon coordinate variable
print("Maximum value located at, "+rad_max)

; calc inner core variance
ix = ind_nearest_coord(rad_max,rad_sfc_v_theta&radius,0)
if (ix .eq. 0) then
  ix = ix + 1
end if
var_core = avg(var_v_theta_bot(ix-1:ix+1)) / max(rad_v_theta_bot)
print(var_core)
; --- new code

;==================================================================================================
outDir="./netcdf/"
system("mkdir -p "+outDir)
outFile=config+"_"+dayofsim+".nc"
system("/bin/rm -f "+outDir+"/"+outFile)   ; remove any pre-existing file
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
ncdf->rad_v_theta  =rad_v_theta  
ncdf->rad_v_rad  =rad_v_rad   
ncdf->rad_W  =rad_W    
ncdf->rad_KVM  =rad_KVM  
ncdf->rad_TKE  =rad_TKE     
ncdf->rad_LSCALE  =rad_LSCALE 
ncdf->rad_THETA  =rad_THETA  
ncdf->rad_T  =rad_T    
ncdf->rad_Q  =rad_Q   
ncdf->rad_CLDLIQ  =rad_CLDLIQ   
ncdf->rad_CME  =rad_CME   
ncdf->rad_DTCOND  =rad_DTCOND   
ncdf->rad_MSE = rad_MSE
; +++ new code
ncdf->rad_v_theta_bot = rad_v_theta_bot
ncdf->var_v_theta_bot = var_v_theta_bot
ncdf->rad_max = rad_max
ncdf->var_core = var_core
; --- new code

;==================================================================================================

end

