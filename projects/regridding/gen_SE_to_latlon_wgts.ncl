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

gridName="WUSVR4"
InterpMethod="bilinear"
;outres="0.25x0.25"
outres="0.125x0.125"
;outres="0.5x0.5"
;outres="1x1"
;outres="2x2"
dstGridDir="./"
dstGridFile=outres+"_SCRIP.nc"
;srcGridDir="/glade/p/cesmdata/cseg/mapping/grids/"
srcGridDir=""
;srcGridDir="/glade/u/home/zarzycki/work/grids/scrip/"
;srcGridDir="/glade/u/home/zarzycki/work/ASD2017_files/grids/scrip/"
;srcGridFile="ne30np4_091226_pentagons.nc"
;srcGridFile="ne16np4_110512_pentagons.nc"
;srcGridFile="ne120np4_pentagons_100310.nc"
;srcGridFile="/global/homes/c/czarzyck/m2637/betacast/cesmfiles/grids/WesternUSA_111-55-28-14-7-4.g_scrip.nc"
srcGridFile="/global/homes/c/czarzyck/m2637/betacast/cesmfiles/grids/ne0np4westernus.ne30x32.g_scrip.nc"
;srcGridFile=gridName+".g_scrip.nc"
wgtFileDir="~/scratch/"
wgtFileName="map_"+gridName+"_to_"+outres+"_"+InterpMethod+".nc"

;----------------------------------------------------------------------

srcGridName=srcGridDir+"/"+srcGridFile
dstGridName=dstGridDir+"/"+dstGridFile

;----------------------------------------------------------------------
; First generate a regular SCRIP file
;----------------------------------------------------------------------

Opt                = True
Opt@ForceOverwrite = True
Opt@PrintTimings   = True

if (fileexists(dstGridName)) then
  print("Latlon scrip already exists...")
else
  latlon_to_SCRIP(dstGridName,outres,Opt)
end if

;---Clean up
delete(Opt)

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
