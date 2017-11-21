;========================================================
; This file reads in a traj file produced by the TC tracker
; and produces a lat-lon plot of trajectories color-coded by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "/glade/u/home/zarzycki/ncl/functions/sorting.ncl"
;========================================================

begin

nsplits=5
delim=","
out_dir="."
out_name="input.txt"
arr1=fspan(8.,16.,nsplits) ; trajMinLength
arr2=fspan(3.5,5.5,nsplits)   ; pslFOdist
arr3=fspan(-6.0,-10.0,nsplits) ; wcFOmag
arr4=fspan(6.5,8.5,nsplits)   ; wcFOdist

quote = inttochar(34)

system("rm "+out_dir+"/"+out_name)

do i = 0,dimsizes(arr1)-1
do j = 0,dimsizes(arr2)-1
do k = 0,dimsizes(arr3)-1
do l = 0,dimsizes(arr4)-1
  str=arr1(i)+delim+arr2(j)+delim+arr3(k)+delim+arr4(l)
  print(str+" ")
  system("echo "+ str+" >> "+out_dir+"/"+out_name)
end do
end do
end do
end do

end
