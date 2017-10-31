load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "/glade/u/home/zarzycki/ncl/functions/rainratetodbz.ncl"

begin

whatVar="PRECT" ; FLUT, WIND850, PRECT

;filedir="/glade/scratch/zarzycki/"
;all_files = systemfunc ("ls "+filedir+"/regrid-test-h3.nc")

filedir="/glade/u/home/zarzycki/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.ne0conus30x8_t12.exp003/atm/hist/"
;all_files = systemfunc ("ls "+filedir+"/f.asd2017.cesm20b05.FAMIPC6CLM5.ne0conus30x8_t12.exp003.cam.h3.1989-09-08-00000.nc")
all_files = systemfunc ("ls "+filedir+"/f.asd2017.cesm20b05.FAMIPC6CLM5.ne0conus30x8_t12.exp003.cam.h4.1981-01-21-00000.nc")

f1      = addfiles (all_files, "r")   ; note the "s" of addfile
ListSetType (f1, "cat")             ; concatenate or "merge" (default)

if (whatVar .eq. "WIND850") then
  u850=f1[:]->U850
  v850=f1[:]->V850
  var = u850
  var = sqrt(u850^2+v850^2)
  delete(u850)
  delete(v850)
else if (whatVar .eq. "PRECT") then
  var1 = f1[:]->$whatVar$
  ptype = f1[:]->PTYPE
  var2 = var1 ; snow
  ;var1 = where(ptype.ne.0,var1,var1@_FillValue)
  var2 = where(ptype.eq.0,var2,var2@_FillValue)
  RAINDBZ = rainratetodbz(var1,1)
  SNOWDBZ = rainratetodbz(var2,1)
else
  var = f1[:]->$whatVar$
end if
end if
time=f1[:]->time
lon1d=f1[0]->lon
lat1d=f1[0]->lat

minlat=25.
maxlat=55.
minlon=-100.
maxlon=-60.

prettytime=cd_calendar(time,3)

;if (whatVar .eq. "FLUT") then
;  var = where(var.ge.245,var@_FillValue,var)
;end if

wks   = gsn_open_wks ("pdf", "snowstorm.test")       ; open ps file

if (whatVar .eq. "FLUT") then
  gsn_define_colormap(wks,"MPL_Greys")
else if (whatVar .eq. "WIND850") then
  gsn_define_colormap(wks,"WhViBlGrYeOrReWh")
else if (whatVar .eq. "PRECT") then
  gsn_define_colormap(wks,"rainsnowradar")
else
  gsn_define_colormap(wks,"irsat")
end if
end if
end if

;do ii=0,dimsizes(time)-1
;do ii=140,190
do ii=140,230
print("doing loop: "+ii)
res                   = True
res@gsnDraw = False
res@gsnFrame = False

res@sfXArray            = lon1d        ; Required to tell NCL where to
res@sfYArray            = lat1d        ; overlay data on globe.

res@cnFillOn          = True              ; color plot desired
res@cnLineLabelsOn    = False             ; turn off contour lines

res@gsnAddCyclic = False

res@gsnSpreadColors     = True            ; use full range of color map

res@gsnSpreadColors      = True              ; use full colormap
res@lbLabelStride        = 4

res@lbLabelBarOn        = False

res@gsnRightString=tostring(ii)
res@gsnLeftString=tostring(prettytime(ii))

res@mpMaxLatF = maxlat
res@mpMinLatF = minlat
res@mpMaxLonF = maxlon
res@mpMinLonF = minlon

res@lbLabelStride = 4
res@lbBoxSeparatorLinesOn = False
;res@cnFillMode = "RasterFill"
res@cnLinesOn = False


  res_rain=res

  res_rain@tiMainString = ""
  res_rain@gsnLeftString = "Simulated Reflectivity"
  res_rain@gsnRightString = "dBZ"

  res_rain@gsnSpreadColors      = False              ; use full colormap
;  res_rain@cnLevelSelectionMode = "EqualSpacedLevels" ; set equal spaced contour levels
;  res_rain@cnFillColors = (/10,11,12,13,14,15,16,17/)
;  res_rain@cnMaxLevelCount = 7                  ; draw 20 equally spaced contours between min(x)+CI and max(x)-CI
  res_rain@cnFillColors = (/-1,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32/)
;  res_rain@cnLevelSelectionMode = "EqualSpacedLevels" ; set equal spaced contour levels
;  res_rain@cnMaxLevelCount =13          ; draw 20 equally spaced contours between min(x)+CI and max(x)-CI
  res_rain@cnLevelSelectionMode = "ExplicitLevels"                      ; set explicit contour levels
  res_rain@cnLevels    = (/2,4,8,16,20,24,28,32,36,40,45,50,55,60,65/) ; set levels
  res_rain@lbLabelStride = 2
  res_rain@lbOrientation = "vertical"

  res_snow = res
  res_snow@tiMainString = ""
  res_snow@gsnLeftString = ""
  res_snow@gsnRightString = ""
  res_snow@cnFillOn               = True
;  res_snow@lbOrientation = "vertical"
  res_snow@lbLabelBarOn = False
  res_snow@cnLineLabelsOn       = False
  res_snow@cnInfoLabelOn = False
  res_snow@cnFillColors = (/-1,3,3,4,5,6,7,8,9/)
  res_snow@cnLinesOn   = False
  res_snow@cnFillColors(0)    = -1  ; make 1st two contours are transparent
;  res_snow@cnLevelSelectionMode = "EqualSpacedLevels" ; set equal spaced contour levels
;  res_snow@cnMaxLevelCount = 7                  ; draw 20 equally spaced contours between min(x)+CI and max(x)-CI
  res_snow@cnLevelSelectionMode = "ExplicitLevels"                      ; set explicit contour levels
  res_snow@cnLevels    = (/1,4,8,12,16,20,24,30/)      ; set levels


  plotrain = gsn_csm_contour_map(wks,RAINDBZ(ii,:),res_rain)
  plotsnow = gsn_csm_contour(wks,SNOWDBZ(ii,:),res_snow)

  overlay(plotrain,plotsnow)


;cmap_r              = read_colormap_file("irsat")
;printVarSummary(cmap_r)
;cmap_new = new((/243,4/),"float")
;cmap_new = cmap_r(0:242,:)
;cmap_new(242,3)         = 0.0    ; Fully transparent
;res@cnFillPalette  = cmap_new


resP                     = True                ; modify the panel plot
resP@gsnPanelLabelBar    = True      
resP@lbBoxSeparatorLinesOn = False          ; add common colorbar
gsn_panel(wks,plotrain,(/1,1/),resP)             ; now draw as one plot

end do

end
