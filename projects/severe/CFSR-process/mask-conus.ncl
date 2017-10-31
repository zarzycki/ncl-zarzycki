load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "/glade/u/home/zarzycki/ecsnow/shapefile_ncl/shapefile_mask_data.ncl"


begin


f = addfile("/glade/u/home/zarzycki/scratch/CFSR/FINAL/CATTED/cfsr-2009.nc","w")

SCP=f->SCP
SIGTOR=f->SIGTOR
SHIP=f->SHIP
PRECT=f->PRECT

lat=f->lat
lon=f->lon
time=f->time

lon=-(360.-SCP&lon)
SCP&lon=lon

nlat=dimsizes(lat)
nlon=dimsizes(lon)
ntime=dimsizes(time)

useExistingMask=True
outputMask=True
maskFileName="mask.nc"

print("Masking...")
if (useExistingMask) then
  maskFile=addfile(maskFileName,"r")
  MASK=maskFile->MASK
  do ii = 0,ntime-1
    SCP(ii,:,:) = where(MASK.gt.0.5,SCP(ii,:,:),0)
    PRECT(ii,:,:) = where(MASK.gt.0.5,PRECT(ii,:,:),0)
    SIGTOR(ii,:,:) = where(MASK.gt.0.5,SIGTOR(ii,:,:),0)
    SHIP(ii,:,:) = where(MASK.gt.0.5,SHIP(ii,:,:),0)
  end do
else
  shp_filename="/glade/u/home/zarzycki/ecsnow/shapefile_ncl/cb_2016_us_nation_20m.shp"
  opt = True
  opt@minlat=37.
  opt@maxlat=49.
  opt@minlon=-82.
  opt@maxlon=-66.
  opt@shape_var = "NAME"
  opt@shape_names = (/"United States"/)
  opt@DEBUG="True"
  var_mask = shapefile_mask_data(SCP(0,:,:),shp_filename,opt)
  if(outputMask) then
    MASK=var_mask
    MASK=where(ismissing(var_mask),0.0,1.0)
    system("/bin/rm -f "+maskFileName)   ; remove any pre-existing file
    ncdf = addfile(maskFileName ,"c")  ; open output netCDF file
    fAtt               = True            ; assign file attributes
    fAtt@Conventions   = "None"
    fAtt@creation_date = systemfunc ("date")
    fileattdef( ncdf, fAtt )
    ncdf->MASK  = MASK
  end if
end if
print("... done masking")

;system("/bin/rm -f simple.nc")   ; remove any pre-existing file
;ncdf = addfile("simple.nc" ,"c")  ; open output netCDF file;
;fAtt               = True            ; assign file attributes
;fAtt@title         = "NCL Simple Approach to netCDF Creation"
;fAtt@source_file   =  "original-file.nc"
;fAtt@Conventions   = "None"
;fAtt@creation_date = systemfunc ("date")
;fileattdef( ncdf, fAtt )            ; copy file attributes
;filedimdef(ncdf,"time",-1,True) 

f->SCP  = (/SCP/)          
f->PRECT  = (/PRECT/)          
f->SIGTOR  = (/SIGTOR/)          
f->SHIP  = (/SHIP/)          

end