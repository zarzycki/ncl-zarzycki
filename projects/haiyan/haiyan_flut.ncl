; Inputs
; iniyear (1999)
; inimon (12)
; iniday (25)
; inisec (24000)
; filename

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

whatVar="FLUT" ; FLUT, WIND850
zoom=True
;f1 = addfile("/glade/scratch/zarzycki/haiyan_plot/haiyan_h1.nc","r")

;filedir="/glade/scratch/zarzycki/haiyan_plot/1004/"
filedir="/glade/scratch/zarzycki/ecsnow_30_x0_forecast/run/2013110412/"
all_files = systemfunc ("ls "+filedir+"/*h1*.nc")
f1      = addfiles (all_files, "r")   ; note the "s" of addfile
ListSetType (f1, "cat")             ; concatenate or "merge" (default)

if (zoom) then
  minlat=5.
  maxlat=17.
  minlon=118.
  maxlon=137.
else
  minlat=2.
  maxlat=18.
  minlon=115.
  maxlon=152.
end if

if (whatVar .eq. "WIND850") then
  u850=f1[:]->U850
  v850=f1[:]->V850
  var = u850
  var = sqrt(u850^2+v850^2)
  delete(u850)
  delete(v850)
else
  var = f1[:]->$whatVar$
end if
time=f1[:]->time
lon1d=f1[0]->lon
lat1d=f1[0]->lat

prettytime=cd_calendar(time,3)

if (whatVar .eq. "FLUT") then
  var = where(var.ge.245,var@_FillValue,var)
end if

wks   = gsn_open_wks ("pdf", "haiyan_flut_2013_11_08_00Z")       ; open ps file

if (whatVar .eq. "FLUT") then
  gsn_define_colormap(wks,"irsat")
else if (whatVar .eq. "WIND850") then
  gsn_define_colormap(wks,"WhViBlGrYeOrReWh")
else
  gsn_define_colormap(wks,"irsat")
end if
end if

do ii=3,dimsizes(time)-1

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

;res@gsnRightString=""
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
  res@cnLevelSpacingF      =  1.0
  res@cnMinLevelValF       =  85.0
  res@cnMaxLevelValF       =  245.0
  res@mpOceanFillColor       = "black"
  res@mpLandFillColor        = "darkgreen"
  res@mpInlandWaterFillColor = "black"
else if (whatVar .eq. "WIND850") then
  res@cnLevelSelectionMode = "ManualLevels"
  res@cnLevelSpacingF      =  2.5
  res@cnMinLevelValF       =  17.5
  res@cnMaxLevelValF       =  80.0
else
  ;
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
