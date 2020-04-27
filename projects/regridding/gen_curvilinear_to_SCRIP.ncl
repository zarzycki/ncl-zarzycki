load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

;src_file = addfile("/glade/u/home/zarzycki/scratch/NARR/2005/merged_AWIP32.2005082100.3D.grb2","r")  
src_file = addfile("/glade/u/home/zarzycki/scratch/NARR/merged_AWIP32.2005082200.3D.grb2","r")  

dstDir = "./"
dstGridName = "NARR_SCRIP.nc"

lat = src_file->gridlat_221
lon = src_file->gridlon_221

lon  = where(lon.lt.0,lon+360.0,lon)


Opt                = True
Opt@ForceOverwrite = True
Opt@PrintTimings   = True

curvilinear_to_SCRIP(dstDir+dstGridName,lat,lon,Opt)

end
