;***********************************************
; plot_supercell_prect.ncl
;
; Version 1.0
;***********************************************

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"  
load "./area_rectlinear_grid.ncl" 

begin

out_type="x11"

whatVar="W"  ; W or PRECL
reslist=(/"r50","r100","r200","r400"/)
model="GEM"
colors = (/"grey15","grey30","grey60","grey90"/)
;models=(/"GEM"/)
nres = dimsizes(reslist)

ntimes = 721
time_s = fspan(0.0, 7200.0, ntimes)

maxw = new((/nres,ntimes/),"float")

if ((model .eq. "ICON" .or. model .eq. "GEM" .or. model .eq. "DYNAMICO" .or. model .eq. "FVM") .and. whatVar .eq. "PRECL")
  whatVar="PRECT"
end if
prec_units="mmd"

do ii = 0,nres-1
  resol=reslist(ii)
  if (resol .eq. "r400") then
    timestep="300"
    resolkm="4km"
    fullreskm="400km"
  else if (resol .eq. "r200") then
    timestep="300"
    resolkm="2km"
    fullreskm="200km"

  else if (resol .eq. "r100") then
    timestep="240"
    resolkm="1km"
    fullreskm="100km"

  else if (resol .eq. "r50") then
    timestep="120"
    resolkm="0.5km"
    fullreskm="50km"

  else
    print("incorrect resol value")
    exit
  end if
  end if
  end if
  end if
  print("analyzing: "+model)
  if (model .eq. "GEM") then
    if (whatVar .eq. "W") then
      data_file = "/glade/p/vetssg/data/DCMIP_2016/gem/publish/Test163_"+resol+"/gem.163."+resol+".L40.interp_latlon.nonhydro.del2.w.nc"
    else
      data_file = "/glade/p/vetssg/data/DCMIP_2016/gem/publish/Test163_"+resol+"/gem.163."+resol+".L40.interp_latlon.nonhydro.del2.prect.nc"
    end if
    time_units = "s"
    time_var_name="time"
    prec_units="ms"
  end if
  if (model .eq. "NICAM") then
    data_file = "/glade/p/vetssg/data/DCMIP_2016/nicam/publish/test3/nicam.163."+resol+".L40.interp_latlon.nonhydro."+whatVar+".nc"
    time_units = "m"
    time_var_name="time"
    prec_units="ms"
  end if
  if (model .eq. "ICON") then
    data_file = "/glade/p/vetssg/data/DCMIP_2016/icon/publish/icon.163."+resol+".L60.interp_latlon.nonhydro.dt"+timestep+"_default_diffusion."+whatVar+".nc"
    time_units = "d"
    time_var_name="time"
    prec_units="ms"
  end if
  if (model .eq. "FV3") then
    data_file = "/glade/p/vetssg/data/DCMIP_2016/fv3/publish/release_v1.0_DCMIP-OLD/SUPERCELL."+resolkm+".64bit.cstdz.lvl40."+resolkm+"/rundir/fv3.163."+resol+".L24.cubed.nonhydro.cstdz.lvl40."+resolkm+"."+whatVar+".nc"
    time_units = "d"
    time_var_name="time"
  end if
  if (model .eq. "DYNAMICO") then
    data_file = "/glade/p/vetssg/data/DCMIP_2016/dynamico/publish/dynamico.163."+fullreskm+".L40.hex.hydro.supercell/dynamico.163."+fullreskm+".L40.hex_interp_latlon.hydro.supercell."+whatVar+".nc"
    time_units = "s"
    time_var_name="time_counter"
    prec_units="ms"
  end if
  if (model .eq. "FVM") then
    data_file = "/glade/p/vetssg/data/DCMIP_2016/fvm/publish/fvm.163."+resol+".L41.nonhydro.interp_latlon."+whatVar+".nc"
    time_units = "d"
    time_var_name="time"
    prec_units="ms"
  end if
  if (model .eq. "MPAS") then
    data_file = "/glade/scratch/shpark/dcmip/test3/mpas.163."+resol+".L40.latlon.nonhydro.nc"
    time_units = "d"
    time_var_name="time"
    prec_units="mms"
  end if

  print(""+data_file)

  f=addfile(data_file,"r")
  w=f->$whatVar$
  ;lat=f->lat
  ;lon=f->lon
  ;area = area_global_rectilinear_grid (lat, lon, False)
  ;area = area*100.*100. ; convert to m^2 
  ;areaC = tofloat(conform (w, area, (/1,2/)) )
  ;printVarSummary(areaC)
  ;printVarSummary(w)
  ;w = w * 1000. * areaC / 1000. / 86400. / 10.^8


  if(whatVar .eq. "W") then
    model_w = dim_max_n(w,(/1,2,3/))
  else
    model_w = dim_sum_n(w,(/1,2/))
    model_w = dim_cumsum_n(model_w,2,0)

    if (prec_units .eq. "ms")
      model_w = model_w * 8.64e7
    end if
    if (prec_units .eq. "mms")
      model_w = model_w * 8.64e7/1000.
    end if
  end if





  model_time = f->$time_var_name$

  if(model .eq. "NICAM") then
    model_time = (/0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 100, 105, 110, 115, 120 /)
  end if

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
  ;delete([/lat,lon,area,areaC/])
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

  if (whatVar .eq. "W") then
    resw@trYMinF = 0.0
    resw@trYMaxF = 60.0
  else
    resw@trYMinF = 0.0
    ;resw@trYMaxF = 8000.0
    resw@trYMaxF = 180.0
  end if

  resw@tmXBMode = "Manual"
  resw@tmXBTickStartF = 0.0
  resw@tmXBTickEndF = 7200.0
  resw@tmXBTickSpacingF = 1800.0

  resw@tmYLMode = "Explicit"
  resw@tmYLTickStartF = 0.0
  resw@tmYLTickEndF = 50.0

  plot = gsn_csm_xy(wks, time_s, maxw, resw)

; add stuff
  nboxes = nres
  lgres                    = True          ; labelbar only resources
  lgres@lgPerimOn          = False
  lgres@lgLineColors       = colors ; labelbar colors
  lgres@lgLineThicknessF   = 5.0
  lgres@lgDashIndexes      = (/0,3,15,1,2/)
  lgres@lgLabelFontHeightF = .04            ; legend label font thickness
  lgres@lgBoxMinorExtentF  = 0.35
  lgres@vpWidthF           = 0.30           ; width of legend (NDC)
  lgres@vpHeightF          = 0.15           ; height of legend (NDC)
  labels = reslist
  id0 = gsn_create_legend(wks,nboxes,labels,lgres)
  amres                  = True
  amres@amJust           = "TopRight"
  amres@amParallelPosF   = 0.55          ; Move legend to left/right
  amres@amOrthogonalPosF = 0.28         ; Move legend up/down
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

