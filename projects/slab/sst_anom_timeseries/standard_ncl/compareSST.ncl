;========================================================
; Reads 
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/glade/u/home/zarzycki/ncl/functions/mask_tc.ncl"
load "/glade/u/home/zarzycki/ncl/functions/surfaceWindCorrFactor.ncl"
load "/glade/u/home/zarzycki/ncl/functions/getTrajectories.ncl"
load "/glade/u/home/zarzycki/ncl/functions/bearing.ncl"
load "/glade/u/home/zarzycki/ncl/functions/LLfromDistBear.ncl"
;========================================================
begin

minWind=32.0
maxWind=1000.0

oldfile="SSTanom_old.nc"
f1=addfile(oldfile,"r")
SSTanom1=f1->SSTanom(:,:)
traj_wind1=f1->traj_10m_wind

newfile="SST-traj_slab2.txt_CATTED.nc"
f2=addfile(newfile,"r")
SSTanom2=f2->SSTanom(:,:,:,{1.0})
traj_wind2=f2->traj_10m_wind


SSTanom2_1d = ndtooned(SSTanom2)



SSTanom2_nomissind = ind(.not.ismissing(SSTanom2_1d))
SSTanom2_nomiss = SSTanom2_1d(SSTanom2_nomissind)   



;do i = 0,994
;  print(SSTanom2_nomiss(i)+" "+SSTanom1(i)+"    "+(SSTanom2_nomiss(i)-SSTanom1(i)))
;end do


traj_wind2_1d = ndtooned(traj_wind2)
traj_wind2_nomissind = ind(.not.ismissing(traj_wind2_1d))
traj_wind2_nomiss = traj_wind2_1d(traj_wind2_nomissind)   

;do i = 0,994
;  print(traj_wind2_nomiss(i)+" "+traj_wind1(i)+"    "+(traj_wind2_nomiss(i)-traj_wind1(i)))
;end do



;===

SSTanom_all_new=SSTanom2
SSTanom_all_old=SSTanom1

do j = 0,dimsizes(SSTanom2&time)-1
  SSTanom_all_new(j,:,:)=where(traj_wind2 .ge. minWind .and. traj_wind2 .le. maxWind,SSTanom2(j,:,:),SSTanom2@_FillValue)
end do

do j = 0,dimsizes(SSTanom1&time)-1
  SSTanom_all_old(j,:)=where(traj_wind1 .ge. minWind .and. traj_wind1 .le. maxWind,SSTanom1(j,:),SSTanom1@_FillValue)
end do

print(avg(SSTanom_all_new))
print(avg(SSTanom_all_old))

avgSSTall=dim_avg_n_Wrap(SSTanom_all_new,(/1,2/))
print(avgSSTall)
avgSSTfast=dim_avg_n_Wrap(SSTanom_all_old,1)
print(avgSSTfast)



end

