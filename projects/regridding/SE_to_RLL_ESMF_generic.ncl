begin


;---Data file containing source grid
srcGridName="conus_30_x8"
outDir="./"
outRes="0.125"
do_regional=True

mapNameTag="CONUS"
minLat=20.0
maxLat=55.0
minLon=-130.0
maxLon=-60.0

src_file = "/global/homes/c/czarzyck/scratch/e3sm_scratch/cori-knl/RoS-F2010C5-ne0conus30x8-001-control/run/1996011300/RoS-F2010C5-ne0conus30x8-001-control.eam.h0.1996-01-16-00000.nc"
var_name = "PSL"

sfile    = addfile(src_file,"r")
var      = sfile->$var_name$(0,:)
src_lat  = sfile->lat
src_lon  = sfile->lon

;---Set up regridding options
Opt                = True
Opt@InterpMethod     = "bilinear" ; "bilinear" is the default. "patch" and "conserve" are other options.

maskstr=""
add_mask=True
if (add_mask) then
  print("adding 2D mask")
  src_file2 = "/global/homes/c/czarzyck/scratch/e3sm_scratch/cori-knl/RoS-F2010C5-ne0conus30x8-001-control/run/1996011300/RoS-F2010C5-ne0conus30x8-001-control.elm.h0.1996-01-17-00000.nc"
  sfile2 = addfile(src_file2,"r")
  Opt@SrcMask2D    = sfile2->landmask
  maskstr="_MASK"
end if

Opt@SrcGridLat       = src_lat
Opt@SrcGridLon       = src_lon
Opt@SrcRegional      = False
Opt@SrcInputFileName = src_file

if (do_regional) then
  Opt@DstLLCorner      = (/ minLat, minLon /)      ;lat/lon
  Opt@DstURCorner      = (/ maxLat, maxLon /)      ;lat/lon (-90-90   0-360)
else
  mapNameTag="GLOB"
end if

Opt@DstGridType      = outRes+"x"+outRes       ; destination grid
Opt@ForceOverwrite   = True
Opt@Debug            = True
Opt@PrintTimings     = True

outname="map_"+srcGridName+"_to_"+Opt@DstGridType+"_"+mapNameTag+maskstr+".nc"
Opt@WgtFileName      = outDir+"/"+outname

var_regrid = ESMF_regrid(var,Opt)     ; Do the regridding

printVarSummary(var_regrid)

print("Successfully created "+Opt@WgtFileName)

end
