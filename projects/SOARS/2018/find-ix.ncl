;========================================================
; This file reads in a traj file produced by the TC tracker
; and produces a lat-lon plot of trajectories color-coded by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "/glade/u/home/zarzycki/ncl/functions/surfaceWindCorrFactor.ncl"
load "/glade/u/home/zarzycki/ncl/functions/getTrajectoriesGeneric.ncl"
load "/glade/u/home/zarzycki/ncl/functions/mask_tc.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"
;========================================================

begin

TESTSTR=(/"MOBILE","MIAMI","HOUSTON","TAMPA","NEWORLEANS","COLIN"/)
TESTLAT=(/ 30.6954, 25.7617, 29.7604, 27.9506, 29.9511, 30.2500/)
TESTLON=(/-88.0399,-80.1918,-95.3698,-82.4572,-90.0715,-93.0000/)

outputname="indices.csv"
system("rm "+outputname)
quote = inttochar(34)
delim = ","

;filelist = systemfunc ("ls /glade/scratch/zarzycki/tmp/*cam.h2*") ; file paths
filelist = systemfunc ("ls ~/scratch/archive/CHEY.VR28.NATL.WAT.CAM5.4CLM5.0.dtime900/atm/hist/*cam.h2*") ; file paths

f1=addfile(filelist(0),"r")
lat=f1->lat
lon=f1->lon

do ii = 0,dimsizes(TESTLAT)-1
  gcdist = gc_latlon(TESTLAT(ii),TESTLON(ii),lat,lon,2,4)
  ix = minind(gcdist)
  print(ix+"")
  print(lat(ix)+"")
  print(lon(ix)+"")
  system("echo "+quote+ix+delim+TESTSTR(ii)+delim+TESTLAT(ii)+delim+TESTLON(ii)+     quote+" >> "+outputname)
end do

end