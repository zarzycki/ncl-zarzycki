load "$NCARG_NCARG/nclscripts/csm/gsn_code.ncl"
load "$NCARG_NCARG/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_NCARG/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

dest_file="/glade/u/home/zarzycki/scratch/AR_vr_snow/vr_climo.nc"
file_to_interp="/glade/u/home/zarzycki/scratch/AR_vr_snow/1deg_climo.nc"
output_file="/glade/u/home/zarzycki/scratch/AR_vr_snow/1deg_climo.nc_regrid.nc"

; Get lat/lon and gw arrays from model
destFile = addfile(dest_file,"r")
destLat = destFile->lat
destLon = destFile->lon
destGW = destFile->gw

interpFile = addfile(file_to_interp,"r")
interpLat = interpFile->lat
interpLon = interpFile->lon
PRECT_n = interpFile->PRECT
CLDTOT_n = interpFile->CLDTOT
PSL_n = interpFile->PSL
U850_n = interpFile->U850
V850_n = interpFile->V850
T850_n = interpFile->T850
Z500_n = interpFile->Z500

PRECT = linint2_Wrap (interpLon,interpLat,PRECT_n,True,destLon,destLat, 0)
CLDTOT = linint2_Wrap (interpLon,interpLat,CLDTOT_n,True,destLon,destLat, 0)
PSL = linint2_Wrap (interpLon,interpLat,PSL_n,True,destLon,destLat, 0)
U850 = linint2_Wrap (interpLon,interpLat,U850_n,True,destLon,destLat, 0)
V850 = linint2_Wrap (interpLon,interpLat,V850_n,True,destLon,destLat, 0)
T850 = linint2_Wrap (interpLon,interpLat,T850_n,True,destLon,destLat, 0)
Z500 = linint2_Wrap (interpLon,interpLat,Z500_n,True,destLon,destLat, 0)

;============================

system("/bin/rm -f "+output_file)   ; remove any pre-existing file
ncdf     = addfile(output_file ,"c")  ; open output netCDF file

; make time and UNLIMITED dimension      ; recommended  for most applications
filedimdef(ncdf,"time",-1,True) 

; output variables directly
ncdf->gw = destGW
ncdf->PRECT = PRECT
ncdf->CLDTOT = CLDTOT
ncdf->PSL = PSL
ncdf->U850 = U850
ncdf->V850 = V850
ncdf->T850 = T850
ncdf->Z500 = Z500

end

