;----------------------------------------------------------------------;
; This is an NCL/ESMF template file for regridding from an 
; unstructured SE/MPAS grid to a RLL grid. It uses ESMF_regrid
; to do the regridding.
;
; This script can be easily modified to do use something other than
; a 0.25 degree grid: "1x1", "G64", "5deg", etc.
;
; The unstructured grid is assumed to be contained in a NetCDF file. 
;----------------------------------------------------------------------
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin
;---Data file containing source grid
    ;src_file = "/glade/u/home/zarzycki/work/unigridFiles/natlantic_30_x4/topo/topo_natlantic_30_x4_smooth.nc"                    ;;---Change (likely)
    src_file = "/glade/p/cesmdata/inputdata/atm/cam/topo/USGS-gtopo30_ne120np4_16xdel2-PFC-consistentSGH.nc"                    ;;---Change (likely)
    sfile    = addfile(src_file,"r")

;---Get variable to regrid
    var_name = "PHIS"                      ;;---Change (likely)
    var      = sfile->$var_name$(:)        ;;---Change (likely)
    src_lat  = sfile->lat                  ;;---Change (maybe)
    src_lon  = sfile->lon                  ;;---Change (maybe)

;---Set up regridding options
    Opt                = True

;---"bilinear" is the default. "patch" and "conserve" are other options.
    Opt@InterpMethod     = "bilinear"        ;;---Change (maybe)
    Opt@WgtFileName      = "unstruct_to_rect.nc"

    Opt@SrcGridLat       = src_lat
    Opt@SrcGridLon       = src_lon
    Opt@SrcRegional      = False            ;;--Change (maybe)
    Opt@SrcInputFileName = src_file          ; optional, but good idea
    Opt@SrcMask2D        = where(.not.ismissing(var),1,0) ; Necessary if has
                                                          ; missing values.

    Opt@DstGridType      = "1.00deg"        ; destination grid
    Opt@DstTitle         = "World Grid 1.00 degree resolution"
    Opt@DstLLCorner      = (/-89.00d,   0.00d /)      ;;--Change (maybe)
    Opt@DstURCorner      = (/ 89.00d, 359.00d /)      ;;--Change (maybe)

    Opt@ForceOverwrite   = True
    Opt@Debug            = True
    Opt@PrintTimings     = True

    var_regrid = ESMF_regrid(var,Opt)     ; Do the regridding

    printVarSummary(var_regrid)
 
;----------------------------------------------------------------------
; Plotting section
;
; This section creates filled contour plots of both the original
; data and the regridded data, and panels them.
;----------------------------------------------------------------------
    wks = gsn_open_wks("x11","se_to_0.25deg")

;---Resources to share between both plots
    res                      = True              ; Plot mods desired

    res@gsnDraw              = False
    res@gsnFrame             = False

    res@gsnMaximize          = True              ; Maximize plot

    res@cnFillOn             = True              ; color plot desired
    res@cnLinesOn            = False             ; turn off contour lines
    res@cnLineLabelsOn       = False             ; turn off contour labels
    res@cnFillMode           = "RasterFill"      ; turn raster on      

;;--Change (maybe)
    mnmxint = nice_mnmxintvl( min(var), max(var), 18, False)
    res@cnLevelSelectionMode = "ManualLevels"
    res@cnMinLevelValF       = mnmxint(0)
    res@cnMaxLevelValF       = mnmxint(1)
    res@cnLevelSpacingF      = mnmxint(2)

    res@lbLabelBarOn         = False      ; Will turn on in panel later

    res@mpFillOn             = False

;---Resources for plotting regridded data
    res@gsnAddCyclic = False            ;;---Change (maybe)
    res@tiMainString  = "0.125 degree grid (" + Opt@InterpMethod + ")"

  res@mpMinLonF            =  60.               ; select a subregion
  res@mpMaxLonF            =  110.               ; select a subregion
  res@mpMinLatF            =  10.              ; select a subregion
  res@mpMaxLatF            =  45.               ; select a subregion

    plot_regrid = gsn_csm_contour_map(wks,var_regrid,res)
    
    printVarSummary(var_regrid)

    gsn_panel(wks,(/plot_regrid/),(/1,1/),False)
end
