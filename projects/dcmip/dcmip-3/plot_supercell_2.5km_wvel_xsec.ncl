;***********************************************
; plot_supercell_2.5km_wvel_xsec.ncl
;
; Version 1.0
;***********************************************

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"  

begin

;****************************************************************************
; DO NOT EDIT ABOVE THIS LINE
;****************************************************************************
; Read in data and store as follows:
;
;   Output:
;     w_2500m(lon, lat)
;     2D vertical velocity field at 2.5km altitude at 7200s (units m/s)
;
;   Dimensions:
;     lon:   arbitrary
;     lat:   arbitrary
;----------------------------------------------------------------------------

model="FVM"
resol="r100"

if (model .eq. "FVM") then
  w_data_file = "/glade/p/vetssg/data/DCMIP_2016/fvm/publish/fvm.163."+resol+".L41.nonhydro.interp_latlon.W.nc"
  correctLon=True
  w_data = addfile(w_data_file,"r")
  lev=w_data->lev(:,0,0)
  print(lev)   ;2500 is the 5th index
  w_2500m = w_data->W(24,5,:,:)
end if

if (model .eq. "TEMPEST") then
  w_data_file = "/glade/scratch/ullrich/tempest.163."+resol+".L40.interp_latlon.nonhydro.W.nc"
  correctLon=False
  w_data = addfile(w_data_file,"r")
  w_2500m = w_data->W(24,{2500.},:,:)
end if

if (model .eq. "MPAS") then
  w_data_file = "/glade/scratch/shpark/dcmip/test3/mpas.163."+resol+".L40.latlon.nonhydro.nc"
  correctLon=False
  w_data = addfile(w_data_file,"r")
  lev=w_data->Z(:,0,0)
  print(lev)   ;2500 is the 5th index
  w_2500m = w_data->W(24,5,:,:)
  w_2500m = lonFlip(w_2500m)
end if

if (model .eq. "GEM") then
  w_data_file = "/glade/p/vetssg/data/DCMIP_2016/gem/publish/Test163_"+resol+"/gem.163."+resol+".L40.interp_latlon.nonhydro.del2.w.nc"
  correctLon=True
  w_data = addfile(w_data_file,"r")
  ; CMZ -- need to interp to Z surfaces
  w_2500m = w_data->W(24,{825.},:,:)
end if

if (model .eq. "FV3") then
  if (resol .eq. "r400") then
    resolkm="4km"
  else if (resol .eq. "r200") then
    resolkm="2km"
  else if (resol .eq. "r100") then
    resolkm="1km"
  else if (resol .eq. "r50") then
    resolkm="0.5km"
  else
    print("incorrect resol value")
    exit
  end if
  end if
  end if
  end if
  w_data_file = "/glade/p/vetssg/data/DCMIP_2016/fv3/publish/release_v1.0_DCMIP-OLD/SUPERCELL."+resolkm+".64bit.cstdz.lvl40."+resolkm+"/rundir/fv3.163."+resol+".L24.cubed.nonhydro.cstdz.lvl40."+resolkm+".w2500m.nc"
  correctLon=True
  w_data = addfile(w_data_file,"r")
  w_2500m = w_data->w2500m(23,:,:)
end if

if (model .eq. "NICAM") then
  w_data_file = "/glade/p/vetssg/data/DCMIP_2016/nicam/publish/test3/nicam.163."+resol+".L40.interp_latlon.nonhydro.W.nc"
  correctLon=False
  w_data = addfile(w_data_file,"r")
  ; CMZ -- still need to interpolate since 5000 falls between two levels in output
  w_2500m = w_data->W(24,{2500.},:,:)
  w_2500m = lonFlip(w_2500m)
end if

if (model .eq. "ICON") then
  if (resol .eq. "r400") then
    timestep="300"
  else if (resol .eq. "r200") then
    timestep="300"
  else if (resol .eq. "r100") then
    timestep="240"
  else if (resol .eq. "r50") then
    timestep="120"
  else
    print("incorrect resol value")
    exit
  end if
  end if
  end if
  end if
  w_data_file = "/glade/p/vetssg/data/DCMIP_2016/icon/publish/icon.163."+resol+".L60.interp_latlon.nonhydro.dt"+timestep+"_default_diffusion.W.nc"
  correctLon=False
  w_data = addfile(w_data_file,"r")
  ; CMZ -- still need to interpolate since 5000 falls between two levels in output
  w = w_data->W(24,:,:,:)
  z_data_file = "/glade/p/vetssg/data/DCMIP_2016/icon/publish/icon.163."+resol+".L60.interp_latlon.nonhydro.dt"+timestep+"_default_diffusion.Z.nc"
  z_data = addfile(z_data_file,"r")
  zmid = z_data->Z(:,0,0)
  zint = new(dimsizes(zmid)+1,"float")
  zint(1:dimsizes(zmid))=zmid-250.
  zint(0) = 30000.0
  w&ilev=zint
  w_2500m = w({2500.0},:,:)
  ; CMZ needs to be interpolated
  w_2500m = lonFlip(w_2500m)
end if

if (model .eq. "DYNAMICO") then
  w_data_file = "/glade/p/vetssg/data/DCMIP_2016/dynamico/publish/dynamico.163.100km.L40.hex.hydro.supercell/dynamico.163.100km.L40.hex_interp_latlon.hydro.supercell.W.nc"
  qr_data_file = "/glade/p/vetssg/data/DCMIP_2016/dynamico/publish/dynamico.163.100km.L40.hex.hydro.supercell/dynamico.163.100km.L40.hex_interp_latlon.hydro.supercell.Qr.nc"
  correctLon=True
  conv_qr_units=True ; do we need to conv from kg/kg to g/kg?
  w_data = addfile(w_data_file,"r")
  qr_data = addfile(qr_data_file,"r")
  w = w_data->W((/5,11,17,23/),:,:,:)
  qr = qr_data->Qr((/5,11,17,23/),:,:,:)

  ; get pressure levels
  ps_data_file="/glade/p/vetssg/data/DCMIP_2016/dynamico/publish/dynamico.163.100km.L40.hex.hydro.supercell/dynamico.163.100km.L40.hex_interp_latlon.hydro.supercell.PS.nc"
  ps_data=addfile(ps_data_file,"r")
  ps = ps_data->PS((/5,11,17,23/),:,:)
  hyai_data_file="/glade/p/vetssg/data/DCMIP_2016/dynamico/publish/dynamico.163.100km.L40.hex.hydro.supercell/dynamico.163.100km.L40.hex_interp_latlon.hydro.supercell.hyai.nc"
  hybi_data_file="/glade/p/vetssg/data/DCMIP_2016/dynamico/publish/dynamico.163.100km.L40.hex.hydro.supercell/dynamico.163.100km.L40.hex_interp_latlon.hydro.supercell.hybi.nc"
  hyam_data_file="/glade/p/vetssg/data/DCMIP_2016/dynamico/publish/dynamico.163.100km.L40.hex.hydro.supercell/dynamico.163.100km.L40.hex_interp_latlon.hydro.supercell.hyam.nc"
  hybm_data_file="/glade/p/vetssg/data/DCMIP_2016/dynamico/publish/dynamico.163.100km.L40.hex.hydro.supercell/dynamico.163.100km.L40.hex_interp_latlon.hydro.supercell.hybm.nc"
  hyai_data=addfile(hyai_data_file,"r")
  hybi_data=addfile(hybi_data_file,"r")
  hyam_data=addfile(hyam_data_file,"r")
  hybm_data=addfile(hybm_data_file,"r")
  hyai = hyai_data->hyai
  hybi = hybi_data->hybi
  hyam = hyam_data->hyam
  hybm = hybm_data->hybm
;p $ _{(i,j,k) }$= A$ _{k}$P$ _{0}$+ B$ _{k}$P$ _{s}$(i,j)

;p(i,j,k)=hya(k)*P0+hyb(k)*PS(i,j) where P0=1000hPa
  exit
end if

print(max(w_2500m))

;****************************************************************************
; DO NOT EDIT BELOW THIS LINE
;****************************************************************************

if (correctLon) then
  loncorr=180.0
else
  loncorr=0.0
end if

;------------------------------------------------
; Workspace
;------------------------------------------------
  wks = gsn_open_wks("x11","plot_supercell_2.5km_wvel_xsec")   

  gsn_merge_colormaps(wks,"temp_diff_18lev","sunshine_9lev")

;------------------------------------------------
; Plot resources [options]
;------------------------------------------------
  plot = new(1,graphic)

; Resources:
  res                     = True

  res@gsnDraw             = False
  res@gsnFrame            = False

  res@vpKeepAspect        = True
  res@vpWidthF            = 0.5
  res@vpHeightF           = 0.6
  res@gsnMaximize         = True
  res@gsnPaperOrientation = "portrait"

  res@cnFillOn          = True
  res@cnLinesOn         = True
  res@cnLineLabelsOn    = False
  res@lbLabelAutoStride = True
  res@cnInfoLabelOn     = False

  res@trXMinF           = -45.0+loncorr
  res@trXMaxF           =  30.0+loncorr

  res@trYMinF           = -45.0
  res@trYMaxF           =  45.0

  res@tmXBLabelsOn      = True
  res@tmXBOn            = True

  res@tmXBMode          = "Explicit"
  res@tmXBValues        = (/-45,-30,-15,0,15,30/)
  res@tmXBLabels        = (/"45W","30W","15W","0","15E","30E"/)

  res@tmXBMinorOn       = True
  res@tmXBMinorValues   = (/-40,-35,-25,-20,-10,-5,5,10,20,25/)

  res@tmXTLabelsOn      = True
  res@tmXTOn            = True

  res@tmYLLabelsOn      = True
  res@tmYLOn            = True

  res@tmYLMode          = "Explicit"
  res@tmYLValues        = (/-45,-30,-15,0,15,30,45/)
  res@tmYLLabels        = (/"45S","30S","15S","0","15N","30N","45N"/)

  res@tmYLMinorOn       = True
  res@tmYLMinorValues   = (/-40,-35,-25,-20,-10,-5,5,10,20,25,35,40/)

  res@gsnSpreadColors = True

  res@gsnContourZeroLineThicknessF = 0.0
  res@gsnContourNegLineDashPattern = 1

  res@gsnSpreadColorStart = 7
  res@gsnSpreadColorEnd = 19
  res@cnLevelSelectionMode = "ManualLevels"
  res@cnLevelSpacingF = 1.0
  res@cnMinLevelValF = -10.0
  res@cnMaxLevelValF = 20.0

  res@tiMainString="2500m W - "+model+" - "+resol

  plot(0) = gsn_csm_contour(wks, w_2500m(:,:), res)

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

