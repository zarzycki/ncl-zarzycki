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
out_string="pdf/RSI-bin-comp-OBS-LENS"
modelfiles=(/"/glade/u/home/zarzycki/scratch/LES-snow/stats/RSI.SNOW.LENS.1990.ALL.5e-9_12.csv.SNOW.tempest.csv","/glade/u/home/zarzycki/scratch/LES-snow/stats/RSI.SNOW.JRA.CAT.csv"/)
nyearsPerSample=(/35*16,57,117/)

RSIcatArray=(/1,2,3,4,5/)
nCases=3
RSInumArray=new((/nCases,dimsizes(RSIcatArray)/),"integer")
RSInormArray=new((/nCases,dimsizes(RSIcatArray)/),"float")

; OBS
RSInumArray(2,:)=(/119,54,15,11,4/)

MMArray=(/1,2,3,4,5,6,7,8,9,10,11,12/)
MMnumArray=new((/nCases,dimsizes(MMArray)/),"integer")

do z = 0,1

filename = modelfiles(z)

lines = asciiread(filename,-1,"string")
delim = ","
member  =           str_get_field(lines,1,delim)
stormID  =           tointeger(str_get_field(lines,2,delim))
RSIval = tofloat(str_get_field(lines,3,delim))
if (z .eq. -1)
  RSIcat  =   tointeger(str_get_field(lines,4,delim))
else
  RSIcat  =   tointeger(str_get_field(lines,7,delim))
end if
YYYYMMDDHH = str_get_field(lines,4,delim)


; split times
dtime_map = (/4,2,2,2/)
tst_dtime = str_split_by_length(YYYYMMDDHH, dtime_map)
YYYY=toint(tst_dtime(:,0))
MM=toint(tst_dtime(:,1))

do i = 0,dimsizes(RSIcatArray)-1
  RSInumArray(z,i) = num(RSIcat.eq.RSIcatArray(i))
end do

MM=where(RSIcat.ge.1,MM,MM@_FillValue)
do jj = 0,dimsizes(MMArray)-1
  MMnumArray(z,jj) = num(MM.eq.MMArray(jj))
end do

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

end do

;print(dim_sum_n_Wrap(RSInumArray,1))

print("Storms by month")
;print(dim_sum_n_Wrap(MMnumArray,1))
print(MMnumArray)

;======

do k = 0,dimsizes(RSIcatArray)-1
  RSInormArray(:,k) = tofloat(RSInumArray(:,k))/tofloat(nyearsPerSample)
end do

print(RSInormArray)

wks = gsn_open_wks(out_type,out_string)
;newcolor = NhlNewColor(wks,.6,.85,1.)
;newcolor = NhlNewColor(wks,0.42,0.42,0.42)

cmap = RGBtoCmap("diverging-cmap.txt")

sres = True
sres@vpWidthF = 0.7
sres@vpHeightF = 0.5
sres@vpXF = .15
sres@trXMinF = 0.4
sres@trXMaxF = 5.6
sres@trYMinF = 0.0
sres@trYMaxF = 1.2
if (plot_log) then
  sres@xyYStyle = "Log"
  sres@trYMinF = 0.001
end if
sres@gsnDraw = True
sres@gsnFrame = False
sres@gsnXYBarChart = True
sres@gsnXYBarChartBarWidth = 0.4           ; change bar widths
sres@tmXBMode          = "Explicit"         ; explicit labels
sres@tmXBValues        = (/1,2,3,4,5/)
sres@tmXBLabels = (/"1","2","3","4","5"/)
sres@tmXBLabelFontHeightF = 0.0205
sres@tmXTLabelFontHeightF = 0.0205
sres@tmYLLabelFontHeightF = 0.0225
sres@tiMainFontHeightF = 0.025
sres@tiMainFont = "helvetica"
sres@tiMainString = "RSI frequency"
sres@gsnRightString = ""
sres@tiYAxisString = "RSI storms per year"
sres@tiXAxisString = "RSI category"

sres@gsnXYBarChartColors = cmap(0,:)
plot1 = gsn_csm_xy(wks,fspan(0.8,4.8,5),RSInormArray(0,:),sres)		; draw each timeseries
sres@gsnXYBarChartColors = cmap(2,:)			; but tweaking where
plot3 = gsn_csm_xy(wks,fspan(1.2,5.2,5),RSInormArray(2,:),sres)		; each timeseries is

lbres                    = True          ; labelbar only resources
lbres@vpWidthF           = 0.2           ; labelbar width
lbres@vpHeightF          = 0.15           ; labelbar height
lbres@lbBoxMajorExtentF  = 0.36          ; puts space between color boxes
lbres@lbFillColors       = (/cmap(2,:),cmap(0,:)/)
lbres@lbMonoFillPattern  = True          ; Solid fill pattern
lbres@lbLabelFontHeightF = 0.019         ; font height. default is small
lbres@lbLabelJust        = "CenterLeft"  ; left justify labels
lbres@lbPerimOn          = False
lbres@lgPerimColor 	 = "white"
tablabels=new(2,"string")
tablabels(0)="LENS (all mem.) 1980-2005"
tablabels(1)="NOAA obs. 1900-2017"
labels=tablabels
;labels = (/"ne0conus30x8","mp15a-120a","Obs 1900-2015"/)  ; labels in reverse
gsn_labelbar_ndc(wks,2,labels(::-1),0.4,0.8,lbres)	; draw right labelbar column
frame(wks)     

end
