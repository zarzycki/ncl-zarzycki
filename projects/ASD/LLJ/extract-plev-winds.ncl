load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

;/glade/u/home/zarzycki/scratch/ASD/archive/f.asd2017.cesm20b05.FAMIPC6CLM5.ne30_g16.exp212/atm/hist/
;filename=""
f=addfile(filename,"r")
wgt_file="/glade/u/home/zarzycki/work/ASD2017_files/offline-remap/map_ne30_to_1x1reg_patch.nc"

U=f->U
V=f->V
PS=f->PS
hyam=f->hyam
hybm=f->hybm
p0=1000.

Opt         = True
Uint  = ESMF_regrid_with_weights(U,wgt_file,Opt)
Vint  = ESMF_regrid_with_weights(V,wgt_file,Opt)
PSint=  ESMF_regrid_with_weights(PS,wgt_file,Opt)

intlev=(/1000., 975., 950., 925., 900., 875., 850., 825., 800., 775., 750., 725., 700., 650., 600., 550., 500., 450., 400., 350., 300., 275., 250., 225., 200., 175., 150., 125., 100./)
Ulev = vinth2p(Uint,hyam,hybm,intlev,PSint,2,p0,1,True)
Vlev = vinth2p(Vint,hyam,hybm,intlev,PSint,2,p0,1,True)

outDir="/glade/u/home/zarzycki/scratch/ASD/LLJ/ne30_g16/"
outFile=outDir+"/"+filename

system("/bin/rm -f "+outFile)   ; remove any pre-existing file
ncdf = addfile(outFile ,"c")  ; open output netCDF file

fAtt               = True            ; assign file attributes
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes

filedimdef(ncdf,"time",-1,True) 

ncdf->U  = Ulev
ncdf->V  = Vlev
ncdf->PS = PSint

end
