;********************************************
; Use these libraries for running on cees

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

;********************************************
begin

; NAME THE DIRECTORIES WHERE FILES ARE HELD

diri = "./data/"


startYear = 1985
endYear = 1986


do i = startYear,endYear

; NAME THE FILES TO BE USED

fili6 = "v700_atl30x8_daily_198*06*.nc"
fili7 = "v700_atl30x8_daily_198*07*.nc"
fili8 = "v700_atl30x8_daily_198*08*.nc"
fili9 = "v700_atl30x8_daily_198*09*.nc"

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
exit

f1 = addfiles(files, "r")
   ListSetType(f1,"cat")

; GRAB LAT AND LON ATTRIBUTES (FOR REGCM)

minLat = -20
maxLat = 40
;minLon = 360-50
;maxLon = 360
minLon = -50
maxLon = 60


; GRAB MERIDIONAL WIND VARIABLE

; WITH PIVOT ----------------------
V_in = f1[:]->V700(:,{minLat:maxLat},:)
lat = f1[0]->lat({-20:40})
longitude_in = f1[0]->lon
longitude_in!0 = "lon"
longitude_in&lon = longitude_in

V_piv = lonPivot(V_in,180)
longitude_piv = lonPivot(longitude_in,180)

printVarSummary(V_piv)
printVarSummary(longitude_piv)
;print(longitude_piv)

V = V_piv(:,:,{minLon:maxLon})
longitude = longitude_piv({minLon:maxLon})
lon = longitude&lon
;lon&lon = lon
;lon = (/lon&lon/) 
;------------------------------------

V!0 = "time"
V!1 = "lat"
V!2 = "lon"

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

V_BPF = wgt_runave (V(lat|:, lon|:, time|:), wgt, 0)   ; 2 - 6 day

V_BPF!0 = "lat"
V_BPF!1 = "lon"
V_BPF!2 = "time"

printVarSummary(V_BPF)

V_BPF&lat = lat
V_BPF&lon = lon


V_BPF_variance = dim_variance(V_BPF)
V_BPF_variance!0 = "lat"
V_BPF_variance!1 = "lon"

printVarSummary(V_BPF_variance)




V_BPF_avg = V_BPF_variance
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




; PLOT THE OUTPUT

wks = gsn_open_wks("pdf", "aew_700mb_Vwind_variance_atl30x8")

 setvalues NhlGetWorkspaceObjectId() 
      "wsMaximumSize" : 33554432 
   end setvalues 

;gsn_define_colormap( wks, "precip3_16lev")
gsn_define_colormap( wks, "BlGrYeOrReVi200")

  res                        = True               ; plot mods desired
  ;cmap=gsn_retrieve_colormap(wks)
  ;cmap(2:,:)=cmap(2::-1,:)
  ;gsn_define_colormap(wks,cmap)


  plot = new(1,graphic)
  

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
  ;res@ScalarContour = True

 res@mpLimitMode   = "LatLon"                 ; control map zoom with lat/lons
   res@mpMaxLatF     =  maxLat                   ; Af
   res@mpMinLatF     =  minLat
   res@mpMinLonF     =  minLon
   res@mpMaxLonF     =  maxLon
;   res@mpMinLonF     =  -50
;   res@mpMaxLonF     =  60
 res@mpOutlineBoundarySets  ="National"


  res@lbLabelBarOn        = False              ; turn off individual cb's
  res@cnLevelSelectionMode   = "ManualLevels"
 res@cnLevelSpacingF        = .5
 res@cnMinLevelValF         = 0
 res@cnMaxLevelValF         = 12
  res@mpPerimOn              = True
 




do j = 0,1
 plot = gsn_csm_contour_map(wks,V_BPF_avg_flip(:,:),res)

  resP                     = True                ; modify the panel plot
  resP@gsnPanelLabelBar    = True                ; add common colorbar
  resP@txString            = "JJAS V-wind Variance 700 hPa CAMSE VarRes Regrid"
  resP@lbLabelStride        = 2 
  gsn_panel(wks,plot,(/1,1/),resP)
  panelRes = True
  panelRes@gsnMaximize = True


end do  
end








