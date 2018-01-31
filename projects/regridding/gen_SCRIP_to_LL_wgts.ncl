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

gridName="conus_60_x4"
InterpMethod="patch"  ;bilinear, patch, conserve, nearestdtos, neareststod
regional=False
atlantic=False
tctest=False

; RLL GRID
outres="0.25x0.25"
;outres="0.125x0.125"
;outres="0.5x0.5"
;outres="1x1"
srcGridDir="/glade/u/home/zarzycki/work/grids/scrip/"
srcGridFile=gridName+".g_scrip.nc"
;srcGridDir="/glade/p/work/zarzycki/ASD2017_files/grids/scrip/"
;srcGridFile="mp15a-120a-US.grid.170118.nc"
;srcGridFile="mp120a_grid_140708.nc"
;srcGridFile="ne30np4_091226_pentagons.nc"
;srcGridFile="uniform_240.g_scrip.nc"

; RLL GRID
;dstGridDir="."
dstGridDir="/glade/p/work/zarzycki/grids/scrip/"
if (regional) then
  dstGridFile=outres+"_reg_SCRIP.nc"
  wgtFileName="map_"+gridName+"_to_"+outres+"reg_"+InterpMethod+".nc"
else if (atlantic) then
  dstGridFile=outres+"_atl_SCRIP.nc"
  wgtFileName="map_"+gridName+"_to_"+outres+"atl_"+InterpMethod+".nc"
else if (tctest) then
  dstGridFile=outres+"_tctest_SCRIP.nc"
  wgtFileName="map_"+gridName+"_to_"+outres+"tctest_"+InterpMethod+".nc"
else
  dstGridFile=outres+"_SCRIP.nc"
  wgtFileName="map_"+gridName+"_to_"+outres+"glob_"+InterpMethod+".nc"
end if
end if
end if
wgtFileDir="/glade/scratch/zarzycki/"

;----------------------------------------------------------------------

srcGridName=srcGridDir+"/"+srcGridFile
dstGridName=dstGridDir+"/"+dstGridFile

;----------------------------------------------------------------------
; First generate a regular SCRIP file
;----------------------------------------------------------------------

Opt                = True
Opt@ForceOverwrite = True
Opt@PrintTimings   = True
Opt@Debug = True

; ASD regional
;if (regional) then
;  Opt@LLCorner      = (/10.0d, 230.0d /) 
;  Opt@URCorner      = (/55.0d, 299.0d /)
;end if
;if (atlantic) then
;  Opt@LLCorner      = (/5.0d, 250.0d /)
;  Opt@URCorner      = (/55.0d,355.0d /)
;end if
if (tctest) then
  Opt@LLCorner      = (/10.0d, 65.0d /) 
  Opt@URCorner      = (/45.0d, 115.0d /)
end if

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
