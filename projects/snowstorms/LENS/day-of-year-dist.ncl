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
out_type="x11"
RSIthresh=3
PRECTSNOW="SNOW"

;modelfiles=(/"/glade/u/home/zarzycki/scratch/LES-snow/stats/RSI.SNOW.LENS.1990.ALL.5e-9_12.csv."+PRECTSNOW+".tempest.csv","/glade/u/home/zarzycki/scratch/LES-snow/stats/RSI.SNOW.LENS.2026.ALL.5e-9_12.csv."+PRECTSNOW+".tempest.csv","/glade/u/home/zarzycki/scratch/LES-snow/stats/RSI.SNOW.LENS.2071.ALL.5e-9_12.csv."+PRECTSNOW+".tempest.csv"/)
;modelcolors=(/"blue","green","red"/)
;labelsArr=(/"1990-2005 (RSI>="+RSIthresh+")","2026-2035 (RSI>="+RSIthresh+")","2071-2080 (RSI>="+RSIthresh+")"/)
;nyearsPerSample=(/35*16,35*10,35*10/)

modelfiles=(/"/glade/u/home/zarzycki/scratch/LES-snow/stats/RSI.SNOW.LENS.1990.ALL.5e-9_12.csv."+PRECTSNOW+".tempest.csv","/glade/u/home/zarzycki/scratch/LES-snow/stats/RSI.SNOW.JRA.ALL.5e-9_12.csv."+PRECTSNOW+".tempest.csv"/)
modelcolors=(/"blue","red"/)
labelsArr=(/"LENS PD (RSI>="+RSIthresh+")","JRA PD (RSI>="+RSIthresh+")"/)
nyearsPerSample=(/35*16,60/)



nCases=dimsizes(modelfiles)

out_string="pdf/DoY-dist-RSIge"+RSIthresh


doyArray=new((/nCases,50000/),"float")

do z = 0,nCases-1

filename = modelfiles(z)

lines = asciiread(filename,-1,"string")
delim = ","
member  =           str_get_field(lines,1,delim)
stormID  =           tointeger(str_get_field(lines,2,delim))
RSIval = tofloat(str_get_field(lines,3,delim))
RSIcat  =   tointeger(str_get_field(lines,7,delim))
YYYYMMDDHH = str_get_field(lines,4,delim)

; split times
dtime_map = (/4,2,2,2/)
tst_dtime = str_split_by_length(YYYYMMDDHH, dtime_map)
YYYY=toint(tst_dtime(:,0))
MM=toint(tst_dtime(:,1))
DD=toint(tst_dtime(:,2))
YYYY@calendar="no_leap"

doy = day_of_year(YYYY,MM,DD)
doy = where(RSIcat.ge.RSIthresh,doy,doy@_FillValue)
doy = doy-213     ; 213 = aug 1
doy = where(doy .lt. 0, doy + 365,doy)

doyArray(z,0:(dimsizes(doy)-1)) = doy


delete(lines)
delete(member)
delete(stormID)
delete(RSIcat)
delete(RSIval)

delete(YYYYMMDDHH)
delete(dtime_map)
delete(tst_dtime)
delete(YYYY)
delete(MM)
delete(DD)
delete(doy)

end do

; calc historgrams
binSettings=True
binSettings@bin_min=0.0
binSettings@bin_max=365.0
nbins=26

ap  = pdfx(doyArray(0,:), nbins, binSettings)
if (nCases .gt. 1) then
  bp  = pdfx(doyArray(1,:), nbins, binSettings)
  if (nCases .gt. 2) then
    cp  = pdfx(doyArray(2,:), nbins, binSettings)
  end if
end if

nVar = nCases

nBin    = ap@nbins          ; retrieve the number of bins
xx      = new ( (/nVar, nBin/), typeof(ap))
xx(0,:) = ap@bin_center
if (nCases .gt. 1) then
  xx(1,:) = bp@bin_center
  if (nCases .gt. 2) then
    xx(2,:) = cp@bin_center
  end if
end if

yy      = new ( (/nVar, nBin/), typeof(ap))
yy(0,:) = (/ ap*num(doyArray(0,:))/100./nyearsPerSample(0) /)
if (nCases .gt. 1) then
  yy(1,:) = (/ bp*num(doyArray(1,:))/100./nyearsPerSample(1) /)
  if (nCases .gt. 2) then
    yy(2,:) = (/ bp*num(doyArray(2,:))/100./nyearsPerSample(2) /)
  end if
end if
;yy(0,0) = 
;==================

wks = gsn_open_wks(out_type,out_string)

plot = new(1,graphic)

res  = True

res@gsnDraw=False
res@gsnFrame=False

res@xyLineThicknesses        = (/8.0,8.0,8.0/)
res@xyLineColors             = modelcolors
res@xyMonoDashPattern        = False              ; all solid
res@xyDashPatterns = (/0,0,0/)
res@tiYAxisString            = "Storm biweekly prob. (%)"
res@tiXAxisString            = "Day of Year"

res@trXMinF           = 0.
res@trXMaxF           = 365.

res@tmXBMode      = "Explicit"   ; Define your own tick mark labels.
res@tmXBLabelFontHeightF = 0.015 ; Change font height of labels.
;res@tmXBMinorOn   = False        ; No minor tick marks.
;res@tmXBValues= (/0,31,61,92,122,153,182,211,242,272,303,334,365/)
;res@tmXBLabels= (/"Aug","Sep","Oct","Nov","Dec","Jan","Feb","Mar","Apr","May","Jun","Jul","Aug"/)
res@tmXBValues= (/0,61,122,182,242,303,365/)
res@tmXBLabels= (/"Aug 1","Oct 1","Dec 1","Feb 1","Apr 1","Jun 1","Aug 1"/)
res@tmXBMinorValues = (/0,31,61,92,122,153,182,211,242,272,303,334,365/)

plot(0) = gsn_csm_xy (wks, xx, yy*100., res)

lgres                    = True
lgres@lgLabelFontHeightF = .06
lgres@vpWidthF           = 0.2
lgres@vpHeightF          = 0.08
lgres@lgPerimColor       = "black"
lgres@lgPerimThicknessF  = 1.0
lgres@lgItemType         = "Lines"
lgres@lgLineColors     = res@xyLineColors
lgres@lgDashIndexes = res@xyDashPatterns
lgres@lgMonoLineThickness = False
lgres@lgLineThicknesses = res@xyLineThicknesses
lbid = gsn_create_legend(wks,nCases,labelsArr,lgres)

amres = True
amres@amJust="TopRight"
amres@amParallelPosF   = 0.49             ; move legend to the right
amres@amOrthogonalPosF = -0.49             ; move the legend down
annoid1 = gsn_add_annotation(plot,lbid(0),amres)   ; add legend to plot

resP = True
gsn_panel(wks,plot,(/1,1/),resP)             ; now draw as one plot
   

end
