
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "plot_outline_fcn.ncl"   
; ================================================;
begin

;date="1203-09-20"
yyyy=1213

print("Getting data")
                          
allh4 = systemfunc ("ls /glade/scratch/zarzycki/nhemi_30_x4_slab/run/"+yyyy+"/nhemi_30_x4_slab.cam.h4."+yyyy+"-08-*-00000.nc_regrid.nc /glade/scratch/zarzycki/nhemi_30_x4_slab/run/"+yyyy+"/nhemi_30_x4_slab.cam.h4."+yyyy+"-09-*-00000.nc_regrid.nc /glade/scratch/zarzycki/nhemi_30_x4_slab/run/"+yyyy+"/nhemi_30_x4_slab.cam.h4."+yyyy+"-10-*-00000.nc_regrid.nc")
allh7 = systemfunc ("ls /glade/scratch/zarzycki/nhemi_30_x4_slab/run/"+yyyy+"/nhemi_30_x4_slab.cam.h7."+yyyy+"-08-*-00000.nc_regrid.nc /glade/scratch/zarzycki/nhemi_30_x4_slab/run/"+yyyy+"/nhemi_30_x4_slab.cam.h7."+yyyy+"-09-*-00000.nc_regrid.nc /glade/scratch/zarzycki/nhemi_30_x4_slab/run/"+yyyy+"/nhemi_30_x4_slab.cam.h7."+yyyy+"-10-*-00000.nc_regrid.nc")

h4file      = addfiles (allh4, "r")
ListSetType (h4file, "cat")             

h7file      = addfiles (allh7, "r")
ListSetType (h7file, "cat")           

;h4file=addfile("/glade/scratch/zarzycki/nhemi_30_x4_slab/run/1203/nhemi_30_x4_slab.cam.h4."+date+"-00000.nc_regrid.nc","r")
;h7file=addfile("/glade/scratch/zarzycki/nhemi_30_x4_slab/run/1203/nhemi_30_x4_slab.cam.h7."+date+"-00000.nc_regrid.nc","r")


SSTA=h7file[:]->SST
;SST=h4file[:]->SST
;FLUT=h4file[:]->FLUT
U10=h4file[:]->U10
time = h4file[:]->time
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


  wks = gsn_open_wks("pdf","2D_CW_figs/2D_CW_movie")    ; Open graphics file.

  res                      = True

  res@gsnDraw              = False
  res@gsnFrame             = False

  res@vpXF                 = 0.03   ; Set X,Y location of upper left
  res@vpYF                 = 0.88   ; of plot
  res@vpWidthF             = 0.80   ; Set width

  res@gsnAddCyclic = False

    ;res@mpMinLatF               = min(lat)
    ;res@mpMaxLatF               = max(lat)
    ;res@mpMinLonF               = min(lon)
    ;res@mpMaxLonF               = max(lon)



  res@cnFillOpacityF = 1.0    ; Fully opaque

  res@cnLevelSelectionMode = "ExplicitLevels"
  res@cnFillOn             = True
  res@cnLinesOn            = False
  res@lbLabelAutoStride    = True

res@gsnLeftString=""
res@gsnRightString=""

; Plotting options for terrain map
  opts_ter                        = res

  opts_ter@mpMinLatF               = 9
  opts_ter@mpMaxLatF               = 47
; PAC OCN
;  opts_ter@mpMinLonF               = 110
;  opts_ter@mpMaxLonF               = 270
; EPAC + ATL
  ;opts_ter@mpMinLonF               = 190
  ;opts_ter@mpMaxLonF               = 340
  ;opts_ter@mpCenterLonF = (opts_ter@mpMinLonF  + opts_ter@mpMaxLonF  )/2.0

; PLOTTING
  opts_ter@mpMinLonF               = 215
  opts_ter@mpMaxLonF               = 320
  opts_ter@mpCenterLonF = (opts_ter@mpMinLonF  + opts_ter@mpMaxLonF  )/2.0

  opts_ter@gsnAddCyclic         = False    ; Don't add lon cyclic point

  opts_ter@cnLevelSelectionMode = "ManualLevels"
  opts_ter@cnLevelSpacingF      =  0.1
  opts_ter@cnMinLevelValF       =  -2.0
  opts_ter@cnMaxLevelValF       =  2.0

  opts_ter@lbTitleString         = "SSTA (K)"
  opts_ter@lbTitleFontHeightF    = 0.01
  opts_ter@lbOrientation         = "vertical"
  opts_ter@pmLabelBarOrthogonalPosF = 0.006
  opts_ter@lbLabelFontHeightF    = 0.01
  opts_ter@pmLabelBarWidthF     = 0.05
  opts_ter@lbBoxSeparatorLinesOn = False
  opts_ter@lbLabelStride     = 10

  opts_ter@cnFillPalette   = "BlueWhiteOrangeRed"   ; change the color palette

; Plotting options for precipitation
  opts_r                      = res

  opts_r@cnLevelSelectionMode = "ManualLevels"
  opts_r@cnLevelSpacingF      =  1.0
  opts_r@cnMinLevelValF       =  25.0
  opts_r@cnMaxLevelValF       =  50.0

  opts_r@lbOrientation         = "horizontal"
  opts_r@pmLabelBarOrthogonalPosF = 0.11    ; move labelbar closer to plot

  opts_r@lbTitleString         = "10-m wind (m/s)"
  opts_r@lbTitleFontHeightF    = 0.01
  opts_r@lbLabelFontHeightF    = 0.01
  ;opts_r@lbTitleOffsetF        = -0.3
  opts_r@lbLabelStride     = 5
  opts_r@lbBoxSeparatorLinesOn = False

  cmap_r              = read_colormap_file("GMT_seis")
  cmap_r(0,3)         = 0.0    ; Fully transparent
  opts_r@cnFillPalette  = cmap_r


do i=0,dimsizes(time)-1

  print("Doing: "+(i+1)+" of "+dimsizes(time))

  map_terrain = gsn_csm_contour_map(wks,SSTA(i,:,:),opts_ter)
  contour_tot = gsn_csm_contour(wks,U10(i,:,:),opts_r)
  overlay(map_terrain,contour_tot)

  dateStr=sprinti("%04d",year(i))+"-"+sprinti("%02d",month(i))+"-"+sprinti("%02d",day(i))+"-"+sprinti("%02d",hour(i))+"Z"
  txres               = True
  txres@txFontHeightF = 0.018             ; Set the font height
  txres@txBackgroundFillColor="White"
  txres@txPerimOn=True
  txres@txPerimColor="Black"
  text1 = gsn_add_text(wks,map_terrain,dateStr,-100,40.0,txres)

draw(map_terrain)
frame(wks)

end do

end
