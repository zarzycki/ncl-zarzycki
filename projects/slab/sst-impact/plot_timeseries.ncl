;========================================================
; Reads 
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/glade/u/home/zarzycki/ncl/functions/mask_tc.ncl"
load "/glade/u/home/zarzycki/ncl/functions/surfaceWindCorrFactor.ncl"
load "/glade/u/home/zarzycki/ncl/functions/getTrajectories.ncl"
load "/glade/u/home/zarzycki/ncl/functions/bearing.ncl"
load "/glade/u/home/zarzycki/ncl/functions/LLfromDistBear.ncl"
;========================================================
begin

wcStrt     = systemfunc("date")

;---------------User settings----------------------------

slab1File="/glade/p/work/zarzycki/slab/ncl/SST-traj_slab.txt_CATTED.nc"

              
SSTfiles = systemfunc ("ls /glade/u/home/zarzycki/work/slab/SSTclimo/nhemi_30_x4.cam.SSTclimo.0000*_regrid.nc")
print(SSTfiles)
SSTfile      = addfiles (SSTfiles, "r")
ListSetType (SSTfile, "cat")
print("Loading SST data...")
SST = SSTfile[:]->SST
printVarSummary(SST)
SSTtime=SSTfile[:]->time

print(SSTtime)

out_type="x11"

latBox=1.0

f1=addfile(slab1File,"r")
SSTanom=f1->SSTanom(:,:,:,{latBox})
SSTanom_d0=SSTanom({0},:,:)
printVarSummary(SSTanom_d0)
SSTanom_mx=dim_min_n_Wrap(SSTanom,0)
printVarSummary(SSTanom_mx)
traj_wind=f1->traj_10m_wind
traj_lat=f1->traj_lat
traj_lon=f1->traj_lon
mm=toint(f1->traj_mm(:,:))
dd=toint(f1->traj_dd(:,:))
hh=toint(f1->traj_hh(:,:))
ndims=dimsizes(SSTanom)
nstorms=ndims(1)
nstorm_times=ndims(2)

exit

do i = 0,nstorms-1
do j = 0,nstorm_times-1
  if(.not.ismissing(SSTanom({0},i,j))) then
  time   = cd_inv_calendar(1220,mm(i,j),dd(i,j),hh(i,j),0,0,SSTtime@units, 0)
  print(" "+SST({time},{traj_lat(i,j)},{traj_lon(i,j)}))
  end if
end do
end do
;time, storm, stormtime

;f2=addfile(slab2File,"r")
;SSTanom2=f2->SSTanom(:,:,:,{latBox})
;traj_wind2=f2->traj_10m_wind
;voverf2=f2->voverf
;offsetArr2=SSTanom2&time


;======================================================================================

wallClockElapseTime(wcStrt, "Time to complete simulation", 0)

end

