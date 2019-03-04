; NOTES

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"  
load "/glade/u/home/zarzycki/ncl/functions/surfaceWindCorrFactor.ncl"
load "../../../functions/radialAvg.ncl"

begin


out_type="pdf"

;config="RCE.QPC6.ne0np4tcfplane.ne15x8.exp799.004"
;dayofsim="09"
k10=0.5
cam5=False

plot_vickery=True
plot_blackadar=True
plot_log_ref=True
plot_10m=True
plot_K_ref=True

;if(cam5) then
;  config="newcyclone30x8_CAM5"
;end if

if(cam5) then
  FILEDIR="/glade/u/home/zarzycki/scratch/TC_PBL/"+config+"/run/"
  filename = FILEDIR+"/"+config+".cam.h1.0001-01-"+dayofsim+"-00000.nc_regrid.nc"
  f2= FILEDIR+"/"+config+".cam.h3.0001-01-"+dayofsim+"-00000.nc_regrid.nc"
  kvmvar="UW_kvm"
  tkevar="UW_tke"
  lengthvar="UW_leng"
else
  FILEDIR="/glade/u/home/zarzycki/scratch/TC_PBL/"+config+"/run/"
  filename = FILEDIR+"/"+config+".cam.h1.0001-01-"+dayofsim+"-00000.nc_regrid.nc"
  f2= FILEDIR+"/"+config+".cam.h3.0001-01-"+dayofsim+"-00000.nc_regrid.nc"
  kvmvar="KVH_CLUBB"
;  kvmvar="DTCOND"
  tkevar="TKE_CLUBB"
;  tkevar="DTCOND"
  lengthvar="LSCALE_CLUBB"
;  lengthvar="DTCOND"
end if



thefile = addfile(filename,"r")
tf2 = addfile(f2,"r")


stride = 1
topLev = 500.
botLev = 1050.
maxLat=-25.
minLat=25.
timeStep=0

pi=3.14159

lat = thefile->lat({maxLat:minLat:stride})
lon = thefile->lon(::stride)
lev = thefile->lev({topLev:botLev})
lev@units = "hPa"
fulllev = thefile->lev
print(lev)
print(fulllev)
toplevix = ind_nearest_coord (lev(0), fulllev, 0)
botlevix = ind_nearest_coord (lev((dimsizes(lev)-1)), fulllev, 0)

print(toplevix+" "+botlevix)

hyam=thefile->hyam(toplevix:botlevix)
hybm=thefile->hybm(toplevix:botlevix)
hyai=thefile->hyai(toplevix+1:botlevix+1)
hybi=thefile->hybi(toplevix+1:botlevix+1)
;P0=thefile->P0
P0=100000.
P0@units="hPa"

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
;Zlev = (/50.,100.,150.,200.,250.,300.,350.500.,750.,1000.,2000.,3000.,4000.,5000.,10000./)
Zlev@units = "m"
Zlev!0     = "Zlev"
Zlev&Zlev = Zlev

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
rad_v_rad = -rad_v_rad  ; NEGATIVE FOR CONVENTION
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
print(max(rad_MSE))
print(min(rad_MSE))

; find RMW
rad_sfc_v_theta=rad_v_theta({70.},:)
inds = maxind(rad_sfc_v_theta)
rad_max = rad_sfc_v_theta&radius(inds)   ; insert the longitude index into the lon coordinate variable
print("Maximum value located at, "+rad_max)
rad_max_2x = rad_max*2

rad_v_theta_vert=new((/2,nlev_rad/),"float")
rad_v_theta_vert!1 = "lev"
rad_v_theta_vert&lev = rad_v_theta&lev

rad_v_rad_vert = rad_v_theta_vert
rad_W_vert     = rad_v_theta_vert
rad_KVM_vert   = rad_v_theta_vert
rad_TKE_vert   = rad_v_theta_vert
rad_LSCALE_vert   = rad_v_theta_vert
rad_THETA_vert   = rad_v_theta_vert
rad_T_vert   = rad_v_theta_vert
rad_Q_vert   = rad_v_theta_vert
rad_CLDLIQ_vert   = rad_v_theta_vert
rad_MSE_vert   = rad_v_theta_vert
rad_CME_vert   = rad_v_theta_vert
rad_DTCOND_vert   = rad_v_theta_vert


rad_v_theta_vert(0,:) = tofloat(rad_v_theta(:,{rad_max}))
rad_v_rad_vert(0,:) = tofloat(rad_v_rad(:,{rad_max}))
rad_W_vert(0,:) = tofloat(rad_W(:,{rad_max}))
rad_KVM_vert(0,:) = tofloat(rad_KVM(:,{rad_max}))
rad_TKE_vert(0,:) = tofloat(rad_TKE(:,{rad_max}))
rad_LSCALE_vert(0,:) = tofloat(rad_LSCALE(:,{rad_max}))
rad_THETA_vert(0,:) = tofloat(rad_THETA(:,{rad_max}))
rad_T_vert(0,:) = tofloat(rad_T(:,{rad_max}))
rad_Q_vert(0,:) = tofloat(rad_Q(:,{rad_max}))
rad_CLDLIQ_vert(0,:) = tofloat(rad_CLDLIQ(:,{rad_max}))
rad_MSE_vert(0,:) = tofloat(rad_MSE(:,{rad_max}))
rad_CME_vert(0,:) = tofloat(rad_CME(:,{rad_max}))
rad_DTCOND_vert(0,:) = tofloat(rad_DTCOND(:,{rad_max}))

rad_v_theta_vert(1,:) = tofloat(rad_v_theta(:,{rad_max_2x}))
rad_v_rad_vert(1,:) = tofloat(rad_v_rad(:,{rad_max_2x}))
rad_W_vert(1,:) = tofloat(rad_W(:,{rad_max_2x}))
rad_KVM_vert(1,:) = tofloat(rad_KVM(:,{rad_max_2x}))
rad_TKE_vert(1,:) = tofloat(rad_TKE(:,{rad_max_2x}))
rad_LSCALE_vert(1,:) = tofloat(rad_LSCALE(:,{rad_max_2x}))
rad_THETA_vert(1,:) = tofloat(rad_THETA(:,{rad_max_2x}))
rad_T_vert(1,:) = tofloat(rad_T(:,{rad_max_2x}))
rad_Q_vert(1,:) = tofloat(rad_Q(:,{rad_max_2x}))
rad_CLDLIQ_vert(1,:) = tofloat(rad_CLDLIQ(:,{rad_max_2x}))
rad_MSE_vert(1,:) = tofloat(rad_MSE(:,{rad_max_2x}))
rad_CME_vert(1,:) = tofloat(rad_CME(:,{rad_max_2x}))
rad_DTCOND_vert(1,:) = tofloat(rad_DTCOND(:,{rad_max_2x}))

; find surface inflow angle
do ii = 0,nlev_rad-1
  if(.not. ismissing(rad_v_theta_vert(0,ii))) then
    sfc_inflow_ang=atan(rad_v_rad_vert(0,ii)/rad_v_theta_vert(0,ii))*180./pi
    sfc_radial_flow=abs(rad_v_rad_vert(1,ii))
    break
  else
    print("Missing value in search for lowest model level...")
  end if
end do

do ii = 0,nlev_rad-1
  if(.not. ismissing(rad_v_theta_vert(1,ii))) then
    if (abs(rad_v_rad_vert(1,ii)) .ge. 0.1*sfc_radial_flow) then
      print("Searing for inflow depth -- at z: "+Zlev(ii)+" "+rad_v_rad_vert(1,ii)+" compared to: "+(0.1*sfc_radial_flow))
      inflow_depth=Zlev(ii)
    else
      print("Breaking -- at z: "+Zlev(ii)+" "+rad_v_rad_vert(1,ii)+" compared to: "+(0.1*sfc_radial_flow))
      break
    end if
  else
    print("Missing value in search for inflow depth...")
  end if
end do

print("-------------------------------------------------------------------")
print("surface inflow angle: "+abs(sfc_inflow_ang))
print("inflow depth: "+inflow_depth+" "+Zlev@units)
print("-------------------------------------------------------------------")

;==================================================================================================
outDir="./netcdf/"
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
;==================================================================================================

end

