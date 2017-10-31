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
; Using daily V data
diri = "/glade/scratch/dtatch/aew/data/vdata/"

nfiles = 2
panels = new(nfiles,graphic)

nyear = 20
startYear = 1981
endYear = startYear+nyear-1

wks = gsn_open_wks("x11", "aew_700mb_Vwind_variance")

; setvalues NhlGetWorkspaceObjectId() 
;      "wsMaximumSize" : 33554432 
;   end setvalues 

;gsn_define_colormap( wks, "precip3_16lev")
gsn_define_colormap( wks, "BlGrYeOrReVi200")


do iFile = 0,nfiles-1


index = 0
do i = startYear,endYear

; NAME THE FILES TO BE USED

if (iFile .eq. 0) then
   fili6 = "v700_ne30_daily_"+i+"06*.nc"
   fili7 = "v700_ne30_daily_"+i+"07*.nc"
   fili8 = "v700_ne30_daily_"+i+"08*.nc"
   fili9 = "v700_ne30_daily_"+i+"09*.nc"
else if (iFile .eq. 1) then
   fili6 = "v700_atl30x4_daily_"+i+"06*.nc"
   fili7 = "v700_atl30x4_daily_"+i+"07*.nc"
   fili8 = "v700_atl30x4_daily_"+i+"08*.nc"
   fili9 = "v700_atl30x4_daily_"+i+"09*.nc"
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

; GRAB LAT AND LON ATTRIBUTES

minLat = -20
maxLat = 40
minLon = -50
maxLon = 60

V_in_yearly = f1[:]->V700(:,{minLat:maxLat},:)

if (index .eq. 0) then
   dimlat = dimsizes(V_in_yearly&lat)
   dimlon = dimsizes(V_in_yearly&lon)
   dimtime = dimsizes(V_in_yearly&time)

   V_in = new((/nyear,dimtime,dimlat,dimlon/),float)
end if

V_in(index,:,:,:) = V_in_yearly

index = index + 1

end do

printVarSummary(V_in)

; GRAB MERIDIONAL WIND VARIABLE

; WITH PIVOT ----------------------
lat = f1[0]->lat({-20:40})
longitude_in = f1[0]->lon
longitude_in!0 = "lon"
longitude_in&lon = longitude_in

V_piv = lonPivot(V_in,180)
longitude_piv = lonPivot(longitude_in,180)

printVarSummary(V_piv)
printVarSummary(longitude_piv)
;print(longitude_piv)

V = V_piv(:,:,:,{minLon:maxLon})
longitude = longitude_piv({minLon:maxLon})
lon = longitude&lon
;lon&lon = lon
;lon = (/lon&lon/) 
;------------------------------------

V!0 = "year"
V!1 = "time"
V!2 = "lat"
V!3 = "lon"

nlat = dimsizes(lat)
nlon = dimsizes(lon)

printVarSummary(V)
printVarSummary(lon)
print(lon)

;*********************************************

; SET UP BANPASS FILTER
; LOOK AT NCL PAGE FOR FILWGTS_LANCZOS FUNCTION FOR DETAILS

ihp = 2
sigma = 1.0

nWgt = 31
fca = 1./6
fcb = 1./2
wgt = filwgts_lanczos (nWgt, ihp, fca, fcb, sigma)

print(wgt)

; FILTER THE TIME DIMENSION FOR EACH OF THE ARRAYS YEARS (26 IN THIS CASE)

V_BPF = wgt_runave (V(year|:,lat|:, lon|:, time|:), wgt, 0)   ; 2 - 6 day

V_BPF!0 = "year"
V_BPF!1 = "lat"
V_BPF!2 = "lon"
V_BPF!3 = "time"

printVarSummary(V_BPF)

V_BPF&lat = lat
V_BPF&lon = lon


V_BPF_variance = dim_variance(V_BPF)
V_BPF_variance!0 = "year"
V_BPF_variance!1 = "lat"
V_BPF_variance!2 = "lon"

printVarSummary(V_BPF_variance)




V_BPF_avg = dim_avg(V_BPF_variance(lat|:,lon|:,year|:))
V_BPF_avg!0 = "lat"
V_BPF_avg!1 = "lon"
V_BPF_avg&lat = lat
V_BPF_avg&lon = lon

printVarSummary(V_BPF_avg)



;V_BPF_avg_flip = lonFlip(V_BPF_avg)
;V_BPF_avg_flip!0 = "lat"
;V_BPF_avg_flip!1 = "lon"
;V_BPF_avg_flip&lat = lat


V_BPF_avg_flip = V_BPF_avg

printVarSummary(V_BPF_avg_flip)


delete([/V_in_yearly, V_in, longitude, longitude_in, lat, longitude_piv, lon, V_piv, V, wgt/])
delete([/V_BPF, V_BPF_variance, V_BPF_avg/])

; PLOT THE OUTPUT


  res                        = True               ; plot mods desired

  res@mpOutlineBoundarySets  = "National"
  res@gsnDraw               =False
  res@gsnFrame              =False
  res@cnRasterModeOn        =False 
  res@cnFillOn               = True               ; color fill
  res@cnLinesOn              = False              
  res@cnLineLabelsOn         = False              ; no contour labels
  res@gsnSpreadColors        = True               ; use total colormap
  res@gsnSpreadColorStart    = 2
  res@gsnSpreadColorEnd      = 201
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
 res@cnLevelSpacingF        = .5
 res@cnMinLevelValF         = 0
 res@cnMaxLevelValF         = 12
  res@mpPerimOn              = True
 
  
;  res@tiMainFontHeightF = 0.08
;  res@tiXAxisFontHeightF = 0.08
;  res@tiYAxisFontHeightF = 0.08



if (iFile .eq. 0) then
   res@tiMainString = "Low Resolution"
else if (iFile .eq. 1) then
   res@tiMainString = "Variable Resolution"
end if
end if

;   res@tiMainString = "Variable Resolution Meridional Wind Variance at 700 hPa"
;   res@tiYAxisString = "Latitude"
;   res@tiXAxisString = "Longitude"
   res@gsnLeftString = "JJAS "+startYear+" to "+endYear
   res@gsnRightString = "m~S~2~N~ s~S~-2~N~"
   panels(iFile) = gsn_csm_contour_map(wks,V_BPF_avg_flip(:,:),res)
if (iFile .eq. 1) then
   panels(iFile) = plot_outline_fcn(wks,panels(iFile),"black",4.0)
end if


delete(V_BPF_avg_flip)

end do  


  resP                     = True                ; modify the panel plot
;  resP@gsnMaximize          = True
  resP@gsnPanelLabelBar    = True                ; add common colorbar
  resP@txString            = "CAM-SE Meridional Wind Variance at 700 hPa"
  resP@lbLabelStride        = 2 
  gsn_panel(wks,panels,(/1,2/),resP)

end








