;********************************************
; Use these libraries for running on cees

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "/glade/u/home/zarzycki/ncl/functions/plot_outline_fcn.ncl"

;********************************************
begin

; NAME THE DIRECTORIES WHERE FILES ARE HELD

diri = "./precipdata_netcdf/"

nyear = 20
startYear = 1981
endYear = startYear+nyear-1

wks = gsn_open_wks("pdf", "era_aew_precip_latlon")

gsn_define_colormap( wks, "WhiteBlueGreenYellowRed")


; NAME THE FILES TO BE USED

   fili6 = "ds124.0_*06*.nc"
   fili7 = "ds124.0_*07*.nc"
   fili8 = "ds124.0_*08*.nc"
   fili9 = "ds124.0_*09*.nc"


; ADD FILENAME TO THE CORRESPONDING DIRECTORY

;files = systemfunc("ls "+diri+fili1)

 files6 = systemfunc("ls "+diri+fili6)
 files7 = systemfunc("ls "+diri+fili7)
 files8 = systemfunc("ls "+diri+fili8)
 files9 = systemfunc("ls "+diri+fili9)

 files1 = array_append_record(files6,files7,0)
 files2 = array_append_record(files8,files9,0)

 files = array_append_record(files1,files2,0)


f1 = addfiles(files, "r")
   ListSetType(f1,"cat")

; GRAB LAT AND LON ATTRIBUTES (FOR REGCM)
minLat = -20
maxLat = 40
minLon = -50
maxLon = 60

  strat_precip_in = f1[:]->LSP_GDS4_SFC(:,{minLat-2:maxLat+2},:)
  conv_precip_in = f1[:]->CP_GDS4_SFC(:,{minLat-2:maxLat+2},:)
  precip_mm = (strat_precip_in + conv_precip_in)*6000
    copy_VarCoords(conv_precip_in,precip_mm)
    precip_mm@units = "mm/day"
  precip_avg = dim_avg_n_Wrap(precip_mm,0)


; WITH PIVOT ----------------------

precip_piv = lonPivot(precip_avg,180)

precip = precip_piv(:,{minLon-2:maxLon+2})

;------------------------------------

; PLOT THE OUTPUT

  res                        = True               ; plot mods desired

  res@gsnDraw               =False
  res@gsnFrame              =False
  res@cnRasterModeOn        =False 
  res@cnFillOn               = True               ; color fill
  res@cnLinesOn              = False              
  res@cnLineLabelsOn         = False              ; no contour labels
  res@gsnSpreadColors        = True               ; use total colormap
  res@cnInfoLabelOn          =False
  res@gsnAddCyclic           =False

 res@mpLimitMode   = "LatLon"                 ; control map zoom with lat/lons
   res@mpMaxLatF     =  maxLat                   ; Af
   res@mpMinLatF     =  minLat
   res@mpMinLonF     =  minLon
   res@mpMaxLonF     =  maxLon
 res@mpOutlineBoundarySets  ="National"
 res@mpGreatCircleLinesOn=True


  res@cnLevelSelectionMode   = "ManualLevels"
 res@cnLevelSpacingF        = 2
 res@cnMinLevelValF         = 0
 res@cnMaxLevelValF         = 30
 
;  res@tiMainFontHeightF = 0.08
;  res@tiXAxisFontHeightF = 0.08
;  res@tiYAxisFontHeightF = 0.08


   res@tiMainString = "ERA-40 Total Precipitation"

   res@gsnLeftString = "JJAS "+startYear+" to "+endYear
   plot = gsn_csm_contour_map(wks,precip,res)

draw(wks)
frame(wks)

end








