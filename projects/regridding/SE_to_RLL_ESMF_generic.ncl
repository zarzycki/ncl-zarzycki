load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin
;---Data file containing source grid
srcGridName="ne30np4"
outDir="/glade/scratch/zarzycki/"
outRes="1.0"
do_regional=True

;mapNameTag="CONUS"
;minLat=20.0
;maxLat=55.0
;minLon=-130.0
;maxLon=-60.0
mapNameTag="NATL"
minLat=0.0
maxLat=60.0
minLon=-105.0
maxLon=15.0
;mapNameTag="REG"
;minLat=-20.0
;maxLat=20.0
;minLon=-20.0
;maxLon=20.0

;src_file = "/glade/u/home/zarzycki/work/unigridFiles/"+srcGridName+"/topo/topo_"+srcGridName+"_smooth.nc"
;var_name = "PHIS"
;src_file = "/glade/u/home/zarzycki/scratch/init_routine/initial_data.cam.ne0np4tcfplane.ne15x8_template.nc.L030.homme.nc"
;var_name = "PS"
src_file = "/glade/u/home/zarzycki/scratch/archive/CHEY.111.GLOB.CAM5.4CLM5.0.dtime1800/atm/hist/CHEY.111.GLOB.CAM5.4CLM5.0.dtime1800.cam.h0.1984-01.nc"
var_name = "PS"

sfile    = addfile(src_file,"r")
var      = sfile->$var_name$(0,:)
src_lat  = sfile->lat
src_lon  = sfile->lon

;---Set up regridding options
Opt                = True

;---"bilinear" is the default. "patch" and "conserve" are other options.
Opt@InterpMethod     = "bilinear"

Opt@SrcGridLat       = src_lat
Opt@SrcGridLon       = src_lon
Opt@SrcRegional      = False
Opt@SrcInputFileName = src_file

if (do_regional) then
  Opt@DstLLCorner      = (/ minLat,  minLon /)      ;lat/lon
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

end
