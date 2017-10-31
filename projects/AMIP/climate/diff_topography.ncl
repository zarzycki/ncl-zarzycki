load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "/glade/u/home/zarzycki/ncl/functions/plot_outline_fcn.ncl"
load "/glade/u/home/zarzycki/ncl/functions/plot_hommegrid_fcn.ncl"

begin

var = "PHIS"
plot_diff = False ; Plot a third panel that is the difference between the two
unifile = addfile("/glade/u/home/zarzycki/work/toposmooth/SEtopo/USGS-gtopo30_0.9x1.25_smooth2000-100_ne30np4_c051027.nc","r")
reffile = addfile("/glade/u/home/zarzycki/work/toposmooth/SEtopo/topo_atlantic_30_x4.zarzycki_new_smoothing_consistentSGH.nc","r")

uni_wgt_file = "/glade/p/work/zarzycki/maps/amip_plot_maps/map_ne30np4_TO_AMIP_ref_latlon_patc.130523.nc"
uni_wgt_file = "/glade/p/work/zarzycki/maps/amip_plot_maps/map_ne30np4_TO_1x1_patc.131122.nc"
ref_wgt_file = "/glade/p/work/zarzycki/maps/amip_plot_maps/map_atl30x4_TO_AMIP_ref_latlon_patc.131202.nc"
;remap

refvar_se = reffile->$var$
univar_se = unifile->$var$

print("Regridding the data")
Opt         = True
Opt@CopyVarCoords = True
refvar  = ESMF_regrid_with_weights(refvar_se,ref_wgt_file,Opt)
univar  = ESMF_regrid_with_weights(univar_se,uni_wgt_file,Opt)
;lat = refvar&lat
;lon = refvar&lon

refvar = where(refvar.lt.0,0,refvar)
univar = where(univar.lt.0,0,univar)

varmax = max(refvar)
varmin = min(refvar)

if (plot_diff) then
diffvar = refvar
diffvar = refvar - univar
end if

wks  = gsn_open_wks("pdf","pdf/diffplots_"+var)            ; open a ps file

gsn_define_colormap(wks,"MPL_terrain")      
;gsn_merge_colormaps(wks,"cmp_haxby","BlueDarkOrange18")
;gsn_draw_colormap(wks)

if (plot_diff) then
  plot = new(3,graphic)
else
  plot = new(2,graphic)
end if

res                             = True
res@mpFillOn                    = True        ; turn off gray fill
res@mpGeophysicalLineColor      = "Black"      ; color of cont. outlines
res@gsnFrame = False
res@gsnDraw = False
res@mpGreatCircleLinesOn=True
res@mpMinLatF   = -20.                      ; set the minimum latitude  
res@mpMaxLatF   = 75.                      ; set the maximum latitude  
res@mpMinLonF   = -120.                     ; set the minimum longitude  
res@mpMaxLonF   = 20.
;res@mpProjection="satellite"
;res@mpCenterLonF = -50. 
;res@mpCenterLatF = 30. 
res@mpOutlineOn            = True
res@mpPerimOn              = False
res@cnFillOn=True
res@gsnLeftString=""

res@cnLinesOn       = False                   ; turn off contour lines
res@cnLineLabelsOn       = False             ; turn off line labels
res@gsnSpreadColors      = True              ; use full colormap
res@lbLabelStride        = 4
res@cnLevelSelectionMode = "ManualLevels"    ; set contour intervals
res@cnLevelSpacingF      =  500.              ;
res@cnMinLevelValF       =  0.0           ;
res@cnMaxLevelValF       =  26000.0 ; Use 80.0 -> 60 for this
;res@gsnSpreadColorStart  = 2
;res@gsnSpreadColorEnd    = 65
res@lbLabelBarOn        = False           ; turn off individual cb's
res@cnFillMode = "RasterFill"
res@cnRasterSampleFactorF = 0.0

plot(0) = gsn_csm_contour_map(wks,refvar,res)
plot(1) = gsn_csm_contour_map(wks,univar,res)
plot(0) = plot_outline_fcn(wks,plot(0),"black",2.0)

if (plot_diff) then
	res@cnLevelSpacingF      =  500.              ;
	res@cnMinLevelValF       =  -6000.0           ;
	res@cnMaxLevelValF       =  6000.0 ; Use 80.0 -> 60 for this
	;res@gsnSpreadColorStart  = 66
	;res@gsnSpreadColorEnd    = 83
	plot(2) = gsn_csm_contour_map(wks,diffvar,res)
	plot(2) = plot_outline_fcn(wks,plot(2),"black",2.0)
end if
  
; Modify panel plots and whatnot
resP                     = True      ; modify the panel plot
;resP@txString            = var      ; Plot title
resP@gsnPanelLabelBar    = True      ; add common colorbar
;resP@lbLabelFontHeightF  = 0.015    ; make labels smaller
resP@lbLabelStride    = 4
;resP@pmLabelBarWidthF = 0.7
; resP@pmLabelBarHeightF
resP@amJust = "TopRight"

if (plot_diff) then
  resP@gsnPanelFigureStrings= (/"VR","Uni","Diff"/)
  gsn_panel(wks,plot,(/3,1/),resP)
else
  resP@gsnPanelFigureStrings= (/"VR","Uni"/)
  gsn_panel(wks,plot,(/1,2/),resP)
end if



end


