load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

pertMag=0.00001

;basFile = addfile("/glade/u/home/zarzycki/scratch/archive/FHIST.f09.PROGMOM/rest/1985-01-01-00000/FHIST.f09.PROGMOM.cam.i.1985-01-01-00000.nc","w")
;basFile = addfile("~/scratch/CHEY.VR28.NATL.REF.CAM5.4CLM5.0.tau3600_noZM/run/CHEY.VR28.NATL.REF.CAM5.4CLM5.0.tau3600_noZM.cam.r.1987-07-01-00000.nc","w")
basFile = addfile("~/scratch/CHEY.VR28.NATL.REF.CAM5.4CLM5.0.tau3600_noZM/run/CHEY.VR28.NATL.REF.CAM5.4CLM5.0.tau3600_noZM.cam.r.1988-01-01-00000.nc","w")

pertMagPerc=pertMag*100.
print("We are using perturbation magnitude of: "+pertMagPerc+"%")

ps = basFile->PSDRY
t = basFile->T
q = basFile->dpQ

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

basFile->PSDRY=ps
basFile->T=t
basFile->dpQ=q

end
