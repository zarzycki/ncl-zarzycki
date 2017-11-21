load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin
;******************************************************
;  Open a netCDF file containing the grid and data from the HOMME
;  (High-Order Multiscale Modeling Environment) model, formerly
;  called SEAM (Spectral Element Atmosphere Model).
;******************************************************
  dir = "/glade/u/home/zarzycki/scratch/APE_levy/CAM5/quadrant_15_x8/"
  filename = "h0avg_regrid_0.25x0.25.nc"
  f     = addfile(dir+filename,"r")
  level = 850.
  
  ;h0avg_regrid_0.25x0.25.nc
  
  var1_name = "V"
  var2_name = "U"
  var12_name = "VU"
  
  var1  = f->$var1_name$(0,{level},:,:)
  var2  = f->$var2_name$(0,{level},:,:)
  var12 = f->$var12_name$(0,{level},:,:)
  
  eddy = var1
  eddy = var12 - var1*var2

   anom = eddy                                     ; trick to copy cv's and atts
   anom = dim_rmvmean(eddy)
   
;******************************************************
; create plot
;******************************************************
  wks = gsn_open_wks("x11","homme")               ; open workstation
  gsn_define_colormap(wks,"BlueWhiteOrangeRed")   ; choose colormap

  res                     = True         ; plot modifications desired
;  res@gsnMaximize         = True         ; Maximize size of plot in frame
  res@gsnSpreadColors     = True         ; Use full colormap, but start
  res@mpOutlineOn = False
  res@mpFillOn = False

  res@cnFillOn            = True         ; Turn on contour fill
;  res@cnFillMode          = "AreaFill"   ; Style of fill. You can also
                                         ; use "CellFill" and "RasterFill"
  res@cnLinesOn           = False        ; Turn off contour lines
  res@cnLineLabelsOn      = False        ; Turn off contour line labels

  ;res@cnLevelSelectionMode = "ManualLevels"
  if (var12_name .eq. "VV")
  res@cnLevelSpacingF      =  1.
  res@cnMinLevelValF       =  -10.
  res@cnMaxLevelValF       =  10.
  end if
  if (var12_name .eq. "VT")
  ;res@cnLevelSpacingF      =  1.
  ;res@cnMinLevelValF       =  -10.
  ;res@cnMaxLevelValF       =  10.
  end if

  
  res@lbLabelAutoStride   = True         ; Clean up labelbar labels.

  map = gsn_csm_contour_map_ce(wks,anom,res)

end
