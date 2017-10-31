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

diri = "./data/precipdata/"

nfiles = 2
panels = new(nfiles,graphic)

nyear = 20
startYear = 1981
endYear = startYear+nyear-1

wks = gsn_open_wks("pdf", "aew_precip_latlon")

; setvalues NhlGetWorkspaceObjectId() 
;      "wsMaximumSize" : 33554432 
;   end setvalues 

gsn_define_colormap( wks, "WhiteBlueGreenYellowRed")

do iFile = 0,nfiles-1


; NAME THE FILES TO BE USED

if (iFile .eq. 0) then
   fili6 = "precip_ne30_daily_*06*_regrid.nc"
   fili7 = "precip_ne30_daily_*07*_regrid.nc"
   fili8 = "precip_ne30_daily_*08*_regrid.nc"
   fili9 = "precip_ne30_daily_*09*_regrid.nc"
else if (iFile .eq. 1) then
   fili6 = "precip_atl30x4_daily_*06*.nc"
   fili7 = "precip_atl30x4_daily_*07*.nc"
   fili8 = "precip_atl30x4_daily_*08*.nc"
   fili9 = "precip_atl30x4_daily_*09*.nc"
end if
end if


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

  precip_in = f1[:]->PRECT(:,{minLat:maxLat},:)
  precip_mm = precip_in*86400000
    copy_VarMeta(precip_in,precip_mm)
    precip_mm@units = "mm/day"
  precip_avg = dim_avg_n_Wrap(precip_mm,0)


; WITH PIVOT ----------------------
;lat = f1[0]->lat({-20:40})
;longitude_in = f1[0]->lon
;longitude_in!0 = "lon"
;longitude_in&lon = longitude_in

precip_piv = lonPivot(precip_avg,180)
;longitude_piv = lonPivot(longitude_in,180)

precip = precip_piv(:,{minLon:maxLon})
;longitude = longitude_piv({minLon:maxLon})

delete([/precip_in,precip_avg,precip_piv,precip_mm/])

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


  res@lbLabelBarOn        = False              ; turn off individual cb's
  res@cnLevelSelectionMode   = "ManualLevels"
 res@cnLevelSpacingF        = 2
 res@cnMinLevelValF         = 0
 res@cnMaxLevelValF         = 30
 
;  res@tiMainFontHeightF = 0.08
;  res@tiXAxisFontHeightF = 0.08
;  res@tiYAxisFontHeightF = 0.08


if (iFile .eq. 0) then
   res@tiMainString = "Low Resolution"
else if (iFile .eq. 1) then
   res@tiMainString = "Variable Resolution"
end if
end if

   res@gsnLeftString = "JJAS "+startYear+" to "+endYear
   panels(iFile) = gsn_csm_contour_map(wks,precip,res)
if (iFile .eq. 1) then
   panels(iFile) = plot_outline_fcn(wks,panels(iFile),"blue",2.0)
end if

   delete(precip)

end do  


  resP                     = True                ; modify the panel plot
  resP@gsnPanelLabelBar    = True                ; add common colorbar
  resP@txString            = "CAM-SE Total Precipitation"
  resP@lbLabelStride        = 2 
  gsn_panel(wks,panels,(/1,2/),resP)

end








