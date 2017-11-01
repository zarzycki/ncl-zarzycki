;========================================================
; This code reads in two sets of RSI files from ensemble members in LENS
; and plots a scatterplot of number of storms per decade over two different time periods
; It also calculates the odds of period 1 having more storms than period 2 using
; a bootstrapping sampling procedure (assuming ensemble members independant)
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;========================================================
begin

out_type="x11"

MINCAT = 1
MAXCAT = 5

RSIlist1=systemfunc("ls /home/zarzycki/snow/LES-snow/stats/RSI.SNOW.LENS.1990.0*.5e-9_12.csv.SNOW.tempest.csv")
RSIlist2=systemfunc("ls /home/zarzycki/snow/LES-snow/stats/RSI.SNOW.LENS.2071.0*.5e-9_12.csv.SNOW.tempest.csv")

if (dimsizes(RSIlist1) .ne. dimsizes(RSIlist2)) then
  print("Sizes of RSI arrays not equal, exiting...")
  exit()
end if

delim = ","

nmembers1=dimsizes(RSIlist1)
nmembers2=dimsizes(RSIlist2)

x1=new(nmembers1,"float")
x2=new(nmembers2,"float")

; number of years in each member sample size
; 16 for 1990-2015
; 10 for 2026-2035 and 2071-2080
yrspmem1=16
yrspmem2=10

do ii = 0,nmembers1-1
  
  ; read RSI files
  lines1 = asciiread(RSIlist1(ii),-1,"string")
  RSIcat1   = tointeger(str_get_field(lines1,7,delim))
  lines2 = asciiread(RSIlist2(ii),-1,"string")
  RSIcat2   = tointeger(str_get_field(lines2,7,delim))

  bool1 = RSIcat1
  bool2 = RSIcat2

  ; find how many events >=MINCAT and <=MAXCAT
  bool1 = where((RSIcat1 .ge. MINCAT .and. RSIcat1 .le. MAXCAT) , 1, 0)
  bool2 = where((RSIcat2 .ge. MINCAT .and. RSIcat2 .le. MAXCAT) , 1, 0)

  ; storms per year
  x1(ii) = tofloat(sum(bool1)) / tofloat(yrspmem1)
  x2(ii) = tofloat(sum(bool2)) / tofloat(yrspmem2)
 
  ; storms per decade
  x1(ii) = x1(ii) * 10.
  x2(ii) = x2(ii) * 10.

  delete(lines1)
  delete(lines2)
  delete(RSIcat1)
  delete(RSIcat2)
  delete(bool1)
  delete(bool2)
end do

maxmax = max((/max(x1),max(x2)/))
print(maxmax)

; resampling
nsamples=10000
x1r=new(nsamples,"float")
x2r=new(nsamples,"float")
x1rr=new(nsamples,"float")
x2rr=new(nsamples,"float")
ratior=new(nsamples,"float")
ratior=0.0
ratiorr=ratior
low  = 0
high = nmembers1

; Randomly get seed based on clock
rseed1 = toint(systemfunc(" date +%s"))
rseed2 = toint((12345l*rseed1)%2147483398l)
random_setallseed(rseed1, rseed2)
do jj = 0,nsamples-1
  unf = toint(floor(random_uniform(low, high, 8)))
  ; bootstraps one climatology regardless of ensemble member
  x1r(jj) = x1(unf(0))
  x2r(jj) = x2(unf(1))
  ; this bootstraps 3 non-consecutive "segments"
  x1rr(jj) = x1(unf(2)) + x1(unf(3)) + x1(unf(4))
  x2rr(jj) = x2(unf(5)) + x2(unf(6)) + x2(unf(7))
  if (x1r(jj) .ge. x2r(jj)) then
    ratior(jj)=1.
  end if
  if (x1rr(jj) .ge. x2rr(jj)) then
    ratiorr(jj)=1.
  end if
end do

; Percentage of events in RSILIST1 > RSILIST2
print(sum(ratior)/tofloat(nsamples))
; Percentage of events in RSILIST1 > RSILIST2 (with 3 cycle sampling)
print(sum(ratiorr)/tofloat(nsamples))

;************************************************
; plotting parameters
;************************************************
wks   = gsn_open_wks (out_type,"scatter")           ; send graphics to PNG file

res                     = True                   ; plot mods desired
res@gsnDraw = False
res@gsnFrame = False

res@xyMarkLineModes     = "Markers" 
res@xyMarkers           = 16                     ; choose type of marker 
res@xyMarkerColor       = "red"                  ; Marker color
res@xyMarkerSizeF       = 0.01                  ; Marker size (default 0.01)

res@tiMainString        = "Output from regline"  ; title

res@trXMaxF  =  maxmax*1.05
res@trYMaxF  =  maxmax*1.05
res@trXMinF  =  -0.05
res@trYMinF  =  -0.05

plot  = gsn_csm_xy (wks,x1,x2,res)        ; create plot

plres=True
dum1 = gsn_add_polyline  (wks, plot, (/-10,1000/), (/-10,1000/), plres)

draw(plot)
frame(wks)

end
