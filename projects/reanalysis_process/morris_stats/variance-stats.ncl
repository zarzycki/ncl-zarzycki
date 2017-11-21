;========================================================
; This file reads in a traj file produced by the TC tracker
; and produces a lat-lon plot of trajectories color-coded by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "/glade/u/home/zarzycki/ncl/functions/sorting.ncl"
;========================================================

begin

;dataset="CFSR"
;var="T500"

filename = "/glade/p/work/zarzycki/reanalysis-20160803/cat.rates.txt."+dataset+"."+var

zero_out=True

do_plot=False
do_ranking_plot=False
do_scatter_plot=True
sortDir=1    ; 1 is descending, 0 is ascending
nvars=12

print("Reading CSV file...")
lines = asciiread(filename,-1,"string")
delim = ","

print("Parsing CSV file...")
NUM_AS=tointeger(str_get_field(lines,1,delim))
nrows=dimsizes(NUM_AS)
HR_AS=tofloat(str_get_field(lines,2,delim))
HR_TS=tofloat(str_get_field(lines,3,delim))
HR_HU=tofloat(str_get_field(lines,4,delim))
HR_MH=tofloat(str_get_field(lines,5,delim))
FA_AS=tofloat(str_get_field(lines,6,delim))
NUM_HT=tointeger(str_get_field(lines,7,delim))
ACE=tointeger(str_get_field(lines,8,delim))
CONFIG=str_get_field(lines,9,delim)
THEVAR=str_get_field(lines,10,delim)
ENSNUM=str_get_field(lines,11,delim)
varStruct=new((/nvars,nrows/),"float")
do i = 0,nvars-1
  ix = 12+i
  varStruct(i,:) = tofloat(str_get_field(lines,ix,delim))
end do
delete(ix)
;var01=tofloat(str_get_field(lines,10,delim))
;var02=tofloat(str_get_field(lines,11,delim))
;var03=tofloat(str_get_field(lines,12,delim))
;var04=tofloat(str_get_field(lines,13,delim))
;var05=tofloat(str_get_field(lines,14,delim))
;var06=tofloat(str_get_field(lines,15,delim))
;var07=tofloat(str_get_field(lines,16,delim))
;var08=tofloat(str_get_field(lines,17,delim))
;var09=tofloat(str_get_field(lines,18,delim))
;var10=tofloat(str_get_field(lines,19,delim))
;var11=tofloat(str_get_field(lines,20,delim))
delete(lines)
print("... end parsing file")

INDEXARR=ispan(1,nrows,1)

; Do calculations post read
HRMINFA=HR_TS-FA_AS

eps=1e-10
if (zero_out) then
  ACE=where(ACE.le.eps,ACE@_FillValue,ACE)
  NUM_AS=where(NUM_AS.le.eps,NUM_AS@_FillValue,NUM_AS)
  NUM_HT=where(NUM_HT.le.eps,NUM_HT@_FillValue,NUM_HT)
  HR_HU=where(HR_HU.le.eps,HR_HU@_FillValue,HR_HU)
  HR_TS=where(HR_TS.le.eps,HR_TS@_FillValue,HR_TS)
  FA_AS=where(FA_AS.le.eps,FA_AS@_FillValue,FA_AS)

end if

ACE_CV   =stddev(ACE)/avg(ACE)
NUM_AS_CV=stddev(NUM_AS)/avg(NUM_AS)
NUM_HT_CV=stddev(NUM_HT)/avg(NUM_HT)
HR_HU_CV=stddev(HR_HU)/avg(HR_HU)
HR_TS_CV=stddev(HR_TS)/avg(HR_TS)
FA_AS_CV=stddev(FA_AS)/avg(FA_AS)

quote = inttochar(34)
outDir="."
outName="CV_stats.csv"
print("ACE_CV  NUM_AS_CV NUM_HT_CV  HR_HU_CV HR_TS FA_AS")
delim=","
print(ACE_CV+delim+NUM_AS_CV+delim+NUM_HT_CV+delim+HR_HU_CV+delim+HR_TS_CV+delim+FA_AS_CV+delim+dataset+delim+var)
system("echo "+quote+ ACE_CV+delim+NUM_AS_CV+delim+NUM_HT_CV+delim+HR_HU_CV+delim+HR_TS_CV+delim+FA_AS_CV+delim+dataset+delim+var +quote+" >> "+outDir+"/"+outName)

end
