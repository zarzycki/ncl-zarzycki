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
  out_type = "x11"

  whatkind = "storms" ; storms, hurr, majhurr
  do_1deg = True
  styr = 1980
  enyr = 2002
  numyrs = enyr - styr + 1
  yearArray = ispan(styr,enyr,1)
  basin = 1
  lineColors = (/"blue","red","springgreen4"/)
  markerStyles = (/4,6,9/)
  dashPatterns = (/0,16,15/)
  
  file_storms = "stats/stats_tcs_by_year_"+whatkind+"_vr.txt"
  file_storms_1deg = "stats/stats_tcs_by_year_"+whatkind+"_1deg.txt"
  
  storms = asciiread(file_storms,-1,"integer")

  model1d_storms = storms(0:206)
  obs1d_storms = storms(207:413)

  model_all_storms = reshape(model1d_storms,(/numyrs,9/))
  obs_all_storms = reshape(obs1d_storms,(/numyrs,9/))
 
  model_storms = model_all_storms(:,basin-1)
  obs_storms = obs_all_storms(:,basin-1)
  
  model_storms_sd = dim_stddev_Wrap(model_storms)
  obs_storms_sd = dim_stddev_Wrap(obs_storms)
  
if do_1deg then
  storms1deg = asciiread(file_storms_1deg,-1,"integer")
  
  model1d_storms_1deg = storms1deg(0:206)
  obs1d_storms_1deg= storms1deg(207:413)

  model_all_storms_1deg = reshape(model1d_storms_1deg,(/numyrs,9/))
  obs_all_storms_1deg = reshape(obs1d_storms_1deg,(/numyrs,9/))

  model_storms_1deg = model_all_storms_1deg(:,basin-1)
  obs_storms_1deg = obs_all_storms_1deg(:,basin-1)
  
  model_storms_1deg_sd = dim_stddev_Wrap(model_storms_1deg)
 
end if


;obs_storms(1996-1980) = obs_storms@_FillValue
;obs_storms(1997-1980) = obs_storms@_FillValue
;obs_storms(1998-1980) = obs_storms@_FillValue
;model_storms(1996-1980) = model_storms@_FillValue
;model_storms(1997-1980) = model_storms@_FillValue
;model_storms(1998-1980) = model_storms@_FillValue

obs_storms_dt = dtrend(obs_storms,False)
model_storms_dt = dtrend(model_storms,False)
model_storms_1deg_dt = dtrend(model_storms_1deg,False)

;obs_storms_dt = obs_storms
;model_storms_dt = model_storms


startcorr = 1980
endcorr = 2002
ccr = escorc(obs_storms_dt(startcorr-styr:endcorr-styr),obs_storms_dt(startcorr-styr:endcorr-styr))   ; ccr is a scalar
print("CCR between obs and obs is "+ccr)
ccr = escorc(obs_storms_dt(startcorr-styr:endcorr-styr),model_storms_dt(startcorr-styr:endcorr-styr))   ; ccr is a scalar
print("CCR between obs and VR CAM-SE is "+ccr)
ccr = escorc(obs_storms_dt(startcorr-styr:endcorr-styr),model_storms_1deg_dt(startcorr-styr:endcorr-styr))   ; ccr is a scalar
print("CCR between obs and 1deg CAM-SE is "+ccr)
ccr = escorc(model_storms_1deg_dt(startcorr-styr:endcorr-styr),model_storms_dt(startcorr-styr:endcorr-styr))   ; ccr is a scalar
print("CCR between 1deg CAM-SE and VR CAM-SE is "+ccr)
  
  wks = gsn_open_wks(out_type,"yeartimeseries_"+whatkind)

  res               = True 
  res@gsnDraw          = False
  res@gsnFrame         = False
  res@gsnMaximize   = True
  res@tiMainString  = ""        ; title
  
  if (whatkind .eq. "storms") then
    res@tiYAxisString = "TCs per year"     ; y axis title
  else if (whatkind .eq. "hurr") then
    res@tiYAxisString = "Hurricanes per year"     ; y axis title
  else if (whatkind .eq. "majhurr") then
    res@tiYAxisString = "Maj. Hurr per year"     ; y axis title
  else
  end if
  end if
  end if
  
  ;res@tiXAxisString = "Year"    ; y axis title
  res@trXMinF = styr
  
  res@vpHeightF = .3
  res@vpWidthF = .6

  res@trXMaxF = enyr

  res@xyLineThicknessF = 7.0
  
  res@trYMinF = 0
  res@trYMaxF = max(obs_storms) + 2
  
  res@tmXTOn = False
  res@tmYROn = False

  res@xyMarkLineMode = "MarkLines"
    res@xyMarkerSizeF = 0.010
  
  res@xyDashPattern = dashPatterns(0)
  res@xyLineColor      =lineColors(0)
  res@xyMarkerColor = lineColors(0)
  res@xyMarker     = markerStyles(0)
  plot0 = gsn_csm_xy(wks,yearArray,obs_storms(startcorr-styr:endcorr-styr),res)

  res@xyDashPattern = dashPatterns(1)
  res@xyLineColor     =lineColors(1)
  res@xyMarkerColor = lineColors(1)
  res@xyMarker     = markerStyles(1)
  plot1 = gsn_csm_xy(wks,yearArray,model_storms(startcorr-styr:endcorr-styr),res)

  res@xyDashPattern = dashPatterns(2)
  res@xyLineColor   =lineColors(2)
  res@xyMarkerColor = lineColors(2)
  res@xyMarker     = markerStyles(2)
  plot2 = gsn_csm_xy(wks,yearArray,model_storms_1deg(startcorr-styr:endcorr-styr),res)

  overlay(plot0,plot1)
  overlay(plot0,plot2)
  
  ; ====== ERROR BARS
  polyres                   = True                       ; marker resources
  polyres@gsMarkerIndex     = 1                          ; index for circle
  polyres@gsMarkerSizeF     = .1                        ; size 
  polyres@gsLineThicknessF = 7.0
  polyres@gsLineColor = "grey35"
  
  ; gsn_add* templates are functions that we set to dummy values. Since
  ; we are going to draw numerous error bars, we create two arrays to
  ; hold the dummy values.
  obs_error_bar = new((/dimsizes(yearArray)/),graphic)
  obs_centers   = new((/dimsizes(yearArray)/),graphic)
  model_error_bar = new((/dimsizes(yearArray)/),graphic)
  model_centers   = new((/dimsizes(yearArray)/),graphic)
  model_1deg_error_bar = new((/dimsizes(yearArray)/),graphic)
  model_1deg_centers   = new((/dimsizes(yearArray)/),graphic)
  
  ; loop through the points
    do t=0,dimsizes(yearArray)-1
      ; add a polymarker as the center of the error bar located at each data
      ; point
      ;obs_centers(t)   = gsn_add_polymarker(wks,plot0,yearArray(t),obs_storms(t),polyres)
      ;model_centers(t)   = gsn_add_polymarker(wks,plot0,yearArray(t),model_storms(t),polyres)
      ;model_1deg_centers(t)   = gsn_add_polymarker(wks,plot0,yearArray(t),model_storms_1deg(t),polyres)
      
      ; the error bar is draw in two segements, above and below the true
      ; value of u(t). I made up these value. You would change this to 
      ; true error.      
      obs_error_bar(t) = gsn_add_polyline(wks,plot0,(/yearArray(t),yearArray(t)/),(/obs_storms(t)+(obs_storms_sd/2.),obs_storms(t)-(obs_storms_sd/2.)/),polyres)
      model_error_bar(t) = gsn_add_polyline(wks,plot0,(/yearArray(t),yearArray(t)/),(/model_storms(t)+(model_storms_sd/2.),model_storms(t)-(model_storms_sd/2.)/),polyres)
      ;model_1deg_error_bar(t) = gsn_add_polyline(wks,plot0,(/yearArray(t),yearArray(t)/),(/model_storms_1deg(t)+(model_storms_1deg_sd/2.),model_storms_1deg(t)-(model_storms_1deg_sd/2.)/),polyres)
    end do
    
; Attach a legend

  labels = (/"Obs","V-R CAM-SE","1~S~o~N~ CAM-SE"/)
  lgres                    = True
  lgres@lgLineColors       = lineColors(::-1)
  lgres@lgLineThicknessF = 4.0
  lgres@lgItemType         = "Lines"        ; show lines only (default)
  lgres@lgLabelFontHeightF = .1            ; legend label font thickness
  lgres@vpWidthF           = 0.18           ; width of legend (NDC)
  lgres@vpHeightF          = 0.10           ; height of legend (NDC)
  lgres@lgPerimThicknessF  = 2.0            ; thicken the box perimeter
  lgres@lgMonoDashIndex    = False
  ;lgres@lgDashIndex        = 0
  lgres@lgDashIndexes = dashPatterns(::-1)

  legend = gsn_create_legend (wks,3,labels(::-1),lgres)

;
; Use gsn_add_annotation to attach this legend to our existing plot.
; This way, if we resize the plot, the legend will stay with the
; plot and be resized automatically.
;
; Point (0,0) is the dead center of the plot. Point (0,.5) is center,
; flush bottom. Point (0.5,0.5) is flush bottom, flush right.
;
  amres                  = True
  amres@amJust           = "TopLeft"    ; Use bottom right corner of box
                                            ; for determining its location.
  amres@amParallelPosF   = -0.5              ; Move legend to right
  amres@amOrthogonalPosF = -0.5              ; Move legend down.

  annoid = gsn_add_annotation(plot0,legend,amres)  ; add legend to plot
  
resP = True
resP@amJust           = "TopRight"
if (whatkind .eq. "storms") then
  resP@gsnPanelFigureStrings= (/"a."/)
else if (whatkind .eq. "hurr") then
  resP@gsnPanelFigureStrings= (/"b."/)
else
  resP@gsnPanelFigureStrings= (/"c."/)
end if
end if
resP@gsnPanelFigureStringsFontHeightF = 0.03
gsn_panel(wks,plot0,(/1,1/),resP)             ; now draw as one plot
   
end
