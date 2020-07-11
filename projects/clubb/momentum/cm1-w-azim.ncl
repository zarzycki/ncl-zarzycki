; NOTES


begin


FILEDIR="/glade/p/mmm/dpm/gbryan/fthurr/fthurr207_0032/"
filename = FILEDIR+"/azim_avg.nc"
thefile = addfile(filename,"r")

UPWPH = thefile->upwpf(0,:,0,:)
VPWPH = thefile->vpwpf(0,:,0,:)

STRESS = UPWPH
STRESS = sqrt(UPWPH^2 + VPWPH^2)

DUDZ = thefile->dudz(0,:,0,:)
DVDZ = thefile->dvdz(0,:,0,:)

eps = 1e-8
K = DUDZ
K = -UPWPH/(DUDZ+eps)

;==================================================================================================
outDir="./netcdf/"
system("mkdir -p "+outDir)
outFile="az_cm1.nc"
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
ncdf->STRESS = STRESS
ncdf->K = K

;==================================================================================================

end

