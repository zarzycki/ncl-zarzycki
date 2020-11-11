ffv = addfile("/glade/p/cesmdata/cseg/inputdata/atm/cam/inic/fv/f.e22.FC2010climo.f09_f09_mg17.cam6_2_022.001.cam.i.0016-01-01-00000_c200610.nc","r")

T = ffv->T
lat = ffv->lat
lon = ffv->lon

moddims = dimsizes(T)
ntim = moddims(0)
nlev = moddims(1)
nlat = moddims(2)
nlon = moddims(3)
nnco = nlat*nlon

lat2d=conform_dims((/nlat,nlon/),lat,0)
lon2d=conform_dims((/nlat,nlon/),lon,1)

T_se = new((/ntim,nlev,nnco/),"float")
lat_se = ndtooned(lat2d)
lon_se = ndtooned(lon2d)

do zz = 0,ntim-1
  do kk = 0,nlev-1
    T_se(zz,kk,:) = ndtooned(T(zz,kk,:,:))
  end do
end do

lat_se!0="ncol"
lon_se!0="ncol"

copy_VarAtts(T,T_se)

T_se!0="time"
T_se!1="lev"
T_se!2="ncol"

T_se&time=T&time
T_se&lev=T&lev

printVarSummary(T_se)
printVarSummary(lat_se)
printVarSummary(lon_se)

; write netcdf
system("/bin/rm -f simple.nc")   ; remove any pre-existing file
ncdf = addfile("simple.nc" ,"c")  ; open output netCDF file
fAtt               = True            ; assign file attributes
fAtt@title         = "NCL Simple Approach to netCDF Creation"
fAtt@source_file   =  "original-file.nc"
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( ncdf, fAtt )            ; copy file attributes
filedimdef(ncdf,"time",-1,True) 
ncdf->lat  = lat_se
ncdf->lon = lon_se
ncdf->T = T_se