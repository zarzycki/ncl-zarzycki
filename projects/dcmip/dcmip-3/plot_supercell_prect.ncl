;***********************************************
; plot_supercell_prect.ncl
;
; Version 1.0
;***********************************************

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"  

begin

out_type="pdf"

models = (/"GEM","NICAM","ICON","FV3","TEMPEST"/)
colors = (/"red","blue","green","purple","orange"/)
;models=(/"GEM"/)
nmodels = dimsizes(models)

ntimes = 721
time_s = fspan(0.0, 7200.0, ntimes)

maxw = new((/nmodels,ntimes/),"float")

do ii = 0,nmodels-1
  model=models(ii)
  print("analyzing: "+model)
  if (model .eq. "GEM") then
    data_file = "/glade/p/vetssg/data/DCMIP_2016/gem/publish/Test163_r100/gem.163.r100.L40.interp_latlon.nonhydro.del2.w.nc"
    time_units = "s"
    time_var_name="time"
  end if
  if (model .eq. "NICAM") then
    data_file = "/glade/p/vetssg/data/DCMIP_2016/nicam/publish/test3/nicam.163.r100.L40.interp_latlon.nonhydro.W.nc"
    time_units = "m"
    time_var_name="time"
  end if
  if (model .eq. "ICON") then
    data_file = "/glade/p/vetssg/data/DCMIP_2016/icon/publish/icon.163.r100.L60.interp_latlon.nonhydro.dt240_default_diffusion.W.nc"
    time_units = "d"
    time_var_name="time"
  end if
  if (model .eq. "FV3") then
    data_file = "/glade/p/vetssg/data/DCMIP_2016/fv3/work/SUPERCELL.1km.64bit.cstdz.lvl40.1km/rundir/fv3.163.r100.L24.interp_latlon.nonhydro.cstdz.lvl40.1km.W.nc"
    time_units = "d"
    time_var_name="time"
  end if
  if (model .eq. "DYNAMICO") then
    data_file = "/glade/p/vetssg/data/DCMIP_2016/dynamico/publish/dynamico.163.100km.L40.hex.hydro.supercell/dynamico.163.100km.L40.hex_interp_latlon.hydro.supercell.W.nc"
    time_units = "s"
    time_var_name="time_counter"
  end if
  if (model .eq. "FVM") then
    data_file = "/glade/p/vetssg/data/DCMIP_2016/fvm/publish/fvm.163.r100.L41.nonhydro.interp_latlon.W.nc"
    time_units = "d"
    time_var_name="time"
  end if
  if (model .eq. "MPAS") then
    data_file = "/glade/scratch/shpark/dcmip/test3/mpas.163.r100.L40.latlon.nonhydro.nc"
    time_units = "d"
    time_var_name="time"
  end if
  if (model .eq. "TEMPEST") then
    data_file = "/glade/scratch/ullrich/tempest.163.r200.L40.interp_latlon.nonhydro.W.nc"
    time_units = "d"
    time_var_name="time"
  end if

  f=addfile(data_file,"r")
  w=f->W
  model_w = tofloat(dim_max_n(w,(/1,2,3/)))
  model_time = tofloat(f->$time_var_name$)

  if (time_units .eq. "d") then
    model_time = model_time * 86400.
  else if (time_units .eq. "m") then
    model_time = model_time * 60.
  else if (time_units .eq. "h") then
    model_time = model_time * 3600.
  end if
    model_time = model_time
  end if
  end if

  maxw(ii,:) = linint1_Wrap(model_time,model_w,False,time_s,0)
  delete([/data_file,time_units,f,w,model_w,model_time,time_var_name/])
end do

;------------------------------------------------
; Workspace
;------------------------------------------------
  wks = gsn_open_wks(out_type,"plot_supercell_wvel")   

;------------------------------------------------
; Plot resources [options]
;------------------------------------------------
; Resources:
  res                     = True

  res@gsnDraw             = False
  res@gsnFrame            = False

  res@vpKeepAspect        = True
  res@vpWidthF            = 0.6
  res@vpHeightF           = 0.6
  res@gsnMaximize         = True
  res@gsnPaperOrientation = "portrait"

  res@tmXBLabelsOn      = True
  res@tmXBOn            = True

  res@tmXTLabelsOn      = False
  res@tmXTOn            = False

  res@tmXBMinorOn       = True
  res@tmYLMinorOn       = True

  res@xyLineThicknessF  = 5.0
  res@xyMarkLineMode    = "Lines"
  res@xyLineColors = colors

  res@tiMainString = "DCMIP Supercell Prelim. Results"

  resw = res

;------------------------------------------------
; Vertical velocity plot
;------------------------------------------------

  resw@tiXAxisOn = True
  resw@tiXAxisString = "time (s)"

  resw@tiYAxisOn = True
  resw@tiYAxisString = "maximum vertical velocity (m/s)"

  resw@trXMinF = 0.0
  resw@trXMaxF = 7200.0
  
  resw@trYMinF = 0.0
  resw@trYMaxF = 60.0

  resw@tmXBMode = "Manual"
  resw@tmXBTickStartF = 0.0
  resw@tmXBTickEndF = 7200.0
  resw@tmXBTickSpacingF = 1800.0

  resw@tmYLMode = "Explicit"
  resw@tmYLTickStartF = 0.0
  resw@tmYLTickEndF = 50.0

  plot = gsn_csm_xy(wks, time_s, maxw, resw)

; add stuff
  nboxes = 5
  lgres                    = True          ; labelbar only resources
  lgres@lgPerimOn          = False
  lgres@lgLineColors       = colors ; labelbar colors
  lgres@lgLineThicknessF   = 5.0
  lgres@lgDashIndexes      = (/0,3,15,1,2/)
  lgres@lgLabelFontHeightF = .04            ; legend label font thickness
  lgres@lgBoxMinorExtentF  = 0.35
  lgres@vpWidthF           = 0.30           ; width of legend (NDC)
  lgres@vpHeightF          = 0.15           ; height of legend (NDC)
  labels = models
  id0 = gsn_create_legend(wks,nboxes,labels,lgres)
  amres                  = True
  amres@amJust           = "TopRight"
  amres@amParallelPosF   = 0.2          ; Move legend to left/right
  amres@amOrthogonalPosF = 0.25         ; Move legend up/down
  annoid = gsn_add_annotation(plot,id0,amres)


;------------------------------------------------
; Panel plot
;------------------------------------------------

  pres = True
  pres@gsnPanelBottom = 0.1
  pres@gsnPanelTop = 0.9
  pres@gsnPanelYWhiteSpacePercent = 5
  pres@gsnPanelXWhiteSpacePercent = 5
  gsn_panel(wks, plot, (/1,1/), pres)

end

