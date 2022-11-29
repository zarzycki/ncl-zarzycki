;   Example script to produce plots for a WRF real-data run,
;   with the ARW coordinate dynamics option.
;   Interpolating to specified pressure levels

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "/glade/u/home/ckruse/git/ncl/kruse.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"

begin


;for i in $(seq 2010 2018); do ncl bincam.ncl in_yyyy=${i}; done

  ii = 2016
  cmzconfig="x004"
  UVAR="PBLH_97.49w_36.61n"

  cmzyyyy=tostring(ii)
  print(cmzyyyy+"")

  datadir = "/glade/u/home/zarzycki/scratch/FHIST-ne30-betacast-ERA5-"+cmzconfig+"/run/"+cmzyyyy+"061600/"
  allfiles = systemfunc("ls "+datadir+"*.cam.h4.????-0[7]*.nc")
  a = addfiles(allfiles,"r")

  batadir = "/glade/u/home/zarzycki/scratch/FHIST-ne30-betacast-ERA5-x003/run/"+cmzyyyy+"061600/"
  bllfiles = systemfunc("ls "+batadir+"*.cam.h4.????-0[7]*.nc")
  b = addfiles(bllfiles,"r")
  
  PS_ref = a[:]->$UVAR$(:,0)
  PS_test = b[:]->$UVAR$(:,0)

  print(escorc(PS_ref,PS_test)+"")

  delete(a)
  delete(b)
  delete(PS_ref)
  delete(PS_test)
  delete(bllfiles)
  delete(allfiles)
  delete(cmzyyyy)
  delete(datadir)
  delete(batadir)
  
end
