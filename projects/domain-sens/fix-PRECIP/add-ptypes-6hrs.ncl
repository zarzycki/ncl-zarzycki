;========================================================
; =============== COMMAND LINE ARGS
; YYYYMMMDDHH (string) --- time of CFSR analysis
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
;========================================================
begin

;ncremap -v PRECBFZ,PRECBIP -i /global/homes/c/czarzyck/scratch/hyperion/CORI.VR28.NATL.WAT.CAM5.4CLM5.0.dtime900.003/atm/hist/CORI.VR28.NATL.WAT.CAM5.4CLM5.0.dtime900.003.cam.h2.2006-11-01-00000.nc -o MAP.nc -m ~/scratch/maps/hyperion/map_ne0np4natlanticwat.ne30x4_to_1.0x1.0_GLOB.nc
;infile="/global/homes/c/czarzyck/scratch/hyperion/CHEY.VR28.NATL.WAT.CAM5.4CLM5.0.dtime900.002/atm/hist/CHEY.VR28.NATL.WAT.CAM5.4CLM5.0.dtime900.002.cam.h4.2014-12-19-00000.nc"

eps=.01

print("USING INFILE:  "+infile)

print("Loading data... ")
in=addfile(infile,"r")
PRECT=in->PRECT(:,:)
PTYPE=in->PTYPE(:,:)
time=in->time
print("... done loading data.")

printVarSummary(PRECT)

dims=dimsizes(PRECT)
ntim=dims(0)
ncol=dims(1)
if (mod(ntim,6) .ne. 0) then
  print("ntim not divisible by 6, probably an end file, let's assume that and chop off")
  ntim=ntim-1
end if
n6hrs=ntim/6
print(n6hrs)
newtime=time(0:ntim-1:6)
print(newtime)
newtime=newtime+0.25

; trick to copy meta data for vars to hold masked precip
PRECB_SN=PRECT
PRECB_IP=PRECT
PRECB_FZ=PRECT
PRECB_RA=PRECT

; mask precip types based on ptype at beginning of hour
INDEX=0.
PRECB_SN=where(PTYPE.ge.(INDEX-eps) .and. PTYPE.le.(INDEX+eps),PRECB_SN,0.0)
INDEX=2.
PRECB_RA=where(PTYPE.ge.(INDEX-eps) .and. PTYPE.le.(INDEX+eps),PRECB_RA,0.0)
INDEX=3.
PRECB_IP=where(PTYPE.ge.(INDEX-eps) .and. PTYPE.le.(INDEX+eps),PRECB_IP,0.0)
INDEX=4.
PRECB_FZ=where(PTYPE.ge.(INDEX-eps) .and. PTYPE.le.(INDEX+eps),PRECB_FZ,0.0)

; gen array to hold avgs, add metadata
PRECB_SN_AVG=new((/n6hrs,ncol/),typeof(PRECB_SN))
PRECB_SN_AVG!0="time"
PRECB_SN_AVG!1="ncol"
PRECB_SN_AVG&time=newtime

; create new avg'ed vars with correct metadata
PRECB_RA_AVG=PRECB_SN_AVG
PRECB_IP_AVG=PRECB_SN_AVG
PRECB_FZ_AVG=PRECB_SN_AVG

; Add long name to variable
PRECB_SN_AVG@long_name="Precipitation rate due to snow from Bourgouin scheme"
PRECB_RA_AVG@long_name="Precipitation rate due to rain from Bourgouin scheme"
PRECB_IP_AVG@long_name="Precipitation rate due to ice pellets from Bourgouin scheme"
PRECB_FZ_AVG@long_name="Precipitation rate due to freezing rain from Bourgouin scheme"

; loop over times, average over index "chunks"
do ii = 0,n6hrs-1
  STIX=ii*6
  ENIX=(ii*6)+5
  print("averaging from time indices:  "+STIX+" "+ENIX)
  PRECB_SN_AVG(ii,:)=dim_avg_n_Wrap(PRECB_SN(STIX:ENIX,:),0)
  PRECB_RA_AVG(ii,:)=dim_avg_n_Wrap(PRECB_RA(STIX:ENIX,:),0)
  PRECB_IP_AVG(ii,:)=dim_avg_n_Wrap(PRECB_IP(STIX:ENIX,:),0)
  PRECB_FZ_AVG(ii,:)=dim_avg_n_Wrap(PRECB_FZ(STIX:ENIX,:),0)
end do

outfilename=str_sub_str(infile,"h4","h8")
outfilename=str_sub_str(outfilename,".nc",".PTYPES.nc")
print(outfilename)

;===================================================================
system("/bin/rm -f "+outfilename)   ; remove any pre-existing file
ncdf = addfile(outfilename,"c")  ; open output netCDF file
fAtt               = True            ; assign file attributes
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes
filedimdef(ncdf,"time",-1,True) 

ncdf->PRECB_SN=PRECB_SN_AVG
ncdf->PRECB_RA=PRECB_RA_AVG
ncdf->PRECB_IP=PRECB_IP_AVG
ncdf->PRECB_FZ=PRECB_FZ_AVG

;===================================================================

end

