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
PRECTSNOW="SNOW"

modelfiles=(/"/glade/u/home/zarzycki/scratch/LES-snow/stats/RSI.SNOW.LENS.1990.ALL.5e-9_12.csv."+PRECTSNOW+".tempest.csv","/glade/u/home/zarzycki/scratch/LES-snow/stats/RSI.SNOW.LENS.2026.ALL.5e-9_12.csv."+PRECTSNOW+".tempest.csv","/glade/u/home/zarzycki/scratch/LES-snow/stats/RSI.SNOW.LENS.2071.ALL.5e-9_12.csv."+PRECTSNOW+".tempest.csv"/)
modelcolors=(/"blue2","green2","red2"/)
labelsArr=(/"  1990-2005","  2026-2035","  2071-2080"/)
nyearsPerSample=(/35*16,35*10,35*10/)

;modelfiles=(/"/glade/u/home/zarzycki/scratch/LES-snow/stats/RSI.SNOW.LENS.1990.ALL.5e-9_12.csv."+PRECTSNOW+".tempest.csv","/glade/u/home/zarzycki/scratch/LES-snow/stats/RSI.SNOW.JRA.ALL.5e-9_12.csv."+PRECTSNOW+".tempest.csv"/)
;modelcolors=(/"blue","red"/)
;labelsArr=(/"LENS PD (RSI>="+RSIthresh+")","JRA PD (RSI>="+RSIthresh+")"/)
;nyearsPerSample=(/35*16,60/)



nCases=dimsizes(modelfiles)

out_string="pdf/DoY-dist-"+PRECTSNOW+"-RSIge"+RSIthresh


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

res  = True

res@gsnDraw=False
res@gsnFrame=False

res@xyLineThicknesses        = (/12.0,12.0,12.0/)
res@xyLineColors             = modelcolors
res@xyMonoDashPattern        = False              ; all solid
res@xyDashPatterns = (/0,0,0/)
res@tiYAxisString            = "Biweekly prob. (%)"
res@tiXAxisString            = "Day of Year"
res@tiMainString         = "Storm probability (RSI ~F34~3~F21~ "+RSIthresh+")"


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

plot_wo_grid = gsn_csm_xy (wks, xx, yy*100., res)

res@tmXMajorGrid      = True
res@tmYMajorGrid      = True
res@tmXMajorGridLineColor = "grey60"
res@tmYMajorGridLineColor = "grey60"
res@tmXMajorGridLineDashPattern = 7
res@tmYMajorGridLineDashPattern = 7

plot_w_grid = gsn_csm_xy (wks, xx, yy*100., res)

annoid = gsn_add_annotation(plot_w_grid,plot_wo_grid,False) 

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
annoid1 = gsn_add_annotation(plot_w_grid,lbid,amres)   ; add legend to plot

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
amid = gsn_add_annotation(plot_w_grid, txid, amres_tr)

draw(plot_w_grid)
frame(wks)
   

end
