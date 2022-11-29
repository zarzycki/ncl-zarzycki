begin

srcGridName="ne0natlantic30x4"
outDir="/glade/scratch/$LOGNAME/"
outRes="0.25"
do_regional=True

mapNameTag="TROPNATL"
minLat=5.0
maxLat=35.0
minLon=-90.0
maxLon=-15.0

src_file = "/glade/u/home/zarzycki/scratch/ne0natlantic30x4-FHIST/run/2003091200/ne0natlantic30x4-FHIST.cam.h0.2003-09-12-00000.nc"
var_name = "PS"

sfile    = addfile(src_file,"r")
var      = sfile->$var_name$(0,:)
src_lat  = sfile->lat
src_lon  = sfile->lon

;---Set up regridding options
Opt                = True
Opt@InterpMethod     = "bilinear" ; "bilinear" is the default. "patch" and "conserve" are other options.

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

outname="map_"+srcGridName+"_to_"+Opt@DstGridType+"_"+mapNameTag+".nc"
Opt@WgtFileName      = outDir+"/"+outname

var_regrid = ESMF_regrid(var,Opt)     ; Do the regridding

printVarSummary(var_regrid)

print("Successfully created "+Opt@WgtFileName)

end
