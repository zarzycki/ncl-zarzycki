load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin

vars=(/"PTYPE","PRECC","PRECL"/)
ensnum="035"
years="1990010100Z-2005123118Z"
fullfiles=(/"/glade/u/home/zarzycki/scratch/LENS-snow/b.e11.B20TRC5CNBDRD.f09_g16."+ensnum+".cam.h2.PTYPE."+years+".nc", \
    "/glade/p/cesmLE/CESM-CAM5-BGC-LE/atm/proc/tseries/hourly1/PRECC/b.e11.B20TRC5CNBDRD.f09_g16."+ensnum+".cam.h3.PRECC.195001010000Z-200512312300Z.nc", \
    "/glade/p/cesmLE/CESM-CAM5-BGC-LE/atm/proc/tseries/hourly1/PRECL/b.e11.B20TRC5CNBDRD.f09_g16."+ensnum+".cam.h3.PRECL.195001010000Z-200512312300Z.nc"/)

;/glade/scratch/zarzycki/LES-snow/storm-files//ind-storms.LENS.1990.035.5e-9_12.nc.tempest.nc,XXX,00233,1995020700,090, 32.61,5
;/glade/scratch/zarzycki/LES-snow/storm-files//ind-storms.LENS.1990.035.5e-9_12.nc.tempest.nc,XXX,00346,1997120612,126, 48.44,5


do ii = 0,(dimsizes(vars)-1)

  var = vars(ii)
  fullfile = fullfiles(ii)

  timesub="timeArr.nc"
  slicefile="slice-"+var+".nc"

  system("rm "+timesub)
  system("rm "+slicefile)

  system("ncks -v time "+fullfile+" "+timesub)

  f=addfile(timesub,"r")

  time=f->time

  units=time@units
  opt=0
  opt@calendar=time@calendar

  ;00393,2080022218,090
  ;2002112506
  sttime=cd_inv_calendar(1997,12,06,00,00,00000,units,opt)
  entime=cd_inv_calendar(1997,12,11,00,00,00000,units,opt)

  print(sttime)
  print(entime)

  stindex  = closest_val(sttime,time)
  enindex  = closest_val(entime,time)

  print(stindex)
  print(enindex)

  system("ncks -d time,"+stindex+","+enindex+" "+fullfile+" "+slicefile)

  system("rm "+timesub)

  delete(time)
  delete(sttime)
  delete(entime)

end do

end