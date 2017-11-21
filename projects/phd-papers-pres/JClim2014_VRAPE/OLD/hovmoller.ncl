; ===========================================
; hov_5.ncl
; ===========================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
; ===========================================
begin

    timeStride = 4   ; number of time samples to stride by

; ;---Names of source and weight file
; ;    src_file = "/glade/p/work/mlevy/HOMME_APE/uniform_15/camrun.cam.h1.0000-10-28-00000.nc"
     src_file = "/glade/scratch/zarzycki/APE_levy/CAM5/quadrant_15_x8/h2_0002.nc"
     wgt_file = "/glade/p/work/zarzycki/maps/plotmaps/map_uni_15_TO_0.25x0.25_patc.130309.nc"
     wgt_file = "/glade/p/work/zarzycki/maps/plotmaps/map_quad_15_x8_TO_0.25x0.25_patc.130417.nc"
; 
; ;---Open files containing source HOMME and destination FV grids
     sfile = addfile(src_file,"r")
; 
; ;---Get two variables to regrid and the source lat/lon grid
     prect  = sfile->PRECL(::timeStride,:)            ; time (1) x ncol
 
     Opt         = True
     prect_regrid  = ESMF_regrid_with_weights(prect,wgt_file,Opt)
;     
;     latband = -10

;    sfile = addfile("/glade/scratch/zarzycki/APE_levy/CAM5/quadrant_15_x8/fullyear_regrid_0.25x0.25.nc","r")
;    prect_regrid  = sfile->PRECL(::timeStride,::4,::4)            ; time (1) x ncol
    
    latband = 10
    prect_avg = dim_avg_n_Wrap(prect_regrid(:,{-latband:latband},:),1)
    
    prect_avg = lonFlip(prect_avg)

    printVarSummary(prect_regrid)

;==============================================
; create color plot
;=============================================
  wks  = gsn_open_wks ("pdf", "hov" )            ; open ps file
  gsn_define_colormap(wks,"precip3_16lev")             ; choose colormap

  res                      = True               ; plot mods desired
  res@cnFillOn             = True               ; turn on color fill
  res@cnLinesOn       = False                   ; turn off contour lines
  res@cnLineLabelsOn  = False                   ; tuen off line labels

;---This resource not needed in V6.1.0
  res@gsnSpreadColors      = True               ; use full range of colors

;  res@tiMainString         = "Pacific Region"   ; title

  res@cnLevelSelectionMode = "ManualLevels"     ; manual contour levels
  res@cnMinLevelValF       = 0.	        ; min level
  res@cnMaxLevelValF       = 4.0e-7               ; max level
  res@cnLevelSpacingF      = 0.2e-7                 ; contour level spacing

  res@trYReverse          = True                ; reverse y axis
  
;  plot = gsn_csm_hov(wks, prect_regrid(:,{0},{100:220}), res) 
  plot = gsn_csm_hov(wks, prect_avg(:,:), res) 
  
end
