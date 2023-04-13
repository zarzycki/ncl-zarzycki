begin

diri = "/global/homes/c/czarzyck/scratch/e3sm_scratch/cori-knl/F-ne120np4-E3SM-F2010C5/run/1996011600/"
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
wgt_file="/global/homes/c/czarzyck/scratch/maps/forecast/map_ne120_to_0.25x0.25_patch.nc"



do ii = 0,dimsizes(time)-1,2

  wks = gsn_open_wks("pdf","panel"+time(ii))              ; open a png file

  thistime = CAMFILES[:]->time(ii)

  prect := CAMFILES[:]->PRECT(ii,:)
  prect = prect*86400000.
  prect@long_name="Total precipitation"
  prect@units="mm/day"
  tbot := CAMFILES[:]->TBOT(ii,:)
  h2osno := CLMFILES[:]->H2OSNO(ii,:)
  qrunoff  := CLMFILES[:]->QOVER(ii,:)
  qrunoff=qrunoff*86400.
  qrunoff@units="mm/day"
  print(max(qrunoff))

  printVarSummary(qrunoff)

  Opt         = True
  prect := ESMF_regrid_with_weights(prect(:),wgt_file,Opt)
  tbot := ESMF_regrid_with_weights(tbot(:),wgt_file,Opt)
  h2osno := ESMF_regrid_with_weights(h2osno(:),wgt_file,Opt)
  qrunoff := ESMF_regrid_with_weights(qrunoff(:),wgt_file,Opt)



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
res@gsnCenterString=cd_calendar(thistime, -3)  

plot(3) = gsn_csm_contour_map(wks,qrunoff,res)

;************************************************
; create panel
;************************************************
  resP                    = True                 ; modify the panel plot
  ;resP@gsnPanelMainString = cd_calendar(thistime, -3)  
  gsn_panel(wks,plot,(/1,4/),resP)             ; now draw as one plot

frame(wks)

end do



end
