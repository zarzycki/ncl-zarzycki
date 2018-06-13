;***********************************************
; plot_supercell_5km_xsec.ncl
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
;     w_5km(time, lon, lat)
;     2D vertical velocity field at 5km altitude (units m/s)
;
;   Output:
;     qr_5km(time, lon, lat)
;     2D rain water mixing ratio at 5km altitude (units g/kg)
;
;   Dimensions:
;     time:  4 elements at 30, 60, 90 and 120 minutes
;     lon:   arbitrary
;     lat:   arbitrary
;----------------------------------------------------------------------------

;model="FVM"
;resol="r50"
out_type="pdf"
cnFillOpt="raster"  ; raster or smooth

if (model .eq. "CSU_LZ" .or. model .eq. "CSU_CP") then
  if (resol .eq. "r50") then
    resol = "r050"
  end if
end if

modeltitle = model
if (model .eq. "ACME") then
  modeltitle = "ACME-A (E3SM)"
end if
if (model .eq. "CSU_LZ" .or. model .eq. "CSU_CP") then
  modeltitle = "CSU"
end if
if (model .eq. "FV3") then
  modeltitle = "FV~S~3~N~"
end if

if (model .eq. "TEMPEST") then
  w_data_file = "/glade/p/vetssg/data/DCMIP_2016/tempest/publish/tempest.163."+resol+".L40.interp_latlon.nonhydro.W.nc"
  qr_data_file = "/glade/p/vetssg/data/DCMIP_2016/tempest/publish/tempest.163."+resol+".L40.interp_latlon.nonhydro.Qr.nc"
  correctLon=False
  conv_qr_units=True ; do we need to conv from kg/kg to g/kg?
  w_data = addfile(w_data_file,"r")
  qr_data = addfile(qr_data_file,"r")
  w_5km = w_data->W((/6,12,18,24/),{5000.},:,:)
  qr_5km = qr_data->Qr((/6,12,18,24/),{5000.},:,:)
end if

if (model .eq. "FVM") then
  w_data_file = "/glade/scratch/zarzycki/FVM_DCMIP_163_DATA/fvm.163."+resol+".L41.nonhydro.interp_latlon.W.nc"
  qr_data_file = "/glade/scratch/zarzycki/FVM_DCMIP_163_DATA/fvm.163."+resol+".L41.nonhydro.interp_latlon.QR.nc"
  correctLon=True
  conv_qr_units=True ; do we need to conv from kg/kg to g/kg?
  w_data = addfile(w_data_file,"r")
  qr_data = addfile(qr_data_file,"r")
  lev=w_data->lev(:)
  print(lev)   ;5000 is the 10th index
  w_5km = w_data->W((/6,12,18,24/),10,:,:)
  qr_5km = qr_data->QR((/6,12,18,24/),10,:,:)
end if

if (model .eq. "FVM_OLD") then
  w_data_file = "/glade/p/vetssg/data/DCMIP_2016/fvm/publish/fvm.163."+resol+".L41.nonhydro.interp_latlon.W.nc"
  qr_data_file = "/glade/p/vetssg/data/DCMIP_2016/fvm/publish/fvm.163."+resol+".L41.nonhydro.interp_latlon.QR.nc"
  correctLon=True
  conv_qr_units=True ; do we need to conv from kg/kg to g/kg?
  w_data = addfile(w_data_file,"r")
  qr_data = addfile(qr_data_file,"r")
  lev=w_data->lev(:)
  print(lev)   ;5000 is the 10th index
  w_5km = w_data->W((/6,12,18,24/),10,:,:)
  qr_5km = qr_data->QR((/6,12,18,24/),10,:,:)
end if

if (model .eq. "MPAS") then
  w_data_file  = "/glade/p/vetssg/data/DCMIP_2016/mpas/publish/mpas.163."+resol+".L40.latlon.nonhydro.nc"
  qr_data_file = "/glade/p/vetssg/data/DCMIP_2016/mpas/publish/mpas.163."+resol+".L40.latlon.nonhydro.nc"
  correctLon=False
  conv_qr_units=True ; do we need to conv from kg/kg to g/kg?
  w_data = addfile(w_data_file,"r")
  qr_data = addfile(qr_data_file,"r")
  lev=w_data->Z(:,0,0)
  print(lev)   ;5000 is the 10th index
  w_5km = w_data->W((/6,12,18,24/),10,:,:)
  qr_5km = qr_data->QR((/6,12,18,24/),10,:,:)
  w_5km = lonFlip(w_5km)
  qr_5km = lonFlip(qr_5km)
end if

if (model .eq. "CSU_CP") then
  w_data_file  = "/glade/p/vetssg/data/DCMIP_2016/csu/publish/csu_CP/csu.163."+resol+".L40.interp_latlon.nonhydro.CP_default.W5.nc"
  qr_data_file = "/glade/p/vetssg/data/DCMIP_2016/csu/publish/csu_CP/csu.163."+resol+".L40.interp_latlon.nonhydro.CP_default.QR5.nc"
  correctLon=False
  conv_qr_units=True ; do we need to conv from kg/kg to g/kg?
  w_data = addfile(w_data_file,"r")
  qr_data = addfile(qr_data_file,"r")
  w_5km = w_data->W5((/6,12,18,24/),:,:)
  qr_5km = qr_data->QR5((/6,12,18,24/),:,:)
  ;w_5km = lonFlip(w_5km)
  ;qr_5km = lonFlip(qr_5km)
end if

if (model .eq. "CSU_LZ") then
  w_data_file  = "/glade/p/vetssg/data/DCMIP_2016/csu/publish/csu_LZ/csu.163."+resol+".L40.interp_latlon.nonhydro.LZ_default.W5.nc"
  qr_data_file = "/glade/p/vetssg/data/DCMIP_2016/csu/publish/csu_LZ/csu.163."+resol+".L40.interp_latlon.nonhydro.LZ_default.QR5.nc"
  correctLon=False
  conv_qr_units=True ; do we need to conv from kg/kg to g/kg?
  w_data = addfile(w_data_file,"r")
  qr_data = addfile(qr_data_file,"r")
  w_5km = w_data->W5((/6,12,18,24/),:,:)
  qr_5km = qr_data->QR5((/6,12,18,24/),:,:)
  ;w_5km = lonFlip(w_5km)
  ;qr_5km = lonFlip(qr_5km)
end if

if (model .eq. "ACME") then
  w_data_file  = "/glade/p/vetssg/data/DCMIP_2016/acme-a/publish/acme.163."+resol+".L40.interp_latlon.nonhydro.W.nc"
  qr_data_file = "/glade/p/vetssg/data/DCMIP_2016/acme-a/publish/acme.163."+resol+".L40.interp_latlon.nonhydro.Qr.nc"
  z_data_file =  "/glade/p/vetssg/data/DCMIP_2016/acme-a/publish/acme.163."+resol+".L40.interp_latlon.nonhydro.Geopotential.nc"

  correctLon=False
  conv_qr_units=True ; do we need to conv from kg/kg to g/kg?

  w_data = addfile(w_data_file,"r")
  qr_data = addfile(qr_data_file,"r")
  z_data = addfile(z_data_file,"r")

  w = w_data->W((/6,12,18,24/),::-1,:,:)
  qr = qr_data->Q3((/6,12,18,24/),::-1,:,:)
  z = z_data->geo((/6,12,18,24/),::-1,:,:)/9.80616

  w_interp = linint1_n_Wrap(z,w, False,5000.0,0,1)
  w_5km    = w_interp(:,0,:,:)

  qr_interp= linint1_n_Wrap(z,qr,False,5000.0,0,1)
  qr_5km   = qr_interp(:,0,:,:)

end if

if (model .eq. "GEM") then
  w_data_file = "/glade/p/vetssg/data/DCMIP_2016/gem/publish/Test163_"+resol+"/gem.163."+resol+".L40.interp_latlon.nonhydro.del2.w.nc"
  qr_data_file = "/glade/p/vetssg/data/DCMIP_2016/gem/publish/Test163_"+resol+"/gem.163."+resol+".L40.interp_latlon.nonhydro.del2.qr.nc"
  correctLon=True
  conv_qr_units=True ; do we need to conv from kg/kg to g/kg?
  w_data = addfile(w_data_file,"r")
  qr_data = addfile(qr_data_file,"r")

  ; CMZ -- need to interp to Z surfaces
  w_pres = w_data->W((/6,12,18,24/),:,:,:)
  qr_pres = qr_data->Qr((/6,12,18,24/),:,:,:)

  q_data_file = "/glade/p/vetssg/data/DCMIP_2016/gem/publish/Test163_"+resol+"/gem.163."+resol+".L40.interp_latlon.nonhydro.del2.q.nc"
  t_data_file = "/glade/p/vetssg/data/DCMIP_2016/gem/publish/Test163_"+resol+"/gem.163."+resol+".L40.interp_latlon.nonhydro.del2.t.nc"
  ps_data_file = "/glade/p/vetssg/data/DCMIP_2016/gem/publish/Test163_"+resol+"/gem.163."+resol+".L40.interp_latlon.nonhydro.del2.ps.nc" 
  ps_data = addfile(ps_data_file,"r")
  q_data = addfile(q_data_file,"r")
  t_data = addfile(t_data_file,"r")
  ps1 = ps_data->PS((/6,12,18,24/),:,:)
  t_pres = t_data->T((/6,12,18,24/),:,:,:)
  q_pres = q_data->Q((/6,12,18,24/),:,:,:)
  lat=w_data->lat
  lon=w_data->lon
  hyai=w_data->hyai
  hybi=w_data->hybi
  hyam=w_data->hyam
  hybm=w_data->hybm
  P0=w_data->P0
  ps_P0 = ps1
  ps_P0 = 100000.
  ilev = exp(hyai + hybi*log(100000./P0))
  print(ilev)

  TV=t_pres*(1.+0.61*(q_pres))
  PHIS=ps1
  PHIS=0.0

  pres_m=w_pres
  pres_m=0.0
  Z_m=w_pres
  Z_m=0.0
  printVarSummary(pres_m)

  do tt=0,3
    do ii = 0,dimsizes(lat)-1
      do jj = 0,dimsizes(lon)-1
        pres_m(tt,:,ii,jj)=tofloat(exp(hyai + hybi*log(ps1(tt,ii,jj)/P0)))
        Z_m(tt,:,ii,jj)=hydro(pres_m(tt,::-1,ii,jj),TV(tt,::-1,ii,jj),0.0)
      end do
    end do
  end do

  print(Z_m(0,:,0,0)+" "+pres_m(0,:,0,0))

  Z_m@units="m"
  Zlev = (/5000./)
  Zlev@units = "m"
  Zlev!0     = "Zlev"
  Zlev&Zlev = Zlev
  ;print(Z(0,:,0,0))

  interp_type=1
  w_5km_int  = int2p_n_Wrap(Z_m,w_pres(:,::-1,:,:),Zlev,interp_type,1)
  qr_5km_int = int2p_n_Wrap(Z_m,qr_pres(:,::-1,:,:),Zlev,interp_type,1)
  printVarSummary(w_5km_int)

  ;w_5km  =  w_pres(:,{500.0},:,:)
  ;qr_5km = qr_pres(:,{500.0},:,:)
  w_5km  =  w_5km_int(:,{5000.0},:,:)
  qr_5km = qr_5km_int(:,{5000.0},:,:)
end if

if (model .eq. "OLAM") then
  correctLon=False
  conv_qr_units=True ; do we need to conv from kg/kg to g/kg?
  time_str_arr=(/"005000","010000","015000","020000"/)
  do kk=0,3
    w_data_file  = "/glade/p/vetssg/data/DCMIP_2016/olam/publish/case131_"+resol+"/dcmip131_"+resol+"-DLL-2000-01-01-"+time_str_arr(kk)+".h5"
    qr_data_file = "/glade/p/vetssg/data/DCMIP_2016/olam/publish/case131_"+resol+"/dcmip131_"+resol+"-DLL-2000-01-01-"+time_str_arr(kk)+".h5"
    z_data = addfile(w_data_file,"r")
    w_data = addfile(w_data_file,"r")
    qr_data = addfile(qr_data_file,"r")

    lat = z_data->lat
    lon = z_data->lon
    z = z_data->z
    w = w_data->W(9:10,:,:)
    qr = qr_data->Qr(9:10,:,:)

    w_5km_single=w(0,:,:)
    qr_5km_single=qr(0,:,:)

    w_5km_single =( w(0,:,:)  +  w(1,:,:))/2.
    qr_5km_single=( qr(0,:,:) + qr(1,:,:))/2.

    ; need to init arrays
    if (kk .eq. 0) then  
      w_5km = new((/4,dimsizes(lat),dimsizes(lon)/),typeof(w_5km_single))
      w_5km!0="time"
      w_5km!1="lat"
      w_5km!2="lon"
      w_5km&lat=lat
      w_5km&lon=lon
      qr_5km=w_5km
    end if
    w_5km(kk,:,:)=w_5km_single
    qr_5km(kk,:,:)=qr_5km_single
  end do
  print("min 5km w: "+min(w_5km))
  print("max 5km w: "+max(w_5km))
  print("min 5km qr: "+min(qr_5km))
  print("max 5km qr: "+max(qr_5km))
  delete(lat)
  delete(lon)
  delete(z)
  delete(w)
  delete(qr)
  delete(w_5km_single)
  delete(qr_5km_single)
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
  w_data_file = "/glade/p/vetssg/data/DCMIP_2016/fv3/publish/release_v1.2_DCMIP/SUPERCELL."+resolkm+".64bit.cstdz.lvl40."+resolkm+"/rundir/fv3.163."+resol+".L24.cubed.nonhydro.cstdz.lvl40."+resolkm+".w5km.nc"
  qr_data_file = "/glade/p/vetssg/data/DCMIP_2016/fv3/publish/release_v1.2_DCMIP/SUPERCELL."+resolkm+".64bit.cstdz.lvl40."+resolkm+"/rundir/fv3.163."+resol+".L24.cubed.nonhydro.cstdz.lvl40."+resolkm+".rain5km.nc"
  correctLon=True
  conv_qr_units=True ; do we need to conv from kg/kg to g/kg?
  w_data = addfile(w_data_file,"r")
  qr_data = addfile(qr_data_file,"r")
  w_5km = w_data->w5km((/5,11,17,23/),:,:)
  qr_5km = qr_data->rain5km((/5,11,17,23/),:,:)
end if

if (model .eq. "NICAM") then
  w_data_file = "/glade/p/vetssg/data/DCMIP_2016/nicam/publish/test3/nicam.163."+resol+".L40.interp_latlon.nonhydro.W.nc"
  qr_data_file = "/glade/p/vetssg/data/DCMIP_2016/nicam/publish/test3/nicam.163."+resol+".L40.interp_latlon.nonhydro.Qr.nc"
  correctLon=False
  conv_qr_units=True ; do we need to conv from kg/kg to g/kg?
  w_data = addfile(w_data_file,"r")
  qr_data = addfile(qr_data_file,"r")

  w_full=w_data->W((/6,12,18,24/),:,:,:)
  qr_full=qr_data->Qr((/6,12,18,24/),:,:,:)

  ; Direct indexing (preinterpolation for AGU, etc.)
  ;w_5km = w_data->W((/6,12,18,24/),{5000.},:,:)
  ;qr_5km = qr_data->Qr((/6,12,18,24/),{5000.},:,:)

  ; Straight linear interpolation to test int2p_n_Wrap use with Z/linear
  ;w_5km_meta = w_data->W((/6,12,18,24/),{5000.},:,:)
  ;qr_5km_meta = qr_data->Qr((/6,12,18,24/),{5000.},:,:)
  ;lev (9)	4750
  ;lev (10)	5250
  ;w_5km=(w_full(:,9,:,:)+w_full(:,10,:,:)) / 2.
  ;qr_5km=(qr_full(:,9,:,:)+qr_full(:,10,:,:)) / 2.
  ;copy_VarMeta(w_5km_meta,w_5km)
  ;copy_VarMeta(qr_5km_meta,qr_5km)

  ; Vertically interpolate levels to 5km
  Z_m = w_full&lev
  Z_m@units="m"
  print(Z_m)
  Zlev = (/5000./)
  Zlev@units = "m"
  Zlev!0     = "Zlev"
  Zlev&Zlev = Zlev
  interp_type=1
  w_5km_int  = int2p_n_Wrap(Z_m,w_full,Zlev,interp_type,1)
  qr_5km_int = int2p_n_Wrap(Z_m,qr_full,Zlev,interp_type,1)
  w_5km=w_5km_int(:,{5000.},:,:)
  qr_5km=qr_5km_int(:,{5000.},:,:)
  
  w_5km = lonFlip(w_5km)
  qr_5km = lonFlip(qr_5km)
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
  qr_data_file = "/glade/p/vetssg/data/DCMIP_2016/icon/publish/icon.163."+resol+".L60.interp_latlon.nonhydro.dt"+timestep+"_default_diffusion.Qr.nc"
  correctLon=False
  conv_qr_units=False ; do we need to conv from kg/kg to g/kg?
  w_data = addfile(w_data_file,"r")
  qr_data = addfile(qr_data_file,"r")
  w = w_data->W((/6,12,18,24/),:,:,:)
  qr = qr_data->Qr((/6,12,18,24/),:,:,:)
  z_data_file = "/glade/p/vetssg/data/DCMIP_2016/icon/publish/icon.163."+resol+".L60.interp_latlon.nonhydro.dt"+timestep+"_default_diffusion.Z.nc"
  z_data = addfile(z_data_file,"r")
  zmid = z_data->Z(:,0,0)
  zint = new(dimsizes(zmid)+1,"float")
  zint(1:dimsizes(zmid))=zmid-250.
  zint(0) = 30000.0
  w&ilev=zint
  w_5km = w(:,{5000.0},:,:)
  qr_5km = w(:,{5000.0},:,:)
  w_5km = lonFlip(w_5km)
  qr_5km = lonFlip(qr_5km)
end if

if (model .eq. "DYNAMICO") then
  w_data_file = "/glade/p/vetssg/data/DCMIP_2016/dynamico/publish/dynamico.163.100km.L40.hex.hydro.supercell/dynamico.163.100km.L40.hex_interp_latlon.hydro.supercell.W.nc"
  qr_data_file = "/glade/p/vetssg/data/DCMIP_2016/dynamico/publish/dynamico.163.100km.L40.hex.hydro.supercell/dynamico.163.100km.L40.hex_interp_latlon.hydro.supercell.Qr.nc"
  correctLon=True
  conv_qr_units=True ; do we need to conv from kg/kg to g/kg?
  w_data = addfile(w_data_file,"r")
  qr_data = addfile(qr_data_file,"r")
  w_pres = w_data->W((/5,11,17,23/),:,:,:)
  qr_pres = qr_data->Qr((/5,11,17,23/),:,:,:)

  ; get pressure levels
  ps_data_file="/glade/p/vetssg/data/DCMIP_2016/dynamico/publish/dynamico.163.100km.L40.hex.hydro.supercell/dynamico.163.100km.L40.hex_interp_latlon.hydro.supercell.PS.nc"
  ps_data=addfile(ps_data_file,"r")
  ps = ps_data->PS((/5,11,17,23/),:,:)
  lat = ps_data->lat
  lon = ps_data->lon
  nlat = dimsizes(lat)
  nlon = dimsizes(lon)
  ntimes = 4
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

  print(hyam)
  print(hybm)

  t_data_file="/glade/p/vetssg/data/DCMIP_2016/dynamico/publish/dynamico.163.100km.L40.hex.hydro.supercell/dynamico.163.100km.L40.hex_interp_latlon.hydro.supercell.T.nc"
  q_data_file="/glade/p/vetssg/data/DCMIP_2016/dynamico/publish/dynamico.163.100km.L40.hex.hydro.supercell/dynamico.163.100km.L40.hex_interp_latlon.hydro.supercell.Q.nc"
  t_data = addfile(t_data_file,"r")
  q_data = addfile(q_data_file,"r")
  t_pres = t_data->T((/5,11,17,23/),:,:,:)
  q_pres = q_data->Q((/5,11,17,23/),:,:,:)

  TV=t_pres*(1.+0.61*(q_pres))
  P0=1000.0
  pres_m = w_pres
  Z_m = w_pres
  do ii = 0,nlat-1
  do jj = 0,nlon-1
  do zz = 0,ntimes-1
  pres_m(zz,:,ii,jj) = hyam(:) + hybm(:)*ps(zz,ii,jj)
  Z_m(zz,:,ii,jj)=hydro(pres_m(zz,:,ii,jj),TV(zz,:,ii,jj),0.0)
  end do
  end do
  end do

  printVarSummary(pres_m)
;p $ _{(i,j,k) }$= A$ _{k}$P$ _{0}$+ B$ _{k}$P$ _{s}$(i,j)
;p(i,j,k)=hya(k)*P0+hyb(k)*PS(i,j) where P0=1000hPa
  print(Z_m(0,:,0,0)+" "+pres_m(0,:,0,0)+" "+t_pres(0,:,0,0))

  Z_m@units="m"
  Zlev = (/5000./)
  Zlev@units = "m"
  Zlev!0     = "Zlev"
  Zlev&Zlev = Zlev
  ;print(Z(0,:,0,0))

  interp_type=1
  w_5km_int  = int2p_n_Wrap(Z_m,w_pres(:,:,:,:),Zlev,interp_type,1)
  qr_5km_int = int2p_n_Wrap(Z_m,qr_pres(:,:,:,:),Zlev,interp_type,1)
  printVarSummary(w_5km_int)

  ;w_5km  =  w_pres(:,{500.0},:,:)
  ;qr_5km = qr_pres(:,{500.0},:,:)
  w_5km  =  w_5km_int(:,{5000.0},:,:)
  qr_5km = qr_5km_int(:,{5000.0},:,:)
  print(max(qr_5km))
  print(max(w_5km))
  ;w_5km = lonFlip(w_5km)
  ;qr_5km = lonFlip(qr_5km)
  exit
end if



if (model .eq. "CAMSE") then
  w_data_file = "/glade/u/home/zarzycki/scratch/cam5_work/dcmip3/1e8.nc"
  qr_data_file = w_data_file
  correctLon=False
  conv_qr_units=True ; do we need to conv from kg/kg to g/kg?
  w_data = addfile(w_data_file,"r")
  qr_data = addfile(qr_data_file,"r")
  omega_pres = w_data->OMEGA((/3,6,9,12/),:,:,:)
  qr_pres = qr_data->CLDICE((/3,6,9,12/),:,:,:)

  ; get pressure levels
  ps_data_file= w_data_file
  ps_data=addfile(ps_data_file,"r")
  ps = ps_data->PS((/3,6,9,12/),:,:)
  lat = ps_data->lat
  lon = ps_data->lon
  nlat = dimsizes(lat)
  nlon = dimsizes(lon)
  ntimes = 4
  hyai_data_file= w_data_file
  hybi_data_file=w_data_file
  hyam_data_file=w_data_file
  hybm_data_file=w_data_file
  hyai_data=addfile(hyai_data_file,"r")
  hybi_data=addfile(hybi_data_file,"r")
  hyam_data=addfile(hyam_data_file,"r")
  hybm_data=addfile(hybm_data_file,"r")
  hyai = tofloat(hyai_data->hyai)
  hybi = tofloat(hybi_data->hybi)
  hyam = tofloat(hyam_data->hyam)
  hybm = tofloat(hybm_data->hybm)

  t_data_file=w_data_file
  q_data_file=w_data_file
  z_data_file=w_data_file

  t_data = addfile(t_data_file,"r")
  q_data = addfile(q_data_file,"r")
  z_data = addfile(z_data_file,"r")

  t_pres = t_data->T((/3,6,9,12/),:,:,:)
  q_pres = q_data->Q((/3,6,9,12/),:,:,:)
  z_pres = z_data->Z3((/3,6,9,12/),:,:,:)

  TV=t_pres*(1.+0.61*(q_pres))
  P0=100000.
  pres_m = omega_pres

  Z_m = omega_pres
  do ii = 0,nlat-1
  do jj = 0,nlon-1
  do zz = 0,ntimes-1
  pres_m(zz,:,ii,jj) = hyam(:)*P0 + hybm(:)*ps(zz,ii,jj)
  Z_m(zz,::-1,ii,jj)=hydro(pres_m(zz,::-1,ii,jj),TV(zz,::-1,ii,jj),z_pres(zz,59,ii,jj))
  end do
  end do
  end do

  print(Z_m(0,:,0,0)+" "+pres_m(0,:,0,0)+" "+t_pres(0,:,0,0))

; need to convert omega to w

  w_pres = omega_to_w(omega_pres,pres_m,t_pres)

  Z_m@units="m"
  Zlev = (/5000./)
  Zlev@units = "m"
  Zlev!0     = "Zlev"
  Zlev&Zlev = Zlev
  ;print(Z(0,:,0,0))

  interp_type=1
  w_5km_int  = int2p_n_Wrap(Z_m,w_pres(:,:,:,:),Zlev,interp_type,1)
  qr_5km_int = int2p_n_Wrap(Z_m,qr_pres(:,:,:,:),Zlev,interp_type,1)
  printVarSummary(w_5km_int)

  ;w_5km  =  w_pres(:,{500.0},:,:)
  ;qr_5km = qr_pres(:,{500.0},:,:)
  w_5km  =  w_5km_int(:,{5000.0},:,:)
  qr_5km = qr_5km_int(:,{5000.0},:,:)
  print("max qr_5km "+max(qr_5km))
  print("max w_5km "+max(w_5km))
  w_5km = lonFlip(w_5km)
  qr_5km = lonFlip(qr_5km)
end if


print(w_data_file)
print(qr_data_file)

printVarSummary(w_5km)
printVarSummary(qr_5km)
;****************************************************************************
; DO NOT EDIT BELOW THIS LINE
;****************************************************************************

if (conv_qr_units) then
  qr_5km = qr_5km*1000.
end if

if (correctLon) then
  loncorr=180.0
else
  loncorr=0.0
end if

;------------------------------------------------
; Workspace
;------------------------------------------------
  wks = gsn_open_wks(out_type,"pdfs/5km_"+model+"."+resol)   

  gsn_merge_colormaps(wks,"temp_diff_18lev","sunshine_9lev")

;------------------------------------------------
; Plot resources [options]
;------------------------------------------------
  plot = new(2,graphic)
  wplot = new(3,graphic)
  qrplot = new(3,graphic)

; Resources:
  res                     = True

  res@gsnDraw             = False
  res@gsnFrame            = False

  res@vpKeepAspect        = True
  res@vpWidthF            = 0.3
  res@vpHeightF           = 0.6
  res@gsnSpreadColors     = True
;  res@gsnMaximize         = True
  res@gsnPaperOrientation = "landscape"


  res@cnFillOn          = True

  res@cnLineLabelsOn    = False
  res@lbLabelAutoStride = True
  res@cnInfoLabelOn     = False
  res@tmXBLabelsOn      = True
  res@tmXBOn            = True

  if (cnFillOpt .eq. "raster") then
    res@cnFillMode = "RasterFill"
    res@cnLinesOn         = False
  else
    res@cnLinesOn         = True
  end if

  res@tmXTLabelsOn      = False
  res@tmXTOn            = False
; turn off ticks on bottom
  res@tmXBLabelsOn      = False
  res@tmXBOn            = False

  res@tmXBLabelFontHeightF = 0.03
  res@tmYLLabelFontHeightF = res@tmXBLabelFontHeightF

  res@gsnSpreadColors = True

  res@lbLabelFontHeightF = 0.03
  res@lbOrientation = "vertical"

  res@gsnLeftString=""
  res@gsnRightString=""

  res@trYMinF = -45.0
  res@trYMaxF =  45.0

  res@gsnContourZeroLineThicknessF = 0.0
  res@gsnContourNegLineDashPattern = 1

;  res@lbLabelBarOn = False
  res@tmYLLabelsOn = True

  resw = res
  resw@gsnSpreadColorStart = 8
  resw@gsnSpreadColorEnd = 19
  resw@cnLevelSelectionMode = "ManualLevels"
  resw@cnLevelSpacingF = 2.0
  resw@cnMinLevelValF = -8.0
  resw@cnMaxLevelValF = 24.0

  resqr = res
  resqr@gsnSpreadColorStart = 21
  resqr@gsnSpreadColorEnd = 30
  resqr@cnLevelSelectionMode = "ManualLevels"
  resqr@cnLevelSpacingF = 1.0
  resqr@cnMinLevelValF = 2.0
  resqr@cnMaxLevelValF = 14.0

;------------------------------------------------
; Vertical velocity plots
;------------------------------------------------

  resw@trXMinF = -25.0+loncorr
  resw@trXMaxF =  25.0+loncorr
  plot(0) = gsn_csm_contour(wks, w_5km(0,:,:), resw)

  resw@trXMinF = -25.0+loncorr
  resw@trXMaxF =  25.0+loncorr
  wplot(0) = gsn_csm_contour(wks, w_5km(1,:,:), resw)

  resw@trXMinF = -20.0+loncorr
  resw@trXMaxF =  30.0+loncorr
  wplot(1) = gsn_csm_contour(wks, w_5km(2,:,:), resw)

  resw@trXMinF = -20.0+loncorr
  resw@trXMaxF =  30.0+loncorr
  wplot(2) = gsn_csm_contour(wks, w_5km(3,:,:), resw)

  mergedw = gsn_attach_plots(plot(0), (/wplot(0),wplot(1),wplot(2)/), False, False)

;------------------------------------------------
; Rain water plots
;------------------------------------------------

  resqr@trXMinF = -25.0+loncorr
  resqr@trXMaxF =  25.0+loncorr
  plot(1) = gsn_csm_contour(wks, qr_5km(0,:,:), resqr)

  resqr@trXMinF = -25.0+loncorr
  resqr@trXMaxF =  25.0+loncorr
  qrplot(0) = gsn_csm_contour(wks, qr_5km(1,:,:), resqr)

  resqr@trXMinF = -20.0+loncorr
  resqr@trXMaxF =  30.0+loncorr
  qrplot(1) = gsn_csm_contour(wks, qr_5km(2,:,:), resqr)

  resqr@trXMinF = -20.0+loncorr
  resqr@trXMaxF =  30.0+loncorr
  qrplot(2) = gsn_csm_contour(wks, qr_5km(3,:,:), resqr)

  mergedqr = gsn_attach_plots(plot(1), (/qrplot(0),qrplot(1),qrplot(2)/), False, False)

;------------------------------------------------
; Panel plot
;------------------------------------------------

  pres = True
  pres@gsnPanelBottom = 0.2
  pres@gsnPanelTop = 0.8
  ;pres@gsnPanelYWhiteSpacePercent = 5
  ;pres@gsnPanelXWhiteSpacePercent = 5
  pres@gsnPanelMainString           = modeltitle+""    ; use this for NCL V6.3.0 and earlier
  pres@gsnPanelMainFontHeightF = .03

  gsn_panel(wks, plot, (/2,1/), pres)

end

