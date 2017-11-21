;========================================================
; TC_cross_and_latlon.ncl:   plots the PS, U, V, and T.
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "calc_area.ncl"
;========================================================
begin
;========================================================
; USER OPTIONS
;========================================================


 
in1 = addfile("/glade/proj3/mich1098/zarzycki/plot_files/atl_30_x4_refine_nochem.cam.h0.1980-09-06-00000.nc","r")

lev  = in1->lev
time = in1->time
lat = in1->lat
lon = in1->lon

nlat = dimsizes(lat)
nlon = dimsizes(lon)

flut = in1->PRECT

;**************** PLOT

 plot_type  = "x11"   ; plot types: ps,x11
 plot_name  = "2dplot"
 wks = gsn_open_wks(plot_type,plot_name)

;----------- Global resources -----------------------------------------
  
  res                 = True
  res@cnFillOn		  = True
  res@cnLinesOn       = False
  res@gsnSpreadColors = True
  res@gsnSpreadColorStart= -1
  res@gsnSpreadColorEnd = 2
  
  res@mpMinLatF              =  10
  res@mpMaxLatF              =  30
  res@mpMinLonF              = -80
  res@mpMaxLonF              = -60
  
  gsn_define_colormap(wks,"satellite")          ; choose colormap
    
  plot = gsn_csm_contour_map(wks,flut(0,:,:),res)    
  

end