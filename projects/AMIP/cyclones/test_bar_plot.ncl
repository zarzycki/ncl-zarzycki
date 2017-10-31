;========================================================
; AMIP Histogram by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "/glade/u/home/zarzycki/ncl/functions/mask_tc.ncl"
;load "/glade/u/home/zarzycki/ncl/functions/calc_area.ncl"
;========================================================
begin

;********************************************************
; create the data
;********************************************************  
  out_type = "pdf"

  x = (/1,2,3/)
  ;y0 = (/10.5,9.6,7.7/)
  ;y1 = (/10.1,9.9,8.7/)
  
  file_storms = "enso_bar_storms.txt"
  file_hurr = "enso_bar_hurr.txt"
  
  storms = asciiread(file_storms,(/2,3/),"float")
  hurr = asciiread(file_hurr,(/2,3/),"float")
  ; 0 index = model
  ; 1 index = obs

  print(storms)
  print(hurr)
  
  labels = (/"El Nino","Neutral","La Nina"/)
;********************************************************
; create the plot
;********************************************************   
  wks = gsn_open_wks(out_type,"enso_bar")                  ; open ps file
  plot = new(4,graphic)                          ; create a plot array

  barres                       = True                 ; plot mods desired  
  ;barres@gsn
  barres@gsnDraw = False
  barres@gsnFrame              = False                ; don't advance frame yet
  barres@gsnXYBarChart         = True                 ; turn on bar chart
  ;barres@gsnXYBarChartBarWidth = 0.75                 ; change bar widths
  barres@gsnXYBarChartColors = (/"blue","purple","red"/)            ; choose colors
  
  barres@tiMainFontHeightF  = 0.038                    ; change font heights
  barres@tiXAxisFontHeightF = 0.032
  barres@tiYAxisFontHeightF = 0.032
  barres@tmXBLabelFontHeightF = 0.03
  
  barres@tmXBOn                = False                ; turn off tickmarks at bot
  barres@tmXTOn                = False                ; turn off tickmarks at bot
  barres@trYMinF               = 0                    ; bring bars down to zero
  ;barres@trXMinF               = 0                    ; adds space on either end
  ;barres@trXMaxF               = 9                    ; of the 1st and last bars

  barres@trYMinF               = 0
  barres@trYMaxF               = 13
  barres@tiMainString          = "VAR-RES CAM-SE"
  barres@tiYAxisString = "ALL STORMS"
  plot(0) = gsn_csm_xy (wks,x,storms(0,:),barres)                  ; create plot
  barres@tiMainString          = "OBSERVATIONS"
  barres@tiYAxisString = ""
  plot(1) = gsn_csm_xy (wks,x,storms(1,:),barres)                  ; create plot
  
  barres@trYMinF               = 0
  barres@trYMaxF               = 8
  barres@tiMainString          = ""
  barres@tiYAxisString = "HURRICANES"
  plot(2) = gsn_csm_xy (wks,x,hurr(0,:),barres)                  ; create plot
  barres@tiMainString          = ""
  barres@tiYAxisString = ""
  plot(3) = gsn_csm_xy (wks,x,hurr(1,:),barres)                  ; create plot
  
  pnlres = True 
  pnlres@gsnFrame = False 
  pnlres@gsnPanelBottom = 0.18 ; Leave room for legend at the bottom. 
  
  pnlres@amJust           = "TopLeft"
  pnlres@gsnPanelFigureStrings= (/"a.","b.","c.","d."/)
  pnlres@gsnPanelFigureStringsFontHeightF = 0.02
  
  gsn_panel(wks,plot,(/2,2/),pnlres)             ; now draw as one plot
;   
;   legend = create "Legend" legendClass wks 
;     "vpXF" : 0.26 
;     "vpYF" : 0.17 
;     "vpWidthF" : 0.5 
;     "vpHeightF" : 0.15 
;     "lgPerimOn" : False 
;     "lgItemCount" : 3 
;     "lgLineLabelStrings" : (/"y1", "y2", "y3"/) 
;     "lgLabelsOn" : False 
;     "lgMonoDashIndex" : True ; Only one dash pattern - solid 
;     "lgLineColors" : (/"red","green","blue"/) 
;     "lgMonoLineLabelFontColor" : True ; Only one label color - black 
;   end create 
;   draw(legend)

  nboxes = dimsizes(barres@gsnXYBarChartColors)
   
  lbres                    = True          ; labelbar only resources
  lbres@vpWidthF           = 0.4     ; labelbar width
  lbres@vpHeightF          = 0.15     ; labelbar height
  lbres@lbBoxMajorExtentF  = 0.75          ; puts space between color boxes
  lbres@lbOrientation        = "Horizontal"        ; orientation
  lbres@lbFillColors       = barres@gsnXYBarChartColors ; labelbar colors
  lbres@lbMonoFillPattern  = True          ; Solid fill pattern
  lbres@lbLabelFontHeightF = 0.020          ; font height. default is small
  ;lbres@lbLabelJust        = "CenterCenter"  ; left justify labels
   
  gsn_labelbar_ndc(wks,nboxes,labels,0.30,0.17,lbres)
  
  frame(wks) 
   
end
