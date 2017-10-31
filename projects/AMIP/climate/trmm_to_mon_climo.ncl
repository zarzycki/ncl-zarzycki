load "$NCARG_NCARG/nclscripts/csm/gsn_code.ncl"
load "$NCARG_NCARG/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_NCARG/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

         
trmm_files = systemfunc ("ls /glade/scratch/zarzycki/ncep/TRMM/3B43*.nc")
trmmmonthly      = addfiles (trmm_files, "r")   ; note the "s" of addfile
ListSetType (trmmmonthly, "cat")             ; concatenate or "merge" (default)


pcp = trmmmonthly[:]->pcp

pcpClm = clmMonTLL( pcp )

printVarSummary(pcp)

system("/bin/rm -f /glade/scratch/zarzycki/ncep/trmm_climo.nc")   ; remove any pre-existing file
ncdf     = addfile("/glade/scratch/zarzycki/ncep/trmm_climo.nc" ,"c")  ; open output netCDF file

filedimdef(ncdf,"time",-1,True) 

ncdf->pcp = pcpClm
;ncdf->T500 = T500     
;ncdf->T850 = T850 
;ncdf->OMEGA500 = OMEGA500     
;ncdf->OMEGA850 = OMEGA850 
;ncdf->PRECT = PRECT
;ncdf->FSNS = FSNS
;ncdf->TMQ = TMQ

end

