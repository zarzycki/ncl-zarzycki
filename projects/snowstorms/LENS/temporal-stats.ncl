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
RSIthresh=2
PRECTSNOW="PRECT"

DEG="12"
SLR="12"
BASEDIR="/glade/u/home/zarzycki/scratch/LES-snow/stats/"
modelstrs=(/"1990","2026","2071"/)
modelfiles=(/BASEDIR+"/RSI.LENS."+modelstrs+".ALL.csv"/)
modelcolors=(/"blue2","green2","red2"/)
labelsArr=(/"  1990-2005","  2026-2035","  2071-2080"/)
nyearsPerSample=(/35*16,35*10,35*10/)

nCases=dimsizes(modelfiles)

timeArray=new((/nCases,50000/),"float")

days_units="days since 1900-01-01 00:00:00"

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

ZERO=DD
ZERO=0

opt = 0
opt@calendar="no_leap"

time = cd_inv_calendar(YYYY,MM,DD,ZERO,ZERO,ZERO,days_units,opt)
time = where(RSIcat.ge.RSIthresh,time,time@_FillValue)

; First get rid of filtered storms
iz = ind(.not.ismissing(time))
time := time(iz)
delete(iz)

; Now get rid of storms across seasons and members...
difftimes=new(dimsizes(time),"float",-999.9)
do ii = 1,dimsizes(time)-1
  difftimes(ii) = tofloat(time(ii) - time(ii-1))
end do
difftimes(0)=difftimes@_FillValue

longthresh=150.
difftimes=where(abs(difftimes).le.longthresh,difftimes,difftimes@_FillValue)

; now get rid of filtered diffs
iz = ind(.not.ismissing(difftimes))
difftimes := difftimes(iz)
delete(iz)

timeArray(z,0:(dimsizes(difftimes)-1)) = tofloat(difftimes)

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
delete(ZERO)

delete(difftimes)
delete(time)

end do

; calc historgrams
binSettings=True
binSettings@bin_min=0.0
binSettings@bin_max=28.0
nbins=4

ap  = pdfx(timeArray(0,:), nbins, binSettings)
if (nCases .gt. 1) then
  bp  = pdfx(timeArray(1,:), nbins, binSettings)
  if (nCases .gt. 2) then
    cp  = pdfx(timeArray(2,:), nbins, binSettings)
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

print(nyearsPerSample)

print(num(timeArray(0,:)))
print(num(timeArray(1,:)))
print(num(timeArray(2,:)))

print(sum(ap*num(timeArray(0,:))/100.))
print(sum(bp*num(timeArray(1,:))/100.))
print(sum(cp*num(timeArray(2,:))/100.))


yy      = new ( (/nVar, nBin/), typeof(ap))
yy(0,:) = (/ ap*num(timeArray(0,:))/100./nyearsPerSample(0) /)
if (nCases .gt. 1) then
  yy(1,:) = (/ bp*num(timeArray(1,:))/100./nyearsPerSample(1) /)
  if (nCases .gt. 2) then
    yy(2,:) = (/ cp*num(timeArray(2,:))/100./nyearsPerSample(2) /)
  end if
end if





wks = gsn_open_wks("x11","test")

res  = True

res@gsnDraw=False
res@gsnFrame=False

liThickness=10.0
res@xyLineThicknesses        = (/liThickness,liThickness,liThickness/)
res@xyLineColors             = modelcolors
res@xyMonoDashPattern        = False              ; all solid
res@xyDashPatterns = (/0,0,0/)
res@tiYAxisString            = "Annual storms per biweekly period"
res@tiXAxisString            = "Day of Year"
if (PRECTSNOW .eq. "SNOW")
  res@tiMainString         = "Storm frequency (RSI ~F34~3~F21~ "+RSIthresh+")"
else
  res@tiMainString         = "Storm frequency (RPI ~F34~3~F21~ "+RSIthresh+")"
end if

res@trXMinF           = 0.
res@trXMaxF           = 28.

plot_wo_grid = gsn_csm_xy (wks, xx, yy, res)

; add legend
lgres                    = True
lgres@lgLabelFontHeightF = .1
lgres@vpWidthF           = 0.15
lgres@vpHeightF          = 0.08
lgres@lgPerimFill            = "SolidFill"      ; Fill legend box w/white
lgres@lgPerimFillColor       = "white"          ; so it masks XY curves
lgres@lgPerimColor       = "black"
lgres@lgPerimThicknessF  = 1.0
lgres@lgItemType         = "Lines"
lgres@lgLineColors     = res@xyLineColors
lgres@lgDashIndexes = res@xyDashPatterns
lgres@lgMonoLineThickness = False
lgres@lgLineThicknesses = res@xyLineThicknesses
;lgres@lgLineDashSegLenF = 0.01
lbid = gsn_create_legend(wks,nCases,labelsArr,lgres)
amres = True
amres@amJust="TopRight"
amres@amParallelPosF   = 0.49             ; move legend to the right
amres@amOrthogonalPosF = -0.49             ; move the legend down
annoid1 = gsn_add_annotation(plot_wo_grid,lbid,amres)   ; add legend to plot

; add panel label
if (RSIthresh .eq. 1) then
  panelStr="a."
else if (RSIthresh .eq. 3) then
  panelStr="b."
else
  panelStr="x."
end if
end if
paneltxres                       = True
paneltxres@txPerimOn             = True
paneltxres@txFontHeightF         = 0.05
amres_tr                  = True
amres_tr@amParallelPosF   = -0.48    ; This is the left edge of the plot.
amres_tr@amOrthogonalPosF = -0.48    ; This is the top edge of the plot.
amres_tr@amJust           = "TopLeft"
paneltxres@txBackgroundFillColor = "White"
txid = gsn_create_text(wks, panelStr, paneltxres)
amid = gsn_add_annotation(plot_wo_grid, txid, amres_tr)

draw(plot_wo_grid)
frame(wks)





end
