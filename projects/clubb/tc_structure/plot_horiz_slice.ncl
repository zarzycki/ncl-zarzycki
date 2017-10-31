load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin
;******************************************************
;  Open a netCDF file containing the grid and data from the HOMME
;  (High-Order Multiscale Modeling Environment) model, formerly
;  called SEAM (Spectral Element Atmosphere Model).
;******************************************************
  whatVar="PRECT"

  f     = addfile("/glade/scratch/patc/archive/f.e15b2.FAMPIC5.ne120_ne120.Club_Test.006/atm/hist/f.e15b2.FAMPIC5.ne120_ne120.Club_Test.006.cam.h3.2004-09-09-21600.nc","r")
  time=f->time
  opt=0
  opt@calendar=time@calendar
  thisDate=cd_inv_calendar(2004,9,11,18,0,0,time@units,opt)
  stormLat0=23.2488
  stormLon0=301.707
  var0  = ndtooned(f->$whatVar$({thisDate},:))      ; Read some data; convert to 1D.

  f     = addfile("/glade/p/cesm/amwg/runs/FAMIPC5_ne120_79to05_03_omp2/atm/hist/FAMIPC5_ne120_79to05_03_omp2.cam.h4.1991-07-18-64800.nc","r")
  time=f->time
  opt=0
  opt@calendar=time@calendar
  thisDate=cd_inv_calendar(1991,7,21,18,0,0,time@units,opt)
  stormLat1=29.1589
  stormLon1=142.707
  var1  = ndtooned(f->$whatVar$({thisDate},:))      ; Read some data; convert to 1D.
;88.0667 1991 7 21 18    29.1589 142.707

  deltaDeg=8.

  lat1d = ndtooned(f->lat)          ; Pull off lat/lon variable and
  lon1d = ndtooned(f->lon)          ; convert both to 1D.


;******************************************************
; create plot
;******************************************************
  wks = gsn_open_wks("pdf","horiz_slice_"+whatVar) 
  map = new(2,graphic)

  res                     = True         ; plot modifications desired
  res@gsnDraw=False
  res@gsnFrame=False


  res@sfXArray            = lon1d        ; Required to tell NCL where to
  res@sfYArray            = lat1d        ; overlay data on globe.

  res@cnFillOn            = True         ; Turn on contour fill
  res@cnLinesOn           = False        ; Turn off contour lines
  res@cnLineLabelsOn      = False        ; Turn off contour line labels

  res@lbLabelAutoStride   = True         ; Clean up labelbar labels.

  if (whatVar .eq. "PRECT") then
    var0 = var0*8.64E+7/24
    var1 = var1*8.64E+7/24
    cmap = read_colormap_file("radar_1")
    print(cmap)
    res@cnFillPalette = cmap(7:23,:)   ; subset color map
    res@cnLevelSelectionMode = "ExplicitLevels"
    res@cnLevels    = (/0.15,0.3,0.5,1.0,2.0,5.0,10.0,15.0,20.0,25.0,30.0,40.0,50.0/)
    unitsStr="mm hr~S~-1"
  end if

  if (whatVar .eq. "OMEGA500") then
    res@cnLevelSelectionMode =  "ManualLevels"
    res@cnMinLevelValF       = -15.
    res@cnMaxLevelValF       = 15.
    res@cnLevelSpacingF      = 1.5
  end if

  res@mpMinLatF=stormLat0-deltaDeg
  res@mpMaxLatF=stormLat0+deltaDeg
  res@mpMinLonF=stormLon0-deltaDeg
  res@mpMaxLonF=stormLon0+deltaDeg

  map(1) = gsn_csm_contour_map_ce(wks,var0,res)

  res@mpMinLatF=stormLat1-deltaDeg
  res@mpMaxLatF=stormLat1+deltaDeg
  res@mpMinLonF=stormLon1-deltaDeg
  res@mpMaxLonF=stormLon1+deltaDeg
  map(0) = gsn_csm_contour_map_ce(wks,var1,res)

  resP                    = True
resP@gsnPanelFigureStringsFontHeightF = 0.02
  resP@gsnPanelFigureStrings= (/"CAM5","CAM5.5"/)
;  resP@gsnPanelMainString = "A common title"     ; new resource added in NCL V6.4.0
; resP@txString           = "A common title"     ; use this for NCL V6.3.0 and earlier
  gsn_panel(wks,map,(/1,2/),resP)               ; now draw as one plot

end
