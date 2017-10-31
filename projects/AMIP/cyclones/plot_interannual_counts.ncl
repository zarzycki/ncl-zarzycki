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
  do_1deg = False

  styr = 1980
  enyr = 2002
  numyrs = enyr - styr + 1
  yearArray = ispan(styr,enyr,1)
  basin = 1
  
  file_storms = "stats/stats_tcs_by_year_storms_vr.txt"
  file_hurr = "stats/stats_tcs_by_year_hurr_vr.txt"
  file_majhurr = "stats/stats_tcs_by_year_majhurr_vr.txt"
  
  storms = asciiread(file_storms,-1,"integer")
  hurr = asciiread(file_hurr,-1,"integer")
  majhurr = asciiread(file_majhurr,-1,"integer")

  
  model1d_storms = storms(0:206)
  obs1d_storms = storms(207:413)
  model1d_hurr = hurr(0:206)
  obs1d_hurr = hurr(207:413)
  model1d_majhurr = majhurr(0:206)
  obs1d_majhurr = majhurr(207:413)

  model_all_storms = reshape(model1d_storms,(/numyrs,9/))
  obs_all_storms = reshape(obs1d_storms,(/numyrs,9/))
  model_all_hurr = reshape(model1d_hurr,(/numyrs,9/))
  obs_all_hurr = reshape(obs1d_hurr,(/numyrs,9/))
  model_all_majhurr = reshape(model1d_majhurr,(/numyrs,9/))
  obs_all_majhurr = reshape(obs1d_majhurr,(/numyrs,9/))
  
  model_storms = model_all_storms(:,basin-1)
  obs_storms = obs_all_storms(:,basin-1)
  model_hurr = model_all_hurr(:,basin-1)
  obs_hurr = obs_all_hurr(:,basin-1)
  model_majhurr = model_all_majhurr(:,basin-1)
  obs_majhurr = obs_all_majhurr(:,basin-1)
      

  print(model_storms)

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

;obs_storms(1996-1980) = obs_storms@_FillValue
;obs_storms(1997-1980) = obs_storms@_FillValue
;obs_storms(1998-1980) = obs_storms@_FillValue
;model_storms(1996-1980) = model_storms@_FillValue
;model_storms(1997-1980) = model_storms@_FillValue
;model_storms(1998-1980) = model_storms@_FillValue

obs_storms_dt = dtrend(obs_storms,False)
model_storms_dt = dtrend(model_storms,False)
obs_hurr_dt = dtrend(obs_hurr,False)
model_hurr_dt = dtrend(model_hurr,False)
obs_majhurr_dt = dtrend(obs_majhurr,False)
model_majhurr_dt = dtrend(model_majhurr,False)


startcorr = 1992
endcorr = 2002
ccr = escorc(obs_storms_dt(startcorr-styr:endcorr-styr),obs_storms_dt(startcorr-styr:endcorr-styr))   ; ccr is a scalar
print("CCR between obs and obs is "+ccr)
ccr = escorc(obs_storms_dt(startcorr-styr:endcorr-styr),model_storms_dt(startcorr-styr:endcorr-styr))   ; ccr is a scalar
print("CCR between obs and CAM-SE is "+ccr)
ccr = escorc(obs_hurr_dt(startcorr-styr:endcorr-styr),obs_hurr_dt(startcorr-styr:endcorr-styr))   ; ccr is a scalar
print("CCR between obs and obs is "+ccr)
ccr = escorc(obs_hurr_dt(startcorr-styr:endcorr-styr),model_hurr_dt(startcorr-styr:endcorr-styr))   ; ccr is a scalar
print("CCR between obs and CAM-SE is "+ccr)
ccr = escorc(obs_majhurr_dt(startcorr-styr:endcorr-styr),obs_majhurr_dt(startcorr-styr:endcorr-styr))   ; ccr is a scalar
print("CCR between obs and obs is "+ccr)
ccr = escorc(obs_majhurr_dt(startcorr-styr:endcorr-styr),model_majhurr_dt(startcorr-styr:endcorr-styr))   ; ccr is a scalar
print("CCR between obs and CAM-SE is "+ccr)
  
  
  wks = gsn_open_wks(out_type,"yeartimeseries")

  res               = True 
  res@gsnMaximize   = True
  res@tiMainString  = "Annual Atlantic TC Count"        ; title
  res@tiYAxisString = "Observed TCs"     ; y axis title
  res@tiXAxisString = "YEAR"    ; y axis title
  res@trXMinF = styr
  res@trXMaxF = enyr

  res@xyLineThicknessF = 5.0
  res@xyLineColor      ="blue"
  res@xyDashPattern = 0
  ;res@xyMarkLineMode = "MarkLines"
  ;res@xyMarker     = 16
  ;res@xyMarkerColor = res@xyLineColor
  
  res@trYMinF = -max(obs_storms)
  res@trYMaxF = max(obs_storms)
  
  res2 = res
  res2@tiYAxisString = "Simulated CAM-SE TCs"     ; y axis title
  res2@xyLineThicknessF = 5.0
  res2@xyLineColor      ="red"
  res2@xyDashPattern = 0
  ;res2@xyMarkLineMode = "MarkLines"
  ;res2@xyMarker     = 16
  res2@trYMinF = -max(obs_storms)
  res2@trYMaxF = max(obs_storms)
  plot = gsn_csm_xy2(wks,yearArray,obs_storms_dt(startcorr-styr:endcorr-styr),model_storms_dt(startcorr-styr:endcorr-styr),res,res2)
   
end
