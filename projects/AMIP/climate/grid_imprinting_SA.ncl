load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "/glade/u/home/zarzycki/ncl/functions/plot_outline_fcn.ncl"
load "/glade/u/home/zarzycki/ncl/functions/plot_hommegrid_fcn.ncl"

begin

var = "PRECT"
plot_diff = False ; Plot a third panel that is the difference between the two
;oldfile = addfile("/glade/u/home/zarzycki/scratch/AMIPmonthly/climo/atl30x4_monthlyavg_climo_h0.08.nc","r")
;newfile = addfile("/glade/u/home/zarzycki/scratch/AMIPmonthly/climo/ne30_monthlyavg_climo_h0.08.nc_regrid.nc","r")
;oldfile = addfile("/glade/u/home/zarzycki/scratch/AMIPmonthly/avgall/atl30x4_climo_h0.all.nc","r")
;newfile = addfile("/glade/u/home/zarzycki/scratch/AMIPmonthly/avgall/ne30_climo_h0.all.nc_regrid.nc","r")
oldfile = addfile("/glade/u/home/zarzycki/scratch/get_months/117avg.nc","r")
newfile = addfile("/glade/u/home/zarzycki/scratch/get_months/120avg.nc","r")

if (var .eq. "PRECT") then
  oldvar2 = oldfile->$var$(0,:,:)
  newvar2 = newfile->$var$(0,:,:)
  oldvar = oldvar2
  newvar = newvar2
  oldvar = oldvar2*3.6e6
  newvar = newvar2*3.6e6
  newvar@long_name = "Total precipitation rate"
  oldvar@long_name = newvar@long_name
  newvar@units = "mm/hr"
  oldvar@units = "mm/hr"
else
  oldvar = oldfile->$var$(0,:,:)
  newvar = newfile->$var$(0,:,:)
end if

if (plot_diff) then
diffvar = oldvar
diffvar = newvar - oldvar
end if

wks  = gsn_open_wks("pdf","pdf/imprint_"+var)            ; open a ps file

;gsn_define_colormap(wks,"MPL_terrain")      
;gsn_merge_colormaps(wks,"cmp_haxby","BlueDarkOrange18")
;gsn_draw_colormap(wks)

if (plot_diff) then
  plot = new(3,graphic)
else
  plot = new(2,graphic)
end if

if (var .eq. "PRECT") then
;gsn_define_colormap(wks,"WhBlGrYeRe")
  gsn_merge_colormaps(wks,"WhBlGrYeRe","temp_19lev")
;gsn_draw_colormap(wks)
end if


res                             = True
res@mpFillOn                    = True        ; turn off gray fill
res@mpGeophysicalLineColor      = "Black"      ; color of cont. outlines
res@gsnFrame = False
res@gsnDraw = False
res@mpGreatCircleLinesOn=True
res@mpMinLatF   = -22.                      ; set the minimum latitude  
res@mpMaxLatF   = 8.                      ; set the maximum latitude  
res@mpMinLonF   = -85.                     ; set the minimum longitude  
res@mpMaxLonF   = -35.
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
res@lbLabelStride        = 2
res@cnLevelSelectionMode = "ManualLevels"    ; set contour intervals
;res@cnLevelSpacingF      =  500.              ;
;res@cnMinLevelValF       =  0.0           ;
;res@cnMaxLevelValF       =  26000.0 ; Use 80.0 -> 60 for this
res@lbLabelBarOn        = False           ; turn off individual cb's
;res@cnFillMode = "RasterFill"
res@cnRasterSampleFactorF = 0.0
res_diff = res

if (var .eq. "PRECT") then
  res@cnLevelSpacingF      =  .05
  res@cnMinLevelValF       =  0.1
  res@cnMaxLevelValF       =  1.0
  res@gsnSpreadColorStart = 2
  res@gsnSpreadColorEnd = 100
  res_diff@cnLevelSpacingF      =  .08
  res_diff@cnMinLevelValF       =  -.4
  res_diff@cnMaxLevelValF       =  .4
  res_diff@gsnSpreadColorStart = 102
  res_diff@gsnSpreadColorEnd = 121
end if
if (var .eq. "SHFLX") then
  print("Using SHFLX")
  res@cnLevelSpacingF      =  5.
  res@cnMinLevelValF       =  0.
  res@cnMaxLevelValF       =  100.
  res_diff@cnLevelSpacingF      =  .08
  res_diff@cnMinLevelValF       =  -.4
  res_diff@cnMaxLevelValF       =  .4
end if

plot(0) = gsn_csm_contour_map(wks,oldvar,res)
plot(1) = gsn_csm_contour_map(wks,newvar,res)
;plot(0) = plot_outline_fcn(wks,plot(0),"black",3.0)
;plot(1) = plot_outline_fcn(wks,plot(1),"black",3.0)
gridname="/glade/u/home/zarzycki/work/grids/exodus/atlantic_30_x4.g"
plot(0) = plot_hommegrid_fcn(wks,plot(0),gridname,"black",1.0,-30,20,-100,0)
plot(1) = plot_hommegrid_fcn(wks,plot(1),gridname,"black",1.0,-30,20,-100,0)

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
resP@lbLabelStride    = 2
;resP@pmLabelBarWidthF = 0.7
; resP@pmLabelBarHeightF
resP@amJust = "TopRight"
resP@gsnPanelFigureStringsFontHeightF = 0.015


resP@lbTitleString = newvar@units
resP@lbTitlePosition  = "Right"              ; title position
resP@lbTitleFontHeightF= .0135                ; make title smaller
resP@lbTitleDirection = "Across"             ; title direction
resP@lbTitleExtentF = 0.005

if (plot_diff) then
  resP@gsnPanelFigureStrings= (/"VR","Uni","Diff"/)
  gsn_panel(wks,plot,(/3,1/),resP)
else
  resP@gsnPanelFigureStrings= (/"a.) CESM 1.1.17_beta","b.) CESM 1.2.0_rel"/)
  gsn_panel(wks,plot,(/2,1/),resP)
end if



end


