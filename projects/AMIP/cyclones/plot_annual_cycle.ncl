;========================================================
; AMIP Histogram by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "/glade/u/home/zarzycki/ncl/functions/mask_tc.ncl"
;========================================================
begin

;********************************************************
; create the data
;********************************************************  
  out_type = "pdf"
  scaled = True
  scalingFactor = 1.05
  do_1deg = True

  monthArray = ispan(1,12,1)
  ;y0 = (/10.5,9.6,7.7/)
  ;y1 = (/10.1,9.9,8.7/)
  basin = 1
  
  ; Obs, V-R, Coarse
  markerStyles = (/4,6,9/)
  dashPatterns = (/0,16,15/)
  lineColors = (/"blue","red","springgreen4"/)
  
  file_storms = "stats/stats_tcs_by_month_storms_vr.txt"
  file_hurr = "stats/stats_tcs_by_month_hurr_vr.txt"
  file_majhurr = "stats/stats_tcs_by_month_majhurr_vr.txt"
  
  storms = asciiread(file_storms,-1,"integer")
  hurr = asciiread(file_hurr,-1,"integer")
  majhurr = asciiread(file_majhurr,-1,"integer")
  
  model1d_storms = storms(0:107)/23.
  obs1d_storms = storms(108:215)/23.
  model1d_hurr = hurr(0:107)/23.
  obs1d_hurr = hurr(108:215)/23.
  model1d_majhurr = majhurr(0:107)/23.
  obs1d_majhurr = majhurr(108:215)/23.
  
  model_all_storms = reshape(model1d_storms,(/12,9/))
  obs_all_storms = reshape(obs1d_storms,(/12,9/))
  model_all_hurr = reshape(model1d_hurr,(/12,9/))
  obs_all_hurr = reshape(obs1d_hurr,(/12,9/))
  model_all_majhurr = reshape(model1d_majhurr,(/12,9/))
  obs_all_majhurr = reshape(obs1d_majhurr,(/12,9/))
  
  obs_storms= obs_all_storms(:,basin-1)
  model_storms = model_all_storms(:,basin-1)
  obs_hurr= obs_all_hurr(:,basin-1)
  model_hurr = model_all_hurr(:,basin-1)
  obs_majhurr= obs_all_majhurr(:,basin-1)
  model_majhurr = model_all_majhurr(:,basin-1)

if do_1deg then
  file_storms_1deg = "stats/stats_tcs_by_month_storms_1deg.txt"
  file_hurr_1deg = "stats/stats_tcs_by_month_hurr_1deg.txt"
  file_majhurr_1deg = "stats/stats_tcs_by_month_majhurr_1deg.txt"
  storms1deg = asciiread(file_storms_1deg,-1,"integer")
  hurr1deg = asciiread(file_hurr_1deg,-1,"integer")
  majhurr1deg = asciiread(file_majhurr_1deg,-1,"integer")
  model1d_storms_1deg = storms1deg(0:107)/23.
  model1d_hurr_1deg = hurr1deg(0:107)/23.
  model1d_majhurr_1deg = majhurr1deg(0:107)/23.
  model_all_storms_1deg = reshape(model1d_storms_1deg,(/12,9/))
  model_all_hurr_1deg = reshape(model1d_hurr_1deg,(/12,9/))
  model_all_majhurr_1deg = reshape(model1d_majhurr_1deg,(/12,9/))
  model_storms_1deg = model_all_storms_1deg(:,basin-1)
  model_hurr_1deg = model_all_hurr_1deg(:,basin-1)
  model_majhurr_1deg = model_all_majhurr_1deg(:,basin-1)
end if
  
  
  
;===================================================================
  wks = gsn_open_wks(out_type,"montimseries")
  plot = new(6,graphic)                          ; create a plot array

  res               = True 
  res@gsnDraw = False
  res@gsnFrame              = False                ; don't advance frame yet
  res@tiMainString  = "Annual Atlantic TC Count"        ; title

  res@tiXAxisString = "Month"    ; y axis title
  res@trXMinF = 1
  res@trXMaxF = 12
  
  ; Initialize some defaults
  res@xyMarkerSizeF = 0.025
  res@xyMarkerColor = "Black"
  res@xyLineThicknessF = 3.5
  
  ; Control title/label heights
  res@tiMainFontHeightF  = 0.04                    ; change font heights
  res@tiXAxisFontHeightF = 0.032
  res@tiYAxisFontHeightF = 0.032
  res@tmXBLabelFontHeightF = 0.028
  res@tmYLLabelFontHeightF = res@tmXBLabelFontHeightF
  res@tmYRLabelFontHeightF = res@tmXBLabelFontHeightF
  
  ; Set L/R color seperation for top panels
  res@tmYLLabelFontColor = lineColors(0)
  res@tmYRLabelFontColor = lineColors(1)
  res@tiYAxisFontColor = lineColors(0)

  ; Obs resources top panels
  res@xyLineColor  = lineColors(0)
  res@xyMarkerColor = res@xyLineColor
  res@xyDashPattern = dashPatterns(0)
  res@xyMarkLineMode = "MarkLines"
  res@xyMarker     = markerStyles(0)
  res@trYMinF = 0
  
  ; V-R CAM resources top panels
  res2 = res
  res2@xyLineColor = lineColors(1)
  res2@xyMarkerColor = res2@xyLineColor
  res2@xyDashPattern = dashPatterns(1)
  res2@xyMarkLineMode = "MarkLines"
  res2@xyMarker     = markerStyles(1)
  res2@tiYAxisFontColor = lineColors(1)
  
  res@tiYAxisString = "Obs (# per year)"     ; y axis title
  res2@tiYAxisString = "V-R CAM-SE (# per year)"     ; y axis title
  
  res@trYMaxF = max(obs_storms)*scalingFactor
  res@tiMainString  = "Tropical Cyclones"        ; title
  if (scaled) then
    res2@trYMaxF = max(model_storms)*scalingFactor
  else
    res2@trYMaxF = max(obs_storms)*scalingFactor
  end if
  plot(0) = gsn_csm_xy2(wks,monthArray,obs_storms,model_storms,res,res2)
  
  
  res@trYMaxF = max(obs_hurr)*scalingFactor
  res@tiMainString  = "Hurricanes"        ; title

  if (scaled) then
    res2@trYMaxF = max(model_hurr)*scalingFactor
  else
    res2@trYMaxF = max(obs_hurr)*scalingFactor
  end if
  plot(1) = gsn_csm_xy2(wks,monthArray,obs_hurr,model_hurr,res,res2)
  
  
  res@trYMaxF = max(obs_majhurr)*scalingFactor
  res@tiMainString  = "Major Hurricanes"        ; title
  if (scaled) then
    res2@trYMaxF = max(model_majhurr)*scalingFactor
  else
    res2@trYMaxF = max(obs_majhurr)*scalingFactor
  end if
  plot(2) = gsn_csm_xy2(wks,monthArray,obs_majhurr,model_majhurr,res,res2)

  ; Change all labels back to black since we are not doing seperate
  ; L/R labels as in the top panels
  res@tmYLLabelFontColor = "Black"
  res@tmYRLabelFontColor = "Black"
  res@tiYAxisFontColor = "Black"
  
  res3 = res
  res3@xyLineColor      =lineColors(2)
  res3@xyDashPattern = dashPatterns(2)
  res3@xyMarkLineMode = "MarkLines"
  res3@xyMarker     = 16
  res3@xyMarkerColor = res3@xyLineColor
  res3@xyMarker     = markerStyles(2)
  res3@tiMainString  = "Tropical Cyclones"
  res3@tiYAxisString = "(# per year)"     ; y axis title
  res3@trYMaxF = max(obs_storms)*scalingFactor
  plot1 = gsn_csm_xy(wks,monthArray,model_storms_1deg,res3)
  

  res3@xyLineColor      =lineColors(1)
  res3@xyMarker     = markerStyles(1)
  res3@xyMarkerColor = res3@xyLineColor
  res3@xyDashPattern = dashPatterns(1)
  plot2 = gsn_csm_xy(wks,monthArray,model_storms,res3)
  overlay(plot1,plot2)
  delete(plot2)
  
  res3@xyLineColor      =lineColors(0)
  res3@xyMarkerColor = res3@xyLineColor
  res3@xyMarker     = markerStyles(0)
  res3@xyDashPattern = dashPatterns(0)
  plot2 = gsn_csm_xy(wks,monthArray,obs_storms,res3)
  overlay(plot1,plot2)
  
  plot(3) = plot1
  delete(plot1)
  
  
  res3@tiMainString  = "Hurricanes"
  res3@xyLineColor      =lineColors(2)
  res3@xyMarkerColor = res3@xyLineColor
  res3@xyMarker     = markerStyles(2)
    res3@xyDashPattern = dashPatterns(2)
  res3@trYMaxF = max(obs_hurr)*scalingFactor
  plot1 = gsn_csm_xy(wks,monthArray,model_hurr_1deg,res3)
  
  res3@xyLineColor      =lineColors(1)
  res3@xyMarkerColor = res3@xyLineColor
  res3@xyMarker     = markerStyles(1)
    res3@xyDashPattern = dashPatterns(1)
  plot2 = gsn_csm_xy(wks,monthArray,model_hurr,res3)
  overlay(plot1,plot2)
  delete(plot2)
  
  res3@xyLineColor      =lineColors(0)
  res3@xyMarkerColor = res3@xyLineColor
  res3@xyMarker     = markerStyles(0)
    res3@xyDashPattern = dashPatterns(0)
  plot2 = gsn_csm_xy(wks,monthArray,obs_hurr,res3)
  overlay(plot1,plot2)
  
  plot(4) = plot1
  delete(plot1)
  

  res3@tiMainString  = "Major Hurricanes"
  res3@xyDashPattern = dashPatterns(2)
  res3@xyLineColor      =lineColors(2)
  res3@xyMarkerColor = res3@xyLineColor
  res3@xyMarker     = markerStyles(2)
  res3@trYMaxF = max(obs_majhurr)*scalingFactor
  plot1 = gsn_csm_xy(wks,monthArray,model_majhurr_1deg,res3)
  
  res3@xyLineColor      =lineColors(1)
  res3@xyMarkerColor = res3@xyLineColor
  res3@xyMarker     = markerStyles(1)
    res3@xyDashPattern = dashPatterns(1)
  plot2 = gsn_csm_xy(wks,monthArray,model_majhurr,res3)
  overlay(plot1,plot2)
  delete(plot2)
  
  res3@xyLineColor      =lineColors(0)
  res3@xyMarkerColor = res3@xyLineColor
  res3@xyMarker     = markerStyles(0)
    res3@xyDashPattern = dashPatterns(0)
  plot2 = gsn_csm_xy(wks,monthArray,obs_majhurr,res3)
  overlay(plot1,plot2)
  
  plot(5) = plot1
  delete(plot1)




   legend = create "Legend" legendClass wks 
     "vpXF" : 0.38 ; positive is to right
     "vpYF" : 0.28 ; positive is up
     "vpWidthF" : 0.2 
     "vpHeightF" : 0.08
     "lgAutoManage" : False
     ;"lgPerimOn" : False 
     ;"lgItemCount" : 3 
     ;"lgLabelStrings" : (/"CAM-SE 1 deg", "CAM-SE VR", "Obs"/) 
     ;"lgMonoDashIndex" : True ; Only one dash pattern - solid 
     ;"lgLineColors" : (/"darkgreen","red","blue"/) 
     ;"lgMonoLineLabelFontColor" : True ; Only one label color - black 
     ;"lgLabelPosition" : "Center"
     ;"lgAutoManage" : False ; to control the label font height directly 
     "lgLabelJust" : "CenterLeft" 
     
      "lgItemCount" : 3
    "lgMonoItemType" : True
    "lgItemType" : (/"MarkLines"/)
    "lgLabelStrings" : (/"CAM-SE 1~S~o~N~", "CAM-SE V-R", "Obs (IBTrACS)"/) 
    "lgLineColors" : lineColors(::-1)
    "lgMarkerColors" : lineColors(::-1)
    "lgMarkerIndexes" : markerStyles(::-1)         ; marker indexes
    "lgMarkerSizeF" : 12.0
    "lgDashIndexes" : dashPatterns(::-1)
    "lgLabelFontHeightF" : 0.011
    "lgLineThicknessF" : 4.0
    ;"lgMonoDashIndex" : True ; Only one dash pattern - solid 
   end create 
   draw(legend)


  resP = True
  resP@gsnPanelXWhiteSpacePercent = 3.
  resP@gsnPanelYWhiteSpacePercent = 6.
  resP@amJust           = "TopLeft"
  resP@gsnPanelFigureStrings= (/"a.","b.","c.","d.","e.","f."/)
  resP@gsnPanelFigureStringsFontHeightF = 0.018
  resP@gsnPanelBottom = 0.18 ; Leave room for legend at the bottom. 
  gsn_panel(wks,plot,(/2,3/),resP)             ; now draw as one plot
  


  delete(res)
  delete(res2)
  
  
   
end
