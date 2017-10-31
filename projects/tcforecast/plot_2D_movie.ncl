load "$NCARG_NCARG/nclscripts/csm/gsn_code.ncl"
load "$NCARG_NCARG/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_NCARG/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "/glade/u/home/zarzycki/ncl/functions/plot_outline_fcn.ncl"
load "/glade/u/home/zarzycki/ncl/functions/plot_hommegrid_fcn.ncl"
load "/glade/u/home/zarzycki/ncl/functions/rainratetodbz.ncl"


begin

;============= USER SETTINGS

timestride = 1
out_type = "pdf"
regrid=True
poisson=True
region="atlantic" ; atlantic for atlantic, anything else for global
variable = "FLUT"

;=============

wks = gsn_open_wks(out_type,"pdf/AMIP_vort")
                   
all_files = systemfunc ("ls /glade/u/home/zarzycki/scratch/sewx_fullforecasts/structure/tcforecast_60_x4/2012_00Z/2012102500/*h1*nc")
print(all_files)
sfile = addfiles (all_files, "r")   ; note the "s" of addfile
ListSetType (sfile, "cat")             ; concatenate or "merge" (default)

timearr = sfile[:]->time
ntimes = dimsizes(timearr)

do time = 1,ntimes-1,timestride

print("Doing time number: "+time)

var = sfile[:]->$variable$(time,:)            ; time (1) x nlev x ncol

if (variable .eq. "PRECT") then
  var2 = rainratetodbz(var,1)
  delete(var)
  var = var2
  delete(var2)
end if

if (regrid) then
    wgt_file = "/glade/p/work/zarzycki/maps/forecast_plot_maps/tcforecast_60_x4_to_0.125x0.125_patch.nc"
    Opt         = True
    var_regrid = ESMF_regrid_with_weights(var,wgt_file,Opt)
    delete(var)
    var = var_regrid
    delete(var_regrid)
end if

if (poisson) then
  print("Begin interp")
  guess     = 1                ; use zonal means
  is_cyclic = True             ; cyclic [global]
  nscan     = 500             ; usually much less than this
  eps       = 1.e-2            ; variable dependent
  relc      = 0.5              ; relaxation coefficient
  opt       = 0                ; not used
  poisson_grid_fill( var, is_cyclic, guess, nscan, eps, relc, opt)
end if

;************************************************

res2 = True
res2@tiMainString = ""

res2@gsnDraw = False
res2@gsnFrame = False
res2@gsnMaximize = True

res2@lbLabelBarOn         = False              ; turn off indiv. label bars
res2@lbBoxLinesOn         = False
res2@cnInfoLabelOn       = False           ; turn off cn info label

res2@cnFillOn		  = True

res2@gsnAddCyclic = True
    
; WIND

res2@cnFillMode = "RasterFill"
;res2@cnSmoothingOn = True
;res2@cnRasterCellSizeF = 0.0005
res2@cnRasterSampleFactorF = 0.0

res2@gsnSpreadColors      = True              ; use full colormap

res2@cnLineLabelsOn       = False             ; turn off line labels
res2@cnLinesOn   = False		   				; turn off the contour lines

res2@lbLabelStride        = 4
res2@mpGreatCircleLinesOn=True

res2@tmXBOn=False
res2@tmXTOn=False
res2@tmYLOn=False
res2@tmYROn=False

res2@gsnAddCyclic = False

res2@gsnLeftString = ""
res2@gsnCenterString = ""
res2@gsnRightString = ""

res2@mpOutlineOn = True
res2@mpFillOn = False
res2@mpFillColors = (/"background","transparent","LightGray","transparent"/)
res2@mpGridAndLimbOn = False

if (variable .eq. "TMQ")
  gsn_define_colormap(wks,"MPL_gist_yarg")          ; choose colormap
  res2@gsnSpreadColors     = True	        ; use full colormap  
  res2@gsnSpreadColorStart  = -1                 ; start with last color
  res2@gsnSpreadColorEnd   = 2                   ; end with a beginning color
  res2@cnLevelSelectionMode = "ManualLevels"    ; set contour intervals
  res2@cnLevelSpacingF      =  1.                ;
  res2@cnMinLevelValF       =  5.0           ;
  res2@cnMaxLevelValF       =  72.0 ; Use 80.0 -> 60 for this
end if

if (variable .eq. "PRECT")
  var = where(var.le.11,var@_FillValue,var)
  gsn_define_colormap(wks,"rainradar")          ; choose colormap
  res2@cnLevelSelectionMode = "ManualLevels"
  res2@cnMinLevelValF       =  10.
  res2@cnMaxLevelValF       =  50.
  res2@cnLevelSpacingF      = 1.
  ;res2@gsnLeftString="Simulated radar reflectivity"
  ;res2@mpFillOn = True
  ;res2@mpOceanFillColor       = "lightblue1"
  ;res2@mpLandFillColor        = "wheat"
  ;res2@mpInlandWaterFillColor = "lightblue1"
end if

if(variable .eq. "FLUT")
  var = where(var.ge.250,var@_FillValue,var)
  gsn_define_colormap(wks,"irsat")        ; choose color map
  res2@cnLevelSelectionMode = "ManualLevels"
  res2@cnLevelSpacingF      =  1.0
  res2@cnMinLevelValF       =  125.0
  res2@cnMaxLevelValF       =  255.0
  res2@mpFillOn = True
  res2@mpOceanFillColor       = "black"
  res2@mpLandFillColor        = "darkgreen"
  res2@mpInlandWaterFillColor = "black"
end if

if (region .eq. "atlantic") then
  res2@mpMinLatF   = 0. 
  res2@mpMaxLatF   = 55.
  res2@mpMinLonF   = 255.
  res2@mpMaxLonF   = 345.
  res2@mpCenterLonF = (res2@mpMinLonF+res2@mpMaxLonF)/2.
end if

plot2 = gsn_csm_contour_map(wks,var,res2)
;plot2 = plot_outline_fcn(wks,plot2,"white",2.0)

;  

resP                     = True                ; modify the panel plot
;  resP@txString            = "A plot with a common label bar"
resP@gsnPanelLabelBar    = True                ; add common colorbar
resP@lbLabelFontHeightF  = 0.015               ; make labels smaller
resP@lbLabelStride    = 4

;  resP@gsnPanelFigureStrings= (/"Day 1","Day 4","Day 6","Day 8"/)
;  resP@amJust = "TopRight"

resP@pmLabelBarWidthF = 0.7
; resP@pmLabelBarHeightF

;gsn_panel(wks,plot2,(/2,1/),resP)
draw(plot2)
frame(wks)

delete(var)
delete(res2)
delete(resP)
delete(plot2)
	
;************************************************

end do

end

