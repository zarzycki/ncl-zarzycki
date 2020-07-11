begin

;infile="/glade//scratch/zarzycki/archive/CHEY.VR28.NATL.WAT.CAM5.4CLM5.0.dtime900/atm/hist/CHEY.VR28.NATL.WAT.CAM5.4CLM5.0.dtime900.cam.h2.1986-04-20-00000.nc"

print("USING INFILE:  "+infile)

print("Loading data... ")
in=addfile(infile,"w")
UP_RLL=in->U850(:,:,:)
VP_RLL=in->V850(:,:,:)

guess     = 1                ; use zonal means
is_cyclic = False             ; cyclic [global]
nscan     = 500             ; usually much less than this
eps       = 1.e-2            ; variable dependent
relc      = 0.5              ; relaxation coefficient
opt       = 0                ; not used
poisson_grid_fill( UP_RLL, is_cyclic, guess, nscan, eps, relc, opt)
poisson_grid_fill( VP_RLL, is_cyclic, guess, nscan, eps, relc, opt)
print("... done with horizontal interpolation.")

dims=dimsizes(UP_RLL)
print(dims)
;ntime=dims(0)
;nlat=dims(1)
;nlon=dims(2)
;lat = mslp&lat
;lon = mslp&lon

print("Begin relative vorticity... ")
lat=UP_RLL&lat
lon=UP_RLL&lon

;VORTXXX=UP_RLL
;uv2vrf(UP_RLL,VP_RLL,VORTXXX)
VORTXXX = uv2vr_cfd (UP_RLL(:,:,:),VP_RLL(:,:,:),lat,lon, 2)
copy_VarMeta(UP_RLL(:,:,:),VORTXXX)
VORTXXX@units="1/s"
VORTXXX@long_name="Relative vorticity"
print("... done with relative vorticity.")

print("flipping SH vort sign...")
VORTXXX=where(conform(VORTXXX,lat,1) .lt. 0.0,-VORTXXX,VORTXXX)
print("... done flipping SH vort sign.")

in->VORT850 = VORTXXX
;===================================================================

end

