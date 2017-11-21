;======================================================================
; ESMF_regrid_18.ncl
;
; Concepts illustrated:
;   - Interpolating from one grid to another using ESMF software
;   - Interpolating data from HOMME unstructured grid to a CAM finite volume grid
;======================================================================
; This example uses ESMF regridding software to regrid two variables 
; on a HOMME unstructured grid to a finite volume rectilinear grid 
; (96 x 144).
;======================================================================
; This script uses ESMF regridding functions that are only available in 
; NCL V6.1.0-beta and later.
;======================================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin
;---Names of source and weight file
    src_file = "camrun.cam.h0.0000-09-01-00000.nc"
    wgt_file = "/glade/u/home/zarzycki/mapping/gen_mapping_files/map_cyc_15_x8_TO_0.25x0.25_blin.130221.nc"

;---Open files containing source HOMME and destination FV grids
    sfile = addfile(src_file,"r")

;---Get two variables to regrid and the source lat/lon grid
    psl  = sfile->PS(:,:)            ; time (1) x ncol
    temp = sfile->T850(:,:)            ; time (1) x nlev x ncol

    Opt         = True
    psl_regrid  = ESMF_regrid_with_weights(psl,wgt_file,Opt)
    temp_regrid = ESMF_regrid_with_weights(temp,wgt_file,Opt)
    printVarSummary(psl_regrid)
    printVarSummary(temp_regrid)

;----------------------------------------------------------------------
; Plotting section
;
; This section creates filled contour plots of both the original
; data and the regridded data, and panels them.
;----------------------------------------------------------------------
    wks = gsn_open_wks("ps","ESMF_wgts")
    gsn_define_colormap(wks,"amwg")              ; Choose colormap

;---Resources to share between both plots
    res                      = True              ; Plot mods desired

    res@gsnDraw              = False
    res@gsnFrame             = False

    res@gsnMaximize          = True              ; Maximize plot

    res@cnFillOn             = True              ; color plot desired
    res@cnLinesOn            = False             ; turn off contour lines
    res@cnLineLabelsOn       = False             ; turn off contour labels

    res@lbLabelBarOn         = False      ; Will turn on in panel later

    res@mpFillOn             = False

    res@gsnAddCyclic = True

;---For titles and level selection
    dims_regrid = tostring(dimsizes(psl_regrid))
    plvl        = 500

;---Main title for regriddded data
    res@tiMainString = "FV grid (" + str_join(dims_regrid," x ") + ")"

;---For PSL
    res@cnLevelSelectionMode = "ManualLevels"
    res@cnMinLevelValF       =  97500
    res@cnMaxLevelValF       = 104000
    res@cnLevelSpacingF      =    500

    plot_psl_regrid  = gsn_csm_contour_map(wks,psl_regrid(120,:,:),res)

;---For TEMP
    res@cnLevelSelectionMode = "ManualLevels"
    res@cnMinLevelValF       = 262
    res@cnMaxLevelValF       = 290
    res@cnLevelSpacingF      =   2
    plot_temp_regrid = gsn_csm_contour_map(wks,temp_regrid(120,:,:),res)

;---Resources for plotting original data
    res@gsnAddCyclic = False
    res@sfXArray     = sfile->lon
    res@sfYArray     = sfile->lat
    res@tiMainString = "Original HOMME grid cells"

;---For PSL
    res@cnLevelSelectionMode = "ManualLevels"
    res@cnMinLevelValF       =  97500
    res@cnMaxLevelValF       = 104000
    res@cnLevelSpacingF      =    500

    plot_psl_orig = gsn_csm_contour_map(wks,psl(120,:),res)  

;---For TEMP
    res@cnLevelSelectionMode = "ManualLevels"
    res@cnMinLevelValF       = 262
    res@cnMaxLevelValF       = 290
    res@cnLevelSpacingF      =   2

    plot_temp_orig = gsn_csm_contour_map(wks,temp(120,:),res)  

;---Draw both sets plots in a panel
    pres                   = True
    pres@gsnMaximize       = True
    pres@gsnPanelLabelBar  = True

    gsn_panel(wks,(/plot_psl_orig,plot_psl_regrid/),(/2,1/),pres)
    gsn_panel(wks,(/plot_temp_orig,plot_temp_regrid/),(/2,1/),pres)
end

