;********************************************
; Use these libraries for running on cees

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

;********************************************
begin

; NAME THE DIRECTORIES WHERE FILES ARE HELD

diri = "/glade/scratch/dtatch/aew/data/udata/"

nfiles = 2
panels = new(nfiles,graphic)

nyear = 11
startYear = 1990
endYear = startYear+nyear-1

wks = gsn_open_wks("x11", "aew_u_levlat")

; setvalues NhlGetWorkspaceObjectId() 
;      "wsMaximumSize" : 33554432 
;   end setvalues 

gsn_define_colormap( wks, "BlueDarkRed18")

do iFile = 0,nfiles-1


index = 0
do i = startYear,endYear

if (i .ne. 1987) then

; NAME THE FILES TO BE USED

if (iFile .eq. 0) then
   fili6 = "u_ne30_monthlyavg_"+i+"06*_regrid.nc"
   fili7 = "u_ne30_monthlyavg_"+i+"07*_regrid.nc"
   fili8 = "u_ne30_monthlyavg_"+i+"08*_regrid.nc"
   fili9 = "u_ne30_monthlyavg_"+i+"09*_regrid.nc"
else if (iFile .eq. 1) then
   fili6 = "u_atl30x4_monthlyavg_"+i+"06*.nc"
   fili7 = "u_atl30x4_monthlyavg_"+i+"07*.nc"
   fili8 = "u_atl30x4_monthlyavg_"+i+"08*.nc"
   fili9 = "u_atl30x4_monthlyavg_"+i+"09*.nc"
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

print(files)

f1 = addfiles(files, "r")
   ListSetType(f1,"cat")

; GRAB LAT AND LON ATTRIBUTES (FOR REGCM)

minLat = -20
maxLat = 40
minLon = -25
maxLon = 15

  lev = f1[0]->lev({200:1000})
  lev@units = "hPa"
  U_in_all = f1[:]->U(:,{200:1000},{minLat:maxLat},:)
  
  U_in_yearly = dim_avg_n_Wrap(U_in_all,0)

;U_in_yearly = f1[:]->U
   printVarSummary(U_in_yearly)

if (index .eq. 0) then
   dimlat = dimsizes(U_in_yearly&lat)
   dimlon = dimsizes(U_in_yearly&lon)
   dimlev = dimsizes(U_in_yearly&lev)

   U_in = new((/nyear,dimlev,dimlat,dimlon/),float)
end if

U_in(index,:,:,:) = U_in_yearly

index = index + 1

end if
end do


; WITH PIVOT ----------------------
lat = f1[0]->lat({-20:40})
longitude_in = f1[0]->lon
longitude_in!0 = "lon"
longitude_in&lon = longitude_in

U_piv = lonPivot(U_in,180)
longitude_piv = lonPivot(longitude_in,180)

printVarSummary(U_piv)
printVarSummary(longitude_piv)
;print(longitude_piv)

U = U_piv(:,:,:,{minLon:maxLon})
longitude = longitude_piv({minLon:maxLon})
lon = longitude&lon
;------------------------------------

U!0 = "time"
U!1 = "lev"
U!2 = "lat"
U!3 = "lon"

U_avg = dim_avg_n_Wrap(U,0)
U_mean = dim_avg_n_Wrap(U_avg,2)


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
;  res@gsnYAxisIrregular2Linear = True

  res@lbLabelBarOn        = False              ; turn off individual cb's
  res@cnLevelSelectionMode   = "ManualLevels"
  res@cnLevelSpacingF        = 2
  res@cnMinLevelValF         = -18
  res@cnMaxLevelValF         = 18
 
  res@trYReverse            = True                 ; reverse y-axis
  res@tmXBMode    = "Explicit"
  res@tmXBValues = (/-15,0,15,30/)
  res@tmXBLabels = (/"15S","EQ","15N","30N"/)

;  res@tiMainFontHeightF = 0.08
;  res@tiXAxisFontHeightF = 0.08
;  res@tiYAxisFontHeightF = 0.08



if (iFile .eq. 0) then
   res@tiMainString = "Uniform 1~S~o~N~"
   res@tiYAxisString = "Pressure (hPa)"
else if (iFile .eq. 1) then
   res@tiMainString = "Variable Resolution"
   res@tiYAxisString = " "
end if
end if

U_mean&lev=lev
printVarSummary(U_mean)

   res@gsnLeftString = "JJAS "+startYear+" to "+endYear
;   panels(iFile) = gsn_csm_contour(wks,U_mean,res)
   panels(iFile) = gsn_csm_pres_hgt(wks,U_mean,res)

   delete([/U_in_all,U_in_yearly,U_in,U_avg,U_mean/])
   delete([/U_piv,U,longitude,longitude_piv,lon,lat,longitude_in/])

end do  


  resP                     = True                ; modify the panel plot
  resP@gsnPanelLabelBar    = True                ; add common colorbar
  resP@txString            = "CAM-SE Zonal Wind: Average between "+-minLon+"~S~o~N~ W and "+maxLon+"~S~o~N~ E"
  resP@lbLabelStride        = 2 
  gsn_panel(wks,panels,(/1,2/),resP)

end








