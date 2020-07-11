; NOTES

load "../../../functions/radialAvg.ncl"

begin


FILEDIR="/glade/p/mmm/dpm/gbryan/fthurr/fthurr207_0032/"
filename = FILEDIR+"/avg_and_perts.nc"

thefile = addfile(filename,"r")

stride = 4        ; how many cells to skip (set to 1 for all)
vstride = 1        ; how many cells to skip (set to 1 for all)
timeStep=0        ; what timestep of file (set to 0 for single indexed files)

;; 0 is surface
U = thefile->uf(timeStep,::vstride,::stride,::stride)
V = thefile->vf(timeStep,::vstride,::stride,::stride)
PS1 = thefile->prs(timeStep,0,::stride,::stride)
KMV = thefile->kmv(timeStep,::vstride,::stride,::stride)
KHV = thefile->khv(timeStep,::vstride,::stride,::stride)

UPWPH = thefile->upwph(timeStep,::vstride,::stride,::stride)
VPWPH = thefile->vpwph(timeStep,::vstride,::stride,::stride)

x = thefile->xh(::stride)
y = thefile->yh(::stride)
lon = x / 111.32 / 1000.
lat = y / 111.32 / 1000.
nlat = dimsizes(lat)
nlon = dimsizes(lon)

Zlev = thefile->zf(::vstride)
Zint = thefile->zh(::vstride)
nlev = dimsizes(Zlev)

printVarSummary(Zlev)

printVarSummary(U)

STRESS = sqrt(UPWPH^2 + VPWPH^2)

Z3D = conform(U,Zlev,0)


DUDZ = -(U(1:nlev-1,:,:) - U(0:nlev-2,:,:)) / (Z3D(1:nlev-1,:,:) - Z3D(0:nlev-2,:,:))
DVDZ = -(V(1:nlev-1,:,:) - V(0:nlev-2,:,:)) / (Z3D(1:nlev-1,:,:) - Z3D(0:nlev-2,:,:))


KM = STRESS*((DUDZ^2 + DVDZ^2)^(-0.5))
KM := linint1_n_Wrap(Zint,KM,False,Zlev,0,0)
KM = where(ismissing(KM),0,KM)

copy_VarMeta(U,KM)
copy_VarMeta(U,STRESS)

DUDZ := linint1_n_Wrap(Zint,DUDZ,False,Zlev,0,0)
DUDZ = where(ismissing(DUDZ),0,DUDZ)
copy_VarMeta(U,DUDZ)


;---FIND LOCATIONS OF PSMIN and WINDMAX
a = new((/nlat,nlon/),float)
a(:,:) = PS1(:,:)
a1D      = ndtooned(a)
dsizes_a = dimsizes(a)
a_indices  = ind_resolve(minind(a1D),dsizes_a)
psminlat = lat(a_indices(0,0))
psminlon = lon(a_indices(0,1))
print(psminlat+" "+psminlon)

; calculate radial stuff
print("calculating wind components")
vComps = calcWindComponents(U,V,lat,lon,psminlat,psminlon,0,0)
v_rad = vComps[0]
v_theta = vComps[1]
delete(vComps)

print("calculating radial integral")
rad_v_theta  = radialAvg3D(v_theta,lat,lon,Zlev,psminlat,psminlon,40.,True)
rad_v_rad    = radialAvg3D(v_rad,lat,lon,Zlev,psminlat,psminlon,40.,True)
rad_kmv    = radialAvg3D(KMV,lat,lon,Zlev,psminlat,psminlon,40.,True)
rad_khv    = radialAvg3D(KHV,lat,lon,Zlev,psminlat,psminlon,40.,True)
rad_dudz    = radialAvg3D(DUDZ,lat,lon,Zlev,psminlat,psminlon,40.,True)


;==================================================================================================
outDir="./netcdf/"
system("mkdir -p "+outDir)
outFile="cm1.nc"
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
ncdf->rad_kmv = rad_kmv
ncdf->rad_khv = rad_khv
ncdf->rad_dudz = rad_dudz

;==================================================================================================

end

