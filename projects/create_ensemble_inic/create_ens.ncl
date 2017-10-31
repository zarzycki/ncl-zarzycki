load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

basFile = addfile("/glade/scratch/zarzycki/DART/katrinaIC/ens/SE30r4_Katrina.cam_0027.i.2005-08-26-00000.nc","r")
ensFile = addfile("/glade/scratch/zarzycki/DART/katrinaIC/ens/SE30r4_Katrina.cam_0027.i.2005-08-26-00000.05.nc","w")

lat = basFile->lat
lon = basFile->lon
lev = basFile->lev
ncol = dimsizes(lat)

hyai = basFile->hyai
hybi = basFile->hyai
hyam = basFile->hyam
hybm = basFile->hybm
P0   = basFile->P0

u = basFile->U
v = basFile->V
ps = basFile->PS
t = basFile->T
q = basFile->Q

random_setallseed(tointeger(systemfunc("date +%s")),tointeger(systemfunc("date +%s"))+5)

; perturb T
low   = 0.99
high  = 1.01
dimT  = dimsizes(t)
unf   = random_uniform(low, high, dimT)
print(unf(0,20,10))
print(max(t))
t     = t * unf
print(max(t))
unf   = random_uniform(low, high, dimT)
q     = q * unf

delete(unf)

dimP  = dimsizes(ps)
unf   = random_uniform(low, high, dimP)
ps     = ps * unf

ensFile->PS=ps
ensFile->U=u
ensFile->V=v
ensFile->T=t
ensFile->Q=q

end
