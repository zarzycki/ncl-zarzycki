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

;filename = "/glade/p/work/zarzycki/reanalysis-20160803/cat.rates.txt.JRA.DZ300500"
filename = "/glade/p/work/zarzycki/reanalysis-monte/rates.txt.JRA.DZ300500.ALL"

do_plot=False
do_ranking_plot=False
do_sort_rank=True

sortDir=1    ; 1 is descending, 0 is ascending
nvars=12     ; number of sample vars

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

; ====== This is the variable we want to sort by...
SORTVAR=HRMINFA

SORTVAR_SORT=SORTVAR
ENSNUM_SORT=ENSNUM
sortitF1S1(SORTVAR_SORT,ENSNUM_SORT,sortDir)

delete(SORTVAR_SORT)
SORTVAR_SORT=SORTVAR
CONFIG_SORT=CONFIG
sortitF1S1(SORTVAR_SORT,CONFIG_SORT,sortDir)

delete(SORTVAR_SORT)
SORTVAR_SORT=SORTVAR
THEVAR_SORT=THEVAR
sortitF1S1(SORTVAR_SORT,THEVAR_SORT,sortDir)

delete(SORTVAR_SORT)
SORTVAR_SORT=SORTVAR
NUM_AS_SORT=NUM_AS
sortitF1I1(SORTVAR_SORT,NUM_AS_SORT,sortDir)

delete(SORTVAR_SORT)
SORTVAR_SORT=SORTVAR
HR_TS_SORT=HR_TS
sortitF1F1(SORTVAR_SORT,HR_TS_SORT,sortDir)

delete(SORTVAR_SORT)
SORTVAR_SORT=SORTVAR
HR_HU_SORT=HR_HU
sortitF1F1(SORTVAR_SORT,HR_HU_SORT,sortDir)

delete(SORTVAR_SORT)
SORTVAR_SORT=SORTVAR
FA_AS_SORT=FA_AS
sortitF1F1(SORTVAR_SORT,FA_AS_SORT,sortDir)

delete(SORTVAR_SORT)
SORTVAR_SORT=SORTVAR
NUM_AS_SORT=NUM_AS
sortitF1I1(SORTVAR_SORT,NUM_AS_SORT,sortDir)

delete(SORTVAR_SORT)
SORTVAR_SORT=SORTVAR
varStruct_SORT=varStruct
sortitF1F2(SORTVAR_SORT,varStruct_SORT,sortDir)

varStructString=new(nrows,"string")
do i = 0,nrows-1
  varStructString(i)=""
  do j = 0,nvars-1
    if (j .eq. nvars-1) then
      varStructString(i)=varStructString(i)+varStruct_SORT(j,i)
    else
      varStructString(i)=varStructString(i)+varStruct_SORT(j,i)+","
    end if
  end do
end do

; Testing ranking using weighted score with equal delta between configs
;wgtRank = sum(varStruct_SORT(10,:)*2*INDEXARR(::-1))/(sum(2*INDEXARR))
;print(wgtRank)

print("SORTVAR_SORT is " + SORTVAR_SORT + "  HR_TS_SORT is " + HR_TS_SORT + "  HR_HU_SORT is " + HR_HU_SORT + "   FA_AS_SORT is " + FA_AS_SORT +" "+ENSNUM_SORT+" "+CONFIG_SORT+" "+THEVAR_SORT+"  varStruct_SORT "+varStructString)

if (do_sort_rank) then
  ;;; do rankings
  ; get rid of zeros
  SORTVAR_SORT=where(SORTVAR_SORT.eq.0,SORTVAR_SORT@_FillValue,SORTVAR_SORT)
  nonmiss_ix = ind(.not.ismissing(SORTVAR_SORT))
  if (.not.all(ismissing(nonmiss_ix))) 
     SORT_RANK = SORTVAR_SORT(nonmiss_ix)   
     THEVAR_RANK = THEVAR_SORT(nonmiss_ix)
  else
     print ("all SORTVAR_SORT are missing")
  end if

  RANKS=ispan(1,num(nonmiss_ix)+1,1)
  printVarSummary(RANKS)
  printVarSummary(SORT_RANK)

  ;vars=(/"T500","T400","T300"/)
  ;vars=(/"DZ300500","DZ400500","DZ200500"/)
  vars=(/"DZ300500","DZ400500","DZ200500","T500","T400","T300"/)
  do ii = 0,dimsizes(vars)-1
    TMPRANK=RANKS
    TMPRANK=where(THEVAR_RANK.eq.vars(ii),RANKS,RANKS@_FillValue)
    print("sum "+vars(ii)+" "+sum(TMPRANK))
    delete(TMPRANK)
  end do
end if



if (do_plot) then
  wks   = gsn_open_wks ("x11","scatter")            ; open workstation

  res                   = True                     ; plot mods desired
  res@gsnMaximize       = True                     ; maximize plot
  res@tiMainString      = "Scatter Plot"           ; add title
  res@xyMarkLineMode    = "Markers"                ; choose to use markers
  res@xyMarkers         =  16                      ; choose type of marker  
  res@xyMarkerColor     = "NavyBlue"               ; Marker color
  res@xyMarkerSizeF     = 0.003                     ; Marker size (default 0.01)

  plot = gsn_csm_xy(wks,INDEXARR,varStruct_SORT(10,:),res)                    ; create plot
end if

if (do_ranking_plot) then
  wks   = gsn_open_wks ("pdf","var-ranking")            ; open workstation

  res                   = True                     ; plot mods desired
  res@tiMainString      = "Var Rankings (HR-FA)"           ; add title
  res@xyMarkLineMode    = "Markers"                ; choose to use markers
  res@xyMarkers         = 16                       ; choose type of marker
  res@xyMarkerSizeF     = 0.001                     ; Marker size (default 0.01)

  vars=(/"T500","DZ300500","T400"/)
  colors=(/"green","red","blue"/)
  numVars=dimsizes(vars)
  xyArr=new((/numVars,dimsizes(INDEXARR)/),"integer")
  do i = 0,numVars-1
    xyArr(i,:) = where(THEVAR_SORT.eq.vars(i),INDEXARR,INDEXARR@_FillValue)
  end do


  res@xyMonoMarkerColor = False
  res@xyMarkerColors    = colors           ; Marker color
  
  plot = gsn_csm_xy(wks,xyArr,xyArr,res)                    ; create plot
end if


end
