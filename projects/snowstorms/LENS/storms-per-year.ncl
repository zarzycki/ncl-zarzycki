;========================================================
; This file reads in a traj file produced by the TC tracker
; and produces a lat-lon plot of trajectories color-coded by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;========================================================
begin

plot_log=False
out_type="pdf"
RSIthresh=1

DEG="12"
SLR="12"
BASEDIR="/glade/u/home/zarzycki/scratch/LES-snow/stats/"
modelstrs=(/"1990","2026","2071"/)
modelfiles=(/BASEDIR+"/RSI.LENS."+modelstrs+".ALL.csv"/)
modelcolors=(/"blue2","green2","red2"/)
labelsArr=(/"  1990-2005","  2026-2035","  2071-2080"/)
stYrs=(/1990,2026,2071/)
enYrs=(/2005,2035,2080/)

nyearsPerSample=(/35*16,35*10,35*10/)

nCases=dimsizes(modelfiles)

timeArray=new((/nCases,50000/),"float")

days_units="days since 1900-01-01 00:00:00"

do z = 0,nCases-1

filename = modelfiles(z)

lines = asciiread(filename,-1,"string")
delim = ","
member  =           str_get_field(lines,1,delim)
;stormID  =           tointeger(str_get_field(lines,2,delim))
RSIval = tofloat(str_get_field(lines,3,delim))
RSIcat  =   tointeger(str_get_field(lines,7,delim))
YYYYMMDDHH = str_get_field(lines,4,delim)

; split times
dtime_map = (/4,2,2,2/)
tst_dtime = str_split_by_length(YYYYMMDDHH, dtime_map)
YYYY=toint(tst_dtime(:,0))
MM=toint(tst_dtime(:,1))
DD=toint(tst_dtime(:,2))

ZERO=DD
ZERO=0

opt = 0
opt@calendar="no_leap"

YYYY@_FillValue=-999
YYYY = where(RSIcat.ge.RSIthresh,YYYY,YYYY@_FillValue)

; First get rid of filtered storms
iz = ind(.not.ismissing(YYYY))
YYYY := YYYY(iz)
delete(iz)

; do number of storms per year
STYR=stYrs(z)
ENYR=enYrs(z)
NYR=ENYR-STYR+1
yrArr=ispan(STYR,ENYR,1)
counts=yrArr
counts=0

do ii=0,NYR-1
  counts(ii) = num(YYYY.eq.yrArr(ii))
end do

print(yrArr+" "+counts)



delete(counts)
delete(yrArr)




delete(lines)
delete(member)
delete(RSIcat)
delete(RSIval)

delete(YYYYMMDDHH)
delete(dtime_map)
delete(tst_dtime)
delete(YYYY)
delete(MM)
delete(DD)
delete(ZERO)

end do

end
