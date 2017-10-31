load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin
;******************************************************
;  Open a netCDF file containing the grid and data from the HOMME
;  (High-Order Multiscale Modeling Environment) model, formerly
;  called SEAM (Spectral Element Atmosphere Model).
;******************************************************
  filename = "/glade/u/home/zarzycki/scratch/mpas120a-FC5-test/run/mpas120a-FC5-test.cam.h1.0001-01-31-00000.nc"
  f     = addfile(filename,"r")

  lat1d = ndtooned(f->lat)          ; Pull off lat/lon variable and
  lon1d = ndtooned(f->lon)          ; convert both to 1D.
  var  = ndtooned(f->TMQ(0,:))      ; Read some data; convert to 1D.

  ;print(lat1d)
;  pi=3.14159
;  r2d=180/pi

;  lat1d=lat1d*r2d
;  lon1d=lon1d*r2d

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

  map = gsn_csm_contour_map_ce(wks,var,res)

end
