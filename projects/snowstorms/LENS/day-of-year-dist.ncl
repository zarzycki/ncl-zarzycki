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
modelfiles=(/"/glade/u/home/zarzycki/scratch/LES-snow/stats/RSI.SNOW.LENS.1990.ALL.5e-9_12.csv.SNOW.tempest.csv","/glade/u/home/zarzycki/scratch/LES-snow/stats/RSI.SNOW.LENS.2026.ALL.5e-9_12.csv.SNOW.tempest.csv","/glade/u/home/zarzycki/scratch/LES-snow/stats/RSI.SNOW.LENS.2071.ALL.5e-9_12.csv.SNOW.tempest.csv"/)
modelcolors=(/"blue","green","red"/)

out_string="pdf/DoY-dist-RSIge"+RSIthresh

nyearsPerSample=(/35*16,35*10,35*10/)

nCases=3
doyArray=new((/nCases,50000/),"float")

do z = 0,2

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
doy = doy-200
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
bp  = pdfx(doyArray(1,:), nbins, binSettings)
cp  = pdfx(doyArray(2,:), nbins, binSettings)

nVar = nCases

nBin    = ap@nbins          ; retrieve the number of bins
xx      = new ( (/nVar, nBin/), typeof(ap))
xx(0,:) = ap@bin_center
xx(1,:) = bp@bin_center
xx(2,:) = cp@bin_center

yy      = new ( (/nVar, nBin/), typeof(ap))
yy(0,:) = (/ ap*num(doyArray(0,:))/100./nyearsPerSample(0) /)
yy(1,:) = (/ bp*num(doyArray(1,:))/100./nyearsPerSample(1) /)
yy(2,:) = (/ bp*num(doyArray(2,:))/100./nyearsPerSample(2) /)

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
plot(0) = gsn_csm_xy (wks, xx, yy, res)

lgres                    = True
lgres@lgLabelFontHeightF = .06
lgres@vpWidthF           = 0.2
lgres@vpHeightF          = 0.08
lgres@lgPerimColor       = "black"
lgres@lgPerimThicknessF  = 1.0
lgres@lgItemType         = "Lines"
lgres@lgLineColors     = res@xyLineColors(::-1)
lgres@lgDashIndexes = res@xyDashPatterns(::-1)
lgres@lgMonoLineThickness = False
lgres@lgLineThicknesses = res@xyLineThicknesses(::-1)
lbid = gsn_create_legend(wks,3,(/"2071-2080 (RSI>="+RSIthresh+")","2026-2035 (RSI>="+RSIthresh+")","1990-2005 (RSI>="+RSIthresh+")"/),lgres)

amres = True
amres@amJust="TopRight"
amres@amParallelPosF   = 0.49             ; move legend to the right
amres@amOrthogonalPosF = -0.49             ; move the legend down
annoid1 = gsn_add_annotation(plot,lbid(0),amres)   ; add legend to plot

resP = True
gsn_panel(wks,plot,(/1,1/),resP)             ; now draw as one plot
   

end
