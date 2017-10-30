;========================================================
; =============== COMMAND LINE ARGS
; YYYYMMMDDHH (string) --- time of CFSR analysis
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;========================================================
begin

f = addfile("/glade/scratch/zarzycki/h1files/JRA//1992/JRA.h1.1992.PRECT.nc","r")

PRECT=f->PRECT
PRECT=PRECT*8.64e7
lat=f->lat
lon=f->lon
time=f->time

wgt  = NormCosWgtGlobe(lat)
glAve = new(dimsizes(time),"float")

do ii = 0,dimsizes(time)-1
  glAve(ii) = wgt_areaave(PRECT(ii,:,:), wgt/1.0, 1.0, 0)
end do

print(glAve)
print(avg(glAve))

exit

print(wgt)

PRECT_avg1 = dim_avg_n_Wrap(PRECT,2)
PRECT_avg = dim_avg_n_Wrap(PRECT_avg1,0)

PRECT_avg=PRECT_avg*wgt  

tot_prect=sum(PRECT_avg)/2.*8.64e7

print(tot_prect)

end