load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

;basFileName="/global/homes/c/czarzyck/scratch/unigrid_files/haiyan_48_x8/inic/haiyan_48_x8_INIC_filter.nc"
;ensFileName="/global/homes/c/czarzyck/scratch/unigrid_files/haiyan_48_x8/inic/haiyan_48_x8_INIC_filter.nc"
pertMag=0.01
basFile = addfile(basFileName,"r")
ensFile = addfile(ensFileName,"w")

print(basFileName)
print(ensFileName)
print(pertMag)

lat = basFile->lat
lon = basFile->lon
lev = basFile->lev
ncol = dimsizes(lat)

hyai = basFile->hyai
hybi = basFile->hyai
hyam = basFile->hyam
hybm = basFile->hybm
P0   = basFile->P0

ps = basFile->PS
t = basFile->T
q = basFile->Q

random_setallseed(tointeger(systemfunc("date +%s")),tointeger(systemfunc("date +%s"))+5)

; perturb T
low   = 1.0-pertMag
high  = 1.0+pertMag
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
ensFile->T=t
ensFile->Q=q

exit

end
