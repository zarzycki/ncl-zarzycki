;********************************************
; Use these libraries for running on cees

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

;********************************************
begin

; NAME THE DIRECTORIES WHERE FILES ARE HELD

diri = "./udata_netcdf/"

nyear = 11
startYear = 1990
endYear = startYear+nyear-1

wks = gsn_open_wks("pdf", "era_aew_u_levlat")

gsn_define_colormap( wks, "BlueRed")

index = 0
do i = startYear,endYear

; NAME THE FILES TO BE USED

   fili = "e4moda.an.ml.t85.u."+i+".nc"


; ADD FILENAME TO THE CORRESPONDING DIRECTORY

 files = systemfunc("ls "+diri+fili)

;print(files)

f1 = addfiles(files, "r")
   ListSetType(f1,"cat")

; GRAB LAT AND LON ATTRIBUTES (FOR REGCM)

minLat = -20
maxLat = 40
minLon = -15
maxLon = 15

  U_in_all = f1[:]->U(:,:,{minLat:maxLat},:)
  U_in_yearly = dim_avg_n_Wrap(U_in_all,0)

;   printVarSummary(U_in_yearly)

if (index .eq. 0) then
   dimlat = dimsizes(U_in_yearly&lat)
   dimlon = dimsizes(U_in_yearly&lon)
   dimlev = dimsizes(U_in_yearly&lev)

   U_in = new((/nyear,dimlev,dimlat,dimlon/),float)
end if

U_in(index,:,:,:) = U_in_yearly

index = index + 1

end do

printVarSummary(U_in)

; WITH PIVOT ----------------------
longitude_in = f1[0]->lon
longitude_in!0 = "lon"
longitude_in&lon = longitude_in

U_piv = lonPivot(U_in,180)
longitude_piv = lonPivot(longitude_in,180)

printVarSummary(U_piv)
printVarSummary(longitude_piv)
print(longitude_piv)

;U = U_piv(:,:,:,{minLon:maxLon})
U = U_piv(:,:,:,117:139)
;longitude = longitude_piv({minLon:maxLon})
longitude = longitude_piv(117:139)
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

  res@cnRasterModeOn        =False 
  res@cnFillOn               = True               ; color fill
  res@cnLinesOn              = False              
  res@cnLineLabelsOn         = False              ; no contour labels
  res@gsnSpreadColors        = True               ; use total colormap
  res@cnInfoLabelOn          =False
  res@gsnAddCyclic           =False
  res@gsnYAxisIrregular2Linear = True

  res@cnLevelSelectionMode   = "ManualLevels"
 res@cnLevelSpacingF        = 2
 res@cnMinLevelValF         = -20
 res@cnMaxLevelValF         = 20
 
  res@trYReverse            = True                 ; reverse y-axis
  res@tmXBMode    = "Explicit"
  res@tmXBValues = (/-15,0,15,30/)
  res@tmXBLabels = (/"15S","EQ","15N","30N"/)

   res@tiMainString = "ERA-40 Zonal Wind: Average between 15~S~o~N~ W and 15~S~o~N~ E"
   res@tiYAxisString = "Pressure (hPa)"

   res@gsnLeftString = "JJAS "+startYear+" to "+endYear
   plot = gsn_csm_contour(wks,U_mean,res)

   delete([/U_in_all,U_in_yearly,U_in,U_avg,U_mean/])
   delete([/U_piv,U,longitude,longitude_piv,lon,longitude_in/])

end








