load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

pertMag=0.01

basFile = addfile("/glade/p/work/zarzycki/unigridFiles/nhemi_30_x4/restart/nhemi_30_x4.cam.i.1001-05-01-00000.nc","r")

if (version .eq. "slab") then
  ensFile = addfile("/glade/p/work/zarzycki/unigridFiles/nhemi_30_x4/restart/nhemi_30_x4.cam.i.1001-05-01-00000.ens2.nc","w")
else if (version .eq. "slab2") then
  ensFile = addfile("/glade/p/work/zarzycki/unigridFiles/nhemi_30_x4/restart/nhemi_30_x4.cam.i.1001-05-01-00000.ens3.nc","w")
else if (version .eq. "fixedSST") then
  ensFile = addfile("/glade/p/work/zarzycki/unigridFiles/nhemi_30_x4/restart/nhemi_30_x4.cam.i.1001-05-01-00000.ens.nc","w")
else
  print("Bad version...")
  exit
end if
end if
end if

pertMagPerc=pertMag*100.
print("We are using perturbation magnitude of: "+pertMagPerc+"%")

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
print("orig Tmax: "+max(t))
t     = t * unf
print("new Tmax: "+max(t))
unf   = random_uniform(low, high, dimT)
print("orig Qmax: "+max(q))
q     = q * unf
print("new Qmax: "+max(q))

delete(unf)

dimP  = dimsizes(ps)
unf   = random_uniform(low, high, dimP)
print("orig PSmax: "+max(ps))
ps     = ps * unf
print("new PSmax: "+max(ps))

ensFile->PS=ps
ensFile->T=t
ensFile->Q=q

end
