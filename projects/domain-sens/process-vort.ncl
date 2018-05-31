;========================================================
; =============== COMMAND LINE ARGS
; YYYYMMMDDHH (string) --- time of CFSR analysis
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
;========================================================
begin

;infile="/glade//scratch/zarzycki/archive/CHEY.VR28.NATL.WAT.CAM5.4CLM5.0.dtime900/atm/hist/CHEY.VR28.NATL.WAT.CAM5.4CLM5.0.dtime900.cam.h2.1986-04-20-00000.nc"
;wgt_file="/glade/p/work/zarzycki/maps/hyperion/map_ne0np4natlanticwat.ne30x4_to_1x1_bilinear.nc"

print("USING INFILE:  "+infile)
print("USING WEIGHTS: "+wgt_file)

print("Loading data... ")
in=addfile(infile,"r")
U=in->U(:,:,:)
V=in->V(:,:,:)
P=in->PRESSURE(:,:,:)
P=P/100.
print("... done loading data.")

print("Begin vertical interpolation... ")
linlog = -1   ; linear interpolation and extrapolation
po =(/ 600. /)                ; extrapolation
UP = int2p_n_Wrap (P,U,po,linlog,1)
VP = int2p_n_Wrap (P,V,po,linlog,1)
print("... done with vertical interpolation.")

print("Begin horizontal interpolation... ")
Opt         = True
UP_RLL = ESMF_regrid_with_weights(UP,wgt_file,Opt)
VP_RLL = ESMF_regrid_with_weights(VP,wgt_file,Opt)
;UP_RLL = ESMF_regrid_with_weights(U,wgt_file,Opt)
;VP_RLL = ESMF_regrid_with_weights(V,wgt_file,Opt)
;PP_RLL = ESMF_regrid_with_weights(P,wgt_file,Opt)
guess     = 1                ; use zonal means
is_cyclic = True             ; cyclic [global]
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

;VORT600=UP_RLL
;uv2vrf(UP_RLL,VP_RLL,VORT600)
VORT600 = uv2vr_cfd (UP_RLL(:,0,:,:),VP_RLL(:,0,:,:),lat,lon, 2)
copy_VarMeta(UP_RLL(:,0,:,:),VORT600)
VORT600@units="1/s"
VORT600@long_name="Vorticity"
print("... done with relative vorticity.")

print("flipping SH vort sign...")
VORT600=where(conform(VORT600,lat,1) .lt. 0.0,-VORT600,VORT600)
print("... done flipping SH vort sign.")



outfilename=str_sub_str(infile,"h2","h9")
outfilename=str_sub_str(outfilename,".nc",".VORT600.2p00.nc")
print(outfilename)

;===================================================================
system("/bin/rm -f "+outfilename)   ; remove any pre-existing file
ncdf = addfile(outfilename,"c")  ; open output netCDF file
fAtt               = True            ; assign file attributes
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes
filedimdef(ncdf,"time",-1,True) 

ncdf->VORT600 = VORT600
;===================================================================

end

