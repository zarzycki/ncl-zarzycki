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

;vartype="T400"  ; DZXXXXXX or TXXX
;vartotest="NUM_HT"
;MODEL1="CFSR"
;MODEL2="MERRA"

if (MODEL1 .eq. MODEL2) then
  print("MODEL1 cannot equal MODEL2")
  exit
end if


filename="/glade/p/work/zarzycki/reanalysis-20160803/cat.rates.txt.ALL."+vartype
out_type="x11"

do_plot=False
do_ranking_plot=False
do_scatter_plot=True
sortDir=1    ; 1 is descending, 0 is ascending
nvars=12     ; number of sample vars

numVars=1

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
NUM_HT=tofloat(str_get_field(lines,7,delim))
ACE=tofloat(str_get_field(lines,8,delim))
CONFIG=str_get_field(lines,9,delim)
THEVAR=str_get_field(lines,10,delim)
ENSNUM=str_get_field(lines,11,delim)
varStruct=new((/nvars,nrows/),"float")

varSingle=new((/nrows/),"string")
varSingle=""
do i = 0,nvars-1
  ix = 12+i
  varStruct(i,:) = tofloat(str_get_field(lines,ix,delim))
  varSingle(:) = varSingle(:)+" "+str_get_field(lines,ix,delim)
end do
delete(ix)

;print(varSingle)

delete(lines)
print("... end parsing file")

INDEXARR=ispan(1,nrows,1)

; Do calculations post read
HRMINFA=HR_TS-FA_AS

num1=0
num2=0
totmatches=0
diffArr=new(nrows,"float",-999.9)

if (vartotest .eq. "ACE") then
  ANLVAR=ACE
  prettyvar="ACE"
else if (vartotest .eq. "HR_TS") then
  ANLVAR=HR_TS
  prettyvar="HR_TS"
else if (vartotest .eq. "FA_AS") then
  ANLVAR=FA_AS
  prettyvar="FA_AS"
else if (vartotest .eq. "NUM_AS") then
  ANLVAR=NUM_AS
  prettyvar="COUNT"
else if (vartotest .eq. "NUM_HT") then
  ANLVAR=NUM_HT
  prettyvar="TCDAYS"
else
  print("incorrect vartotest.. exiting...")
  exit
end if
end if
end if
end if
end if

do jj = 0,nrows-1
  thisString = varSingle(jj)
  thisModel = CONFIG(jj)
  do kk = 0,nrows-1
    if ( kk .ne. jj .and. thisString .eq. varSingle(kk) .and. thisModel .eq. MODEL1 .and. CONFIG(kk) .eq. MODEL2)
      totmatches=totmatches+1
      compstring=(CONFIG(jj)+" "+CONFIG(kk)+" "+ANLVAR(jj)+" "+ANLVAR(kk))
      diffArr(jj) = ANLVAR(jj)-ANLVAR(kk)
      if (ANLVAR(jj) .gt. ANLVAR(kk)) then
        print(" 111111111111 "+compstring)
        num1 = num1+1
      else if (ANLVAR(jj) .lt. ANLVAR(kk)) then
        print("  22222222222 "+compstring)
        num2 = num2+1
      else
        print("------------- "+compstring)
      end if
      end if
    end if
  end do
end do

diffArr=where(diffArr.ne.0,diffArr,diffArr@_FillValue)

print(num1)
print(num2)

  ap  = pdfx(diffArr, 40, False)    ; specify 40 bins

;------------------------------------------------
; 
;------------------------------------------------
  nVar    = 1
  nBin    = ap@nbins          ; retrieve the number of bins

  xx      = new ( (/nVar, nBin/), typeof(ap))
  xx(0,:) = ap@bin_center     ; assign appropriate "x" axis values

  yy      = new ( (/nVar, nBin/), typeof(ap))
  yy(0,:) = (/ ap /)

  wks  = gsn_open_wks ("png","compare_img/"+vartype+"_"+MODEL1+"_"+MODEL2+"_"+prettyvar)                ; send graphics to PNG file
  res  = True
  res@gsnDraw = False
  res@gsnFrame = False

  res@xyLineThicknesses        = (/5.0/)        
  res@xyLineColors             = (/"red"/)  
  res@xyMonoDashPattern        = True              ; all solid 
  res@tiYAxisString            = "PDF (%)"
  res@tiXAxisString = prettyvar+" diff ("+vartype+")"
  res@gsnXYBarChart            = True              ; Create bar plot
  res@gsnXYBarChartOutlineOnly = True

;  res@pmLegendDisplayMode    = "Always"            ; turn on legend
;  res@pmLegendSide           = "Top"               ; Change location of 
;  res@pmLegendParallelPosF   = .25                 ; move units right
;  res@pmLegendOrthogonalPosF = -0.4                ; move units down
;  res@pmLegendWidthF         = 0.125               ; Change width and
;  res@pmLegendHeightF        = 0.15                ; height of legend.
;  res@lgPerimOn              = True                ; turn off/on box around
;  res@lgLabelFontHeightF     = .015                ; label font height
;  res@xyExplicitLegendLabels = (/"AP"/)  ; create explicit labels

  res@tiMainString           = "<-- ("+num2+") "+MODEL2+" | "+MODEL1+" ("+num1+") -->"
  plot = gsn_csm_xy (wks, xx, yy, res)

  zlineres = True
  zlineres@gsLineColor = "black"
  zlineres@gsLineThicknessF = 5.0
  dummy_vert = gsn_add_polyline(wks,plot,(/0,0/),(/-1000,1000/),zlineres)

  draw(plot)
  frame(wks)


end
