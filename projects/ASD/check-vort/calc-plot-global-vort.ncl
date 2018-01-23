load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

h4filename="/glade/u/home/zarzycki/acgd0005/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.mp15a-120a-US_t12.exp213/atm/hist/f.asd2017.cesm20b05.FAMIPC6CLM5.mp15a-120a-US_t12.exp213.cam.h3.1993-08-19-00000.nc"

h4file=addfile(h4filename,"r")
wgtname="/glade/p/work/zarzycki/ASD2017_files/offline-remap/map_mp15a-120a-US_to_0.25x0.25glob_patch.nc"

Uasd=h4file->U200(:,:)
Vasd=h4file->V200(:,:)

Opt                = True
Opt@ForceOverwrite = True
Opt@PrintTimings   = True
U=ESMF_regrid_with_weights(Uasd,wgtname,Opt)
V=ESMF_regrid_with_weights(Vasd,wgtname,Opt)

lat=U&lat
lon=U&lon

vort = uv2vr_cfd (U,V,lat,lon, 2)
copy_VarMeta(U,vort)
vort = vort/1e-5
vort@units="1E-5 1/s"
vort@long_name="Vorticity"
printVarSummary(vort)

outFileName="/glade/scratch/zarzycki/test-vort.nc"
system("/bin/rm -f "+outFileName)   ; remove any pre-existing file
ncdf = addfile(outFileName ,"c")  ; open output netCDF file
filedimdef(ncdf,"time",-1,True) 

ncdf->vort=vort

end
