begin

files = (/"RWP_2011.nc","CAM_x005.nc","CAM_x010.nc","CAM_x121.nc"/)
var = "TAU"

nfiles = dimsizes(files)

do ii = 0,nfiles-1

  f1 = addfile(files(ii),"r")

  if (ii .eq. 0) then
    vars = new((/nfiles,24/),typeof(f1->$var$))
    time = f1->Time
  end if

  vars(ii,:) = f1->$var$

end do

 wks   = gsn_open_wks ("x11","xy")                 ; send graphics to PNG file

;---Set plotting parameters

 res                   = True                      ; plot mods desired
 res@tiMainString      = "Two curve XY plot"       ; add title
;
; Similiar resources are xyLineThicknessF and xyLineColor,
; which will affect all lines in the array.
;
 res@xyLineThicknesses = (/  1.0,   2.0,2.0,2.0/)          ; make second line thicker
 res@xyLineColors      = (/"black","blue","red","green"/)          ; change line color

  res@pmLegendDisplayMode    = "Always"

  res@pmLegendSide           = "Top"               ; Change location of 
  res@pmLegendParallelPosF   = .25                 ; move units right
  res@pmLegendOrthogonalPosF = -0.4                ; move units down

  res@pmLegendWidthF         = 0.12                ; Change width and
  res@pmLegendHeightF        = 0.15                ; height of legend.
  res@lgLabelFontHeightF     = .013                 ; change font height
  res@lgOrientation          = "vertical"
  res@lgPerimOn              = False               ; no box around

  res@lgLabelAngleF          = 0.                ; angle of legend label
  res@xyExplicitLegendLabels = files
  
  
  
 plot  = gsn_csm_xy (wks,time,vars,res) ; create plot

end
