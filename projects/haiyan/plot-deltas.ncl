
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
; ================================================;
begin

  plot_delta=False
  out_type="pdf"

  in = addfile("air.mon.ltm.nc","r")
  t  = in->air(10,{500.},::-1,:)
  t = t+273.

  dfile = addfile("/glade/u/home/zarzycki/work/apply-haiyan-perturb/delta_ta_cam5.1_ACE_v2.0_2013.nc","r")
  dt_nat = dfile->delta_ta(10,{50000.},:,:)

  printVarSummary(t)
  printVarSummary(dt_nat)
  dt = linint2_Wrap (dt_nat&lon,dt_nat&lat,dt_nat, True, t&lon,t&lat, 0)

  t2 = t
  t2 = t+dt

if (plot_delta)
  wks = gsn_open_wks(out_type,"deltaex_delta")      ; send graphics to PNG file

  plot = new(1,graphic)                          ; create a plot array

  res                       = True     ; plot mods desired
  res@gsnDraw=False
  res@gsnFrame=False

  res@cnFillOn              = True     ; turn on color fill
  res@cnInfoLabelOn       = False           ; turn off cn info label
  res@cnLinesOn             = False    ; turn of contour lines
  res@cnFillPalette         = "NCV_blu_red"
  res@lbLabelBarOn        = False           ; turn off individual cb's
  res@cnLineLabelsOn = False

  res@gsnLeftString=""
  res@gsnRightString=""

  res@gsnAddCyclic          = True

  res@cnLevelSelectionMode =  "ManualLevels"   
  res@cnMinLevelValF       = -2.0
  res@cnMaxLevelValF       = 2.0
  res@cnLevelSpacingF      =   0.2 
  
  plot(0) = gsn_csm_contour_map(wks,dt, res)

;************************************************
; create panel
;************************************************
  resP                     = True 
  resP@gsnPanelLabelBar    = True 

  gsn_panel(wks,plot,(/1,1/),resP)               ; now draw as one plot

else
;************************************************
; create plot
;************************************************
  wks = gsn_open_wks(out_type,"deltaex_full")      ; send graphics to PNG file

  plot = new(2,graphic)                          ; create a plot array

  res                       = True     ; plot mods desired
  res@gsnDraw=False
  res@gsnFrame=False

  res@cnFillOn              = True     ; turn on color fill
  res@cnInfoLabelOn       = False           ; turn off cn info label
  res@cnLinesOn             = False    ; turn of contour lines
  res@cnFillPalette         = "BlAqGrYeOrRe"
  res@lbLabelBarOn        = False           ; turn off individual cb's
  res@cnLineLabelsOn = False

  res@gsnLeftString=""
  res@gsnRightString=""

  res@gsnAddCyclic          = True

  res@cnLevelSelectionMode =  "ManualLevels"   
  res@cnMinLevelValF       = 235.
  res@cnMaxLevelValF       = 270.
  res@cnLevelSpacingF      =   2.5 
  
  plot(0) = gsn_csm_contour_map(wks,t, res)
  plot(1) = gsn_csm_contour_map(wks,t2, res)

;************************************************
; create panel
;************************************************
  resP                     = True                ; modify the panel plot
                                                 ; new resource added in NCL V6.4.0
  resP@gsnPanelLabelBar    = True                ; add common colorbar
  ;resP@lbLabelFontHeightF  = 0.007               ; make labels smaller

  gsn_panel(wks,plot,(/2,1/),resP)               ; now draw as one plot

end if

end
