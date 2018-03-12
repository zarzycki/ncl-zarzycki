load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

anom_filename = "cfsr_z500.grb"
anom_netcdf = "cfsr_z500.nc"
grb_file = addfile(anom_filename,"r")
in = addfile(anom_netcdf,"c")

grblat = grb_file->g0_lat_1
grblon = grb_file->g0_lon_2
grbtime = grb_file->initial_time0_hours

z500 = grb_file->PRES_GDS0_SFC(:,:,:)

ps = grb_file->PRMSL_GDS0_SFC(:,:,:)

system("/bin/rm -f simple.nc")   ; remove any pre-existing file
ncdf = addfile("simple.nc" ,"c")  ; open output netCDF file

; make time and UNLIMITED dimension      ; recommended  for most applications
filedimdef(ncdf,"time",-1,True) 

; output variables directly
ncdf->Z500  = z500                          ; 4D               
ncdf->PS = ps                         ; 3D 

print("done")
  
end

