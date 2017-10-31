load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

;src_file = addfile("/glade/scratch_cheyenne/zarzycki/MTD-example/test-grid/WRF4_hh-sum-20120602_220000_55--60-15--135_remapbil-ctr.nc","r")  
;src_file = addfile("/glade/u/home/zarzycki/scratch/MTD-example/obs-data/STAGE4_hh-sum-20130928_090000_51--66-24--125_remapbil.nc","r")
src_file = addfile("/glade/u/home/zarzycki/ncl/projects/asd/mesoscale-tracking/ST4.2017041507.01h.nc","r")

dstDir = "/glade/p/work/zarzycki/grids/scrip/"
;dstGridName = "WRF4km-andy-MTD_scrip.nc"
dstGridName = "STAGE4-4km-MTD_scrip.nc"

lat = src_file->g5_lat_0
lon = src_file->g5_lon_1

Opt                = True
Opt@ForceOverwrite = True
Opt@PrintTimings   = True
;Opt@Title          = "Curvilinear 4km WRF MODE destination"
Opt@Title          = "Curvilinear 4km STAGE4 MODE destination"


curvilinear_to_SCRIP(dstDir+dstGridName,lat,lon,Opt)



end
