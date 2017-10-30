load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin
;******************************************************
;  Open a netCDF file containing the grid and data from the HOMME
;  (High-Order Multiscale Modeling Environment) model, formerly
;  called SEAM (Spectral Element Atmosphere Model).
;******************************************************
  filename = "/glade/scratch/zarzycki/archive/ecsnow30x4_AMIP/atm/hist/ecsnow30x4_AMIP.cam.h5.2000-01-24-00000.nc"
  f     = addfile(filename,"r")

  lat1d = ndtooned(f->lat)          ; Pull off lat/lon variable and
  lon1d = ndtooned(f->lon)          ; convert both to 1D.
  var  = ndtooned(f->PTYPE(2,:))      ; Read some data; convert to 1D.

;******************************************************
; create plot
;******************************************************
  wks = gsn_open_wks("pdf","sample_ptype")               ; open workstation
  gsn_define_colormap(wks,"BlAqGrYeOrReVi200")   ; choose colormap

  res                     = True         ; plot modifications desired
;  res@gsnMaximize         = True         ; Maximize size of plot in frame
  res@gsnSpreadColors     = True         ; Use full colormap, but start

  res@sfXArray            = lon1d        ; Required to tell NCL where to
  res@sfYArray            = lat1d        ; overlay data on globe.

  res@cnFillOn            = True         ; Turn on contour fill
;  res@cnFillMode          = "AreaFill"   ; Style of fill. You can also
                                         ; use "CellFill" and "RasterFill"
  res@mpMinLatF=20.
  res@mpMaxLatF=60.
  res@mpMinLonF=230.
  res@mpMaxLonF=290.


  ;res@cnLinesOn           = False        ; Turn off contour lines
  res@cnLineLabelsOn      = False        ; Turn off contour line labels

  res@cnLevelSelectionMode = "ExplicitLevels"   ; set explicit contour levels
  res@cnLevels    = (/ 0.5,1.5,2.5,3.5/)   ; set levels
  res@cnFillColors = (/ "lightblue","paleturquoise","palegreen","yellow","red"/)  ; set the colors to be used


  res@lbLabelAutoStride   = True         ; Clean up labelbar labels.

  map = gsn_csm_contour_map_ce(wks,var,res)

end
