;********************************************
; Use these libraries for running on cees

load "/opt/ncl-6.1.0-beta/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "/opt/ncl-6.1.0-beta/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/opt/ncl-6.1.0-beta/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "/opt/ncl-6.1.0-beta/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

;********************************************
begin

; NAME THE DIRECTORIES WHERE FILES ARE HELD

diri = "/glade/scratch/zarzycki/1980/"

; NAME THE FILES TO BE USED

fili1 = "atl_30_x4_refine_nochem.cam.h1.1980*.nc"

; ADD FILENAME TO THE CORRESPONDING DIRECTORY

files = systemfunc("ls "+diri+fili1)
f1 = addfiles(files, "r")
   ListSetType(f1,"cat")

; GRAB LAT AND LON ATTRIBUTES (FOR REGCM)

latitude = f1[0]->lat
longitude = f1[0]->lon

nlat = dimsizes(latitude)
nlon = dimsizes(longitude)

; GRAB MERIDIONAL WIND VARIABLE

V = f1[:]->V850(:,:,:)
V!0 = "time"
V!1 = "lat"
V!2 = "lon"

printVarSummary(V)

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


V_BPF&lat = latitude
V_BPF&lon = longitude


V_BPF_variance = dim_variance(V_BPF)
V_BPF_variance!0 = "lat"
V_BPF_variance!1 = "lon"

printVarSummary(V_BPF_variance)




V_BPF_avg = V_BPF_variance
V_BPF_avg!0 = "lat"
V_BPF_avg!1 = "lon"
V_BPF_avg&lat = latitude
V_BPF_avg&lon = longitude

printVarSummary(V_BPF_avg)



V_BPF_avg_flip = lonFlip(V_BPF_avg)
V_BPF_avg_flip!0 = "lat"
V_BPF_avg_flip!1 = "lon"
V_BPF_avg_flip&lat = latitude

;V_BPF_final = V_BPF_avg_flip(::-1,:)

printVarSummary(V_BPF_avg_flip)




; PLOT THE OUTPUT

wks = gsn_open_wks("pdf", "CAMSE_850mb_Vwind_variance_80-05_regrid")

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
   res@mpMaxLatF     =  40.                   ; Af
   res@mpMinLatF     =  -20.
   res@mpMinLonF     =  -50.
   res@mpMaxLonF     =  60.
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
  resP@txString            = "V-wind Variance '80-'05 850mb ERA-INTERIM Regrid"
  resP@lbLabelStride        = 2 
  gsn_panel(wks,plot,(/1,1/),resP)
  panelRes = True
  panelRes@gsnMaximize = True


end do  
end








