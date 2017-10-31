;================================================;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
; ================================================;
begin

; File Paths ---------------------------------------------------
  eulpath = getenv("eulpath")
  fvpath = getenv("fvpath")
  sepath = getenv("sepath")
  sldpath = getenv("sldpath")
  apeeulpath = getenv("apeeulpath")
  apefvpath = getenv("apefvpath")
  apesepath = getenv("apesepath")
  apesldpath = getenv("apesldpath")
  sebmpath = getenv("sebmpath")

  eulcase = getenv("eulcase")
  fvcase = getenv("fvcase")
  secase = getenv("secase")
  sldcase = getenv("sldcase")
  apeeulcase = getenv("apeeulcase")
  apefvcase = getenv("apefvcase")
  apesecase = getenv("apesecase")
  apesldcase = getenv("apesldcase")
  sebmcase = getenv("sebmcase")

; Input settings from shell script -----------------------------
  start_month = stringtointeger(getenv("START"))
  end_month = stringtointeger(getenv("END"))
  setting = getenv("setting")

; Options ------------------------------------------------------
    pfmt = "pdf"

  var_num = 2
  variables = (/"T","U"/)
  varName = (/"temperature difference","zonal wind difference"/)
  units = (/"K","m/s"/)

; Case specific settings ----------------------------------------
if (setting .eq. "all")
  nfiles = 2             ; number of files
  panelSize = (/2,3/)    ; panel dimensions

  plotTit = (/"Moist Idealized - Aquaplanet"/)
  yaxTit = (/"Pressure (hPa)","Pressure (hPa)"/)
  xaxTit = (/" ","Latitude"/)
  paths = (/sepath,apesepath/)
  cases = (/secase,apesecase/)

else if (setting .eq. "se_fv")

  nfiles = 2             ; number of files
  panelSize = (/2,1/)    ; panel dimensions

  plotTit = (/"SE - FV"/)
  yaxTit = (/"Pressure (hPa)","Pressure (hPa)"/)
  xaxTit = (/" ","Latitude"/)
  paths = (/sepath,fvpath/)
  cases = (/secase,fvcase/)

end if
end if

;=================================================================
;=================================================================
; open wks and preallocate plot space

  plots = new(2,graphic)
  wks  = gsn_open_wks(pfmt,"mhs_ttest_TU_"+setting)

; Loop over all variables --------------------------------------
do i = 0,var_num-1       ; variable loop
print("Variable: "+variables(i))

; Loop over all files ------------------------------------------
do file_step=0,nfiles-1  ; dycore loop
print("      File "+file_step)

;=================================================================
; load data and variables

   fnam1 = paths(file_step)+cases(file_step)+".cam.h0.*.nc"
   files1 = systemfunc("ls "+fnam1)
   input = addfiles(files1,"r")
       ListSetType(input,"cat")

  var_in  = input[:]->$variables(i)$(start_month:end_month-1,:,:,:)
  dim_var = dimsizes(var_in)
  ntime = dim_var(0)
  nlev = dim_var(1)
  nlat = dim_var(2)
  
;=================================================================
; compute zonal average and subset data into 3 month chunks
;     skip 1 month between each subset of data

  var_avg = dim_avg_n_Wrap(var_in,3)     ; zonal average
  var_zonal = dim_avg_n_Wrap(var_avg,0)  ; time mean (for data contour)

  sub_data = new((/nlev,nlat,ntime/4/),float)
  j = 0
  do k=0,((end_month-start_month)/4.)-1.
    sub_data(:,:,k) = dim_avg_n_Wrap(var_avg(j:j+2,:,:),0)  ; avg 3 months
    j = j + 4                                               ; skip 1 month
  end do

if(any(ismissing(sub_data))) then
    print("Your data contains some missing values. Beware.")
end if

;=================================================================
; gather values for students t test for significant differences

; significance for equivalent sample size
  sig = 0.05

; average and variance over time dimension
  if (file_step .eq. 0) then
     avg1 = dim_avg(sub_data)
     var1 = dim_variance(sub_data)
     size1 = ntime/4
     tmp1 = var_zonal
  else
     avg2 = dim_avg(sub_data)
     var2 = dim_variance(sub_data)
     size2 = ntime/4
     tmp2 = var_zonal
  end if

  delete([/files1,input,fnam1,var_in,dim_var,sub_data/])
end do     ; dycore loop

;=================================================================
; perform students t test (two-sided)

   prob = ttest(avg1,var1,size1,avg2,var2,size2,False,False)
      copy_VarCoords(tmp1,prob)
printVarSummary(prob)
Num_missing = num(ismissing(prob))
print(Num_missing)

sig_num = num(prob .lt. sig)
prob_avg = avg(prob)
print(sig_num)    ; print number of significant points
print(prob_avg)   ; print average probability

    var_plot = tmp1-tmp2      ; compute differences for data contours
     copy_VarMeta(tmp1,var_plot)

;=================================================================
; define resources for data contours

  res = True
  res@gsnDraw   = False
  res@gsnFrame  = False
  res@vpHeightF = 0.40
  
  res@gsnLeftString  = "  "+varName(i)
  res@gsnRightString = units(i)+"  "
  res@tiYAxisString  = "Pressure (hPa)"
  
  res@trXMinF    = -90
  res@trXMaxF    = 90
  res@tmXBMode   = "Explicit"
  res@tmXBValues = (/-90,-60,-30,0,30,60,90/)
  res@tmXBLabels = (/"90S","60S","30S","EQ","30N","60N","90N"/)

  res@trYReverse               = True
  res@gsnYAxisIrregular2Linear = True
  
  res@gsnContourZeroLineThicknessF = 2
  res@gsnContourNegLineDashPattern = 1

;=================================================================
; define resources for ttest contours

  res2          = True
  res2@gsnFrame = False
  res2@gsnDraw  = False
  
  res2@trXMinF = -90
  res2@trXMaxF = 90
  
  res2@trYReverse               = True
  res2@gsnYAxisIrregular2Linear = True

  res2@cnLinesOn      = False
  res2@cnLineLabelsOn = False
  res2@cnInfoLabelOn  = False
  res2@lbLabelBarOn   = False
  
  res2@cnLevelSelectionMode = "ExplicitLevels"
  res2@cnLevels             = (/0.01,0.05/)
  res2@cnFillOn             = True
  res2@cnFillColors         = (/"gray15","gray50","transparent"/)
  res2@cnFillOpacityF       = 0.6

;=================================================================
; define resources for panelling

  resP = True
  resP@gsnMaximize  = True
  resP@amJust       = "TopLeft"
  resP@gsnPanelFigureStringsFontHeightF = 0.018
  resP@gsnPanelFigureStrings            = (/"a.","b."/)
    
;=================================================================
; plot and overlay

if (i .eq. 0) then
  res@tiMainString = plotTit

  plots(0) = gsn_csm_contour(wks,var_plot,res) 
  sig_plot0 = gsn_csm_contour(wks,prob,res2)
    
  overlay(plots(0),sig_plot0)
  
else if (i .eq. 1) then
  res@tiMainString = " "

  plots(1) = gsn_csm_contour(wks,var_plot,res)
  sig_plot1 = gsn_csm_contour(wks,prob,res2)
  
  overlay(plots(1),sig_plot1)
end if
end if
end do

  gsn_panel(wks,plots,(/2,1/),resP)

end
