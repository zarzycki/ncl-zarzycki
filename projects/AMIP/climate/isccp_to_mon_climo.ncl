load "$NCARG_NCARG/nclscripts/csm/gsn_code.ncl"
load "$NCARG_NCARG/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_NCARG/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

isccpmonthly = addfile("/glade/scratch/zarzycki/ncep/MnCldAmt.nc","r")
time_full = isccpmonthly->time
numtimes = dimsizes(time_full)
sttime = 6 ;month to start
time = isccpmonthly->time(sttime:numtimes-1)

utc_date = ut_calendar(time, -1)

print(utc_date)

MnCldAmt = isccpmonthly->MnCldAmt(sttime:numtimes-1,:,:)

MnCldAmtClm = clmMonTLL( MnCldAmt )

printVarSummary(MnCldAmtClm)

system("/bin/rm -f /glade/scratch/zarzycki/ncep/isccp_d2_climo.nc")   ; remove any pre-existing file
ncdf     = addfile("/glade/scratch/zarzycki/ncep/isccp_d2_climo.nc" ,"c")  ; open output netCDF file

filedimdef(ncdf,"time",-1,True) 

ncdf->MnCldAmt = MnCldAmtClm
;ncdf->T500 = T500     
;ncdf->T850 = T850 
;ncdf->OMEGA500 = OMEGA500     
;ncdf->OMEGA850 = OMEGA850 
;ncdf->PRECT = PRECT
;ncdf->FSNS = FSNS
;ncdf->TMQ = TMQ

end

