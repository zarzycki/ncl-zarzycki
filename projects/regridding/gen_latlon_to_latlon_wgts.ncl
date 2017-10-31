;========================================================
; TC_cross_and_latlon.ncl:   plots the PS, U, V, and T.
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
;========================================================

begin

InterpMethod="conserve"
outres="2.5x2.5"
dstGridDir="."
dstGridFile=outres+"_SCRIP.nc"
srcGridDir="/glade/u/home/zarzycki/work/grids/scrip/"
srcGridFile="AMIP_refined_interp_latlon_scrip.nc"
wgtFileName="AMIP_to_2.5x2.5_"+InterpMethod+".nc"

;----------------------------------------------------------------------

srcGridName=srcGridDir+"/"+srcGridFile
dstGridName=dstGridDir+"/"+dstGridFile

;----------------------------------------------------------------------
; First generate a regular SCRIP file
;----------------------------------------------------------------------

Opt                = True
Opt@ForceOverwrite = True
Opt@PrintTimings   = True

latlon_to_SCRIP(dstGridName,outres,Opt)

;---Clean up
delete(Opt)

;----------------------------------------------------------------------
; Now generate weights file
;----------------------------------------------------------------------

Opt                      = True
Opt@InterpMethod         = InterpMethod
Opt@ForceOverwrite       = True
Opt@PrintTimings         = True

ESMF_regrid_gen_weights(srcGridName,dstGridName,wgtFileName,Opt)

delete(Opt)

end
