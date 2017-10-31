load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "/glade/u/home/zarzycki/ncl/functions/trackDensity.ncl"
begin

filename="/glade/u/home/zarzycki/scratch/MTD-example/output/mp120a/cat.txt"
plot_title="mp120a"
lines = asciiread(filename,-1,"string")

delim = " "

;VERSION  MODEL  FCST_LEAD       FCST_LEAD  OBS_LEAD  OBS_VALID  T_DELTA  FCST_RAD  FCST_THR  OBS_RAD  OBS_THR
;FCST_VAR  FCST_LEV  OBS_VAR  OBS_LEV  OBJ_ID  CLUSTER_ID  TIME_INDEX  AREA  CENTROID_X  CENTROID_Y;
;CENTROID_LAT  CENTROID_LON  AXIS_ANG

;VERSION = str_get_field(lines,1,delim)
;MODEL = str_get_field(lines,2,delim)
;FCST_LEAD = str_get_field(lines,3,delim)
;FCST_LEAD = str_get_field(lines,4,delim)
;OBS_LEAD = str_get_field(lines,5,delim)
;OBS_VALID = str_get_field(lines,6,delim)
;T_DELTA = str_get_field(lines,7,delim)
;FCST_RAD = str_get_field(lines,8,delim)
;FCST_THR = toint(str_get_field(lines,9,delim))
;OBS_RAD = str_get_field(lines,10,delim)
;OBS_THR  = str_get_field(lines,11,delim)
;
;FCST_VAR = str_get_field(lines,12,delim)
;FCST_LEV = str_get_field(lines,13,delim)
;OBS_VAR = str_get_field(lines,14,delim)
;OBS_LEV = str_get_field(lines,15,delim)
;OBJ_ID = str_get_field(lines,16,delim)
;CLUSTER_ID = str_get_field(lines,17,delim)
;TIME_INDEX = str_get_field(lines,18,delim)
;AREA = str_get_field(lines,19,delim)
;CENTROID_X = str_get_field(lines,20,delim)
;CENTROID_Y = str_get_field(lines,21,delim)

CENTROID_LAT = tofloat(str_get_field(lines,22,delim))
CENTROID_LON = tofloat(str_get_field(lines,23,delim))
;AXIS_ANG = str_get_field(lines,24,delim)


count = track_density(3.0,0.0,CENTROID_LAT,CENTROID_LON,True)

count = count/10.

printVarSummary(count)

;************************************************
; create plot
;************************************************

wks = gsn_open_wks("pdf","MCS-dens-"+plot_title)
plot = new(1,"graphic")


colorMap1="MPL_Purples"

res                       = True     ; plot mods desired
res@gsnDraw = False
res@gsnFrame = False
;res@gsnSpreadColors       = True     ; use full range of color map
res@gsnAddCyclic          = False

res@cnFillOn              = True     ; turn on color fill
res@cnFillMode            = "RasterFill"       ; Raster Mode
res@cnLinesOn             = False    ; turn of contour lines
res@cnLineLabelsOn  = False

res@cnLevelSelectionMode  = "ManualLevels"
res@cnMinLevelValF        = 0
res@cnMaxLevelValF        = 10.
res@cnLevelSpacingF       = res@cnMaxLevelValF/25.

res@lbLabelStride = 2

res@mpMinLatF             = 25
res@mpMaxLatF             = 55
res@mpMinLonF             = 240
res@mpMaxLonF             = 290
res@mpGridAndLimbOn       = False
res@mpGridLineDashPattern = 2             ; Dashed lines
res@mpGridLatSpacingF     = 5.0
res@mpGridLonSpacingF     = 10.0

res@gsnCenterString       = "MCS per year: "+plot_title

res@cnFillPalette=colorMap1
plot(0) = gsn_csm_contour_map_ce(wks,count(:,:),res)

resP = True
resP@amJust           = "TopLeft"

resP@gsnPanelFigureStringsFontHeightF = 0.04

gsn_panel(wks,plot,(/1,1/),resP)

end
