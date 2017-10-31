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

InterpMethod="bilinear"   ;bilinear, patch, conserve

;srcName="conus30x8"
;srcGridDir="/glade/p/work/zarzycki/grids/scrip/"
;srcGridFile="conus_30_x8.g_scrip.nc"

dstName="0.125x0.125reg"
dstGridDir="/glade/u/home/zarzycki/work/grids/scrip/"
dstGridFile="0.125x0.125_reg_SCRIP.nc"

;dstName="1x1"
;dstGridDir="/glade/u/home/zarzycki/work/grids/scrip/"
;dstGridFile="1x1_SCRIP.nc"



srcName="STAGE4-4km-curv-MODE"
srcGridDir="/glade/p/work/zarzycki/grids/scrip/"
srcGridFile="STAGE4-4km-MTD_scrip.nc"

wgtFileDir="/glade/scratch/zarzycki/"
if (InterpMethod .eq. "patch") then
  interpString="patc"
end if
if (InterpMethod .eq. "bilinear") then
  interpString="blin"
end if
if (InterpMethod .eq. "conserve") then
  interpString="aave"
end if
cdate=systemfunc("date +%y%m%d")
wgtFileName="map_"+srcName+"_TO_"+dstName+"_"+interpString+"."+cdate+".nc"



;----------------------------------------------------------------------

srcGridName=srcGridDir+"/"+srcGridFile
dstGridName=dstGridDir+"/"+dstGridFile

;----------------------------------------------------------------------
; Now generate weights file
;----------------------------------------------------------------------

Opt                      = True
Opt@InterpMethod         = InterpMethod
Opt@ForceOverwrite       = True
Opt@PrintTimings         = True

ESMF_regrid_gen_weights(srcGridName,dstGridName,wgtFileDir+"/"+wgtFileName,Opt)

delete(Opt)

end
