load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin
;******************************************************
;  Open a netCDF file containing the grid and data from the HOMME
;  (High-Order Multiscale Modeling Environment) model, formerly
;  called SEAM (Spectral Element Atmosphere Model).
;******************************************************
  dir = "/glade/u/home/zarzycki/scratch/APE_levy/CAM4/quadrant_15_x8/"
  dir = "/glade/u/home/zarzycki/scratch/APE_levy/CAM5/quadrant_15_x8/"
  filename = "h0avg.nc"
  f     = addfile(dir+filename,"r")
  level = 500.
  
  ;h0avg_regrid_0.25x0.25.nc
  
  lat1d = ndtooned(f->lat)          ; Pull off lat/lon variable and
  lon1d = ndtooned(f->lon)          ; convert both to 1D.
  var1  = ndtooned(f->V(0,{level},:)) 
  var2  = ndtooned(f->V(0,{level},:))
  var12 = ndtooned(f->VV(0,{level},:))
  
  eddy = var1
  eddy = var12 - var1*var2

;******************************************************
; create plot
;******************************************************
  wks = gsn_open_wks("x11","homme")               ; open workstation
  gsn_define_colormap(wks,"BlAqGrYeOrReVi200")   ; choose colormap

  res                     = True         ; plot modifications desired
;  res@gsnMaximize         = True         ; Maximize size of plot in frame
  res@gsnSpreadColors     = True         ; Use full colormap, but start

  res@sfXArray            = lon1d        ; Required to tell NCL where to
  res@sfYArray            = lat1d        ; overlay data on globe.

  res@cnFillOn            = True         ; Turn on contour fill
;  res@cnFillMode          = "AreaFill"   ; Style of fill. You can also
                                         ; use "CellFill" and "RasterFill"
  res@cnLinesOn           = False        ; Turn off contour lines
  res@cnLineLabelsOn      = False        ; Turn off contour line labels

  res@lbLabelAutoStride   = True         ; Clean up labelbar labels.

  map = gsn_csm_contour_map_ce(wks,eddy,res)

end
