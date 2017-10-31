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

wcStrt     = systemfunc("date")

;---------------User settings----------------------------

slab1File="/glade/p/work/zarzycki/slab/ncl/SST-traj_slab.txt_CATTED.nc"
slab2File="/glade/p/work/zarzycki/slab/ncl/SST-traj_slab2.txt_CATTED.nc"

out_type = "pdf"

stormType="as" ; hurr or as

if (stormType .eq. "hurr") then
  minWind=32.0
  maxWind=999.0
  stormTypeStr="hurr."
else if (stormType .eq. "as") then
  minWind=0.0
  maxWind=999.0
  stormTypeStr="TCs"
else
  print("invalid storm type")
  exit
end if
end if

latBox=1.0
offset=-3
SSTthreshold=-0.5

f1=addfile(slab1File,"r")
SSTanom1=f1->SSTanom({offset},:,:,{latBox})
traj_wind1=f1->traj_10m_wind
voverf1=f1->voverf

f2=addfile(slab2File,"r")
SSTanom2=f2->SSTanom({offset},:,:,{latBox})
traj_wind2=f2->traj_10m_wind
voverf2=f2->voverf

SSTanom1cross = SSTanom1
SSTanom1cross = where(SSTanom1.le.SSTthreshold,1,SSTanom1@_FillValue)
SSTanom1cross_sum = dim_sum_n_Wrap(SSTanom1cross,1)
print(tofloat(num(SSTanom1cross_sum))/tofloat(dimsizes(SSTanom1cross_sum)))

SSTanom2cross = SSTanom2
SSTanom2cross = where(SSTanom2.le.SSTthreshold,1,SSTanom2@_FillValue)
SSTanom2cross_sum = dim_sum_n_Wrap(SSTanom2cross,1)
print(tofloat(num(SSTanom2cross_sum))/tofloat(dimsizes(SSTanom2cross_sum)))

;======================================================================================

wallClockElapseTime(wcStrt, "Time to complete simulation", 0)

end

