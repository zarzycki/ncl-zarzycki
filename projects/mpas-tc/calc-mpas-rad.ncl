load "/glade/u/home/zarzycki/ncl/functions/radialAvg.ncl"

begin

stride = 1        ; how many cells to skip (set to 1 for all)
topLev = 15000.    ; top level of analysis
botLev = 0.       ; lowest level of analysis (set to something like 1050+ for surface)
minLat=17.        ; lat bound to extract
maxLat=35.        ; lat bound to extract
timeStep=0        ; what timestep of file (set to 0 for single indexed files)
file_3D=addfile("/glade/u/home/zarzycki/scratch/for-bill/MPAS.cam.h1.2008-08-31-00000.nc_remap.nc","r")
file_2D=addfile("/glade/u/home/zarzycki/scratch/for-bill/MPAS.cam.h0.2008-08-31-00000.nc_remap.nc","r")

; get data
lat = file_3D->lat({minLat:maxLat:stride})
lon = file_3D->lon(::stride)
lev = file_3D->lev({topLev:botLev})
lev@units = "m"
fulllev = file_3D->lev
toplevix = ind_nearest_coord (lev(0), fulllev, 0)
botlevix = ind_nearest_coord (lev((dimsizes(lev)-1)), fulllev, 0)
nlat = dimsizes(lat)
nlon = dimsizes(lon)
nlev = dimsizes(lev)
U = file_3D->U(timeStep,{topLev:botLev},{minLat:maxLat:stride},::stride)
V = file_3D->V(timeStep,{topLev:botLev},{minLat:maxLat:stride},::stride)
T = file_3D->T(timeStep,{topLev:botLev},{minLat:maxLat:stride},::stride)
PS1 = file_2D->PSL(timeStep,{minLat:maxLat:stride},::stride)

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

Z = conform(v_theta,lev,0)

; generate Zlev
Zlev = fspan(0.,12000.,121)
Zlev@units = "m"
Zlev!0     = "Zlev"
Zlev&Zlev = Zlev

; do vertical interpolation from model levels to equally spaced Z levels
interp_type=1
v_theta_Z  = int2p_n_Wrap(Z,v_theta,Zlev,interp_type,0)
v_rad_Z    = int2p_n_Wrap(Z,v_rad,Zlev,interp_type,0)
t_Z    = int2p_n_Wrap(Z,T,Zlev,interp_type,0)

print(lat)
print(lon)

; do radial integrals
rad_v_theta  = radialAvg3D(v_theta_Z,lat,lon,Zlev,psminlat,psminlon,500.,True)
rad_v_rad    = radialAvg3D(v_rad_Z,lat,lon,Zlev,psminlat,psminlon,500.,True)
rad_v_rad    = -rad_v_rad  ; SWITCH TO NEGATIVE FOR CONVENTION
rad_t      = radialAvg3D(t_Z,lat,lon,Zlev,psminlat,psminlon,500.,True)

; crudely calculate t_anomaly
nrad = dimsizes(rad_t&radius)
rad_t_anom = rad_t
rad_t_anom = rad_t - conform(rad_t,rad_t(:,nrad-1),0)

;==================================================================================================
; WRITE NETCDF
;==================================================================================================
outDir="./"
system("mkdir -p "+outDir)
outFile="radial_avg.nc"
system("/bin/rm -f "+outDir+"/"+outFile)   ; remove any pre-existing file
ncdf = addfile(outDir+"/"+outFile ,"c")  ; open output netCDF file

fAtt               = True            ; assign file attributes
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes
filedimdef(ncdf,"time",-1,True) 

ncdf->rad_v_theta  =rad_v_theta  
ncdf->rad_v_rad  =rad_v_rad   
ncdf->rad_T  =rad_t
ncdf->rad_TA  =rad_t_anom

end

