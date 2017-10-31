load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "plot_outline_fcn.ncl"   
begin

; ================================================;
; This script produces a snapshot panel plot of cold wake
; anomalies overlaid with 10-m wind speeds. It requires
; remapped h4 and h7 files from the nhemi_30_x4 slab experiments
; ================================================;

;; ==========================USER SPEC
yyyy=1213    ; year of interest
dateArr=(/"1213-09-11-00","1213-09-13-12","1213-09-16-00","1213-09-18-12","1213-09-21-00"/)  ; array of strings containing YYYY-MM-DD-HH to be processed
out_type="pdf"
;; ==========================


numDates=dimsizes(dateArr)
CAMtimeUnits = "days since "+yyyy+"-05-01 00:00:00"
nativeDateArr=new(numDates,"double")

do i = 0,numDates-1
  datestrs=str_split(dateArr(i),"-")
  thisYear=toint(datestrs(0))
  thisMonth=toint(datestrs(1))
  thisDay=toint(datestrs(2))
  thisHour=toint(datestrs(3))
  nativeDateArr(i)=cd_inv_calendar(thisYear,thisMonth,thisDay,thisHour,0,0,CAMtimeUnits,0)
end do

print("Getting data")
                          
;allh4 = systemfunc ("ls /glade/scratch/zarzycki/nhemi_30_x4_slab/run/"+yyyy+"/nhemi_30_x4_slab.cam.h4."+yyyy+"-08-*-00000.nc_regrid.nc /glade/scratch/zarzycki/nhemi_30_x4_slab/run/"+yyyy+"/nhemi_30_x4_slab.cam.h4."+yyyy+"-09-*-00000.nc_regrid.nc /glade/scratch/zarzycki/nhemi_30_x4_slab/run/"+yyyy+"/nhemi_30_x4_slab.cam.h4."+yyyy+"-10-*-00000.nc_regrid.nc")
;allh7 = systemfunc ("ls /glade/scratch/zarzycki/nhemi_30_x4_slab/run/"+yyyy+"/nhemi_30_x4_slab.cam.h7."+yyyy+"-08-*-00000.nc_regrid.nc /glade/scratch/zarzycki/nhemi_30_x4_slab/run/"+yyyy+"/nhemi_30_x4_slab.cam.h7."+yyyy+"-09-*-00000.nc_regrid.nc /glade/scratch/zarzycki/nhemi_30_x4_slab/run/"+yyyy+"/nhemi_30_x4_slab.cam.h7."+yyyy+"-10-*-00000.nc_regrid.nc")
allh4 = systemfunc ("ls /glade/scratch/zarzycki/nhemi_30_x4_slab/run/"+yyyy+"/nhemi_30_x4_slab.cam.h4."+yyyy+"-09-*-00000.nc_regrid.nc")
allh7 = systemfunc ("ls /glade/scratch/zarzycki/nhemi_30_x4_slab/run/"+yyyy+"/nhemi_30_x4_slab.cam.h7."+yyyy+"-09-*-00000.nc_regrid.nc")

h4file      = addfiles (allh4, "r")
ListSetType (h4file, "cat")             

h7file      = addfiles (allh7, "r")
ListSetType (h7file, "cat")           

SSTA=h7file[:]->SST({nativeDateArr},:,:)
U10=h4file[:]->U10({nativeDateArr},:,:)
time = h4file[:]->time({nativeDateArr})
lat = h4file[0]->lat
lon = h4file[0]->lon
lat@units="degree_north"
lon@units="degree_east"
U10&lat=lat
U10&lon=lon
copy_VarMeta(U10,SSTA)

utc_date = cd_calendar(time, 0)
year   = tointeger(utc_date(:,0))
month  = tointeger(utc_date(:,1))
day    = tointeger(utc_date(:,2))
hour   = tointeger(utc_date(:,3))

print("... done getting data")

;; ===== PLOTTING

wks = gsn_open_wks(out_type,"2D_CW_figs/2D_CW_panel") 
map_terrain = new(numDates,graphic)
contour_tot = new(numDates,graphic)

res                      = True
res@gsnDraw              = False
res@gsnFrame             = False

res@gsnAddCyclic = False

res@cnFillOpacityF = 1.0    ; Fully opaque

res@cnLevelSelectionMode = "ExplicitLevels"
res@cnFillOn             = True
res@cnLinesOn            = False
res@cnLineLabelsOn = False
res@cnInfoLabelOn = False 
res@lbLabelAutoStride    = True

res@gsnLeftString=""
res@gsnRightString=""

; Plotting options for terrain map
opts_ter                        = res
opts_ter@mpMinLatF               = 10
opts_ter@mpMaxLatF               = 45
opts_ter@mpMinLonF               = 220
opts_ter@mpMaxLonF               = 315

opts_ter@tmXBLabelFontHeightF = 0.016
opts_ter@tmYLLabelFontHeightF = 0.016

;tmXBLabelsOn
opts_ter@mpCenterLonF = (opts_ter@mpMinLonF  + opts_ter@mpMaxLonF  )/2.0
opts_ter@gsnAddCyclic         = False    ; Don't add lon cyclic point
opts_ter@cnLevelSelectionMode = "ManualLevels"
opts_ter@cnLevelSpacingF      =  0.1
opts_ter@cnMinLevelValF       =  -2.0
opts_ter@cnMaxLevelValF       =  0.0
opts_ter@lbLabelBarOn=False
cmap = read_colormap_file("WhiteBlueExtended")
opts_ter@cnFillPalette = cmap(::-1,:)     ; reverse color map

; Plotting options for wind
opts_r                      = res
opts_r@cnLevelSelectionMode = "ManualLevels"
opts_r@cnLevelSpacingF      =  2.0
opts_r@cnMinLevelValF       =  18.0
opts_r@cnMaxLevelValF       =  38.0
opts_r@lbLabelBarOn=False
cmap_r              = read_colormap_file("MPL_autumn")
cmap_r(0,3)         = 0.0    ; Fully transparent
opts_r@cnFillPalette  = cmap_r

do i=0,dimsizes(time)-1
  print("Doing: "+(i+1)+" of "+dimsizes(time))

  ; set tick marks for top/bottom of each panel
  if (i .eq. 0) then
    opts_ter@tmXBOn = False
    opts_ter@tmXTOn = True  
  else if (i .eq. dimsizes(time)-1) then
    opts_ter@tmXBOn = True
    opts_ter@tmXTOn = False  
  else
    opts_ter@tmXBOn = False
    opts_ter@tmXTOn = False  
  end if
  end if

  if (i .eq. dimsizes(time)-1) then
    opts_r@lbLabelBarOn=True
    opts_r@lbTitleString         = "10-m wind (m/s)"
    opts_r@lbTitleFontHeightF    = 0.014
    opts_r@lbLabelFontHeightF    = 0.014
    ;opts_r@lbTitleOffsetF        = -0.3
    opts_r@lbLabelStride     = 2
    opts_r@lbBoxSeparatorLinesOn = False
    opts_r@pmLabelBarOrthogonalPosF = 0.0
    opts_r@pmLabelBarKeepAspect     = True

    opts_ter@lbLabelBarOn=True
    opts_ter@lbTitleString         = "SSTA (K)"
    opts_ter@lbTitleFontHeightF    = 0.018
    opts_ter@lbLabelFontHeightF    = 0.018
    opts_ter@lbBoxSeparatorLinesOn = False
    opts_ter@lbLabelStride     = 10
    opts_ter@pmLabelBarOrthogonalPosF = 0.19   ; higher means further down, pushes other label bar
    opts_ter@pmLabelBarKeepAspect     = True
  end if

  map_terrain(i) = gsn_csm_contour_map(wks,SSTA(i,:,:),opts_ter)
  contour_tot(i) = gsn_csm_contour(wks,U10(i,:,:),opts_r)
  overlay(map_terrain(i),contour_tot(i))

  dateStr=sprinti("%04d",year(i))+"-"+sprinti("%02d",month(i))+"-"+sprinti("%02d",day(i))+"-"+sprinti("%02d",hour(i))+"Z"
  txres               = True
  txres@txFontHeightF = 0.02             ; Set the font height
  txres@txBackgroundFillColor="White"
  txres@txPerimOn=True
  txres@txPerimColor="Black"
  text1 = gsn_add_text(wks,map_terrain(i),dateStr,-105,41.0,txres)
end do


;************************************************
; create panel
;************************************************
resP                     = True                ; modify the panel plot
                                               ; new resource added in NCL V6.3.1
resP@gsnPanelMainString = "A plot with a common label bar"


resP@gsnPanelLabelBar    = False                ; add common colorbar
;; Add white space to bottom of panel plot for label bars in final panel.
;; Increase if labels getting cut off.
resP@gsnPanelBottom = 0.13

gsn_panel(wks,map_terrain,(/numDates,1/),resP)             ; now draw as one plot

end
