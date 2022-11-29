begin

fname="CAM_x132.nc"
f=addfile(fname,"r")

vars = (/"vpwp_ac_97.49w_36.61n", \
         "vpwp_bp_97.49w_36.61n", \
         "vpwp_bt_97.49w_36.61n", \
         "vpwp_cl_97.49w_36.61n", \
         "vpwp_dp1_97.49w_36.61n", \                  
         "vpwp_ma_97.49w_36.61n", \
         "vpwp_mfl_97.49w_36.61n", \
         "vpwp_pr1_97.49w_36.61n", \
         "vpwp_pr2_97.49w_36.61n", \
         "vpwp_pr3_97.49w_36.61n", \
         "vpwp_pr4_97.49w_36.61n", \
         "vpwp_ta_97.49w_36.61n", \
         "vpwp_tp_97.49w_36.61n" /)

nvars = dimsizes(vars)
nvars = nvars+1

z = f->z
time = f->Time

nz = dimsizes(z)
nt = dimsizes(time)

anl_times = (/15.0/)
nanlt = dimsizes(anl_times)

arr = new((/nvars,nanlt,nz/),"double")
arrstr = new(nvars,"string")

do ii = 0,nvars-1
  thisTime = anl_times(0)
  
  if (ii .eq. nvars-1) then
    arr(ii,0,:) = dim_sum_n_Wrap(arr(0:nvars-2,0,:),0)
    arr(ii,0,:) = arr(ii,0,:)*30.
    arrstr(ii) = "sum"
  else
    thisVar = vars(ii)
    arr(ii,0,:) = f->$thisVar$(:,{thisTime})
    arrstr(ii) = str_sub_str(thisVar,"_97.49w_36.61n","")
  end if
  
end do



wks   = gsn_open_wks ("x11","xy")                 ; send graphics to PNG file

res                   = True                      ; plot mods desired
res@tiMainString      = fname       ; add title
res@xyLineColors      = (/"blue","red","green","orange","gray50","purple","gray70","RoyalBlue",\
             "PowderBlue","pink","PaleGreen","Wheat","Brown"/)

res@xyMonoLineThickness=True
res@xyLineThicknessF=5.0

res@xyMonoDashPattern=True

res@pmLegendDisplayMode    = "Always"
res@pmLegendSide           = "Top"               ; Change location of 
res@pmLegendParallelPosF   = 0.17                 ; move units right
res@pmLegendOrthogonalPosF = -0.63                ; move units down
res@pmLegendWidthF         = 0.12                ; Change width and
res@pmLegendHeightF        = 0.30                ; height of legend.
res@lgLabelFontHeightF     = .013                 ; change font height
res@lgOrientation          = "vertical"
res@lgPerimOn              = False               ; no box around
res@lgLabelAngleF          = 0.                ; angle of legend label
res@xyExplicitLegendLabels = str_sub_str(vars,"_97.49w_36.61n","")

res@trYMinF       = 0.0       
res@trYMaxF       = 4000.0
res@trXMinF=-.0035
res@trXMaxF=.0035
plot  = gsn_csm_xy (wks,arr(:,0,:),z,res) ; create plot



    
 
end

