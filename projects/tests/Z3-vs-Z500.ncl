load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

f=addfile("/glade/u/home/zarzycki/scratch/forecast_conus_30_x8_CAM5/run/2018011800/_forecast_conus_30_x8_CAM5.cam.h0.2018-01-25-00000.nc","r")
wgt_file="/glade/u/home/zarzycki/work/ASD2017_files/offline-remap/map_conus_30_x8_to_0.25x0.25glob_patch.nc"

Z500=f->Z500

Z3=f->Z3
PS=f->PS
hyam=f->hyam
hybm=f->hybm
p0=1000.

Opt         = True
Z3int  = ESMF_regrid_with_weights(Z3,wgt_file,Opt)
PSint  = ESMF_regrid_with_weights(PS,wgt_file,Opt)

Z500int = vinth2p(Z3int,hyam,hybm,500.0,PSint,2,p0,1,True)

Z500orig  = ESMF_regrid_with_weights(Z500,wgt_file,Opt)

printVarSummary(Z500orig)
printVarSummary(Z500int)

Z500intsq = Z500int(:,0,:,:)

Z500diff = Z500orig
Z500diff = Z500intsq - Z500orig

;************************************************
; create plots
;************************************************
  wks = gsn_open_wks("x11","panel")           ; send graphics to PNG file

  plot = new(3,graphic)                       ; create a plot array
  
  res                     = True
  res@gsnDraw             = False            ; don't draw
  res@gsnFrame            = False            ; don't advance frame
  res@cnInfoLabelOn       = False            ; turn off cn info label
  res@cnFillOn            = True             ; turn on color
  res@cnLinesOn       = False                   ; turn off contour lines
  res@cnLineLabelsOn  = False                   ; tuen off line labels

  cmap  = read_colormap_file("gui_default")
  res@cnFillPalette       = cmap 

  res@cnLevelSelectionMode =  "ManualLevels"   
  res@cnMinLevelValF       = 5000.
  res@cnMaxLevelValF       = 6000.
  res@cnLevelSpacingF      = 100. 

  res@gsnRightString="m"

  res@gsnLeftString="Z500 w/ hybrid interp."
  plot(0) = gsn_csm_contour_map(wks,Z500intsq(0,:,:),res) 
  res@gsnLeftString="Z500 w/ online interp."
  plot(1) = gsn_csm_contour_map(wks,Z500orig(0,:,:),res) 

  cmapdiff=read_colormap_file("NCV_blu_red")
  resdiff=res
  delete(resdiff@cnFillPalette)
  resdiff@cnFillPalette       = cmapdiff 
  resdiff@cnMinLevelValF       = -30.
  resdiff@cnMaxLevelValF       = 30.
  resdiff@cnLevelSpacingF      = 6. 
  resdiff@gsnLeftString="Z500_hybrid - Z500_online"
  plot(2) = gsn_csm_contour_map(wks,Z500diff(0,:,:),resdiff) 
;************************************************
; create panel
;************************************************
  resP                    = True                 ; modify the panel plot
  resP@gsnPanelBottom     = 0.05
  resP@gsnPanelMainString = "Z500 comparison"
  gsn_panel(wks,plot,(/3,1/),resP)

end
