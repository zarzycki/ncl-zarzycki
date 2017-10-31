;========================================================
; This script plots pressure-wind curves given a tc-pairs
; output from met-TC
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
;========================================================
begin

;tail -n +2 file.txt (remove header)
;filename = "/glade/u/home/zarzycki/work/met_files/filter_all_ts.tcst"
filename = "/glade/u/home/zarzycki/work/met_files/filter_cam_clubb.tcst"

lines = asciiread(filename,-1,"string")
drawRegLines=False
outtype="pdf"

colorArray = (/"red","blue"/)
markerTypes = (/15,16/)


models = (/"CAM","BEST"/)
;leadTimes = (/12,24,48,72,96,120/);,144,168,192/)
leadTimes = (/24,48,96,120,192/);,144,168,192/)
panelLabels = (/"a.","b.","c."/);,144,168,192/)

ms_to_kts = 1.94384449

;print(lines)

delim = " "

;VERSION AMODEL BMODEL STORM_ID BASIN CYCLONE STORM_NAME INIT            LEAD    VALID           INIT_MASK VALID_MASK LINE_TYPE TOTAL INDEX LEVEL WATCH_WARN INITIALS ALAT     ALON       BLAT     BLON      TK_ERR     X_ERR       Y_ERR       ALTK_ERR    CRTK_ERR    ADLAND      BDLAND     AMSLP BMSLP AMAX_WIND BMAX_WIND AAL_WIND_34 BAL_WIND_34 ANE_WIND_34 BNE_WIND_34 ASE_WIND_34 BSE_WIND_34 ASW_WIND_34 BSW_WIND_34 ANW_WIND_34 BNW_WIND_34 AAL_WIND_50 BAL_WIND_50 ANE_WIND_50 BNE_WIND_50 ASE_WIND_50 BSE_WIND_50 ASW_WIND_50 BSW_WIND_50 ANW_WIND_50 BNW_WIND_50 AAL_WIND_64 BAL_WIND_64 ANE_WIND_64 BNE_WIND_64 ASE_WIND_64 BSE_WIND_64 ASW_WIND_64 BSW_WIND_64 ANW_WIND_64 BNW_WIND_64
;V4.1    CARQ   BEST   AL012012 AL    01      ALBERTO    20120519_120000 -120000 20120519_000000 NA        NA         TCMPR     3     1     LO    NA         X        33.10000 -76.80000  33.10000 -77.00000 10.05247   10.05247    0.00000     -2.70744    -9.67913    80.55836    73.46449   NA    1010  25        25        0.00000     NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA          NA


VERSION = str_get_field(lines,1,delim)
AMODEL = str_get_field(lines,2,delim)
BMODEL = str_get_field(lines,3,delim)
STORM_ID = str_get_field(lines,4,delim)
BASIN = str_get_field(lines,5,delim)
CYCLONE = str_get_field(lines,6,delim)
STORM_NAME = str_get_field(lines,7,delim)
INIT = str_get_field(lines,8,delim)
LEAD = toint(str_get_field(lines,9,delim))/10000
VALID = str_get_field(lines,10,delim)
INIT_MASK  = str_get_field(lines,11,delim)
VALID_MASK = str_get_field(lines,12,delim)
LINE_TYPE = str_get_field(lines,13,delim)
TOTAL = toint(str_get_field(lines,14,delim))
INDEX = toint(str_get_field(lines,15,delim))
LEVEL = str_get_field(lines,16,delim)
WATCH_WARN = str_get_field(lines,17,delim)
INITIALS = str_get_field(lines,18,delim)
ALAT = tofloat(str_get_field(lines,19,delim))
ALON = tofloat(str_get_field(lines,20,delim))
BLAT = tofloat(str_get_field(lines,21,delim))
BLON = tofloat(str_get_field(lines,22,delim))
TK_ERR = tofloat(str_get_field(lines,23,delim))
X_ERR = tofloat(str_get_field(lines,24,delim))
Y_ERR = tofloat(str_get_field(lines,25,delim))
ALTK_ERR = tofloat(str_get_field(lines,26,delim))
CRTK_ERR = tofloat(str_get_field(lines,27,delim))
ADLAND = tofloat(str_get_field(lines,28,delim))
BDLAND = tofloat(str_get_field(lines,29,delim))
AMSLP = tofloat(str_get_field(lines,30,delim))
BMSLP = tofloat(str_get_field(lines,31,delim))
AMAX_WIND = tofloat(str_get_field(lines,32,delim))
BMAX_WIND = tofloat(str_get_field(lines,33,delim))
;AAL_WIND_34 = str_get_field(lines,34,delim)
;BAL_WIND_34 = str_get_field(lines,35,delim)

do j = 0,dimsizes(leadTimes)-1

thisTime = leadTimes(j)

pres = new((/dimsizes(models),dimsizes(VERSION)/),"float")
wind = new((/dimsizes(models),dimsizes(VERSION)/),"float")

do i = 0,dimsizes(models)-1

thisModel = models(i)
print("Doing: "+thisModel)

;stats = where(LEAD .eq. thisTime,stats,stats@_FillValue)

if (thisModel .eq. "BEST") then
  p = where(BMODEL .eq. thisModel,BMSLP,BMSLP@_FillValue)
  p = where(LEAD .eq. thisTime,p,p@_FillValue)
  w = where(BMODEL .eq. thisModel,BMAX_WIND,BMAX_WIND@_FillValue)
  w = where(LEAD .eq. thisTime,w,w@_FillValue)
else
  p = where(AMODEL .eq. thisModel,AMSLP,AMSLP@_FillValue)
  p = where(LEAD .eq. thisTime,p,p@_FillValue)
  w = where(AMODEL .eq. thisModel,AMAX_WIND,AMAX_WIND@_FillValue)
  w = where(LEAD .eq. thisTime,w,w@_FillValue)
end if

pres(i,:) = p
wind(i,:) = w

delete(p)
delete(w)
delete(thisModel)

end do

wind = wind/ms_to_kts

;--------------------------------------------------------
if drawRegLines then
  print("Calculating regression for best-fit line")

  polyn = 3
  quad_obs = lspoly(wind(0,:), pres(0,:) , 1, polyn)    ; all weights are set to one
  ;print("Calculating regression for cam")
  quad_cam = lspoly(wind(1,:), pres(1,:) , 1, polyn)
  ;print(quad_cam) ; Y = c(0) + c(1)*x + c(2)*x^2
  regx = fspan(0,100,750)
  camregy = new(dimsizes(regx),float)
  obsregy = new(dimsizes(regx),float)
  camregy = quad_cam(0) + quad_cam(1)*regx + quad_cam(2)*regx^2
  obsregy = quad_obs(0) + quad_obs(1)*regx + quad_obs(2)*regx^2

end if

;--------------------------------------------------------

wks   = gsn_open_wks (outtype,"pres_wind_pdfs/pres_wind_curve_"+thisTime)                  ; open workstation

res  = True
;res@gsnMaximize            = True       ; Maximize plot in frame.
res@gsnDraw    = False                         ; don't draw
res@gsnFrame   = False                         ; don't advance frame

res@tiMainString  = "+"+thisTime+" hour forecasts"       ; title
res@tiYAxisString = "Wind speed (m/s)"  ; y axis title
res@tiXAxisString = "Surface pressure (hPa)"    ; y axis title

;res@tiYAxisFontHeightF = 0.02
;res@tiXAxisFontHeightF = 0.02
;res@tiMainFontHeightF = 0.022
;res@tmXBLabelFontHeightF = 0.017
;res@tmYLLabelFontHeightF = 0.017

res@tiYAxisFontHeightF = 0.025
res@tiXAxisFontHeightF = 0.025
res@tiMainFontHeightF = 0.027
res@tmXBLabelFontHeightF = 0.025
res@tmYLLabelFontHeightF = 0.025

res@trXMinF           = 893.
res@trXMaxF           = 1022.
res@trYMinF           = 0.
res@trYMaxF           = 72.

res@xyMarkLineMode = "Markers"

; Draw ibTracks data
res@xyMarkerColors = colorArray(0)
res@xyMarker      = markerTypes(0)
res@xyMarkerSizeF = 0.009
plot = gsn_csm_xy(wks,pres(0,:),wind(0,:),res)

do i = 0,dimsizes(VERSION)-1
if .not.ismissing(pres(0,i)) then
if (pres(0,i) .lt. 930) then
  print(STORM_NAME(i)+" "+INIT(i)+" "+pres(0,i)+" ")
end if
end if
end do

; Draw CAM-SE data
res@xyMarkerColors = colorArray(1)
res@xyMarker      = markerTypes(1)
res@xyMarkerSizeF = 0.007
plot2 = gsn_csm_xy(wks,pres(1,:),wind(1,:),res)
overlay(plot,plot2)

; Now we will plot the quad fit lines
if drawRegLines then
  res@xyMarker      = 1

  res@xyMarkerSizeF = 0.020
  res@xyMarkerColors = colorArray(0)
  plot3 = gsn_csm_xy(wks,obsregy,regx,res)
  overlay(plot,plot3)

  res@xyMarkerColors = colorArray(1)
  plot4 = gsn_csm_xy(wks,camregy,regx,res)
  overlay(plot,plot4)

  delete(plot3)
  delete(plot4)
  delete([/obsregy,camregy,quad_cam,regx/])
end if


lgres                    = True
lgres@lgMonoMarkerSize = False
lgres@lgLabelFontHeightF = .18
lgres@vpWidthF           = 0.24
lgres@vpHeightF          = 0.10
lgres@lgPerimColor       = "black"
lgres@lgPerimThicknessF  = 1.0
lgres@lgMonoMarkerIndex = False
lgres@lgItemType         = "Markers"
lgres@lgMarkerColors     = (/colorArray(1),colorArray(0)/)
lgres@lgMarkerIndexes = (/markerTypes(1),markerTypes(0)/)
lgres@lgMarkerSizes = (/0.010,0.012/)
lbid = gsn_create_legend(wks,2,(/"Obs","CAM-SE 14km"/),lgres)
;(0.125~S~o~N~)


amres = True
amres@amParallelPosF   = 0.27		    ; move legend to the right
amres@amOrthogonalPosF = -.4             ; move the legend down
annoid1 = gsn_add_annotation(plot,lbid,amres)   ; add legend to plot

resP = True
resP@amJust           = "BottomLeft"
resP@gsnPanelFigureStrings=panelLabels(j)
resP@gsnPanelFigureStringsFontHeightF = 0.04
gsn_panel(wks,plot,(/1,1/),resP)             ; now draw as one plot

;draw(plot)
;frame(wks)

delete([/amres,lgres,pres,wind,res,plot,plot2/])

end do


end
