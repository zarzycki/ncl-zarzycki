;   Example script to produce plots for a WRF real-data run,
;   with the ARW coordinate dynamics option.
;   Interpolating to specified pressure levels

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "/glade/u/home/ckruse/git/ncl/kruse.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"

begin


;for i in $(seq 2010 2018); do ncl bincam.ncl in_yyyy=${i}; done

  cmzconfig="x087"
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

  file_created=False
  ; start with cam data

  datadir = "/glade/u/home/zarzycki/scratch/FHIST-ne30-betacast-ERA5-"+cmzconfig+"/run/"+cmzyyyy+"061600/"
  allfiles = systemfunc("ls "+datadir+"*.cam.h4.????-0[7]*.nc")
  print(allfiles)

  files = allfiles
  nf = dimsizes(files)
  a = addfiles(files,"r")
  
  z = new((/nf,nt,32/),double)
  zi = new((/nf,nt,33/),double)
  pi = new((/nf,nt,33/),double)
  dp = new((/nf,nt,32/),double)
  v = new((/nf,nt,32/),double)
  u = new((/nf,nt,32/),double)
  wind = new((/nf,nt,32/),double)
  vint = new((/nf,nt/),double)
  
  ZVAR="Z3_97.49w_36.61n"
  PHISVAR="PHIS_97.49w_36.61n"
  PSVAR="PS_97.49w_36.61n"
  VVAR="Nudge_V_97.49w_36.61n"
  UVAR="Nudge_U_97.49w_36.61n"

  p0=1000.
  p0@units="Pa"
  hyai=a[0]->hyai
  hybi=a[0]->hybi

  do fi=0,nf-1
    v(fi,:,:) = a[fi]->$VVAR$(:,:,0)
    u(fi,:,:) = a[fi]->$UVAR$(:,:,0)
    wind(fi,:,:) = sqrt(u(fi,:,:)^2. + v(fi,:,:)^2.)
    do kk=0,nt-1
      pi(fi,kk,:) = hyai * p0 + hybi * a[fi]->$PSVAR$(kk,0)
      dp(fi,kk,:) =  pi(fi,kk,1:32) - pi(fi,kk,0:31)
      vint(fi,kk) = wgt_vertical_n(wind(fi,kk,:),dp(fi,kk,:),1,0)
    end do
  end do
  
  stinds = ispan(0,23,1)*2
  spinds = stinds+1

  vdavg = dim_avg_n(v,0)
  vdiavg = dim_avg_n(vint,0)

  vdhavg = 0.5*(vdavg(stinds,:) + vdavg(spinds,:))
  vf = vdhavg

  vdihavg = 0.5*(vdiavg(stinds) + vdiavg(spinds))
  vfi = vdihavg
  
  print(vfi)
  print(avg(vfi)+"")
  

  
  
  
  outfname="test.nc"
  system("/bin/rm -f "+outfname)
  ncdf = addfile(outfname,"c")
  print(outfname+" file created")
  ;filedimdef(ncdf,"Time",-1,True)

  vf!0 = "Time"
  vf!1 = "lev"
  vf&lev=a[0]->lev
   ; invert for plotting
  ncdf->vf = vf(lev|:,Time|:)

  
  
end
