;   Example script to produce plots for a WRF real-data run,
;   with the ARW coordinate dynamics option.
;   Interpolating to specified pressure levels

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "/glade/u/home/ckruse/git/ncl/kruse.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"

begin




  cmzconfig="x128"
  cmzyyyy="2011"
  ;cmzyyyy=tostring(in_yyyy)
  
  setfileoption("nc","Format","LargeFile")

  f=addfile("CAM_"+cmzconfig+".nc","r")
  
  vpwp_var="vpwp_97.49w_36.61n"
  v_var="V_97.49w_36.61n"
  z_var="z"


  vpwp=f->$vpwp_var$
  v=f->$v_var$
  z=f->$z_var$

  nlev = dimsizes(z)
  print(nlev)
  
  dvdz = v
  dvdz(nlev-1,:) = 1000000.
  printVarSummary(dvdz)

  do ii = 0,23
    dvdz(0:nlev-2,ii) = (v(1:nlev-1,ii) - v(0:nlev-2,ii)) / (z(1:nlev-1) - z(0:nlev-2))
    if (ii .eq. 0) then
      print(v(:,0)+" "+z(:)+" "+vpwp(:,0)+" "+dvdz(:,0))
    end if
  end do
  
  keff = vpwp
  keff = -vpwp / dvdz
  keff = where(keff.lt.0,keff@_FillValue,keff)
  
  
  
  
  outfname="test.nc"
  system("/bin/rm -f "+outfname)
  ncdf = addfile(outfname,"c")
  print(outfname+" file created")
  ;filedimdef(ncdf,"Time",-1,True)

  ncdf->keff = keff
  ncdf->v = v
  
  
end