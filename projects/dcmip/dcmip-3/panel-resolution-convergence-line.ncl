;***********************************************
; plot_supercell_prect.ncl
;
; Version 1.0
;***********************************************

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"  
load "/glade/u/home/zarzycki/ncl/functions/calc_area.ncl"

begin

out_type="x11"

thisVar="W"  ; W or PRECL

;modellist=(/"ACME","CSU_LZ","FV3","FVM","GEM","ICON","MPAS","NICAM","OLAM","TEMPEST"/)
modellist=(/"GEM"/)

;modellist=(/"CSU_CP","CSU_LZ"/)
reslist=(/"r50","r100","r200","r400"/)
nres = dimsizes(reslist)
;colors = (/"black","grey40","grey60","grey85"/)
colors = (/"black","turquoise3","violetred2","lightpink1"/)

;------------------------------------------------
; Workspace
;------------------------------------------------
wks = gsn_open_wks(out_type,"pdfs/plot_line_"+thisVar)   

plot = new(dimsizes(modellist),graphic)

do ii = 0,dimsizes(modellist)-1

whatVar=thisVar
model=modellist(ii)
;models=(/"GEM"/)

ntimes = 721
time_s = fspan(0.0, 7200.0, ntimes)

maxw = new((/nres,ntimes/),"float")

if ((model .eq. "ICON" .or. model .eq. "TEMPEST" .or. model .eq. "CSU_LZ" .or. model .eq. "CSU_CP" .or. model .eq. "ACME" .or. model .eq. "GEM" .or. model .eq. "DYNAMICO" .or. model .eq. "FVM" .or. model .eq. "FVM_OLD") .and. whatVar .eq. "PRECL")
  whatVar="PRECT"
end if

print(whatVar+" "+model)

do jj = 0,nres-1
  resol=reslist(jj)
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
      data_file = "/glade/p_old/vetssg/data/DCMIP_2016/gem/publish/Test163_"+resol+"/gem.163."+resol+".L40.interp_latlon.nonhydro.del2.w.nc"
    else if (whatVar .eq. "KE") then
      data_file = "/glade/p_old/vetssg/data/DCMIP_2016/gem/publish/Test163_"+resol+"/gem.163."+resol+".L40.interp_latlon.nonhydro.del2.u.nc"
      data_fil2 = "/glade/p_old/vetssg/data/DCMIP_2016/gem/publish/Test163_"+resol+"/gem.163."+resol+".L40.interp_latlon.nonhydro.del2.v.nc"
    else
      data_file = "/glade/p_old/vetssg/data/DCMIP_2016/gem/publish/Test163_"+resol+"/gem.163."+resol+".L40.interp_latlon.nonhydro.del2.prect.nc"
    end if
    end if
    time_units = "s"
    time_var_name="time"
    prec_units="ms"
  end if
  if (model .eq. "NICAM") then
    data_file = "/glade/p_old/vetssg/data/DCMIP_2016/nicam/publish/test3/nicam.163."+resol+".L40.interp_latlon.nonhydro."+whatVar+".nc"
    time_units = "m"
    time_var_name="time"
    prec_units="ms"
  end if
  if (model .eq. "ICON") then
    data_file = "/glade/p_old/vetssg/data/DCMIP_2016/icon/publish/icon.163."+resol+".L60.interp_latlon.nonhydro.dt"+timestep+"_default_diffusion."+whatVar+".nc"
    time_units = "d"
    time_var_name="time"
    prec_units="ms"
  end if
  if (model .eq. "ACME") then
    data_file = "/glade/p_old/vetssg/data/DCMIP_2016/acme-a/publish/acme.163."+resol+".L40.interp_latlon.nonhydro."+whatVar+".nc"
    time_units = "d"
    time_var_name="time"
    prec_units="ms"
  end if
  if (model .eq. "FV3") then
    data_file = "/glade/p_old/vetssg/data/DCMIP_2016/fv3/publish/release_v1.2_DCMIP/SUPERCELL."+resolkm+".64bit.cstdz.lvl40."+resolkm+"/rundir/fv3.163."+resol+".L24.cubed.nonhydro.cstdz.lvl40."+resolkm+"."+whatVar+".nc"
    time_units = "d"
    time_var_name="time"
    prec_units="mmd"
  end if
  if (model .eq. "DYNAMICO") then
    data_file = "/glade/p_old/vetssg/data/DCMIP_2016/dynamico/publish/dynamico.163."+fullreskm+".L40.hex.hydro.supercell/dynamico.163."+fullreskm+".L40.hex_interp_latlon.hydro.supercell."+whatVar+".nc"
    time_units = "s"
    time_var_name="time_counter"
    prec_units="ms"
  end if
  if (model .eq. "FVM") then
    data_file = "/glade/scratch/zarzycki/DCMIP-TMP/fvm.163."+resol+".L41.nonhydro.interp_latlon."+whatVar+".nc"
    time_units = "d"
    time_var_name="time"
    prec_units="ms"
  end if
  if (model .eq. "FVM_OLD") then
    data_file = "/glade/p_old/vetssg/data/DCMIP_2016/fvm/publish/fvm.163."+resol+".L41.nonhydro.interp_latlon."+whatVar+".nc"
    time_units = "d"
    time_var_name="time"
    prec_units="ms"
  end if
  if (model .eq. "MPAS") then
    data_file = "/glade/p_old/vetssg/data/DCMIP_2016/mpas/publish/mpas.163."+resol+".L40.latlon.nonhydro.nc"
    time_units = "d"
    time_var_name="time"
    prec_units="mms"
  end if
  if (model .eq. "TEMPEST") then
    data_file = "/glade/p_old/vetssg/data/DCMIP_2016/tempest/publish/tempest.163."+resol+".L40.interp_latlon.nonhydro."+whatVar+".nc"
    time_units = "d"
    time_var_name="time"
    prec_units="ms"
  end if
  if (model .eq. "CSU_CP") then
    if (resol .eq. "r50") then
      resol="r050"
    end if
    data_file = "/glade/p_old/vetssg/data/DCMIP_2016/csu/publish/csu_CP/csu.163."+resol+".L40.interp_latlon.nonhydro.CP_default."+whatVar+".nc"
    time_units = "csu"
    time_var_name="time"
    prec_units="ms"
  end if
  if (model .eq. "CSU_LZ") then
    if (resol .eq. "r50") then
      resol="r050"
    end if
    data_file = "/glade/p_old/vetssg/data/DCMIP_2016/csu/publish/csu_LZ/csu.163."+resol+".L40.interp_latlon.nonhydro.LZ_default."+whatVar+".nc"
    time_units = "h"
    time_var_name="time"
    prec_units="ms"
  end if
  if (model .eq. "OLAM") then
    data_file = "/glade/u/home/zarzycki/work/dcmip-2016/olam/dcmip131_"+resol+"-DLL-2000-01-01-CAT.nc"
    time_units = "m"
    time_var_name="time"
    prec_units="ms"
  end if

  print(""+data_file)

  f=addfile(data_file,"r")
  lat=f->lat
  lon=f->lon
  area=calc_area(lat,lon)
  if(whatVar .eq. "W" .or. whatVar .eq. "w") then
    w=f->$whatVar$
    model_w = dim_max_n(w,(/1,2,3/))
  else if(whatVar .eq. "KE") then
    w=f->U
    f2=addfile(data_fil2,"r")
    v=f2->V
    w=sqrt(w*w+v*v)
    countdims = dimsizes(w)
    ntimes = countdims(0)
    model_w = new(ntimes,"double")
    area3D = conform (w(0,:,:,:),area,(/1,2/)) 
    do kk = 0,ntimes-1
      model_w(kk)=sum(w(kk,:,:,:)*area3D)/sum(area3D)
    end do
    print(model_w)
    delete(f2)
    delete(area3D)
    delete(v)
  else
    w=f->$whatVar$
    if (prec_units .eq. "mms")
      w = w / 1000.
    end if
    if (prec_units .eq. "mmd")
      w = w * 1.15741e-8
    end if
    countdims = dimsizes(w)
    ntimes = countdims(0)
    model_w = new(ntimes,"double")
    do kk = 0,ntimes-1
      model_w(kk)=sum(w(kk,:,:)*area)/sum(area)
    end do
    rho_h2o = 1000.
    model_w = model_w * rho_h2o * 4 * 3.14159 * (6371000./120.)^2 / 10^5
  end if
  end if
  
  if (model .ne. "OLAM")
    model_time = f->$time_var_name$
  end if 

  if(model .eq. "NICAM" .or. model .eq. "OLAM") then
    model_time = (/0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 100, 105, 110, 115, 120 /)
  end if

  if(model .eq. "OLAM") then
    model_time_float = tofloat(model_time)
    delete(model_time)
    model_time = model_time_float
    delete(model_time_float)
  end if

  if (time_units .eq. "d") then
    model_time = model_time * 86400.
  else if (time_units .eq. "m") then
    model_time = model_time * 60.
  else if (time_units .eq. "h") then
    model_time = model_time * 3600.
  else if (time_units .eq. "csu") then
    model_time = model_time * 24.
  else
    model_time = model_time
  end if
  end if
  end if
  end if

  printVarSummary(model_time)
  printVarSummary(model_w)

  maxw(jj,:) = tofloat(linint1_Wrap(model_time,model_w,False,time_s,0))
  delete([/data_file,time_units,f,w,model_w,model_time,time_var_name/])
  delete([/prec_units/])
  delete([/lat,lon,area/])


end do



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

  ; turn on minor tickmarks
  res@tmXBMinorOn       = True
  res@tmYLMinorOn       = True

  ; no top X labels, turn top X tickmarks inside box for reference
  res@tmXTLabelsOn      = False
  ;res@tmXTOn            = False
  res@tmXUseBottom = False
  res@tmXTMajorOutwardLengthF = 0.0
  res@tmXTMinorOutwardLengthF = 0.0

  ;res@xyLineThicknessF  = 4.0
  res@xyLineThicknesses = (/5.5,4.9,4.3,3.7/)
  res@xyMarkLineMode    = "Lines"
  res@xyLineColors = colors

  if (model .eq. "ACME") then
    res@tiMainString = "ACME-A (E3SM)"
  else if (model .eq. "CSU_LZ") then
    res@tiMainString = "CSU"
  else if (model .eq. "FV3") then
    res@tiMainString = "FV~S~3~N~"
  else
    res@tiMainString = model+""
  end if
  end if
  end if
  res@tiMainFontHeightF = 0.04

  resw = res

;------------------------------------------------
; Vertical velocity plot
;------------------------------------------------

  resw@tiXAxisOn = True
  if (ii .eq. 0) then
    resw@tiXAxisString = "time (s)"
  else
    resw@tiXAxisString = ""
  end if

  resw@tiYAxisOn = True

  resw@tmXBLabelFontHeightF = 0.035
  resw@tmYLLabelFontHeightF = resw@tmXBLabelFontHeightF
  resw@trXMinF = 0.0
  resw@trXMaxF = 7200.0

  resw@tiXAxisFontHeightF = 0.035
  resw@tiYAxisFontHeightF = resw@tiXAxisFontHeightF
  resw@tiYAxisString=""
  if (whatVar .eq. "W" .or. whatVar .eq. "w") then
    resw@trYMinF = 0.0
    resw@trYMaxF = 67.0
    if ( ii .eq. 0 ) then
      resw@tiYAxisString = "max. vert. velocity (m s~S~-1~N~)"
    end if
  else
    resw@trYMinF = 0.0
    resw@trYMaxF = 265.0
    if ( ii .eq. 0 ) then
      resw@tiYAxisString = "precip. rate (x10~S~5~N~ kg s~S~-1~N~)"
    end if
  end if

  resw@tmXBMode = "Manual"
  resw@tmXBTickStartF = 0.0
  resw@tmXBTickEndF = 7200.0
  resw@tmXBTickSpacingF = 1800.0

  ;resw@tmYLMode = "Explicit"
  ;resw@tmYLTickStartF = 0.0
  ;resw@tmYLTickEndF = 50.0

  plot(ii) = gsn_csm_xy(wks, time_s, maxw, resw)

; add legend
  if (ii .eq. 0)
    nboxes = nres
    lgres                    = True          ; labelbar only resources
    lgres@lgPerimOn          = False
    lgres@lgLineColors       = colors ; labelbar colors
    ;lgres@lgLineThicknessF   = res@xyLineThicknessF
    lgres@lgMonoLineThickness = False
    lgres@lgLineThicknesses   = res@xyLineThicknesses
    lgres@lgMonoLineDashSegLen = True
    lgres@lgMonoDashIndex = True
    lgres@lgDashIndexes      = (/0,3,15,1,2/)
    lgres@lgLabelFontHeightF = 0.09
    lgres@lgBoxMinorExtentF  = 0.35
    lgres@vpWidthF           = 0.35           ; width of legend (NDC)
    lgres@vpHeightF          = 0.25           ; height of legend (NDC)
    labels = (/" 0.5km"," 1km"," 2km"," 4km"/)
    id0 = gsn_create_legend(wks,nboxes,labels,lgres)
    amres                  = True
    if (whatVar .eq. "W" .or. whatVar .eq. "w") then
      amres@amJust           = "BottomRight"
      amres@amParallelPosF   = 0.48          ; Move legend to left/right
      amres@amOrthogonalPosF = 0.48         ; Move legend up/down
    else
      amres@amJust           = "TopLeft"
      amres@amParallelPosF   = -0.48          ; Move legend to left/right
      amres@amOrthogonalPosF = -0.48         ; Move legend up/down
    end if
    annoid = gsn_add_annotation(plot(ii),id0,amres)
  end if

  delete(whatVar)

end do
;------------------------------------------------
; Panel plot
;------------------------------------------------

  pres = True
  ;pres@gsnPanelBottom = 0.1
  ;pres@gsnPanelTop = 0.9
  pres@gsnPanelYWhiteSpacePercent = 3
  pres@gsnPanelXWhiteSpacePercent = 0
  gsn_panel(wks, plot, (/3,4/), pres)

end

