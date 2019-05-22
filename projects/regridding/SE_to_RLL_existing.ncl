load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin
;---Data file containing source grid
srcGridName="ne0np4natlanticwat.ne30x4"

dst_file=addfile("./CPC_gauge_precip_1985-2017.nc","r")
mapNameTag="CPC"

;---Set up regridding options
Opt                = True

;---"bilinear" is the default. "patch" and "conserve" are other options.
Opt@InterpMethod     = "conserve"

Opt@ForceOverwrite   = True
Opt@Debug            = True
Opt@PrintTimings     = True

rectilinear_to_SCRIP("tmp.nc",dst_file->lat,dst_file->lon,Opt)

outname="map_"+srcGridName+"_to_"+mapNameTag+"_"+Opt@InterpMethod+".nc"

dstGridName="CPC"

ESMF_regrid_gen_weights("/glade/u/home/zarzycki/work/grids/scrip/"+srcGridName+".g_scrip.nc","tmp.nc",outname,Opt)

end
