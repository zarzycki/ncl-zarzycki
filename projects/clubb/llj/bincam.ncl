;   Example script to produce plots for a WRF real-data run,
;   with the ARW coordinate dynamics option.
;   Interpolating to specified pressure levels

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "/glade/u/home/ckruse/git/ncl/kruse.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"

begin


;for i in $(seq 2010 2018); do ncl bincam.ncl in_yyyy=${i}; done

  cmzconfig="x013"
  ;cmzyyyy="2011"
  cmzyyyy=tostring(in_yyyy)
  
  setfileoption("nc","Format","LargeFile")

  dz = 100
  zmax = 2500
  zmin = 100
  nz =  (zmax-zmin)/dz + 1
  zlin = fspan(zmin,zmax,nz)

  nt = 24*2
  tlin = fspan(0,23,24) + 0.5

  ; start with cam data

  datadir = "/glade/u/home/zarzycki/scratch/FHIST-ne30-betacast-ERA5-"+cmzconfig+"/run/"+cmzyyyy+"061600/"
  allfiles = systemfunc("ls "+datadir+"*.cam.h4.????-0[7]*.nc")
  print(allfiles)

  files = allfiles
  nf = dimsizes(files)
  a = addfiles(files,"r")
  


  v = new((/nf,nt,32/),double)
  u = new((/nf,nt,32/),double)
  theta = new((/nf,nt,32/),double)
  z = new((/nf,nt,32/),double)
      
  UVAR="U_97.49w_36.61n"
  VVAR="V_97.49w_36.61n"
  ZVAR="Z3_97.49w_36.61n"
  THETAVAR="vpwp_97.49w_36.61n"
  PHISVAR="PHIS_97.49w_36.61n"
  
  do fi=0,nf-1
    u(fi,:,:) = a[fi]->$UVAR$(:,::-1,0)
    v(fi,:,:) = a[fi]->$VVAR$(:,::-1,0)
    theta(fi,:,:) = a[fi]->$THETAVAR$(:,1:32:-1,0)
    z(fi,:,:) = a[fi]->$ZVAR$(:,::-1,0)
  end do
  print("Files read in")

  thgt = a[0]->$PHISVAR$(0,0)/9.81

  z = z-thgt ; now in agl

  stinds = ispan(0,23,1)*2
  spinds = stinds+1

  udavg = dim_avg_n(u,0)
  vdavg = dim_avg_n(v,0)
  thetadavg = dim_avg_n(theta,0)
  zdavg = dim_avg_n(z,0)

  udhavg = 0.5*(udavg(stinds,:) + udavg(spinds,:))
  vdhavg = 0.5*(vdavg(stinds,:) + vdavg(spinds,:))
  thetadhavg = 0.5*(thetadavg(stinds,:) + thetadavg(spinds,:))
  zdhavg = 0.5*(zdavg(stinds,:) + zdavg(spinds,:))

  uf = linint1_n(zdhavg,udhavg,False,zlin,0,1)
  vf = linint1_n(zdhavg,vdhavg,False,zlin,0,1)
  thetaf = linint1_n(zdhavg,thetadhavg,False,zlin,0,1)

  print(tlin)

  outfname=cmzconfig+"_"+cmzyyyy+".nc"
  system("/bin/rm -f "+outfname)
  ncdf = addfile(outfname,"c")
  print(outfname+" file created")
  ;filedimdef(ncdf,"Time",-1,True)

  tlin!0 = "Time"
  tlin&Time = tlin
  tlin@long_name = "Time of Day"
  tlin@units     = "hr"

  zlin!0 = "z"
  zlin&z = zlin
  zlin@long_name = "Height"
  zlin@units = "m"

  ncdf->Time = tlin
  ncdf->z = zlin

  vf!1 = "z"
  vf!0 = "Time"
  vf&z = zlin
  vf&Time = tlin
  vf@long_name = "Diurnal-Avg Meridional Wind"
  vf@units     = "m s-1"
  ncdf->v = vf(z|:,Time|:)

  copy_VarMeta(vf,uf)
  uf@long_name = "Diurnal-Avg Zonal Wind"
  ncdf->u = uf(z|:,Time|:)

  copy_VarMeta(vf,thetaf)
  thetaf@long_name = "Diurnal-Avg Zonal Wind"
  ncdf->theta = thetaf(z|:,Time|:)

end
