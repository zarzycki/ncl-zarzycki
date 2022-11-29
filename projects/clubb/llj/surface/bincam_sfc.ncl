;   Example script to produce plots for a WRF real-data run,
;   with the ARW coordinate dynamics option.
;   Interpolating to specified pressure levels

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "/glade/u/home/ckruse/git/ncl/kruse.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"

begin


;for i in $(seq 2010 2018); do ncl bincam_sfc.ncl in_yyyy=${i}; done

  ;cmzconfig="x005"
  ;cmzyyyy="2011"
  cmzyyyy=tostring(in_yyyy)
  
  setfileoption("nc","Format","LargeFile")

  nt = 24*2
  tlin = fspan(0,23,24) + 0.5

  ; start with cam data

  datadir = "/glade/u/home/zarzycki/scratch/FHIST-ne30-betacast-ERA5-"+cmzconfig+"/run/"+cmzyyyy+"061600/"
  allfiles = systemfunc("ls "+datadir+"*.cam.h4.????-0[7]*.nc")
  print(allfiles)

  files = allfiles
  nf = dimsizes(files)
  a = addfiles(files,"r")
  
  v = new((/nf,nt/),double)
  sh = new((/nf,nt/),double)
  lh = new((/nf,nt/),double)
  k = new((/nf,nt/),double)

  
  VVAR="V_97.49w_36.61n"
  SHVAR="SHFLX_97.49w_36.61n"
  LHVAR="LHFLX_97.49w_36.61n"
  TXVAR="TAUX_97.49w_36.61n"
  TYVAR="TAUY_97.49w_36.61n"
  
  do fi=0,nf-1
    v(fi,:) = a[fi]->$VVAR$(:,0,0)
    sh(fi,:) = a[fi]->$SHVAR$(:,0)
    lh(fi,:) = a[fi]->$LHVAR$(:,0)

    tmp1 = a[fi]->$TXVAR$(:,0)
    tmp2 = a[fi]->$TYVAR$(:,0)
    k(fi,:) = sqrt(tmp1^2. + tmp2^2.)
    delete(tmp1)
    delete(tmp2)
    
  end do
  print("Files read in")

  stinds = ispan(0,23,1)*2
  spinds = stinds+1

  vdavg = dim_avg_n(v,0)
  vf = 0.5*(vdavg(stinds) + vdavg(spinds))

  shdavg = dim_avg_n(sh,0)
  shf = 0.5*(shdavg(stinds) + shdavg(spinds))

  lhdavg = dim_avg_n(lh,0)
  lhf = 0.5*(lhdavg(stinds) + lhdavg(spinds))
 
  kdavg = dim_avg_n(k,0)
  kf = 0.5*(kdavg(stinds) + kdavg(spinds))

  outfname=cmzconfig+"_"+cmzyyyy+".nc"
  system("/bin/rm -f "+outfname)
  ncdf = addfile(outfname,"c")
  print(outfname+" file created")
  ;filedimdef(ncdf,"Time",-1,True)

  tlin!0 = "Time"
  tlin&Time = tlin
  tlin@long_name = "Time of Day"
  tlin@units     = "hr"


  ncdf->Time = tlin

  vf!0 = "Time"
  vf&Time = tlin
  vf@long_name = "Diurnal-Avg Meridional Wind"
  vf@units     = "m s-1"
  ncdf->VBOT = vf

  copy_VarMeta(vf,shf)
  ncdf->SHFLX = shf

  copy_VarMeta(vf,lhf)
  ncdf->LHFLX = lhf

  copy_VarMeta(vf,kf)
  ncdf->TAU = kf
  
  thf = shf
  thf = shf + lhf
  ncdf->THFLX = thf

  exit
  
 wks   = gsn_open_wks ("x11","xy")               ; send graphics to PNG file

 res                  = True                     ; plot mods desired
 res@tiMainString     = "Basic XY plot"          ; add title

 plot  = gsn_csm_xy (wks,tlin,kf,res) ; create plot
end
