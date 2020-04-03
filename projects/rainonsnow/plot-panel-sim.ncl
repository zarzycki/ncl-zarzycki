begin

diri = "/global/homes/c/czarzyck/scratch/e3sm_scratch/cori-knl/F-ne120np4-E3SM/run/1996011700/"
clmfili = systemfunc("ls "+diri+"/*.clm2.h0.*nc")
camfili = systemfunc("ls "+diri+"/*.cam.h0.*nc")
camfili := camfili(::2)

CLMFILES = addfiles(clmfili,"r") 
CAMFILES = addfiles(camfili,"r") 

printVarSummary(CLMFILES)
printVarSummary(CAMFILES)

time = CAMFILES[:]->time

lat1d  = CAMFILES[0]->lat
lon1d  = CAMFILES[0]->lon

;wgt_file="/global/homes/c/czarzyck/scratch/maps/forecast/map_ne120np4_to_1x1_bilinear.nc"
wgt_file="/global/homes/c/czarzyck/scratch/maps/forecast/ne120_to_0.25x0.25_patch.nc"

wks = gsn_open_wks("pdf","panel")              ; open a png file

do ii = 0,dimsizes(time)-1

  thistime = CAMFILES[ii]->time(0)

  prect := CAMFILES[ii]->PRECT
  prect = prect*86400000.
  prect@long_name="Total precipitation"
  prect@units="mm/day"
  tbot := CAMFILES[ii]->TBOT
  h2osno := CLMFILES[ii]->H2OSNO
  qrunoff  := CLMFILES[ii]->QOVER
  qrunoff=qrunoff*86400.
  qrunoff@units="mm/day"
  print(max(qrunoff))

  printVarSummary(qrunoff)

  Opt         = True
  prect := ESMF_regrid_with_weights(prect(0,:),wgt_file,Opt)
  tbot := ESMF_regrid_with_weights(tbot(0,:),wgt_file,Opt)
  h2osno := ESMF_regrid_with_weights(h2osno(0,:),wgt_file,Opt)
  qrunoff := ESMF_regrid_with_weights(qrunoff(0,:),wgt_file,Opt)



plot = new(4,graphic)                          ; create a plot array

res          = True
res@gsnDraw  = False                          ; don't draw
res@gsnFrame = False                          ; don't advance frame
res@cnInfoLabelOn = False                     ; turn off cn info label

res@cnFillOn            = True         ; Turn on contour fill
;res@cnFillMode          = "RasterFill"   ; Style of fill. You can also
                                       ; use "CellFill" and "RasterFill"
res@cnLinesOn           = False        ; Turn off contour lines
res@cnLineLabelsOn      = False        ; Turn off contour line labels

res@mpMinLatF             = 35.
res@mpMaxLatF             = 50.
res@mpMinLonF             = 270.
res@mpMaxLonF             = 290.

  res@mpOutlineOn           = True                ; turn on map outline
  res@mpOutlineBoundarySets = "USStates"          ; turn on state boundaries

res@cnLevelSelectionMode  = "ManualLevels"
res@cnMinLevelValF        = 20.
res@cnMaxLevelValF        = 300.
res@cnLevelSpacingF       = (res@cnMaxLevelValF - res@cnMinLevelValF) / 14.
res@cnFillPalette="precip2_17lev"

plot(0) = gsn_csm_contour_map(wks,prect,res)

res@cnLevelSelectionMode  = "ManualLevels"
res@cnMinLevelValF        = 250.
res@cnMaxLevelValF        = 295.
res@cnLevelSpacingF       = (res@cnMaxLevelValF - res@cnMinLevelValF) / 15.
res@cnFillPalette="temp1"

plot(1) = gsn_csm_contour_map(wks,tbot,res)

res@cnLevelSelectionMode  = "ManualLevels"
res@cnMinLevelValF        = 10.
res@cnMaxLevelValF        = 130.
res@cnLevelSpacingF       = (res@cnMaxLevelValF - res@cnMinLevelValF) / 12.
res@cnFillPalette="MPL_BuPu"

plot(2) = gsn_csm_contour_map(wks,h2osno,res)

res@cnLevelSelectionMode  = "ManualLevels"
res@cnMinLevelValF        = 5.
res@cnMaxLevelValF        = 65.
res@cnLevelSpacingF       = (res@cnMaxLevelValF - res@cnMinLevelValF) / 12.
res@cnFillPalette="WhViBlGrYeOrRe"

plot(3) = gsn_csm_contour_map(wks,qrunoff,res)

;************************************************
; create panel
;************************************************
  resP                    = True                 ; modify the panel plot
  resP@gsnPanelMainString = cd_calendar(thistime, -3)  
  gsn_panel(wks,plot,(/2,2/),resP)             ; now draw as one plot

end do



end
