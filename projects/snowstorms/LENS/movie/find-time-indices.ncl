load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin

vars=(/"PTYPE","PRECC","PRECL"/)
fullfiles=(/"/glade/u/home/zarzycki/scratch/LENS-snow/b.e11.BRCP85C5CNBDRD.f09_g16.035.cam.h2.PTYPE.2071010100Z-2080123118Z.nc","/glade/p/cesmLE/CESM-CAM5-BGC-LE/atm/proc/tseries/hourly1/PRECC/b.e11.BRCP85C5CNBDRD.f09_g16.035.cam.h3.PRECC.200601010000Z-210012312300Z.nc","/glade/p/cesmLE/CESM-CAM5-BGC-LE/atm/proc/tseries/hourly1/PRECL/b.e11.BRCP85C5CNBDRD.f09_g16.035.cam.h3.PRECL.200601010000Z-210012312300Z.nc"/)

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
  sttime=cd_inv_calendar(2080,02,22,18,00,00000,units,opt)
  entime=cd_inv_calendar(2080,02,26,18,00,00000,units,opt)

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