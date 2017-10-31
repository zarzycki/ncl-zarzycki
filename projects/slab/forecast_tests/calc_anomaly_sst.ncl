; Inputs
; iniyear (1999)
; inimon (12)
; iniday (25)
; inisec (24000)
; filename

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin 
                          
;all_files = systemfunc ("ls /glade/scratch/zarzycki/DART_newgulf_30_x4/run/DART_newgulf_30_x4.cam.h0*.nc")
all_files = systemfunc ("ls /glade/scratch/zarzycki/compare_slab/yes_slab/DART_newgulf_30_x4.cam.h0*.nc")
print(all_files)
fall      = addfiles (all_files, "r")   ; note the "s" of addfile
ListSetType (fall, "cat")
PSL  = fall[:]->PSL
SST  = fall[:]->SST
U10  = fall[:]->U10
time = fall[:]->time
ntim = dimsizes(time)
baseSST = SST(0,:,:)

SSTanom = SST

do i = 0,ntim-1
  SSTanom(i,:,:) = SST(i,:,:) - baseSST(:,:)
end do

outFile="DART_katrina_2005082600_yes_slab.nc"
system("/bin/rm -f "+outFile)   ; remove any pre-existing file
ncdf = addfile(outFile ,"c")  ; open output netCDF file
fAtt               = True            ; assign file attributes
fAtt@title         = "SST anom using parameterized turb flux"
fAtt@source_file   =  all_files(0)
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes

filedimdef(ncdf,"time",-1,True) 

maxlat = 45
minlat = 25
maxlon = 284
minlon = 258
ncdf->PSL = PSL(:,{minlat:maxlat},{minlon:maxlon})
ncdf->SSTanom  = SSTanom(:,{minlat:maxlat},{minlon:maxlon})           
ncdf->U10  = U10(:,{minlat:maxlat},{minlon:maxlon}) 

end
