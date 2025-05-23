load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "/glade/u/home/zarzycki/ncl/functions/rainratetodbz.ncl"

begin

whatVar="PRECT" ; FLUT, WIND850, PRECT

;filedir="/glade/scratch/zarzycki/"
;all_files = systemfunc ("ls "+filedir+"/regrid-test-h3.nc")

;filedir="/glade/u/home/zarzycki/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.ne0conus30x8_t12.exp003/atm/hist/"
;all_files = systemfunc ("ls "+filedir+"/f.asd2017.cesm20b05.FAMIPC6CLM5.ne0conus30x8_t12.exp003.cam.h3.1989-09-08-00000.nc")
;all_files = systemfunc ("ls "+filedir+"/f.asd2017.cesm20b05.FAMIPC6CLM5.ne0conus30x8_t12.exp003.cam.h4.1989-09-28-00000.nc")

filedir="/glade/u/home/zarzycki/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.mp15a-120a-US_t12.exp004/atm/hist/"
all_files = systemfunc ("ls "+filedir+"/f.asd2017.cesm20b05.FAMIPC6CLM5.mp15a-120a-US_t12.exp004.cam.h3.1985-05-31-00000.nc")
;filedir="/glade/u/home/zarzycki/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.mp120a_g16.exp005/atm/hist/"
;all_files = systemfunc ("ls "+filedir+"/f.asd2017.cesm20b05.FAMIPC6CLM5.mp120a_g16.exp005.cam.h4.1985-05-31-00000.nc")


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
  var = rainratetodbz(var1,1)
else
  var = f1[:]->$whatVar$
end if
end if
time=f1[:]->time
lon1d=f1[0]->lon
lat1d=f1[0]->lat

;minlat=15.
;maxlat=40.
;minlon=-100.
;maxlon=-80.

minlat=10.
maxlat=60.
minlon=-130.
maxlon=-60.

prettytime=cd_calendar(time,3)

;if (whatVar .eq. "FLUT") then
;  var = where(var.ge.245,var@_FillValue,var)
;end if

wks   = gsn_open_wks ("pdf", "haiyan_flut_2013_11_08_00Z")       ; open ps file

if (whatVar .eq. "FLUT") then
  gsn_define_colormap(wks,"MPL_Greys")
else if (whatVar .eq. "WIND850") then
  gsn_define_colormap(wks,"WhViBlGrYeOrReWh")
else if (whatVar .eq. "PRECT" .or. whatVar .eq. "MAXREFL") then
  gsn_define_colormap(wks,"rainradar")
else
  gsn_define_colormap(wks,"irsat")
end if
end if
end if

do ii=0,dimsizes(time)-1
;do ii=130,190
;do ii=0,24
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
res@cnFillMode = "RasterFill"
res@cnLinesOn = False

if (whatVar .eq. "FLUT") then
  res@cnLevelSelectionMode = "ManualLevels"
  res@cnLevelSpacingF      =  2.0
  res@cnMinLevelValF       =  89.0
  res@cnMaxLevelValF       =  265.0
  res@mpOceanFillColor       = "black"
  res@mpLandFillColor        = "darkgreen"
  res@mpInlandWaterFillColor = "black"
else if (whatVar .eq. "WIND850") then
  res@cnLevelSelectionMode = "ManualLevels"
  res@cnLevelSpacingF      =  2.5
  res@cnMinLevelValF       =  17.5
  res@cnMaxLevelValF       =  80.0
else if (whatVar .eq. "PRECT") then
  res@cnLevelSelectionMode = "ManualLevels"
  res@cnMinLevelValF       =  4.
  res@cnMaxLevelValF       =  52.
  res@cnLevelSpacingF      = 2.
  res@cnLinesOn = False
else if (whatVar .eq. "MAXREFL") then
  res@cnLevelSelectionMode = "ManualLevels"
  res@cnMinLevelValF       =  2.
  res@cnMaxLevelValF       =  20.
  res@cnLevelSpacingF      = 2.
  res@cnLinesOn = False
else
  ;
end if
end if
end if
end if

;cmap_r              = read_colormap_file("irsat")
;printVarSummary(cmap_r)
;cmap_new = new((/243,4/),"float")
;cmap_new = cmap_r(0:242,:)
;cmap_new(242,3)         = 0.0    ; Fully transparent
;res@cnFillPalette  = cmap_new

contour = gsn_csm_contour_map(wks,var(ii,:),res)  ; create the plot

resP                     = True                ; modify the panel plot
resP@gsnPanelLabelBar    = True      
resP@lbBoxSeparatorLinesOn = False          ; add common colorbar
gsn_panel(wks,contour,(/1,1/),resP)             ; now draw as one plot

end do

end
