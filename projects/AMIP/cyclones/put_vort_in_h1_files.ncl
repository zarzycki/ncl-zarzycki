;======================================================================
; ESMF_regrid_18.ncl
;======================================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

;filename = "/glade/u/home/zarzycki/scratch/h1files/atl30x4/1992/TEST/atl_30_x4_refine_nochem.cam.h1.1992-09-10-00000.nc"

debug = True

thefile = addfile(filename,"w")   ; note the "s" of addfile

if (debug) then
u850 = thefile->U850
v850 = thefile->V850
;ubot = thefile->UBOT
;vbot = thefile->VBOT

vr850 = v850
vr850 = uv2vrF(u850,v850)

;vrbot = vbot
;vrbot = uv2vrF(ubot,vbot)
end if

vr850sm = smth9_Wrap(vr850, 0.50, 0.50, True)

print("Begin interp")
guess     = 1                ; use zonal means
is_cyclic = True             ; cyclic [global]
nscan     = 50             ; usually much less than this
eps       = 1.e-2            ; variable dependent
relc      = 0.5              ; relaxation coefficient
opt       = 0                ; not used

poisson_grid_fill( vr850sm, is_cyclic, guess, nscan, eps, relc, opt)

thefile->VR850  = vr850
thefile->VR850SM  = vr850sm
;thefile->VRBOT = vrbot

end

