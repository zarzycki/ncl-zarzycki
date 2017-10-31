; Inputs
; iniyear (1999)
; inimon (12)
; iniday (25)
; inisec (24000)
; filename

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin


do_regional=True

raw_file = addfile("/glade/u/home/zarzycki/work/tcforecast_paper/filter/unfiltered.nc","r")
fil_file = addfile("/glade/u/home/zarzycki/work/tcforecast_paper/filter/filtered.nc","r")

raw_var_se = raw_file->PSL({0.125},:)/100.
fil_var_se = fil_file->PSL(0,:)/100.

wgt_file = "/glade/p/work/zarzycki/maps/newgulf_30_x4/map_newgulf_30_x4_TO_0.25x0.25_patc.140508.nc"

Opt         = True
raw_var  = ESMF_regrid_with_weights(raw_var_se,wgt_file,Opt)
fil_var  = ESMF_regrid_with_weights(fil_var_se,wgt_file,Opt)

print("Begin interp")
guess     = 1                ; use zonal means
is_cyclic = True             ; cyclic [global]
nscan     = 500             ; usually much less than this
eps       = 1.e-2            ; variable dependent
relc      = 0.5              ; relaxation coefficient
opt       = 0                ; not used
poisson_grid_fill( raw_var, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( fil_var, is_cyclic, guess, nscan, eps, relc, opt)

if(do_regional) then
maxlat = 65.           ; choose subregion           
minlat = -35.
minlon = -170. 
maxlon = 30.
end if

;prect_sub = prect(0,{minlat:maxlat},{minlon:maxlon})
;precc_sub = precc(0,{minlat:maxlat},{minlon:maxlon})
;precl_sub = precl(0,{minlat:maxlat},{minlon:maxlon})

contour = new(2,"graphic")

wks = gsn_open_wks("pdf","pdf/filtered_panel")           ; open a ps file
;gsn_define_colormap(wks,"3gauss")
gsn_define_colormap(wks,"MPL_gnuplot2")


res                   = True
res@gsnDraw = False
res@gsnFrame = False

res@cnFillOn          = True              ; color plot desired
res@cnLineLabelsOn    = False             ; turn off contour lines

res@gsnAddCyclic = False

res@gsnSpreadColors     = True            ; use full range of color map

if(do_regional) then
res@mpMaxLatF                   = maxlat           ; choose subregion
res@mpMinLatF                   = minlat
res@mpMinLonF = minlon
res@mpMaxLonF = maxlon
end if

res@cnLevelSelectionMode = "ManualLevels"    ; set contour intervals
res@cnLevelSpacingF      =    0.5
res@cnMinLevelValF       =     980.0
res@cnMaxLevelValF       =  1020.0

res@cnFillMode = "RasterFill"
res@cnLinesOn = False

res@lbLabelBarOn = False

res@gsnStringFontHeightF=0.018
res@gsnRightString="hPa"
res@gsnLeftString="Sea level pressure"
contour(0) = gsn_csm_contour_map(wks,raw_var,res)  ; create the plot
res@gsnLeftString=""
res@gsnRightString=""
contour(1) = gsn_csm_contour_map(wks,fil_var,res)  ; create the plot

pres = True
pres@gsnPanelLabelBar = True

pres@amJust           = "TopLeft"
pres@gsnPanelFigureStringsFontHeightF = 0.024
pres@gsnPanelFigureStrings= (/"a.) Raw","b.) Filtered"/)
;pres@lbLabelStride = toint((res@cnMaxLevelValF-res@cnMinLevelValF)/res@cnLevelSpacingF)
pres@lbLabelStride = 10
pres@lbBoxSeparatorLinesOn = False
pres@lbLabelFontHeightF = 0.018

gsn_panel(wks,contour,(/2,1/),pres)             ; now draw as one plot


end
